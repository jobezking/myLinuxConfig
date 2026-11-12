#!/bin/bash
# ==============================================================================
# Simple Kubernetes (CKA Exam Prep) Automated Installation Script
# Target Version: Kubernetes v1.35[cite: 2]
# Topology: 1 Control Plane (2 GB RAM), 2 Workers (2 GB RAM each)[cite: 2]
# Companion Repo: https://github.com/Ghada-Atef/cka-practice-exams-lab[cite: 2]
# ==============================================================================

set -euo pipefail

echo "[*] Starting CKA Kubernetes v1.35 Environment Setup..."

# 1. System Prerequisites & Network Settings
echo "[*] Configuring kernel modules and sysctl parameters..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# 2. Disable Swap
echo "[*] Disabling swap..."
sudo swapoff -a
sudo sed -i 's|^/swap\.img|#/swap.img|' /etc/fstab

# 3. Install Preliminary Packages
echo "[*] Installing preliminary packages..."
sudo apt update
sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl gpg qemu-guest-agent gnupg lsb-release vim git make

# 4. Install containerd Runtime (with SystemdCgroup = true)
echo "[*] Installing and configuring containerd..."
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# 5. Install Kubernetes v1.35 Components (kubelet, kubeadm, kubectl)[cite: 2]
echo "[*] Adding Kubernetes v1.35 apt repository and installing binaries..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# 6. Companion Repository Setup (Ghada Atef CKA Practice Exams)[cite: 2]
echo "[*] Cloning CKA practice exams lab companion repository..."
if [ ! -d "cka-practice-exams-lab" ]; then
  git clone https://github.com/Ghada-Atef/cka-practice-exams-lab.git
fi
cd cka-practice-exams-lab
git checkout v1.35-edition-1 || echo "Warning: Tag v1.35-edition-1 not found, staying on default branch."
cd ..

# 7. Control Plane Initialization (Run on Control Plane node only)
if [ "${1:-}" = "control-plane" ]; then
  echo "[*] Initializing Kubernetes Control Plane..."
  
  ADVERTISE_IP=$(ip route get 8.8.8.8 | grep -oP 'src \K\S+' || hostname -I | awk '{print $1}')
  
  sudo kubeadm init \
    --apiserver-advertise-address "$ADVERTISE_IP" \
    --pod-network-cidr "10.244.0.0/16" \
    --upload-certs

  # Configure local kubeconfig
  mkdir -p "$HOME/.kube"
  sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
  sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

  echo "[*] Installing Calico Network Plugin..."
  kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.33.0/manifests/v3_projectcalico_org.yaml
  kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.33.0/manifests/tigera-operator.yaml
  
  curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.33.0/manifests/custom-resources.yaml
  sed -i 's|cidr: 192.168.0.0/16|cidr: 10.244.0.0/16|' custom-resources.yaml
  kubectl create -f custom-resources.yaml

  echo "[*] Installing Metrics Server..."
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  kubectl patch deployment metrics-server -n kube-system --type='json' \
    -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

  echo "[*] Installing Helm 3..."
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod +x get_helm.sh
  sudo ./get_helm.sh
  rm get_helm.sh

  echo "[*] Installing NGINX Ingress Controller..."
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm repo update
  helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

  echo "[*] Control plane setup and core add-ons complete!"
  echo "[*] Run 'sudo kubeadm token create --print-join-command' to get the worker join command."
else
  echo "[*] Node provisioning complete. Run this script with 'control-plane' argument on the control node, or execute 'kubeadm join ...' on worker nodes."
fi