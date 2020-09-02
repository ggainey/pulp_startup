#!/bin/bash -v
BASE='centos8-baseos-ks'
REMOTE1='http://centos.mirror.rafal.ca/8.2.2004/BaseOS/ppc64le/kickstart/'
pulp-admin rpm repo create --serve-http=true --repo-id=$BASE --relative-url=$BASE --feed=$REMOTE1 --download-policy immediate
pulp-admin rpm repo sync run --repo-id=$BASE
