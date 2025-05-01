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
use_helper dependencies_helpers.sh

#### Dependency and files installation ####
function install_home_mac {
  install_homebrew
  install_rust
  install_asdf
  install_asdf_plugins
  install_git
  install_git_delta
  install_openjdk

  install_homebrew_tools
  install_aider

  # These steps are interactive, so the script must be run
  # by a human and not by automation
  if ls "$HOME/var/notes"; then
    return
  fi

  git clone https://gitlab.com/arlindohall/notes "$HOME/var/notes"
}

function install_home_linux {
  install_clang
  install_rust
  install_asdf
  install_asdf_plugins
  install_git
  install_git_delta

  install_apt_tools

  set_install_shell
}

function install_work_mac {
  install_homebrew
  install_rust
  install_git
  install_git_delta
  install_openjdk
  install_asdf
  install_asdf_plugins

  install_homebrew_tools
  install_aider

  # These steps are interactive, so the script must be run
  # by a human and not by automation
  clone_var_repo notes
}

function install_work_linux {
  curl -sSf https://sh.rustup.rs >/tmp/rustup.sh
  chmod u+x /tmp/rustup.sh
  /tmp/rustup.sh -y

  rustup default stable
  install_git_delta

  install_apt_tools
}

install
