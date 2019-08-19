#!/bin/bash
# Setting up a freshly-created vagrant machine
# setup my bash env
cat >> $HOME/.bashrc <<HERE
set -o vi
export HISTSIZE=10000
export HISTFILESIZE=100000
alias h='history 25'
alias pin='pulp-admin login -u admin -p admin'
HERE
. $HOME/.bashrc
# pause pulp
pstop
# install needed modules
sudo yum install -y wget openssl-dev python2-pip
# set download_interval to Very Fast
#sudo ex /etc/pulp/server.conf <<HERE2
#:%s/# download_interval: 30/download_interval: 1/
#:wq
#HERE2
cd
cd devel/pulp
sudo pip install -r test_requirements.txt

# start up pulp again
prestart
