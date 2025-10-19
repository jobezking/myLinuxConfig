#!/bin/bash
sudo apt update && sudo apt upgrade -y
sudo apt install nginx -y
sudo mkdir -p /var/www/csv
sudo chown -R $USER:$USER /var/www/csv
echo "col1,col2\n1,2\n3,4" > /var/www/csv/test.csv
sudo vim /etc/nginx/sites-available/csv-server
#
server {
    listen 80;
    server_name _;

    root /var/www/csv;
    index index.html;

    location / {
        autoindex on;   # allows directory listing
        try_files $uri $uri/ =404;
    }
}
#
sudo ln -s /etc/nginx/sites-available/csv-server /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
curl http://localhost/test.csv
sudo systemctl status nginx