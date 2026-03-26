sudo systemctl install -y haproxy
sudo apt install -y haproxy
sudo systemctl enable haproxy
upload and edit /etc/haproxy/haproxy.cfg
sudo haproxy.cfg /etc/haproxy/
sudo systemctl restart haproxy
sudo systemctl status haproxy
