📊 Kubernetes Monitoring Stack Deployment
This document outlines the Kubernetes manifests for deploying Prometheus, Alertmanager, Grafana, and node-exporter in a cluster under a dedicated monitoring namespace.

📦 Namespace
yaml
Copy
Edit
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
📊 Prometheus
Deployment

yaml
Copy
Edit
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:v2.52.0
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: prometheus-data
          mountPath: /prometheus
      volumes:
      - name: prometheus-data
        emptyDir: {}
Service

yaml
Copy
Edit
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service
  namespace: monitoring
spec:
  type: LoadBalancer
  ports:
  - port: 9090
    targetPort: 9090
  selector:
    app: prometheus
📣 Alertmanager
Deployment

yaml
Copy
Edit
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alertmanager
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alertmanager
  template:
    metadata:
      labels:
        app: alertmanager
    spec:
      containers:
      - name: alertmanager
        image: prom/alertmanager:v0.27.0
        ports:
        - containerPort: 9093
Service

yaml
Copy
Edit
apiVersion: v1
kind: Service
metadata:
  name: alertmanager-service
  namespace: monitoring
spec:
  type: ClusterIP
  ports:
  - port: 9093
    targetPort: 9093
  selector:
    app: alertmanager
📈 Grafana
Deployment

yaml
Copy
Edit
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:10.4.0
        ports:
        - containerPort: 3000
Service

yaml
Copy
Edit
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
  namespace: monitoring
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 3000
  selector:
    app: grafana
📡 node-exporter
DaemonSet

yaml
Copy
Edit
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      hostPID: true
      containers:
      - name: node-exporter
        image: prom/node-exporter:v1.7.0
        ports:
        - containerPort: 9100
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
        - name: root
          mountPath: /rootfs
          readOnly: true
        args:
          - --path.procfs=/host/proc
          - --path.sysfs=/host/sys
          - --path.rootfs=/rootfs
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
      - name: root
        hostPath:
          path: /
Service

yaml
Copy
Edit
apiVersion: v1
kind: Service
metadata:
  name: node-exporter-service
  namespace: monitoring
spec:
  type: ClusterIP
  ports:
  - port: 9100
    targetPort: 9100
  selector:
    app: node-exporter
🚀 Apply Manifests
To deploy everything:

bash
Copy
Edit
kubectl apply -f namespace.yaml
kubectl apply -f prometheus.yaml
kubectl apply -f alertmanager.yaml
kubectl apply -f grafana.yaml
kubectl apply -f node-exporter.yaml
