#!/bin/ksh
set -eu

# relayd for https reverse-proxy / tls accel
rcctl enable relayd
rcctl start  relayd
rcctl reload relayd

# httpd for static files
rcctl enable httpd
rcctl start  httpd
rcctl reload relayd

# supervisord for our servicessss
rcctl enable supervisord
rcctl start  supervisord
