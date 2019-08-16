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
sudo yum erase -y python2-nectar
sudo yum install -y https://repos.fedorapeople.org/repos/pulp/pulp/testing/automation/2-master/stage/7/x86_64/python-nectar-1.6.0-1.el7.noarch.rpm
sudo yum install -y wget
sudo yum install -y openssl-devel
#sudo pip install pydevd-pycharm rhsm
# set download_interval to Very Fast
#sudo ex /etc/pulp/server.conf <<HERE2
#:%s/# download_interval: 30/download_interval: 1/
#:wq
#HERE2
cd
cd devel/pulp
#sudo pip install -r test_requirements.txt

# start up pulp again
prestart
