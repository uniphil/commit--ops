a diagram that will probably quickly go out of date:

```
   CF DNS          public      public
     ^             :80 http    :443 https          :22 ssh
+----+------+    +--+-----------^---------+    +---------------------+
|           |    |  |           |         |    |                     |
| acme.sh   |    |  +-301-redir-+         |    | git /home/blogger   |
|  ^        |    |                        |    |                     |
+----@acme--+    | relayd                 |    +--+---@blogger-------+
   |      |      | ^                      |       |
 cron     |      | |   /static         /  |       |     post-recieve:
          |      +-----+---@www--------+--+     reload    co static /var/www/htdocs
          |        |   |               |          |       co app /var/commit--blog
          +-reload-+   |               |          |       install reqs
                       |               |          |       reload app
                       v               v          v
        localhost:8000 http            localhost:9000 http
       +-------------------+          +--------------------v--+
       |                   |          |                       |
       | /var/www/htdocs/  |          | var/commit--blog/wsgi |
       |                   |          | gunicorn (+ newrelic) |
       | httpd             |          |                       |
       |                   |          +--+-@commit--blog-+----+
       +---@www------------+             |       |       |
                                      +--v---+ +-v---+ +-v----+
                                      | app  | | app | | app  |
@acme                                 +---+--+ +---+-+ +---+--+
 HOME=/home/acme                          |        |       |
 owns /etc/ssl{,/private}             +---v--------v-------v--+
 doas root relayctl reload            |                       |
                                      | sqlite3 on block      |
@blogger g/www | ssh allowed          | volume                |
 HOME=/home/blogger                   |                       |
 doas commit--blog pip install        +----@commit--blog------+
 doas commit--blog gunicorn reload

@commit--blog g/www
 chroot /var/commit--blog gunicorn

@www
 chroot /var/www
 owns /var/www/htdocs
```


```sh
git remote add server ssh://blogger@172.81.178.30/home/blogger/commit--blog.git
```

updating environment variables
---

```bash
su root
cd /root
nano gunicorn-environment.json
# edit and save the environment object
./supervisor-environmentize.py gunicorn-environment.json
# copy the printed line
nano /etc/supervisord.d/gunicorn.ini
# paste it to replace the `environment=` line's value
```

^^ i probably already messed that up by directly editing gunicorn.ini (fixme)

running db migrations (or ./manage.py generally)
---

- switch users to `commit--blog`
- source `.profile`: `. /var/commit--blog/.profile` (abs path **required** -- i forget this every time)
- double check that the db path is there `echo $DATABASE_URL`

then it should be good to go
