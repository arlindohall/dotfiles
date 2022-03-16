#!/bin/bash

set -euxo pipefail

. ./helpers.sh

#### Dotfile placement and env config ####
function install_home_mac {
    set_up_directory_structure
    install_personal_bin

    rc_install bash-bash_profile        .bash_profile
    rc_install fish-config              .config/fish/config.fish
    rc_install fish-mac_config          .config/fish/conf.d/mac_config.fish
    rc_install fish-home_mac_config     .config/fish/conf.d/home_mac_config.fish
    rc_install gitconfig-home           .gitconfig
    rc_install sh-inputrc               .inputrc
    rc_install sh-profile               .profile
    rc_install tmux-conf                .tmux.conf
    rc_install tmux-conf_local          .tmux.conf.local
    rc_install vim-vimrc                .vimrc
    rc_install zsh-mac_zshrc            .zshrc
}

function install_home_linux {
    set_up_directory_structure
    install_personal_bin

    rc_install bash-bash_profile        .bash_profile
    rc_install fish-config              .config/fish/config.fish
    rc_install fish-linux_config        .config/fish/conf.d/linux_config.fish
    rc_install gitconfig-home           .gitconfig
    rc_install sh-inputrc               .inputrc
    rc_install sh-profile               .profile
    rc_install tmux-conf                .tmux.conf
    rc_install tmux-conf_local          .tmux.conf.local
    rc_install vim-vimrc                .vimrc
}

function install_work_mac {
    set_up_directory_structure
    install_personal_bin

    rc_install bash-bash_profile        .bash_profile
    rc_install fish-config              .config/fish/config.fish
    rc_install fish-mac_config          .config/fish/conf.d/mac_config.fish
    rc_install fish-work_mac_config     .config/fish/conf.d/work_mac_config.fish
    rc_install gitconfig-work           .gitconfig
    rc_install gitconfig-work-dev       .config/dev/gitconfig
    rc_install sh-inputrc               .inputrc
    rc_install sh-profile               .profile
    rc_install tmux-conf                .tmux.conf
    rc_install tmux-conf_local          .tmux.conf.local
    rc_install vim-vimrc                .vimrc
    rc_install zsh-mac_zshrc            .zshrc
}

function install_work_linux {
    set_up_directory_structure
    install_personal_bin

    rc_install gitconfig-work           .gitconfig
    rc_install sh-inputrc               .inputrc
    rc_install sh-profile               .profile
    rc_install tmux-conf                .tmux.conf
    rc_install tmux-conf_local          .tmux.conf.local
    rc_install vim-vimrc                .vimrc
    rc_install zsh-zshrc                .zshrc
}

function install_personal_bin {
    cp -r ./bin $HOME/
}

install
