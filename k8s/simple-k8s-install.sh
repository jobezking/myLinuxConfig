https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
In the Proxmox UI → select your storage (e.g., local) → ISO Images → Upload or Download from URL.
Select the Ubuntu ISO (ubuntu-24.04.3-live-server-amd64.iso).
Create VM → Name it (e.g., k8s-control-01).

OS tab
	Select the uploaded ISO
	Type: Linux

System tab
	Enable QEMU Guest Agent
	Machine: q35 (recommended)
	BIOS: OVMF (UEFI)

Disks
	40–60GB for control plane; 60–120GB for data plane

CPU

	Type: host
	Sockets: 1
	Cores: 4 for control plane; 8 for data plane

Memory
	
	4 GB for control plane, 8 GB for data plane

Network

	Model: VirtIO
	Bridge: vmbr0

Finish → Start VM → Install Ubuntu normally. Only enable SSH server. Reboot then remove ISO

#OS and network config for all 3 nodes
#network config
ip route 		#obtain IP address and default gateway
upload and modify 50-cloud-init.yaml
sudo mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak
sudo mv 50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml
sudo netplan try

# disable swap
sudo swapoff -a
sudo sed -i 's|^/swap\.img|#/swap.img|' /etc/fstab

# containerd prerequisites
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

sudo sysctl --system

#
sudo hostnamectl set-hostname new-name
ssh-copy-id username@new-name          # from client to server

# install preliminary packages
sudo apt update; sudo apt upgrade -y; sudo apt dist-upgrade -y; sudo apt autoremove -y; sudo apt clean && \
sudo apt install -y apt-transport-https ca-certificates curl gpg qemu-guest-agent gnupg lsb-release vim

# Install Kubernetes
# On all 3 nodes
# Install containerd
sudo apt install -y containerd; sudo mkdir -p /etc/containerd && \
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml && \
sudo systemctl restart containerd
# Install kubeadm, kubelet and kubectl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.37/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.37/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list && \
sudo apt update; sudo apt install -y kubelet kubeadm kubectl; sudo apt-mark hold kubelet kubeadm kubectl
#'#

# Initialize only the main Control Plane Node. The advertised address comes from the primary interface from "ip addr" or "ip a"
sudo kubeadm init \
  --apiserver-advertise-address $(ip route get 8.8.8.8 | grep -oP 'src \K\S+') \
  --pod-network-cidr "10.244.0.0/16" \
  --upload-certs
mkdir -p $HOME/.kube; sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config; sudo chown $(id -u):$(id -g) $HOME/.kube/config
#To test: 
kubectl get nodes
# Add kubernetes networking. Choose between flannel or calico but not both
# add flannel networking
# If you use custom podCIDR (not 10.244.0.0/16) you first need to download the YAML below and modify the network to match your one.
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl get nodes
# add calico networking see https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises
kubectl cluster-info dump | grep -m1 cluster-cidr  # get podCIDR from output for step 3
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.33.0/manifests/v3_projectcalico_org.yaml # Install the Calico CRDs
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.33.0/manifests/tigera-operator.yaml # Install the Tigera Operator
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.33.0/manifests/custom-resources.yaml
sed -i 's|cidr: 192.168.0.0/16|cidr: 10.244.0.0/16|' custom-resources.yaml  # Edit the file to set the correct podCIDR from step 1
grep cidr custom-resources.yaml   # verify
kubectl create -f custom-resources.yaml # Install the Calico custom resources
watch kubectl get tigerastatus # After a few minutes, apiserver, calico, goldmane, ippools and whisker should all show AVAILABLE = True. Press Ctrl+C to exit.
kubectl get pods -n calico-system
kubectl get nodes
### Troubleshooting
Pods stuck in Pending or ContainerCreating: run 
kubectl describe pod <name> -n calico-system 
and 
kubectl logs -n tigera-operator deploy/tigera-operator.
Node still NotReady after pods are up: wait another minute or two, then check kubectl describe node controlplane.
###
# Generate command Join worker nodes. Will expire after 24 hours. If expired run again.

sudo kubeadm token create --print-join-command  

# Run on On worker nodes
sudo kubeadm join 192.168.1.161:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash> from output above

# Add basics for kubernetes. Run on control plane node only
# Add metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Create default ingress
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
chmod +x get_helm.sh; sudo ./get_helm.sh
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update; helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

# storage class
kubectl apply -f https://raw.githubusercontent.com/jobezking/myLinuxConfig/refs/heads/main/k8s/storageclass.yaml

# Prometheus and Grafana monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts; helm repo update
kubectl create namespace monitoring
helm install kps prometheus-community/kube-prometheus-stack -n monitoring
kubectl port-forward -n monitoring svc/kps-grafana 3000:80
# Web UI:  http://localhost:3000  User: adminPassword: prom-operator