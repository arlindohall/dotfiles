#!/bin/bash

# shellcheck disable=SC2002

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
    if ! (which ruby 1>/dev/null) ; then
        set +o pipefail # about to interrupt this pipe
        base64 /dev/urandom | tr -d '+/' | head -c 4
        set -o pipefail
        return
    fi

    length=$1
    ruby -e "puts Random.bytes($length/2).bytes.map{|b| b.to_s(16)}.join"
}

function install_with_curl {
    name="/tmp/$1-$(random_digits 4)"
    url=$2
    run_command=$3
    hash=$4

    curl -sSLf "$url" > "$name"

    # Run command is not quoted because it might have arguments stuffed in
    openssl sha512 -r "$name" | grep "$hash" && cat "$name" | $run_command
}

function is_linux {
    uname | grep -i 'linux'
}

function is_mac {
    uname | grep -i 'darwin'
}
