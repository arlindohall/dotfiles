#!/bin/bash

set -euxo pipefail

INSTALL_PATH="$HOME/dotfiles/"
WORKING_PATH="$HOME/workspace/dotfiles/"

function use_helper {
    if ls "$INSTALL_PATH" ; then
        # shellcheck source=/dev/null
        . "$INSTALL_PATH/lib/$1"
    elif ls "$WORKING_PATH" ; then
        # shellcheck source=/dev/null
        . "$WORKING_PATH/lib/$1"
    else
        echo "Unable to run script..."
        echo "Please place dir in either $HOME/dotfiles or $HOME/worksapce/dotfiles..."
        exit 1
    fi
}

use_helper helpers.sh
use_helper dependencies_helpers.sh

#### Dependency and files installation ####
function install_home_mac {
    install_homebrew
    install_rust
    install_rbenv
    install_pybin
    install_git
    install_git_delta
    install_openjdk

    install_homebrew_tools

    # These steps are interactive, so the script must be run
    # by a human and not by automation
    clone_var_repo notes
    clone_var_repo journal
    clone_var_repo essays
}

function install_home_linux {
    install_clang
    install_rust
    install_rbenv
    install_pybin
    install_git
    install_git_delta

    install_apt_tools

    set_install_shell
}

function install_work_mac {
    install_homebrew
    install_rust
    install_pybin
    install_git
    install_git_delta
    install_openjdk

    install_homebrew_tools

    # These steps are interactive, so the script must be run
    # by a human and not by automation
    clone_var_repo notes
}

function install_work_linux {
    install_rust
    rustup default stable
    install_git_delta

    install_apt_tools
}

install
