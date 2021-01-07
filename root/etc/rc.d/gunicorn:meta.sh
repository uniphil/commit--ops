#!/bin/ksh
set -eu; fp=$1

chmod +x $fp
chmod 0555 $fp
chown root:wheel $fp
