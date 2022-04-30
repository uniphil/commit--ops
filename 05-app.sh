#!/bin/ksh
. $PWD/nice.sh

msg Setup the blogger user
if user info -e blogger; then
    msg Found user blogger already exists, continuing...
else
    run useradd -m -d /var/commit--blog -s /sbin/nologin -G www blogger
fi

msg Setup app monitor
install_file blogger:blogger 0400 /var/commit--blog/newrelic.ini

msg Setup supervisor configs
write_supervisor_configs() {
    install_file root:wheel 0644 /etc/supervisord.d/gunicorn.ini
    msg Please paste the environment for the gunicorn app:
    read APP_ENV
    echo "environment=$APP_ENV" >> /etc/supervisord.d/gunicorn.ini
    install_file root:wheel 0644 /etc/supervisord.d/app_tasks.ini
    msg Please paste the environment for the app tasks:
    read TASKS_ENV
    echo "environment=$TASKS_ENV" >> /etc/supervisord.d/app_tasks.ini    
}
if [[ -f /etc/supervisord.d/gunicorn.ini ]]; then
    msg Fix up supervisor configs? \(y/N\)
    read YES_FIX_PLZ
    if [[ $YES_FIX_PLZ = "y" ]]; then write_supervisor_configs; fi
else
    write_supervisor_configs
fi

msg Install app virtualenv
run su -s /bin/ksh blogger -c 'cd /var/commit--blog/ && python3 -m venv venv'

msg Install wheel to the virtualenv
run su -s /bin/ksh blogger -c '/var/commit--blog/venv/bin/pip install wheel'

msg Share blogger\'s stuff with just www
run chmod -R 770 /var/commit--blog
run chown -R blogger:www /var/commit--blog

msg Setup static directory
run mkdir -p /var/www/htdocs/static
run chown www:www /var/www/htdocs/static
run chmod 774 /var/www/htdocs/static

msg Start services
run rcctl enable supervisord
run rcctl start supervisord
run rcctl reload supervisord
run rcctl start relayd
run rcctl reload relayd

msg Please add the git origin and push, if you haven\'t yet

msg Ok
