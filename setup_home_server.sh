#!/bin/bash

function setup_static_ip {
  CONFIG_FILE="./server/netplan-home_server_netplan_installer"
  if test $(hostname -I | grep 192.168.1.200) ; then
    return
  fi

  if ! ls "$CONFIG_FILE" ; then
    echo "Please run this script from the dotfiles root directory, I don't want to do"
    echo "all the work that I'd need to do in order to make this script not care about"
    echo "where it is run..."
    exit 1
  fi

  echo "Warning: This will reset the network to use IP 192.168.1.200, you will need to reconnect..."
  cp "$CONFIG_FILE" /etc/netplan/00-installer-config.yaml
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

function setup {
  setup_static_ip
  install_nginx
  install_pihole
}

setup
