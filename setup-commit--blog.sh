#!/bin/ksh
set -eu

useradd -m -d /var/commit--blog -s /sbin/nologin -G www commit--blog
chmod 700 /var/commit--blog
