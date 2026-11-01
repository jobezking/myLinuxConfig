# Simple Kubernetes Install (kubeadm on Proxmox)

Reference: <https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/>

This guide builds a 3-node cluster (1 control plane, 2 workers) on Ubuntu 24.04 VMs running in Proxmox.

---

## 1. Create the VMs in Proxmox

### Upload the ISO

In the Proxmox UI, select your storage (e.g., `local`) → **ISO Images** → **Upload** or **Download from URL**. Select the Ubuntu ISO (`ubuntu-24.04.3-live-server-amd64.iso`).

### Create the VM

Click **Create VM** and name it (e.g., `k8s-control-01`).

| Tab | Setting |
|---|---|
| **OS** | Select the uploaded ISO; Type: Linux |
| **System** | Enable QEMU Guest Agent; Machine: `q35` (recommended); BIOS: OVMF (UEFI) |
| **Disks** | 40–60 GB for control plane; 60–120 GB for data plane |
| **CPU** | Type: `host`; Sockets: 1; Cores: 4 for control plane, 8 for data plane |
| **Memory** | 4 GB for control plane; 8 GB for data plane |
| **Network** | Model: VirtIO; Bridge: `vmbr0` |

Finish → Start VM → install Ubuntu normally. Only enable the SSH server. Reboot, then remove the ISO.

---

## 2. OS and network configuration (all 3 nodes)

### Network config

Obtain the IP address and default gateway:

```bash
ip route
```

Upload and modify `50-cloud-init.yaml`, then apply it:

```bash
sudo mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak
sudo mv 50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml
sudo netplan try
```

### Disable swap

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo sed -i '/ swap.img / s/^\(.*\)$/#\1/g' /etc/fstab
```

### containerd prerequisites

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay; sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system; sudo systemctl restart containerd
```

> **Note:** `containerd` isn't installed until the next section, so the `restart` here may fail on a fresh VM. It's harmless; the service is restarted again after install.

### Install preliminary packages

```bash
sudo apt update; sudo apt upgrade -y; sudo apt dist-upgrade -y; sudo apt autoremove -y; sudo apt clean
sudo apt install -y apt-transport-https ca-certificates curl gpg qemu-guest-agent gnupg lsb-release vim
```

---

## 3. Install Kubernetes (all 3 nodes)

### Install containerd

```bash
sudo apt install -y containerd; sudo mkdir -p /etc/containerd
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
```

### Install kubeadm, kubelet and kubectl

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.37/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.37/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update; sudo apt install -y kubelet kubeadm kubectl; sudo apt-mark hold kubelet kubeadm kubectl
```

---

## 4. Initialize the control plane (main control plane node only)

The advertised address comes from the primary interface shown by `ip addr` or `ip a`.

```bash
sudo kubeadm init --apiserver-advertise-address 192.168.1.161 --pod-network-cidr "10.244.0.0/16" --upload-certs
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Test:

```bash
kubectl get nodes
```

---

## 5. Add Kubernetes networking

Choose **either** Flannel **or** Calico, but not both.

### Option A: Flannel

If you use a custom pod CIDR (not `10.244.0.0/16`), first download the YAML below and modify the network to match yours.

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl get nodes
```

### Option B: Calico

Follow the install guide: <https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises>

Then verify:

```bash
kubectl get pods -n calico-system
kubectl get nodes
```

---

## 6. Join the worker nodes

### Generate the join command (control plane)

The token expires after 24 hours. If expired, run this again.

```bash
sudo kubeadm token create --print-join-command
```

### Run on the worker nodes

Use the output of the command above:

```bash
sudo kubeadm join 192.168.1.161:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

---

## 7. Add basics (control plane node only)

### Metrics server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```

### Default ingress (Helm + ingress-nginx)

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh
sudo ./get_helm.sh
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
```

### Storage class

Manifest: <https://raw.githubusercontent.com/jobezking/myLinuxConfig/refs/heads/main/k8s/storageclass.yaml>

```bash
kubectl apply -f https://raw.githubusercontent.com/jobezking/myLinuxConfig/refs/heads/main/k8s/storageclass.yaml
```
