sudo apt update; sudo apt upgrade -y; sudo apt dist-upgrade -y; sudo apt autoremove -y
sudo apt install -y ca-certificates curl gnupg lsb-release vim
sudo mkdir -p -m 755 /etc/apt/keyrings 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y containerd.io
containerd config default > config.toml; sudo mv config.toml /etc/containerd/config.toml; sudo systemctl restart containerd
sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni

###
192.168.1.215	k8s-control-01
192.168.1.156	k8s-control-02
192.168.1.187	k8s-control-03
192.168.1.195	k8s-haproxy
192.168.1.142	k8s-data-01
192.168.1.232	k8s-data-02
192.168.1.233	k8s-data-03
192.168.1.144	k8s-data-04
###
sudo kubeadm init \
  --control-plane-endpoint "192.168.1.195:6443" \
  --pod-network-cidr 10.244.0.0/16 \
  --apiserver-cert-extra-sans 192.168.1.195 \
  --apiserver-cert-extra-sans k8s-control-01 \
  --apiserver-cert-extra-sans k8s-control-02 \
  --apiserver-cert-extra-sans k8s-control-03

###
1. On k8s-control-01: Generate the Key
Run this command to upload the certificates to the cluster securely for 2 hours:

Bash
sudo kubeadm init phase upload-certs --upload-certs
Copy the 64-character hex string it outputs (this is your --certificate-key).

2. On k8s-control-01: Get the Join Command
Now get the rest of the join token:

Bash
kubeadm token create --print-join-command
3. On k8s-control-02: Run the Combined Command
Now, combine them. Your command on the second node should look like this (using sudo!):

Bash
sudo kubeadm join 192.168.1.195:6443 \
  --token <your-token> \
  --discovery-token-ca-cert-hash sha256:<your-hash> \
  --control-plane \
  --certificate-key <the-key-from-step-1>
  
https://learn.microsoft.com/en-us/windows/ai/directml/pytorch-wsl
