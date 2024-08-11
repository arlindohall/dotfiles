#!/bin/bash

INSTALL_PATH="$HOME/dotfiles/"
WORKING_PATH="$HOME/workspace/dotfiles/"

#### Utility functions ####
function rc_install {
    if ls "$INSTALL_PATH" ; then
        source="$INSTALL_PATH/rc/$1"
        dest=$HOME/$2

	mkdir -p "$(dirname $dest)"
        cp "$source" "$dest"
    elif ls "$WORKING_PATH" ; then
        source="$WORKING_PATH/rc/$1"
        dest=$HOME/$2

	mkdir -p "$(dirname $dest)"
        cp "$source" "$dest"
    else
        echo "Unable to run script..."
        echo "Please place dir in either $HOME/dotfiles or $HOME/worksapce/dotfiles..."
        exit 1
    fi
}

function set_up_directory_structure {
    mkdir -p "$HOME"/.rm-trash-can
    mkdir -p "$HOME"/var
    mkdir -p "$HOME"/workspace
}

function create_notes_symlink_if_home {
    if ! home_mac ; then
      return
    fi

    if ! test -d ~/Library/Mobile\ Documents/iCloud~com\~logseq\~logseq/Documents/notes/ ; then
      return
    fi

    if test -L ~/notes-symlink/ ; then
      return
    fi

    ln -s ~/Library/Mobile\ Documents/iCloud~com\~logseq\~logseq/Documents/notes/ ~/notes-symlink^C
}
