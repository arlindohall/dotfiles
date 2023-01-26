#!/bin/bash

function check_root {
  if ! whoami | grep root ; then
    echo "Run the script as root..."
    exit 1
  fi
}

function install_systemd_startup_service {
  if ! ls ./server/opt/rbin ; then
    echo "Run this script from the project root..."
    exit 2
  fi

  echo "Installing systemd startup service"

  rm -rf /opt/rbin
  cp -r ./server/opt/rbin /opt/
  cp ./server/systemd/start-servers.service /etc/systemd/system/
  systemd start start-servers
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
  install_systemd_startup_service
  install_cron_backup_service
};setup
