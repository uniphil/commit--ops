#!/bin/ksh
. $PWD/nice.sh

msg Add mount points for block storage
mkdir -p /var/commit--store
mkdir -p /var/commit--repos

msg Setup fstab entries for block storage
run sysctl hw.disknames

addfstab() {
    name=$1
    path=$2
    if [[ -z $(grep "$path" "/etc/fstab") ]]; then
        msg Add "$path" to fstab...
        echo "$name.a $path ffs rw,nodev,nosuid,softdep 1 0" >> /etc/fstab
    else
        msg Found "$path" in fstab already
    fi
    run grep "$path" /etc/fstab
}

addfstab f4296ea28c048d37 /var/commit--store
addfstab 4896977cdc7f10ba /var/commit--repos

msg Please check that the grepped lines from fstab match the disk labels from \`sysctl hw.disknames\`
msg Please edit /etc/fstab and add \'softdep\' to every rw mount option

msg Ok
