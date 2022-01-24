#!/bin/ksh
set -euo pipefail

msg() {
    word="${1-}"; shift
    case "$word" in
        Init | Install | Setup | Ok) COLOR='1;35' ;;  # green
        Wait | Fix | Check | Found)  COLOR='1;33' ;;  # yellow
        Copy | Enable | Add | Get)   COLOR='1;36' ;;  # cyan
        Ohno | Please | Change)      COLOR='1;31' ;;  # red
        -?*)                         COLOR='1;37' ;;  # white
    esac
    echo -e " \033[1;37m-> \033[1m\033[${COLOR}m${word}\033[1;37m ${*}\033[0m"
}

etab() {
    if [ -t 1 ]
        then sed 's/^/      /'
        else cat
    fi
}

run() {
    cmd="${1-}"; shift
    echo -e "    \033[1;37m+ \033[1m\033[1;37m${cmd}\033[0m ${*}"
    $cmd "$@" | etab
}

install_file() {
    owner=$1
    moddr=$2
    fpath=$3
    msg Install $fpath for $owner with $moddr...
    cp "files$fpath" "$fpath"
    chown $owner "$fpath"
    chmod $moddr "$fpath"
}
