#!/bin/bash

set -e

echo "⚠️  Stopping services..."
sudo systemctl stop prometheus || true
sudo systemctl stop node_exporter || true
sudo systemctl stop grafana-server || true

echo "🧹 Disabling services..."
sudo systemctl disable prometheus || true
sudo systemctl disable node_exporter || true
sudo systemctl disable grafana-server || true

echo "🗑️  Removing binaries..."
sudo rm -f /usr/local/bin/prometheus
sudo rm -f /usr/local/bin/promtool
sudo rm -f /usr/local/bin/node_exporter

echo "🗑️  Removing users..."
sudo userdel -r prometheus || true
sudo userdel -r node_exporter || true

echo "🗑️  Removing configuration and data directories..."
sudo rm -rf /etc/prometheus
sudo rm -rf /opt/prometheus
sudo rm -rf /var/lib/prometheus
sudo rm -f /etc/systemd/system/prometheus.service
sudo rm -f /etc/systemd/system/node_exporter.service

echo "🗑️  Removing Grafana packages and repo..."
sudo apt-get purge --yes grafana || true
sudo rm -f /etc/apt/sources.list.d/grafana.list
sudo rm -f /etc/apt/keyrings/grafana.gpg
sudo apt-get autoremove --yes
sudo apt-get clean

echo "🚀 Reloading systemd..."
sudo systemctl daemon-reload

echo "✅ Monitoring stack uninstalled successfully."
