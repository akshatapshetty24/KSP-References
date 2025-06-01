#!/bin/bash

set -e

function install_kubernetes() {
    echo "👉 Disabling swap..."
    sudo swapoff -a
    sudo sed -i '/ swap / s/^/#/' /etc/fstab

    echo "👉 Installing containerd..."
    sudo apt update && sudo apt install -y containerd

    echo "👉 Generating default containerd config..."
    sudo mkdir -p /etc/containerd
    sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null

    echo "👉 Restarting containerd..."
    sudo systemctl restart containerd
    sudo systemctl enable containerd

    echo "👉 Setting sysctl parameters for Kubernetes networking..."
    cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables  = 1
net.bridge.bridge-nf-call-iptables   = 1
net.ipv4.ip_forward                  = 1
EOF

    sudo sysctl --system

    echo "👉 Adding Kubernetes apt repository and GPG key..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    echo "👉 Installing kubeadm, kubelet, kubectl..."
    sudo apt update
    sudo apt install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl

    echo "👉 Enabling containerd and kubelet services..."
    sudo systemctl enable containerd
    sudo systemctl enable kubelet

    echo "✅ Kubernetes installation completed successfully!"
}

function initialize_master() {
    echo "👉 Initializing Kubernetes master node..."
    read -p "Enter pod network CIDR (default 192.168.0.0/16): " pod_cidr
    pod_cidr=${pod_cidr:-192.168.0.0/16}

    sudo kubeadm init --pod-network-cidr=$pod_cidr

    echo "👉 Setting up kubeconfig for current user..."
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    echo "✅ Master node initialized!"
}

function install_calico() {
    echo "👉 Making /sys and / mounts shared to avoid mount propagation issues..."
    sudo mount --make-shared /sys
    sudo mount --make-shared /

    echo "👉 Installing Calico CNI..."
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/calico.yaml
    echo "✅ Calico CNI installed!"
}

function reset_kubernetes() {
    echo "🚨 WARNING: This will completely reset your kubeadm Kubernetes cluster!"

    read -p "Are you sure you want to proceed? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo "Aborted."
        return
    fi

    echo "👉 Resetting kubeadm cluster..."
    sudo kubeadm reset -f

    echo "👉 Removing Kubernetes configs..."
    sudo rm -rf $HOME/.kube
    sudo rm -rf /root/.kube

    echo "👉 Removing CNI configs..."
    sudo rm -rf /etc/cni/net.d

    echo "👉 Stopping containerd and cleaning up containers/images..."
    sudo systemctl stop containerd
    sudo rm -rf /var/lib/containerd
    sudo systemctl start containerd

    echo "👉 Removing etcd data directory..."
    sudo rm -rf /var/lib/etcd

    echo "👉 Flushing iptables rules..."
    sudo iptables -F
    sudo iptables -t nat -F
    sudo iptables -t mangle -F
    sudo iptables -X

    echo "👉 Restarting kubelet and containerd..."
    sudo systemctl restart containerd
    sudo systemctl restart kubelet

    echo "✅ Kubernetes cluster reset complete!"
}

function show_menu() {
    clear
    echo "============================"
    echo " Kubernetes Manager"
    echo "============================"
    echo "1. Install Kubernetes (containerd + kubeadm etc.)"
    echo "2. Initialize Master Node"
    echo "3. Install Calico CNI"
    echo "4. Reset Kubernetes Cluster"
    echo "5. Exit"
    echo "============================"
}

while true; do
    show_menu
    read -p "Select an option [1-5]: " option
    case $option in
        1)
            install_kubernetes
            read -p "Press Enter to continue..."
            ;;
        2)
            initialize_master
            read -p "Press Enter to continue..."
            ;;
        3)
            install_calico
            read -p "Press Enter to continue..."
            ;;
        4)
            reset_kubernetes
            read -p "Press Enter to continue..."
            ;;
        5)
            echo "👋 Exiting."
            exit 0
            ;;
        *)
            echo "❌ Invalid option."
            read -p "Press Enter to continue..."
            ;;
    esac
done

#kubectl taint nodes --all node-role.kubernetes.io/control-plane-
#kubectl create deploy kspdeploy --image=nginx --replicas=3
#kubectl expose deploy kspdeploy --port=80 --target-port=80 --type=ClusterIP
#kubectl create deploy http-echo --image=hashicorp/http-echo --replicas=3
#
#kubectl run ksp2 --image=hashicorp/http-echo
