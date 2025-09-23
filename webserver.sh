sudo apt update && sudo apt upgrade -y
sudo apt install apache2 -y
sudo chown www-data:www-data /var/www/html/test.csv
sudo chmod -R 644 /var/www/html/test.csv
sudo systemctl enable apache2
sudo systemctl status apache2
sudo ufw allow 'Apache'
sudo ufw status
#sudo cp /home/user/input/* /var/www/html
curl http://hostname/test.csv
