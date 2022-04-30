#!/bin/ksh
. $PWD/nice.sh

msg Setup publisher account...

msg Add publisher to groups 'www' and 'wheel'
run user mod -G www,wheel publisher

msg Please paste your ssh pubkey for authorized_keys, or press enter to skip:
read pubkey
echo $pubkey >> /home/publisher/.ssh/authorized_keys

msg Init git repo for app
run su -s /bin/ksh publisher -c 'git init --bare /home/publisher/commit--blog.git -b main'

install_file publisher:publisher +x /home/publisher/commit--blog.git/hooks/post-receive
install_file publisher:publisher +x /home/publisher/deploy.sh

msg Ok

