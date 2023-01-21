#!/bin/bash

set -euxo pipefail

function setup_static_ip {
  CONFIG_FILE="./server/netplan-home_server_netplan_installer"
  if hostname -I | grep 192.168.0.200 ; then
    return
  fi

  if ! ls "$CONFIG_FILE" ; then
    echo "Please run this script from the dotfiles root directory, I don't want to do"
    echo "all the work that I'd need to do in order to make this script not care about"
    echo "where it is run..."
    exit 1
  fi

  echo "Warning: This will reset the network to use IP 192.168.0.200, you will need to reconnect..."
  sudo cp "$CONFIG_FILE" /etc/netplan/00-installer-config.yaml
  sudo netplan apply
}

function install_nginx {
  if ! which nginx ; then
    sudo apt update -y
    sudo apt install -y nginx
  fi

  sudo cp ./server/nginx-home_server /etc/nginx/nginx.conf
  sudo systemctl restart nginx
}

function install_pihole {
  if ! which pihole ; then
    curl -sSL https://install.pi-hole.net | bash
  fi
}

function setup_static_page {
  build_sum="$(find server/static-homesite/build/ -type f | xargs cat | md5sum | awk '{print $1}')"
  target_sum="$(find /var/hall-house/www/ -type f | xargs cat | md5sum | awk '{print $1}')"

  if test "$build_sum" = "$target_sum" ; then
    return
  fi

  sudo rm -rf /var/hall-house/www/
  sudo mkdir -p /var/hall-house/www/
  sudo cp -r ./server/static-homesite/build/* /var/hall-house/www/
  sudo systemctl restart nginx
}

function setup_baby_buddy {
  mkdir -p "$HOME/var/babybuddy/appdata"

  if sudo docker ps -a | grep babybuddy ; then
    return
  fi

  run_baby_buddy_container
}

function run_baby_buddy_container {
  # todo: use https
  sudo docker run -d \
    --name=babybuddy \
    -e PUID=1000 \
    -e PGID=1000 \
    -e TZ=America/New_York \
    -e CSRF_TRUSTED_ORIGINS=http://127.0.0.1:8000,http://baby.hallhouse.link \
    -p 3080:8000 \
    -v "$HOME/var/babybuddy/appdata:/config" \
    --restart unless-stopped \
    lscr.io/linuxserver/babybuddy:latest
}

function setup_wassup {
  mkdir -p "$HOME/var/wassup/appdata"

  if sudo docker ps -a | grep wassup ; then
    return
  fi

  run_wassup_container
}

function run_wassup_container {
  sudo docker run # todo: run wassup as a container
}

function setup {
  setup_static_ip
  install_nginx

  install_pihole

  setup_static_page

  setup_baby_buddy
}

setup
