#!/bin/bash

set -e

echo "🛠️  Updating system..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Install Prometheus
echo "📥 Installing Prometheus..."
cd /tmp
PROM_VERSION="2.52.0"
wget https://github.com/prometheus/prometheus/releases/download/v$PROM_VERSION/prometheus-$PROM_VERSION.linux-amd64.tar.gz
tar -xvf prometheus-$PROM_VERSION.linux-amd64.tar.gz
sudo mv prometheus-$PROM_VERSION.linux-amd64 /opt/prometheus

# Create Prometheus user
sudo useradd --no-create-home --shell /bin/false prometheus || true

# Set permissions
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo cp /opt/prometheus/prometheus /opt/prometheus/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool
sudo cp -r /opt/prometheus/consoles /opt/prometheus/console_libraries /etc/prometheus/
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

# Sample prometheus.yml config
cat <<EOF | sudo tee /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

rule_files:
  - "/etc/prometheus/test_alert.rules.yml"

alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - localhost:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

# Sample test_alert.rules.yml config
cat <<EOF | sudo tee /etc/prometheus/test_alert.rules.yml
groups:
- name: test_alert
  rules:
  - alert: TestAlert
    expr: vector(1)
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "This is a test alert"
      description: "This alert is triggered for testing purposes."      
EOF

# Prometheus systemd service
cat <<EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Monitoring
After=network.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus/

[Install]
WantedBy=multi-user.target
EOF

# Install Node Exporter
echo "📥 Installing Node Exporter..."
NODE_EXPORTER_VERSION="1.8.0"
wget https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
tar -xvf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
sudo mv node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter /usr/local/bin/
sudo useradd --no-create-home --shell /bin/false node_exporter || true

# Node Exporter systemd service
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Install Grafana (updated GPG and repo)
echo "📥 Installing Grafana..."

sudo apt-get install -y apt-transport-https software-properties-common curl gnupg

sudo rm -f /etc/apt/sources.list.d/grafana.list
sudo rm -f /etc/apt/keyrings/grafana.gpg

sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://packages.grafana.com/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/grafana.gpg

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

sudo apt-get update -y
sudo apt-get install -y grafana

# Install Alertmanager
echo "📥 Installing Alertmanager..."
ALERTMANAGER_VERSION="0.26.0"
cd /tmp
wget https://github.com/prometheus/alertmanager/releases/download/v$ALERTMANAGER_VERSION/alertmanager-$ALERTMANAGER_VERSION.linux-amd64.tar.gz
tar -xvf alertmanager-$ALERTMANAGER_VERSION.linux-amd64.tar.gz
sudo mv alertmanager-$ALERTMANAGER_VERSION.linux-amd64 /opt/alertmanager

# Create Alertmanager user and directories
sudo useradd --no-create-home --shell /bin/false alertmanager || true
sudo mkdir -p /etc/alertmanager /var/lib/alertmanager
sudo cp /opt/alertmanager/alertmanager /opt/alertmanager/amtool /usr/local/bin/
sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager /usr/local/bin/amtool
#sudo cp -r /opt/alertmanager/templates /etc/alertmanager/
sudo chown -R alertmanager:alertmanager /etc/alertmanager /var/lib/alertmanager

# Sample alertmanager.yml config (update your Slack webhook accordingly)
cat <<EOF | sudo tee /etc/alertmanager/alertmanager.yml
global:
  resolve_timeout: 5m

route:
  receiver: 'slack-notifications'

receivers:
  - name: 'slack-notifications'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#alerts'
        send_resolved: true
EOF

# Alertmanager systemd service
cat <<EOF | sudo tee /etc/systemd/system/alertmanager.service
[Unit]
Description=Prometheus Alertmanager
After=network.target

[Service]
User=alertmanager
ExecStart=/usr/local/bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --storage.path=/var/lib/alertmanager

[Install]
WantedBy=multi-user.target
EOF

# Enable and start all services
echo "🚀 Enabling and starting services..."
sudo systemctl daemon-reload

sudo systemctl enable prometheus
sudo systemctl start prometheus

sudo systemctl enable node_exporter
sudo systemctl start node_exporter

sudo systemctl enable grafana-server
sudo systemctl start grafana-server

sudo systemctl enable alertmanager
sudo systemctl start alertmanager

echo "✅ Monitoring stack installed successfully!"
echo "-------------------------------------------------"
echo "Prometheus: http://<server_ip>:9090"
echo "Node Exporter: http://<server_ip>:9100/metrics"
echo "Grafana: http://<server_ip>:3000  (default admin/admin)"
echo "Alertmanager: http://<server_ip>:9093"
echo "-------------------------------------------------"
