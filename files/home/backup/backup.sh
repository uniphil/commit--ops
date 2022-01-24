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
