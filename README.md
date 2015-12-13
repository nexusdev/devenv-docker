# devenv-docker

A repository for the Nexus development environment Dockerfile and documentation.
The **nexus_dev** Docker image provides everything a new developer might need to
start working on Nexus' toolchain. It also allows for a consistent environment
between developers, which can help with duplicating reported bugs.

The image currently contains:

- NodeJS
- Python + pip
- solc
- IPFS
- geth
- Git
- Vim
- inotifytools
- All of Nexus' Github repositories
- An FTP server
- A unprivileged "dev" user

The image is based on [a stripped-down Ubuntu
distribution](https://github.com/phusion/baseimage-docker) and may also contain
other tools as a result. For a deeper understanding of this image, feel free to
[examine the Dockerfile](base-image/Dockerfile).

## Quickstart

A shell script called [`docker-run`](docker-run) is provided to save you some
typing. It wraps the `docker run` command, setting the `--daemon` flag and
binding to host ports all the container ports the contained services need. If
you want more control over this process (e.g., changing the host ports the
container ports bind to), you may consider using `docker run` directly.

```
$ ./docker-run --name nexus ryepdx/nexus_dev
$ docker exec -it nexus bash

# passwd dev
(enter new password for 'dev' user)
# exit

$ docker exec -u dev -it nexus bash
```

By default, the unprivileged dev user's password is "nexus". Since this is not a
strong password, it is recommended you change it (as demonstrated above).

Be aware that the Docker container does not start automatically. You may need to
run `docker start nexus` after restarting or logging out of your computer before
you can run `docker exec` again.

## Github Keys

To get your Github SSH keys into the container, please use FTP. Also, please be
aware that you will not have `push` permissions on the Github remotes that ship
with this image. In order to get your code into those remotes, you will need to
fork the Nexus repositories, add your forks as new remotes, push to those, and
issue pull requests.

```
$ docker exec -it nexus bash

# chown -R dev /home/dev/.ssh
# chgrp -R dev /home/dev/.ssh
# exit

$ ifconfig

...
docker0   Link encap:Ethernet  HWaddr 02:42:2A:19:B8:B2
          inet addr:172.17.42.1  Bcast:0.0.0.0  Mask:255.255.0.0
...

$ ftp 172.17.42.1 2121

Name: dev
Password:

230 OK. Current directory is /home/dev
Remote system type is UNIX.
Using binary mode to transfer files.

ftp> put ~/.ssh/github.key .ssh/github.key
local: /home/ryepdx/.ssh/github.key remote: .ssh/github.key
200 PORT command successful
150 Connecting to port 42773
226-File successfully transferred

local: /home/ryepdx/.ssh/github.pub remote: .ssh/github.pub
200 PORT command successful
150 Connecting to port 54191
226-File successfully transferred

ftp> bye
221 Goodbye. You uploaded 4 and downloaded 0 kbytes.

$ docker exec -u dev -it nexus bash
$ chmod -w ~/.ssh/*
$ chmod og-r ~/.ssh/*
$ exit
```

After this, you can use `ssh-agent bash` and `ssh-add` to have your container
use your Github key when pushing without prompting for your password every time:

```
$ docker exec -u dev -it nexus ssh-agent bash

$ ssh-add ~/.ssh/github.key
```

While the image ships with Vim installed, you may also use FTP to modify files
in the container using an editor of your choice.

You may also consider adding the line `ssh-add ~/.ssh/github.key` to your
`~/.bashrc` file. This will make it so the container prompts you once for your
Github key password upon `exec`ing `ssh-agent bash` and then keeps your key
unlocked for the duration of the session. Otherwise you will have to type your
key's password each time you want to push to Github.
