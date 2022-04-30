a diagram that will probably quickly go out of date:

```
   CF DNS          public      public
     ^             :80 http    :443 https          :22 ssh
+----+------+    +--+-----------^---------+    +---------------------+
|           |    |  |           |         |    |                     |
| acme.sh   |    |  +-301-redir-+         |    | git /home/publisher |
|  ^        |    |                        |    |                     |
+----@acme--+    | relayd                 |    +--+---@publisher-----+
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
@publisher g/www | ssh allowed        | volume                |
 HOME=/home/publisher                 |                       |
 doas commit--blog pip install        +----@commit--blog------+
 doas commit--blog gunicorn reload

@commit--blog g/www
 chroot /var/commit--blog gunicorn

@www
 chroot /var/www
 owns /var/www/htdocs
```


```sh
git remote add server ssh://publisher@172.81.178.30/home/publisher/commit--blog.git
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


spinning up a new machine
---

### requirements

- [ ] new password for root
- [ ] new password for publisher account
- [ ] tarsnap write-only key
- [ ] DNS A-records pointed at new IP
- [ ] acme: email address, CF_Zone_ID, CF_Account_ID, acme: CF_Token
- [ ] lunanode login
- [ ] prod secrets for app

### approximate steps

1. install openbsd (time of writing: 7.0)

   - do you expect to run X? **no**
   - set up a user? `publisher` (will be able to ssh)
   - do not allow root ssh login
   - no X* sets (`-x*`)
   - when done, `h`alt, and disconnect/swap the install disk image

2. grab these scripts

   - ssh in as `publisher`

   ```bash
   su root
   cd /root
   pkg_add curl
   curl 'https://github.com/uniphil/commit--ops/archive/refs/heads/main.tar.gz' -Lo ops.tar.gz
   tar xzf ops.tar.gz
   cd commit--ops-main/
   ```

TODO: set disks to mount with Soft Updates -- https://www.openbsd.org/faq/faq14.html#SoftUpdates

   - attach volumes
   - reboot
   - run `sysctl hw.disknames` to get the volume ids  `hw.disknames=sd0:d3d80d1262b77228,sd1:,sd2:f4296ea28c048d37,fd0:`
      - note: the current disklabel for commit--store (5GB/id 8965) is `f4296ea28c048d37`
   - edit `/etc/fstab` to mount the disk
      - **set fs_passno to 0** (the last field in fstab)
      - note that it will just awkwardly not mount if it needs to be fsck'd (after a hard reboot for example)
         - todo: confirm that manually fscking fixes this
   - block storage is finicky to disconnect -- may need to hard shut down from the web UI to successfully detatch (and might need to fsck on new host before mounting)



   original commit--serve fstab
   ```
   commit--serve# cat /etc/fstab
   d3d80d1262b77228.b none swap sw
   d3d80d1262b77228.a / ffs rw 1 1
   d3d80d1262b77228.k /home ffs rw,nodev,nosuid 1 2
   d3d80d1262b77228.d /tmp ffs rw,nodev,nosuid 1 2
   d3d80d1262b77228.f /usr ffs rw,nodev 1 2
   d3d80d1262b77228.g /usr/X11R6 ffs rw,nodev 1 2
   d3d80d1262b77228.h /usr/local ffs rw,wxallowed,nodev 1 2
   d3d80d1262b77228.j /usr/obj ffs rw,nodev,nosuid 1 2
   d3d80d1262b77228.i /usr/src ffs rw,nodev,nosuid 1 2
   d3d80d1262b77228.e /var ffs rw,nodev,nosuid 1 2
   f4296ea28c048d37.a /var/commit--store ffs rw,nodev,nosuid 1 2
   ```

   does it boot with noauto?


   original commit--serve fstab
   ```
   commit--serve# cat /etc/fstab
   d3d80d1262b77228.b none swap sw
   d3d80d1262b77228.a / ffs rw 1 1
   d3d80d1262b77228.k /home ffs rw,nodev,nosuid 1 2
   d3d80d1262b77228.d /tmp ffs rw,nodev,nosuid 1 2
   d3d80d1262b77228.f /usr ffs rw,nodev 1 2
   d3d80d1262b77228.g /usr/X11R6 ffs rw,nodev 1 2
   d3d80d1262b77228.h /usr/local ffs rw,wxallowed,nodev 1 2
   d3d80d1262b77228.j /usr/obj ffs rw,nodev,nosuid 1 2
   d3d80d1262b77228.i /usr/src ffs rw,nodev,nosuid 1 2
   d3d80d1262b77228.e /var ffs rw,nodev,nosuid 1 2
   f4296ea28c048d37.a /var/commit--store ffs rw,nodev,nosuid,noauto 1 2
   ```


#### Initializing a new block storage

1. attach it
2. reboot
3. run `sysctl hw.disknames` should show just `sdN:` (wit no name after)
4. run `fdisk -g sdN` to write a new GPT (!!!danger!!!)
   ... or (or and?) `fdisk -i sdN` to write an MBR? needed this.
5. run `fdisk sdN` to view the partitions. something like:

   ```
   commit--sketch# fdisk sd2
   Disk: sd2   geometry: 2088/255/63 [33554432 Sectors]
   Offset: 0   Signature: 0xAA55
               Starting         Ending         LBA Info:
    #: id      C   H   S -      C   H   S [       start:        size ]
   -------------------------------------------------------------------------------
    0: 00      0   0   0 -      0   0   0 [           0:           0 ] unused
    1: 00      0   0   0 -      0   0   0 [           0:           0 ] unused
    2: 00      0   0   0 -      0   0   0 [           0:           0 ] unused
   *3: A6      0   1   2 -   2087 254  63 [          64:    33543656 ] OpenBSD
   ```

6. run `disklabel -E sdN` for the interactive lable editor

   - type `a` to add a partition
   - accept all defaults to let it take up the whole disk with an FFS partition
   - type `w` to write the disk lable
   - type `q` to exit the editor

7. run `newfs sdNa` to initialize the filesystem
8. get the new disklabel with `sysctl hw.disknames`


#### Getting acme/cf creds from a live machine

   ```sh
   cat /home/acme/.acme.sh/account.conf
   ```
