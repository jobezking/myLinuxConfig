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

	40–60GB for control plane

	60–120GB for data plane

	20–40GB for registry

CPU

	Type: host

	Sockets: 1

	Cores: 2 for private Docker registry; 4 for control plane; 8 for data plane

Memory

	2 GB for private Docker registry; 4 GB for control plane, 8 GB for data plane

Network

	Model: VirtIO

	Bridge: vmbr0

Finish → Start VM → Install Ubuntu normally. Only enable SSH server. Reboot then remove ISO

ip route 		#obtain IP address and default gateway
upload and modify 50-cloud-init.yaml
sudo mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak
sudo mv 50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml
sudo netplan try
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo apt update; sudo apt upgrade -y; sudo apt dist-upgrade -y; sudo apt autoremove -y
sudo apt install -y qemu-guest-agent ca-certificates curl gnupg lsb-release vim
### enable the bridge netfilter module and flip the IP forwarding switch
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

# Apply the changes immediately
sudo sysctl --system
