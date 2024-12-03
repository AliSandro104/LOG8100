#!/bin/bash

# Function to check if a specific port-forward process is running
check_port_forward() {
    local service=$1
    local pattern=$2
    pgrep -f "$pattern" > /dev/null
    return $?
}

# Function to start a specific port-forward
start_port_forward() {
    local service=$1
    echo "$(date): Starting port-forward for $service..." >> /tmp/monitor-port-forward.log
    
    case $service in
        "nginx")
            sudo nohup kubectl port-forward --address 0.0.0.0 service/nginx-ingress-ingress-nginx-controller -n ingress-nginx 80:80 443:443 > /tmp/port-forward-nginx.log 2>&1 &
            ;;
        "prometheus")
            sudo nohup kubectl port-forward --address 0.0.0.0 service/prometheus-server -n prometheus 9090:80 > /tmp/port-forward-prometheus.log 2>&1 &
            ;;
        "alertmanager")
            sudo nohup kubectl port-forward --address 0.0.0.0 service/prometheus-alertmanager -n prometheus 9093:9093 > /tmp/port-forward-alertmanager.log 2>&1 &
            ;;
        "grafana")
            sudo nohup kubectl port-forward --address 0.0.0.0 --namespace grafana service/grafana 3000:80 > /tmp/port-forward-grafana.log 2>&1 &
            ;;
    esac
    sleep 5  # Wait for process to start
}

# Function to check and restart a service if needed
monitor_service() {
    local service=$1
    local pattern=$2
    
    if ! check_port_forward "$service" "$pattern"; then
        echo "$(date): $service port-forward not running. Restarting..." >> /tmp/monitor-port-forward.log
        # Kill any existing port-forward processes (cleanup)
        pkill -f "$pattern"
        start_port_forward "$service"
    fi
}

# Main loop
while true; do
    # Monitor nginx-ingress
    monitor_service "nginx" "kubectl port-forward.*nginx-ingress.*80:80 443:443"
    
    # Monitor prometheus
    monitor_service "prometheus" "kubectl port-forward.*prometheus-server.*9090:80"
    
    # Monitor grafana
    monitor_service "grafana" "kubectl port-forward.*grafana.*3000:80"
    
    sleep 5  # Check every 5 seconds
done