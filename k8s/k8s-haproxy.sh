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

# install and configure haproxy

sudo systemctl install -y haproxy
sudo apt install -y haproxy
sudo systemctl enable haproxy
upload and edit /etc/haproxy/haproxy.cfg
sudo haproxy.cfg /etc/haproxy/
sudo systemctl restart haproxy
sudo systemctl status haproxy
