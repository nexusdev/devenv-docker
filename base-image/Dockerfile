FROM phusion/baseimage:0.9.17
MAINTAINER ryepdx

# Pre-reqs 
RUN apt-get -y -q update && \
    apt-get -y install language-pack-en-base && \
    dpkg-reconfigure locales && \
    apt-get -y install software-properties-common curl wget && \
    add-apt-repository -y ppa:ethereum/ethereum && \
    add-apt-repository -y ppa:ethereum/ethereum-dev && \
    apt-add-repository -y ppa:george-edison55/cmake-3.x && \
    apt-get -y -q update && \
    apt-get -y -q upgrade

RUN apt-get install -y -q build-essential libgmp3-dev golang git cmake libboost-all-dev libgmp-dev libleveldb-dev libminiupnpc-dev libreadline-dev libncurses5-dev libcurl4-openssl-dev libcryptopp-dev libjson-rpc-cpp-dev libmicrohttpd-dev libjsoncpp-dev libargtable2-dev libedit-dev mesa-common-dev libgoogle-perftools-dev libv8-dev

# Python
RUN apt-get install -q -y git python python-pip
RUN pip install virtualenvwrapper

# supervisord
RUN pip install supervisor
ADD ./etc-supervisord.conf /etc/supervisord.conf
ADD ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisor/

# rsyslog
RUN apt-get install -y rsyslog
ADD ./etc-rsyslog.conf /etc/rsyslog.conf
ADD ./etc-rsyslog.d-50-default.conf /etc/rsyslog.d/50-default.conf

#  FTP
RUN apt-get install -y inetutils-ftp
RUN wget http://download.pureftpd.org/pub/pure-ftpd/releases/pure-ftpd-1.0.41.tar.gz
RUN tar -xzf pure-ftpd-1.0.41.tar.gz

RUN apt-get build-dep -y pure-ftpd

RUN cd /pure-ftpd-1.0.41; ./configure optflags=--with-everything --with-privsep --without-capabilities
RUN cd /pure-ftpd-1.0.41; make; make install

RUN mkdir -p /etc/pure-ftpd/conf

RUN echo yes > /etc/pure-ftpd/conf/ChrootEveryone && \
    echo no > /etc/pure-ftpd/conf/PAMAuthentication && \
    echo yes > /etc/pure-ftpd/conf/UnixAuthentication && \
    echo "30000 30009" > /etc/pure-ftpd/conf/PassivePortRange && \
    echo "10" > /etc/pure-ftpd/conf/MaxClientsNumber

# Vim
RUN apt-get -y -q install vim

# inotify-tools (for running tasks when files change)
RUN apt-get install -y inotify-tools

# Cleanup installation
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add non-root user.
RUN useradd -m -s /bin/bash dev 
RUN echo dev:nexus | chpasswd

# Install most of the environment under the non-root user
USER dev

# Add a local bin for the user.
RUN mkdir ~/bin && printf "cd ~\nexport TERM=xterm\nexport PATH=\$PATH:\$HOME/bin" >> ~/.bashrc

# Solidity
RUN cd ~ && \
    git clone https://github.com/ethereum/webthree-helpers && \
    webthree-helpers/scripts/ethupdate.sh --no-push --simple-pull --project solidity && \
    webthree-helpers/scripts/ethbuild.sh --no-git --cores 2 --project solidity -DEVMJIT=0 -DETHASHCL=0 && \
    ln -s ~/solidity/build/solc/solc ~/bin/solc

# Geth
ENV GOPATH /home/dev/go
ENV PATH $PATH:$GOPATH/bin
RUN cd ~ && \
    git clone https://github.com/ethereum/go-ethereum && \
    mkdir ~/go && \
    echo "export GOPATH=\$HOME/go" >> ~/.bashrc && \
    cd ~/go-ethereum && \
    make geth && \
    ln -s ~/go-ethereum/build/bin/geth ~/bin/geth

# Python virtualenv
RUN pip completion --bash >> ~/.bashrc && \
    export WORKON_HOME=~/.virtualenvs && \
    mkdir ~/.virtualenvs && \
    echo "export WORKON_HOME=\$WORKON_HOME" >> ~/.bashrc && \
    echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc && \
    echo "export PIP_VIRTUALENV_BASE=\$WORKON_HOME" >> ~/.bashrc 

# IPFS
RUN echo "export PATH=\$GOPATH/bin:\$PATH:" >> ~/.bashrc && \
    echo "export PATH=\$PATH:/usr/local/opt/go/libexec/bin" >> ~/.bashrc && \
    go get -u github.com/ipfs/go-ipfs/cmd/ipfs

# Node (home directory local install)
ENV NODE_VERSION node-v5.1.1-linux-x64
RUN cd ~/bin && \
    wget https://nodejs.org/dist/v5.1.1/$NODE_VERSION.tar.gz && \
    tar xzf $NODE_VERSION.tar.gz && \
    ln -s $NODE_VERSION/bin/npm npm && \
    ln -s $NODE_VERSION/bin/node node && \
    rm $NODE_VERSION.tar.gz && \
    echo "export PATH=\$PATH:~/bin/$NODE_VERSION/bin" >> ~/.bashrc && \
    mkdir ~/npm && \
    ~/bin/npm config set prefix ~/npm && \
    echo "export PATH=\"\$PATH:$HOME/npm/bin\"" >> ~/.bashrc && \
    echo "export NODE_PATH=\"\$NODE_PATH:$HOME/npm/lib/node_modules\"" >> ~/.bashrc && \
    ~/bin/npm install -g eslint groc livereload

# Nexus
RUN cd ~ && \
    git clone --recursive https://github.com/NexusDevelopment/devenv && \
    cd devenv && \
    git submodule init && \
    git submodule update

# `source` only works with bash
RUN /bin/bash -c 'source /usr/local/bin/virtualenvwrapper.sh && \
    cd ~/devenv/dapple && \
    git pull origin master && \
    cd ~/devenv/dapple/pydapple && \
    mkvirtualenv nexus && \
    workon nexus && \
    python setup.py install' && \
    echo "workon nexus" >> $HOME/.bashrc

RUN ln -s ~/devenv/dapple/cmd/main.js ~/bin/dapple

# Switch back to root so we can run our daemons
USER root

# Expose ports and set up daemon script 
EXPOSE 20 21 22 4001 5001 8000 8080 8545 30000 30001 30002 30003 30004 30005 30006 30007 30008 30009 30303

ADD ./start.sh /start.sh

CMD ["/start.sh"]
