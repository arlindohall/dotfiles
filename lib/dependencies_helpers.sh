#!/bin/bash

#### Specific installations commands ###
function install_pybin {
    if ls "$HOME"/pybin ; then
        return
    fi

    if is_linux ; then
        sudo apt install -y python3.10-venv
    fi

    python3 -m venv "$HOME"/pybin
}

function clone_var_repo {
    repo=$1

    if ls "$HOME"/var/"$repo" ; then
        return
    fi

    git clone https://gitlab.com/arlindohall/"$repo" "$HOME"/var/"$repo"
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

function install_clang {
    sudo apt install -y clang
}

function install_rust {
    if ls "$HOME"/.cargo/bin/cargo ; then
        return
    fi

    if ls "$HOME"/.rust/bin/cargo ; then
        return
    fi

    # Add cargo to path just for the duration of install script
    # This is technically a global variable but it makes it easier
    # to install later without checking where cargo is installed
    #
    # Might be on an instance where rust is installed at `.rust/bin/`
    export PATH="$PATH:$HOME/.cargo/bin"
    export PATH="$PATH:$HOME/.rust/bin"

    install_with_curl \
        rustup \
        https://sh.rustup.rs  \
        sh \
        baf397601a78f37584a80e6c66f83f503bc42839c1362c8e2ccb719f5bb74e00801d74940fcf559dcc35d06c9b4124866017f85ba8766e545a2ef30068637839
}

function install_rbenv {
    if which rbenv ; then
        return
    fi

    if is_linux ; then
        git clone https://github.com/rbenv/rbenv.git ~/.rbenv
        PATH=$PATH:$HOME/.rbenv/bin
        git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
    else
        brew install rbenv ruby-build
    fi
}

function homebrew_tools_installed {
    which bat &&
        which delta &&
        which fish &&
        which node &&
        which podman &&
        which rg &&
        which shellcheck &&
        which tmux &&
        which tree &&
        which watch &&
        which watchman
}

function install_homebrew_tools {
    if homebrew_tools_installed ; then
        return
    fi

    brew install \
        bat \
        fish \
        jj \
        graphviz \
        node \
        pandoc \
        podman \
        ripgrep \
        shellcheck \
        tmux \
        tree \
        watch \
        watchman
}

function install_apt_tools {
    if apt_tools_installed ; then
        return
    fi

    sudo apt install -y \
        bat \
        docker.io \
        fish \
        graphviz \
        pandoc \
        ripgrep \
        tmux \
        tree \
        watch
}

function apt_tools_installed {
    which bat &&
        which docker &&
        which fish &&
        which dot &&
        which pandoc &&
        which rg &&
        which tmux &&
        which tree &&
        which watch
}

function install_git {
    if which git ; then
        return
    fi

    if is_linux ; then
        sudo apt install -y git
    else
        xcode-select --install
    fi
}

function install_jj {
    if which jj ; then
      return
    fi

    if ! is_linux ; then
      return
    fi

    cargo install jj
}

function install_openjdk {
    if ls /opt/amazon-corretto-11/ || ls /Library/Java/JavaVirtualMachines/amazon-corretto-11.jdk ; then
        return
    fi

    if is_linux ; then
        install_with_curl \
            corretto \
            https://corretto.aws/downloads/latest/amazon-corretto-11-x64-linux-jdk.tar.gz \
            "tee /opt/amazon-corretto-11-x64-linux-jdk.tar.gz" \
            5fd3899788ca447f0b8f572e15e6b02b602be6e08b3413ce1e368886dbab380c4195cd1e6f218304c87fc68297372fca9193fdf3dca88d65649f166768046569

        read -pr "In a new shell, unzip the corretto installation, press any key to continue..."
    elif is_mac ; then
        echo "Install java from the amazon downloads page: [link should open automatically]"
        echo "For help see: https://docs.aws.amazon.com/corretto/latest/corretto-11-ug/macos-install.html"
        open "https://docs.aws.amazon.com/corretto/latest/corretto-11-ug/macos-install.html"
        read -pr "Press any key to continue"
    fi
}

function install_git_delta {
    if which delta ; then
        return
    fi

    if ! which cargo ; then
        install_rust
    fi

    cargo install -j 8 git-delta
}

function set_install_shell {
    chsh -s "$(which fish)" millerhall
}
