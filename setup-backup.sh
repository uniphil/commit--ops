#!/bin/ksh
# this script runs as root, final config runs as `backup` limited user
set -eu
IFS=$'\n\t'

msg() {
    echo -e " \033[0;36m--->\033[0m ${1-}" >&2
}

msg "create user 'backup'..."
useradd -m -d /home/backup -s /sbin/nologin backup
cd /home/backup

msg "download and verify tarsnap 1.0.39..."
curl -LO "https://www.tarsnap.com/download/tarsnap-autoconf-1.0.39.tgz"
echo -e "SHA256 (tarsnap-autoconf-1.0.39.tgz) = 5613218b2a1060c730b6c4a14c2b34ce33898dd19b38fb9ea0858c5517e42082\n" > checklist
sha256 -C checklist tarsnap-autoconf-1.0.39.tgz

msg "build targsnap..."
tar xzf tarsnap-autoconf-1.0.39.tgz
cd tarsnap-autoconf-1.0.39
./configure --prefix=/home/backup
make && make install
cd ..
mkdir db tarsnap-cache

msg "create backup.sh script..."
cat << 'EOF' > backup.sh
#!/bin/ksh
set -e

# create the backup
echo ".backup /home/backup/db/db.sqlite3" \
    | sqlite3 /var/commit--store/db.sqlite3

# tarsnap it
/home/backup/bin/tarsnap -c \
    --keyfile /home/backup/tarsnap.key \
    --cachedir /home/backup/tarsnap-cache \
    -f "commit--db-$(date +%Y-%m-%dT%H:%M:%S)" \
    /home/backup/db/db.sqlite3
EOF
chmod +x backup.sh

msg "assigning ownership of stuff at /home/backup to user 'backup'..."
chmod 700 /home/backup
chown -R backup:backup /home/backup

msg "installing daily cron job for backups.."
su -s /bin/ksh backup -c 'echo "0 0 * * * /home/backup/backup.sh > /dev/null" | crontab -'

msg "done"
msg
msg "user created. please copy 'tarsnap.key' (preferably created with only -w permission) to /home/backup/"
msg
