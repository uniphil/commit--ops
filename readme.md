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
