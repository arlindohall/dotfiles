
#### Top-level command ###
function install {
    if hostname | grep 'work' && is_mac ; then
        install_work_mac
    elif hostname | grep 'home' && is_mac ; then
        install_home_mac
    elif hostname | grep 'droplet' && is_linux ; then
        install_home_linux
    else
        install_work_linux
    fi
}

function random_digits {
    if ! which ruby ; then
      install_rvm
      rvm default
    fi

    length=$1
    ruby -e "puts Random.bytes($length/2).bytes.map{|b| b.to_s(16)}.join"
}

function install_with_curl {
    name="/tmp/$1-$(random_digits 4)"
    url=$2
    run_command=$3
    hash=$4

    curl -sSLf $url > $name

    # Run command is not quoted because it might have arguments stuffed in
    openssl sha512 -r $name | grep $hash && cat $name | $run_command
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
        9480c31d52b2841b1389d3cf02d54f9c85a6010312c3c141977b396d168e556c4a52137286a288286988ddec0f6244430eb220341dfbd0c73ce538509053c2fc

    # Fish configuration
    mkdir -p "$HOME/.config/fish/functions/"
    install_with_curl \
        rvm-fish \
        https://raw.github.com/lunks/fish-nuggets/master/functions/rvm.fish \
        "tee > $HOME/.config/fish/functions/rvm.fish" \
        80f8cd98656c99b2ce66c665ee957a77d107e62a87c0554bf3c7fc291680382653a8acf4f5f78397e254002c985dc2dae85f3c7b07c3251d8634c5ea5a530ecb
}

function is_linux {
    uname | grep -i 'linux'
}

function is_mac {
    uname | grep -i 'darwin'
}