#!/bin/ksh
set -eu; fp=$1

chown -R www:www $fp
chmod -R 0550 $fp
