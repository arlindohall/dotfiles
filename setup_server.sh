#!/bin/bash

set -euxo pipefail

adduser miller
adduser miller root
usermod -a -G sudo miller
echo 'miller    ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

mkdir /home/miller/.ssh
cat .ssh/authorized_keys >> /home/miller/.ssh/authorized_keys

chown miller:miller /home/miller/.ssh
chown miller:miller /home/miller/.ssh/*

apt update -y && apt upgrade -y
apt install -y \
    fish \
    ruby ruby-dev \
    sqlite3 libsqlite3-dev \
    nodejs npm \
    nginx \
    git \
    vim tmux

sudo -u miller chsh -s /usr/bin/fish

echo 'Port 1989' >> /etc/ssh/sshd_config
service ssh restart

sudo echo '
events {}

http {
  server {
    server_name droplet1.arlindohall.com;
    root /var/www/html;
    location / {
    # proxy_pass http://localhost:3000;
    }
  }

  server {
    server_name droplet1.arlindohall.com;
    listen 80;
  }
}
' > /etc/nginx/nginx.conf

sudo service nginx restart

certbot --nginx

sudo -u miller npm install --global yarn
sudo -u miller gem install rails bundler