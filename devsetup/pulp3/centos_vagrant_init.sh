#!/bin/bash
# Setting up a freshly-created vagrant machine
# setup my bash env
cat >> $HOME/.bashrc <<HERE
set -o vi
export HISTSIZE=10000
export HISTFILESIZE=100000
alias h='history 25'
HERE
. $HOME/.bashrc
# install needed modules
sudo yum install -y wget openssl-devel python3-pip
sudo pip install rhsm
cd $HOME/devel/pulpcore
sudo pip install -r test_requirements.txt
cd ../devel/pulp_file
sudo pip install -r test_requirements.txt
cd ../devel/pulp_rpm
sudo pip install -r test_requirements.txt
