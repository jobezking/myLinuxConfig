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
sudo mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak
sudo netplan try
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo apt update; sudo apt upgrade -y; sudo apt dist-upgrade -y; sudo apt autoremove -y
sudo apt install -y containerd qemu-guest-agent; sudo systemctl enable --now containerd
