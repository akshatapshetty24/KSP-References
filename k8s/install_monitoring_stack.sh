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
sudo useradd --no-create-home --shell /bin/false prometheus

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
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

# Prometheus service
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
sudo useradd --no-create-home --shell /bin/false node_exporter

# Node Exporter service
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Install Grafana (2025 update)
echo "📥 Installing Grafana..."

sudo apt-get install -y apt-transport-https software-properties-common curl gnupg

# Clean any previous keys & repos
sudo rm -f /etc/apt/sources.list.d/grafana.list
sudo rm -f /etc/apt/keyrings/grafana.gpg

# Add updated Grafana GPG key and repo
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://packages.grafana.com/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/grafana.gpg

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

# Install Grafana
sudo apt-get update -y
sudo apt-get install -y grafana

# Enable and start services
echo "🚀 Enabling and starting services..."
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

sudo systemctl enable node_exporter
sudo systemctl start node_exporter

sudo systemctl enable grafana-server
sudo systemctl start grafana-server

echo "✅ Monitoring stack installed successfully!"
echo "-------------------------------------------------"
echo "Prometheus: http://<server_ip>:9090"
echo "Node Exporter: http://<server_ip>:9100/metrics"
echo "Grafana: http://<server_ip>:3000  (default admin/admin)"
echo "-------------------------------------------------"
