#!/bin/bash

INSTALL_PATH="$HOME/dotfiles/"

#### Utility functions ####
function rc_install {
  if ls "$INSTALL_PATH"; then
    source="$INSTALL_PATH/rc/$1"
    dest=$HOME/$2

    mkdir -p "$(dirname $dest)"
    cp "$source" "$dest"
  else
    echo "Unable to run script..."
    echo "Please place dir in $HOME/dotfiles..."
    exit 1
  fi
}

function set_up_directory_structure {
  mkdir -p "$HOME"/.rm-trash-can
  mkdir -p "$HOME"/var
  mkdir -p "$HOME"/src
}

function create_notes_symlink_if_home {
  if ! test -d ~/Library/Mobile\ Documents/iCloud~com\~logseq\~logseq/Documents/notes/; then
    return
  fi

  if test -L ~/notes-symlink; then
    return
  fi

  ln -s ~/Library/Mobile\ Documents/iCloud~com\~logseq\~logseq/Documents/notes/ ~/notes-symlink
}

function install_lazyvim_config {
  config_dir="$HOME/.config/nvim"
  backup_dir="$HOME/.config/nvim.bak"

  if ls "$config_dir"; then
    rm -rf "$backup_dir"
    mv -f "$config_dir" "$backup_dir"
  fi

  mkdir "$config_dir"
  cp -r lazyvim/* "$config_dir"
}
