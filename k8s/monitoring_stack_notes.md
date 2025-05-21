# 📖 Monitoring Stack: Prometheus + Grafana + Node Exporter — Quick Notes

---

## 📦 Tools Involved:
- **Prometheus**: Metric collection and time-series database.
- **Node Exporter**: System metrics exporter for Prometheus.
- **Grafana**: Visualization and dashboard tool.

---

## 📍 Service Ports:
| Service          | Default Port |
|:----------------|:-------------|
| Prometheus       | 9090        |
| Node Exporter    | 9100        |
| Grafana          | 3000        |

---

## 📂 Key Config Files:
- `/etc/prometheus/prometheus.yml` → Prometheus scrape config
- `/etc/systemd/system/prometheus.service` → Prometheus systemd service
- `/etc/systemd/system/node_exporter.service` → Node Exporter service

---

## 📊 Test & Verify Metrics:

### 🔸 Prometheus
- Web UI: `http://<server-ip>:9090`
- Check targets: **Status → Targets**
- Test query: `up`, `node_cpu_seconds_total`, `node_memory_MemAvailable_bytes`
- Test endpoint:
  ```bash
  curl http://localhost:9090
  ```

### 🔸 Node Exporter
- Metrics endpoint:
  ```bash
  curl http://localhost:9100/metrics
  ```

### 🔸 Grafana
- Web UI: `http://<server-ip>:3000`
- Default creds: `admin / admin`
- Add Prometheus data source
- Import dashboards (Node Exporter Full dashboard ID: **1860**)

---

## 📃 Useful Commands:

### Check Service Status:
```bash
sudo systemctl status prometheus
sudo systemctl status node_exporter
sudo systemctl status grafana-server
```

### Restart Service:
```bash
sudo systemctl restart prometheus
sudo systemctl restart node_exporter
sudo systemctl restart grafana-server
```

---

## 🧹 Uninstall Script:
Run the uninstall script to remove everything cleanly:
```bash
sudo ./uninstall_monitoring_stack.sh
```

---

## 📌 Diagram Overview:

```plaintext
[Node Exporter] --> (9100) --> [Prometheus] --> (9090) --> [Grafana UI (3000)]
      |                               |
   System Metrics              PromQL Queries
```

---

## ✅ Pro Tips:
- Always restart Prometheus after updating `prometheus.yml`
- Use dashboards from Grafana.com (look up dashboard IDs)
- Regularly test targets status in Prometheus UI
- Secure Grafana & Prometheus with authentication and firewall rules in production

---

_Last updated: 2025-05-21 00:55:19 UTC_
