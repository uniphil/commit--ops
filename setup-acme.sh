#!/bin/ksh
# inspired by https://gist.github.com/Nothing4You/ecbb69d2270e36bac88cfcab9cf736ef
# this script runs as root, final config runs as `acme` limited user
set -euo pipefail
IFS=$'\n\t'

# ensure we have all the variables we need
# -> since we `set -u` above, if any of these are undefined, we get a decent error
: $ACME_EMAIL
: $CF_Zone_ID
: $CF_Account_ID
: $CF_Token

# First things first - create a user account for acme
useradd -m -d /home/acme -s /sbin/nologin -g www acme
chmod 700 /home/acme

# Let acme touch httpd's default cert locations
# this might not be the best idea... possibly should make a subdir and leave this default
chown acme /etc/ssl
chown acme /etc/ssl/private

#relayd keypair default: /etc/ssl/<name>:<port>.crt
#relayd keypair default: /etc/ssl/private/<name>:<port>.key

# Edit your doas.conf to allow the acme user to reload (not restart) nginx
echo 'permit nopass acme cmd relayctl args reload' >> /etc/doas.conf

# Now change to the ACME user
su - -s /bin/ksh acme
export HOME=/home/acme
cd $HOME

# Install latest(!?) acme.sh. yolo.
curl -Lo acme.tar.gz https://github.com/acmesh-official/acme.sh/archive/master.tar.gz
tar xzvf acme.tar.gz
cd acme.sh-master
./acme.sh --install --accountemail "$ACME_EMAIL"

acme.sh --issue \
    --domain "commit--blog.com" \
    --challenge-alias "dns01-challenged.com" \
    --dns dns_cf \
    --domain "*.commit--blog.com" \
    --domain "*.staged.commit--blog.com" \
    --fullchain-file "/etc/ssl/server.crt" \
    --key-file "/etc/ssl/private/server.key" \
    --reloadcmd "doas relayctl reload"
