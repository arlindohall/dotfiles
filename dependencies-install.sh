#!/bin/bash

set -euxo pipefail

. ./helpers.sh

#### Dependency and files installation ####
function install_home_mac {
    install_homebrew
    install_rust
    install_rvm
    install_pybin
    install_git
    install_openjdk

    install_homebrew_tools

    # These steps are interactive, so the script must be run
    # by a human and not by automation
    clone_var_repo notes
    clone_var_repo journal
    clone_var_repo essays
}

function install_home_linux {
    install_homebrew
    install_rust
    install_rvm
    install_pybin
    install_git
    install_openjdk

    install_homebrew_tools
}

function install_work_mac {
    install_homebrew
    install_rust
    install_rvm
    install_pybin
    install_git

    install_homebrew_tools

    # These steps are interactive, so the script must be run
    # by a human and not by automation
    clone_var_repo notes
}

function install_work_linux {
    true
}

#### Specific installations ####
function install_pybin {
    if ls $HOME/pybin ; then
        return
    fi

    python3 -m venv $HOME/pybin
}

function clone_var_repo {
    repo=$1

    if ls $HOME/var/$repo ; then
        return
    fi

    git clone https://gitlab.com/arlindohall/$repo $HOME/var/$repo
}

function install_homebrew {
    if which brew ; then
        return
    fi

    install_with_curl \
        homebrew \
        https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh \
        /bin/bash \
        72600deefd090113dc51c5a5e4620d59bf411e76f1a8d9991b720e17b195366e24dca535a2d75cad44cec610a27608c55440da887132feb2643f7b11775bd8b5
}

function install_rust {
    if ls $HOME/.cargo/bin/cargo ; then
        return
    fi

    install_with_curl \
        rustup \
        https://sh.rustup.rs  \
        sh \
        2d4bb2575338948c647d0a09ce486a4ca9080b7add15e7f699e2997404f318694318b7b4561f71d5a8e1c94d217db4b19083925845157bbf43957aeea7c1de20
}

function install_rvm {
    if which rvm ; then
        return
    fi

    if which gpg2 ; then
        gpg_command=gpg2
    else
        gpg_command=gpg
    fi

    $gpg_command --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    install_with_curl \
        rvm \
        https://get.rvm.io \
        'bash -s stable' \
        58d498927cda6d8d79f6d94a4a91d9996f1641932122eb7184e92b01507d323779b2438f6967beeeac0fa69f79152d5e7f94ae35d1db4b4c54d70fbaf1b841db

    # Fish configuration
    install_with_curl \
        rvm-fish \
        https://raw.github.com/lunks/fish-nuggets/master/functions/rvm.fish \
        "tee > $HOME/.config/fish/functions/rvm.fish" \
        80f8cd98656c99b2ce66c665ee957a77d107e62a87c0554bf3c7fc291680382653a8acf4f5f78397e254002c985dc2dae85f3c7b07c3251d8634c5ea5a530ecb

}

function homebrew_tools_installed {
    which rg && which watch && which node && which fish && which tmux
}

function install_homebrew_tools {
    if homebrew_tools_installed ; then
        return
    fi

    brew install \
        rg \
        fish \
        node \
        tmux \
        graphviz \
        pandoc \
        watch
}

function install_git {
    if which git ; then
        return
    fi

    if $(is_linux) ; then
        apt install git
    else
        xcode-select --install
    fi
}

function install_openjdk {
    if ls /opt/amazon-corretto-11/ || ls /Library/Java/JavaVirtualMachines/amazon-corretto-11.jdk ; then
        return
    fi

    if $(is_linux) ; then
        install_with_curl \
            corretto \
            https://corretto.aws/downloads/latest/amazon-corretto-11-x64-linux-jdk.tar.gz \
            "tee > /opt/amazon-corretto-11-x64-linux-jdk.tar.gz" \
            a56da85a5487991f997cd566344d963f69e257ee9835bf1099f70ed3fe6aee6e0c5b4757617b47847f31997dd7cbdb66605a97daa555560959c1c78f30efc158

        read -p "In a new shell, unzip the corretto installation, press any key to continue..."
    elif $(is_mac) ; then
        echo "Install java from the amazon downloads page: [link should open automatically]"
        echo "For help see: https://docs.aws.amazon.com/corretto/latest/corretto-11-ug/macos-install.html"
        open "https://docs.aws.amazon.com/corretto/latest/corretto-11-ug/macos-install.html"
        read -p "Press any key to continue"
    fi
}

install