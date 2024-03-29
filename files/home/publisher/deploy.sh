#!/bin/ksh
set -eux

REV=$1
export GIT_DIR=/home/publisher/commit--blog.git

GIT_WORK_TREE=/var/commit--blog/ git reset --hard
GIT_WORK_TREE=/var/commit--blog/ git -c advice.detachedHead=false checkout $REV
GIT_WORK_TREE=/var/commit--blog/ git reset --hard
GIT_WORK_TREE=/var/commit--blog/ git checkout -- '*'

doas -u blogger /var/commit--blog/venv/bin/pip --disable-pip-version-check install --no-deps -r /var/commit--blog/requirements.txt

doas /usr/local/bin/supervisorctl restart gunicorn
doas /usr/local/bin/supervisorctl restart app_tasks

GIT_WORK_TREE=/var/www/htdocs/ git checkout $REV -- static

echo $(date "+%Y-%m-%dT%H:%M:%S") $REV \
  | tee -a /var/www/htdocs/static/release.txt \
  | xargs -I'{}' printf "\n\nDeployed! {}\n\n"
