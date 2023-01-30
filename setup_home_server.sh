#!/bin/bash

function check_root {
  if ! whoami | grep root ; then
    echo "Run the script as root..."
    exit 1
  fi
}

function install_ruby {
  apt install -y ruby
}

function install_systemd_startup_service {
  if ! ls ./server/opt/rbin ; then
    echo "Run this script from the project root..."
    exit 2
  fi

  echo "Installing systemd home-servers service"

  rm -rf /opt/rbin
  cp -r ./server/opt/rbin /opt/

  /opt/rbin/install-servers

  echo "Starting home-servers service"

  cp ./server/systemd/home-servers.service /etc/systemd/system/

  systemctl daemon-reload
  systemctl enable home-servers
  systemctl start home-servers
}

function install_cron_backup_service {
  echo "Installing cron backup service"

  crontab_file | crontab -u root -
}

function crontab_file {
  echo "# Crontab set by setup_home_server.sh
0 3 * * * /opt/rbin/backup
"
}

function setup {
  check_root
  install_ruby
  install_systemd_startup_service
  install_cron_backup_service
};setup
