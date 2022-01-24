#!/bin/ksh
. $PWD/nice.sh

msg Install packages...
run pkg_add $(cat pkgs)

msg Copy proxy configs...
install_file root:wheel 0644 /etc/httpd.conf 
install_file root:wheel 0644 /etc/relayd.conf

msg Enable services...
run rcctl enable httpd
run rcctl -d start httpd

run rcctl enable relayd
msg Wait to start relayd for certs from acme setup

msg Copy permission configs
install_file root:wheel 0644 /etc/doas.conf

msg Ok
