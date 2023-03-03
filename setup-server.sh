#!/bin/bash

set -euxo pipefail

if ! whoami | grep -q root ; then
  echo "Please run as root."
  exit 1
fi

adduser miller
adduser miller root
usermod -a -G miller
echo 'miller    ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

mkdir /home/miller/.ssh
cat /root/.ssh/authorized_keys >> /home/miller/.ssh/authorized_keys

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

echo '
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

service nginx restart

sudo apt install -y snapd
snap install core
snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

certbot certonly --nginx

sudo -u miller npm install --global yarn
sudo -u miller gem install rails bundler

restart
