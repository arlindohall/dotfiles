#!/bin/bash

function install_systemd_startup_service {
  echo "Installing systemd startup service"
}

function install_cron_backup_service {
  echo "Installing cron backup service"
}

function setup {
  install_systemd_startup_service
  install_cron_backup_service
}

setup
