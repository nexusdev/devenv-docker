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
- A unprivileged default user

The image is based on [a stripped-down Ubuntu
distribution](https://github.com/phusion/baseimage-docker) and may also contain
other tools as a result. For a deeper understanding of this image, feel free to
[examine the Dockerfile](base-image/Dockerfile).

## Installation

A shell script called [`docker-run`](docker-run) is provided to save you some
typing. It wraps the `docker run` command, setting the `--daemon` flag and
binding to host ports all the container ports the contained services need. If
you want more control over this process (e.g., changing the host ports the
container ports bind to), you may consider using `docker run` directly.

```
$ ./docker-run --name nexus ryepdx/nexus_dev
```

To get into the container, you will need to provide an SSH key via FTP. If you
don't have an SSH key ready, you can generate one using
[ssh-keygen](http://www.cyberciti.biz/faq/linux-unix-generating-ssh-keys/) on
Unix-like systems and
[Putty](https://www.siteground.com/kb/how_to_generate_an_ssh_key_on_windows_using_putty/)
on Windows systems.

The default password for the "dev" user is "nexus". You will use these login
credentials to connect to the container via FTP. Below is a demonstration of
this process using the `ftp` command provided on most Unix-like systems. Windows
also sometimes comes with an `ftp` command, but if your copy is missing that,
you can use something like [SmartFTP](https://www.smartftp.com/).

```
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

ftp> put ~/.ssh/docker.pub .ssh/authorized_keys
local: /home/ryepdx/.ssh/docker.pub remote: .ssh/authorized_keys
200 PORT command successful
150 Connecting to port 42773
226-File successfully transferred
```

As long as you're FTPed in, you might as well also transfer over any Github
keys you have.

```
ftp> put ~/.ssh/github.key .ssh/github.key
local: /home/ryepdx/.ssh/github.key remote: .ssh/github.key
200 PORT command successful
150 Connecting to port 42773
226-File successfully transferred

local: /home/ryepdx/.ssh/github.pub remote: .ssh/github.pub
200 PORT command successful
150 Connecting to port 54191
226-File successfully transferred
```

And that's it for the FTPing.

```
ftp> bye
221 Goodbye.

```

Next we will need to get into our container as the root user and do some
additional setup. Once in, you should change your
password. (The default is "nexus".) You should probably also update the
permissions on your keys.

```
$ docker -it nexus exec bash

# passwd dev
(Enter new password for 'dev' user.)

# chmod 400 /home/dev/.ssh/*.key*

# exit
```

Then you can use SSH to login to your Docker container as the unprivileged dev
user via the private counterpart to the public key you uploaded. This is the way
you should normally access your container.

``` 
$ ssh -i ~/.ssh/docker.key -p 2222 dev@172.17.42.1
```

You might consider aliasing that SSH command to something shorter to save
yourself time in the future.

Be aware that the Docker container does not start automatically. You may need to
run `docker start nexus` after restarting or logging out of your computer before
you can SSH in again.

If you are using SSH keys to connect to Github, you might want to use
`ssh-agent` and `ssh-add` to cut down on the number of times you have to enter
your SSH key's password when pulling from and pushing to Github..

In particular, you might consider adding these lines to your container's
`~/.bashrc` file:

```
if [ $(pgrep -c ssh-agent) -eq 0 ]; then
  rm ~/.ssh/ssh_auth_sock > /dev/null
fi

if [ ! -S ~/.ssh/ssh_auth_sock ]; then
  eval `ssh-agent` > /dev/null
  ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
fi
export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
ssh-add -l | grep "The agent has no identities" && ssh-add -t 10800 ~/.ssh/github.key
```

This will make it so you're prompted upon SSHing in for your Github key's
password and then left alone for three hours following.

Finally, while the image ships with Vim installed, you may also use FTP to
modify files in the container using an editor of your choice.
