# main.tf

# Define Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "LOG8100_K8S"
  location = "Canada Central"
}

# Define Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "project_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Define Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "project_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Define Public IP Address
resource "azurerm_public_ip" "public_ip" {
  name                = "project_public_ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = "team-1-log8100-project"
}

# Define Network Security Group (NSG) with SSH, HTTP, and HTTPS rules
resource "azurerm_network_security_group" "nsg" {
  name                = "project_nsg"
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
}

# Define Network Interface (NIC)
resource "azurerm_network_interface" "nic" {
  name                = "project_nic"
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
  name                = "projectLinuxVm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"

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
      # Create the ansible user and set its password
      "sudo useradd -m -s /bin/bash ansible",
      "echo 'ansible:{{var.ansible_user_password}}' | sudo chpasswd",
      # Grant the ansible user passwordless sudo privileges
      "echo 'ansible ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ansible",
      # Ensure SSH access is enabled for the ansible user
      "sudo mkdir -p /home/ansible/.ssh",
      "sudo cp /root/.ssh/authorized_keys /home/ansible/.ssh/",
      "sudo chown -R ansible:ansible /home/ansible/.ssh",
      "sudo chmod 700 /home/ansible/.ssh",
      "sudo chmod 600 /home/ansible/.ssh/authorized_keys",
      # Setup pip3 + libraries
      "apt install python3-pip",
      "pip3 install kubernetes",
      # Install Ansible
      "sudo apt-get update",
      "sudo apt-get install -y software-properties-common",
      "sudo apt-add-repository --yes --update ppa:ansible/ansible",
      "sudo apt-get install -y ansible",
      # Fetch IaC scripts
      # "git clone {{var.iac_remote_repository_url}} /opt/iac"
      # "cd /opt/iac/ansible"
      # "ansible-playbook master.yml"
    ]
  }

}
