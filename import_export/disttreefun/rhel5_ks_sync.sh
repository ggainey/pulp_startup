#!/bin/bash
REPO_NAME="rhel5-ks"
#REMOTE_URL=https://cdn.redhat.com/content/dist/rhel/server/5/5.11/x86_64/kickstart
REMOTE_URL=https://cdn.redhat.com/content/dist/rhel/server/6/6.1/x86_64/os
#REMOTE_URL="https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/kickstart/"
pulp rpm remote create --name ${REPO_NAME} --url ${REMOTE_URL} --policy 'immediate' \
  --ca-cert @/home/vagrant/devel/pulp_startup/CDN_cert/redhat-uep.pem \
  --client-key @/home/vagrant/devel/pulp_startup/CDN_cert/cdn.key \
  --client-cert @/home/vagrant/devel/pulp_startup/CDN_cert/cdn.pem \
  --tls-validation false
pulp rpm repository create --name ${REPO_NAME} --remote ${REPO_NAME} | jq -r .pulp_href
pulp rpm repository sync --name ${REPO_NAME}
