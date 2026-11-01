# Comprehensive Kubernetes Cluster Setup (Proxmox VMs + kubeadm)

This guide builds a Kubernetes cluster on Ubuntu 24.04 VMs running in Proxmox, with a control plane node, worker nodes, and an optional registry node.

---

## Phase 1: Proxmox VM provisioning (manual, via the UI)

### Upload the ISO

In the Proxmox UI, select your storage → **ISO Images** → **Upload** the Ubuntu ISO (`ubuntu-24.04.3-live-server-amd64.iso`).

### Create the VM

Click **Create VM** and name it (e.g., `k8s-control-01`).

| Tab | Setting |
|---|---|
| **OS** | Select the uploaded ISO; Type: Linux |
| **System** | Enable QEMU Guest Agent; Machine: `q35`; BIOS: OVMF (UEFI) |
| **Disks** | 40–60 GB (control plane); 60–120 GB (data plane); 20–40 GB (registry) |
| **CPU** | Type: `host`; Sockets: 1; Cores: 2 (registry), 4 (control plane), 8 (worker) |
| **Memory** | 2 GB (registry), 4 GB (control plane), 8 GB (worker) |
| **Network** | Model: VirtIO; Bridge: `vmbr0` |

Start the VM, install Ubuntu (enable the SSH server only), reboot, and remove the ISO.

---

## Phase 2: Initial OS, network, and storage setup (run on each node)

Obtain the IP address and default gateway:

```bash
ip route
```

Upload and apply a static Netplan configuration if needed:

```bash
sudo mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak
sudo mv 50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml
sudo netplan try
```

### Disable swap completely

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo sed -i '/ swap.img / s/^\(.*\)$/#\1/g' /etc/fstab
```

### System updates and essential packages

```bash
sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y
sudo apt install -y qemu-guest-agent ca-certificates curl gnupg lsb-release vim apt-transport-https gpg
```

---

## Phase 3: Kernel modules and sysctl settings

These are crucial for container networking.

```bash
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
```

Apply the changes immediately:

```bash
sudo sysctl --system
```

---

## Phase 4: Container runtime (containerd) configuration

```bash
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
```

---

## Phase 5: Install Kubernetes binaries (kubelet, kubeadm, kubectl)

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.37/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.37/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

Final restart to ensure containerd and kubelet recognize the bridge parameters:

```bash
sudo systemctl restart containerd
```

---

## Phase 6: Control plane initialization (control plane node only)

```bash
sudo kubeadm init --apiserver-advertise-address 192.168.1.161 --pod-network-cidr "10.244.0.0/16" --upload-certs
```

Set up the local kubeconfig:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Verify cluster node status:

```bash
kubectl get nodes
```

---

## Phase 7: CNI network plugin setup (choose Flannel or Calico)

### Option A: Flannel

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

### Option B: Calico (alternative)

Follow the install guide: <https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises>

### Verify

```bash
kubectl get nodes
```

---

## Phase 8: Join worker nodes

Run this on the control plane to generate the join command:

```bash
sudo kubeadm token create --print-join-command
```

Then execute the resulting command on each worker node:

```bash
sudo kubeadm join 192.168.1.161:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

---

## Phase 9: Cluster add-ons and tooling

### 1. Metrics server (for `kubectl top`)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```

### 2. Helm and NGINX ingress controller

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh
sudo ./get_helm.sh

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
```

### 3. Storage class setup

```bash
kubectl apply -f https://raw.githubusercontent.com/jobezking/myLinuxConfig/refs/heads/main/k8s/storageclass.yaml
```
