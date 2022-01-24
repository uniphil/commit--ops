#!/bin/ksh
. $PWD/nice.sh

msg Setup the acme user
if user info -e acme; then
    msg Found user acme already exists, continuing...
else
    run useradd -m -d /home/acme -s /sbin/nologin -g www acme
    run cp nice.sh /home/acme/
fi

msg Get acme.sh
if [[ -d "/home/acme/acme.sh-master" ]]; then
    msg Found "/home/acme/acme.sh-master" folder, skipping download...
else
    # latest working commit from acme.sh: 4c32bc8e22075d3333f49973016a62983205f0aa
    run curl -sLo acme.tar.gz \
        https://github.com/acmesh-official/acme.sh/archive/master.tar.gz
    run tar xzf acme.tar.gz -C /home/acme/
fi

msg Fix ssl location ownership to acme
# Let acme touch httpd's default cert locations
# this might not be the best idea... possibly should make a subdir and leave these default
# relayd keypair default: /etc/ssl/<name>:<port>.crt
# relayd keypair default: /etc/ssl/private/<name>:<port>.key
run chown acme /etc/ssl
run chown acme /etc/ssl/private

export HOME=/home/acme

msg Install acme.sh...
msg Please enter the email address for letsencrypt:
read ACME_EMAIL
export ACME_EMAIL

run su -l -s /bin/ksh acme <<EOF
. $HOME/nice.sh
cd acme.sh-master

export 
./acme.sh --install \
    --force \
    --accountemail "$ACME_EMAIL"
EOF

msg Install commit--blog certificates...
msg Please enter the Cloudflare Account ID for the delegated domain:
read CF_Account_ID
echo "SAVED_CF_Account_ID='$CF_Account_ID'" >> $HOME/.acme.sh/account.conf
msg Please enter the Cloudflare Zone ID:
read CF_Zone_ID
echo "SAVED_CF_Zone_ID='$CF_Zone_ID'" >> $HOME/.acme.sh/account.conf
msg Please enter the Cloudflare Token:
read CF_Token
echo "SAVED_CF_Token='$CF_Token'" >> $HOME/.acme.sh/account.conf

run su -l -s /bin/ksh acme <<EOF
. $HOME/nice.sh
msg Setup acme with the dns01 challenge via a delegated domain\!
acme.sh --issue \
    --force-color \
    --server letsencrypt \
    --domain "commit--blog.com" \
    --challenge-alias "dns01-challenged.com" \
    --dns dns_cf \
    --domain "*.commit--blog.com" \
    --domain "*.staged.commit--blog.com" \
    --fullchain-file "/etc/ssl/server.crt" \
    --key-file "/etc/ssl/private/server.key" \
    --reloadcmd "doas /etc/rc.d/relayd reload"
EOF

msg Hide acme\'s stuff from everyone
run chmod -R 700 /home/acme

msg Ok
