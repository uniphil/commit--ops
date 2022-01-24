#!/bin/ksh
# this script runs as root, final config runs as `backup` limited user
. $PWD/nice.sh

msg Setup the backup user...
if user info -e backup; then
    msg Found user backup already exists, continuing...
else
    run user add -m -d /home/backup -s /sbin/nologin backup
fi

START=$PWD
cd /home/backup

msg Install tarsnap? \(n/Y\)
read YES_INSTALL_PLZ
if [[ ! $YES_INSTALL_PLZ = "n" ]]; then
    msg Get and verify tarsnap 1.0.39...
    run curl -LO "https://www.tarsnap.com/download/tarsnap-autoconf-1.0.39.tgz"
    echo -e "SHA256 (tarsnap-autoconf-1.0.39.tgz) = 5613218b2a1060c730b6c4a14c2b34ce33898dd19b38fb9ea0858c5517e42082\n" > checklist
    run sha256 -C checklist tarsnap-autoconf-1.0.39.tgz

    msg Setup tarsnap...
    run tar xzf tarsnap-autoconf-1.0.39.tgz
    cd tarsnap-autoconf-1.0.39
    run ./configure --prefix=/home/backup
    run make
    run make install
    cd ..
fi

run mkdir -p db tarsnap-cache

msg Create backup.sh script...
cd $START
install_file backup:backup +x /home/backup/backup.sh

msg Hide backup contents from others
run chown -R backup:backup /home/backup
run chmod -R 700 /home/backup

msg Install daily cron job for backups..
run su -s /bin/ksh backup -c 'echo "0 0 * * * /home/backup/backup.sh > /dev/null" | crontab -'

msg Setup tarsnap keys? \(n/Y\)
read YES_KEYS_PLZ
if [[ ! $YES_KEYS_PLZ = "n" ]]; then
    msg Please paste the contents of \'tarsnap.key\' \(preferably created with only -w permission\)
    TARSNAP_WO_KEY=$(sed '/^$/q')
    echo "$TARSNAP_WO_KEY" > /home/backup/tarsnap.key
    chown backup:backup /home/backup/tarsnap.key
fi

msg Ok

# TODO: tarsnap --fsck needs to be run once if we lost tarsnap-cache/, which needs a read key.
# TODO: ping healthchecks.io on successfulbackup, so that something makes noise if it fails
