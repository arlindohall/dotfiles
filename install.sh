#!/bin/bash

set -euxo pipefail

INSTALL_PATH="$HOME/dotfiles/"

function use_helper {
  if ls "$INSTALL_PATH"; then
    # shellcheck source=/dev/null
    . "$INSTALL_PATH/lib/$1"
  else
    echo "Unable to run script..."
    echo "Please place dir in $HOME/dotfiles..."
    exit 1
  fi
}

use_helper helpers.sh
use_helper rc_helpers.sh

#### Dotfile placement and env config ####
function install_home_mac {
  set_up_directory_structure
  install_personal_bin
  create_notes_symlink_if_home

  rc_install aspell/dictionary.txt var/dictionary.txt
  rc_install bash/bash_profile .bash_profile
  rc_install fish/config .config/fish/config.fish
  rc_install fish/mac_config .config/fish/conf.d/500_mac_config.fish
  rc_install fish/home_mac_config .config/fish/conf.d/550_home_mac_config.fish
  rc_install gitconfig/home .gitconfig
  rc_install gitconfig/gitignore .gitignore
  rc_install sh/inputrc .inputrc
  rc_install sh/profile .profile
  rc_install tmux/conf .tmux.conf
  rc_install tmux/conf_local .tmux.conf.local
  rc_install vim/vimrc .vimrc
  rc_install zsh/mac_zshrc .zshrc

  install_lazyvim_config
}

function install_home_linux {
  set_up_directory_structure
  install_personal_bin

  rc_install aspell/dictionary.txt var/dictionary.txt
  rc_install bash/bash_profile .bash_profile
  rc_install fish/config .config/fish/config.fish
  rc_install fish/linux_config .config/fish/conf.d/500_linux_config.fish
  rc_install gitconfig/home .gitconfig
  rc_install gitconfig/gitignore .gitignore
  rc_install sh/inputrc .inputrc
  rc_install sh/profile .profile
  rc_install tmux/conf .tmux.conf
  rc_install tmux/conf_local .tmux.conf.local
  rc_install vim/vimrc .vimrc

  install_lazyvim_config
}

function install_work_mac {
  set_up_directory_structure
  install_personal_bin

  rc_install aspell/dictionary.txt var/dictionary.txt
  rc_install bash/bash_profile .bash_profile
  rc_install fish/config .config/fish/config.fish
  rc_install fish/mac_config .config/fish/conf.d/500_mac_config.fish
  rc_install fish/work_mac_config .config/fish/conf.d/550_work_mac_config.fish
  rc_install fish/dev_config .config/fish/conf.d/700_dev_config.fish
  rc_install gitconfig/work .gitconfig
  rc_install gitconfig/work-dev .config/dev/gitconfig
  rc_install gitconfig/gitignore .gitignore
  rc_install sh/inputrc .inputrc
  rc_install sh/profile .profile
  rc_install tmux/conf .tmux.conf
  rc_install tmux/conf_local .tmux.conf.local
  rc_install vim/vimrc .vimrc
  rc_install zsh/work_zshrc .config/.work_zshrc
  rc_install zsh/mac_zshrc .zshrc

  install_lazyvim_config
}

function install_work_linux {
  set_up_directory_structure
  install_personal_bin

  rc_install aspell/dictionary.txt var/dictionary.txt
  rc_install fish/config .config/fish/config.fish
  rc_install fish/linux_config .config/fish/conf.d/500_linux_config.fish
  rc_install gitconfig/work .gitconfig
  rc_install gitconfig/gitignore .gitignore
  rc_install sh/inputrc .inputrc
  rc_install sh/profile .profile
  rc_install tmux/conf .tmux.conf
  rc_install tmux/conf_local .tmux.conf.local
  rc_install vim/vimrc .vimrc
  rc_install zsh/work_zshrc .zshrc

  install_lazyvim_config
}

function install_personal_bin {
  mkdir -p "$HOME/bin"

  if ls "$INSTALL_PATH"; then
    echo "Installing personal bin from $INSTALL_PATH to $HOME"
    cp -r "$INSTALL_PATH/bin/"* "$HOME/bin/"
  else
    echo "Unable to run script..."
    echo "Please place dir in either $HOME/dotfiles or $HOME/worksapce/dotfiles..."
    exit 1
  fi
}

install
