#!/bin/ksh
set -eu

useradd -m -d /home/blogger -G www blogger

cd /home/blogger
python3 -m venv venv
mkdir commit--blog.git
git init --bare commit--blog.git

chown -R blogger:blogger commit--blog.git
