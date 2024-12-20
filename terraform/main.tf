# main.tf

# Define Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "LOG8100_PROJECT_K8S"
  location = "Canada Central"
}

# Define Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "log8100_project_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Define Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "log8100_project_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Define Public IP Address
resource "azurerm_public_ip" "public_ip" {
  name                = "log8100_project_public_ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  domain_name_label   = "team-1-log8100-project"
}

# Define Network Security Group (NSG) with SSH, HTTP, and HTTPS rules
resource "azurerm_network_security_group" "nsg" {
  name                = "log8100_project_nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Prometheus"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9090"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Grafana"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_AlertManager"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9093"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Kubecost"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9095"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Define Network Interface (NIC)
resource "azurerm_network_interface" "nic" {
  name                = "log8100_project_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Create SSH Key Pair for VM Access (Linux VM)
resource "tls_private_key" "example_ssh_key" {
  algorithm   = "RSA"
  rsa_bits    = 4096
}

# Output SSH Private Key for VM Access (Sensitive)
output "tls_private_key_pem" {
  value       = tls_private_key.example_ssh_key.private_key_pem
  sensitive   = true
}

# Define Linux Virtual Machine (Ubuntu)
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "Log8100WebGoat"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2ms"

  admin_username      = var.admin_username
  admin_password      = var.admin_password

  disable_password_authentication = false

  network_interface_ids   = [azurerm_network_interface.nic.id]
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 50
    name                 = "${var.admin_username}-os-disk"
  }

  source_image_reference {
    publisher   = "Canonical"
    offer       = "0001-com-ubuntu-server-jammy"
    sku         = "22_04-lts"
    version     = "latest"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.example_ssh_key.public_key_openssh
  }

  # Ensure that the VM waits for the public IP to be assigned before running the provisioner
  depends_on = [azurerm_public_ip.public_ip]

  # Use remote-exec provisioner to install Ansible
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = var.admin_username
      private_key = tls_private_key.example_ssh_key.private_key_pem
      host     = azurerm_public_ip.public_ip.ip_address
    }

    inline = [
      # Install python related packages
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip",
      "sudo pip3 install kubernetes",
      # Install Ansible
      "sudo apt-get install -y software-properties-common",
      "sudo apt-add-repository --yes --update ppa:ansible/ansible",
      "sudo apt-get install -y ansible",
      "sudo git clone {{var.iac_remote_repository_url}} /opt/iac",
      "cd /opt/iac/ansible",
      "sudo ansible-playbook master.yml",
      "cd /opt/iac/systemd",
      "./monitor-port-forward.sh &"
    ]
  }

}
