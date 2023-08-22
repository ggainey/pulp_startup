#!/bin/bash
EXPORTER_URL="/pulp/api/v3/exporters/core/pulp/"

RHEL7_URL="https://cdn.redhat.com/content/dist/rhel/server/7/7.9/x86_64/kickstart"
#RHEL7_URL="https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/os"
#RHEL7_URL="http://cdn.stage.redhat.com/content/dist/rhel/server/7/7Server/x86_64/os/"
RHEL7_NAME="rhel7"
pulp rpm remote create --name 'rhel7' --url ${RHEL7_URL} --policy 'immediate' \
  --ca-cert @/home/vagrant/devel/pulp_startup/CDN_cert/redhat-uep.pem \
  --client-key @/home/vagrant/devel/pulp_startup/CDN_cert/cdn.key \
  --client-cert @/home/vagrant/devel/pulp_startup/CDN_cert/cdn.pem
RHEL7_HREF=$(pulp rpm repository create --name 'rhel7' --remote 'rhel7' | jq -r .pulp_href)
pulp rpm repository sync --name 'rhel7'
exit
# create exporter
EXPORTER_NAME="test"
EXPORTER_HREF=$(http POST :$EXPORTER_URL name="${EXPORTER_NAME}"-exporter repositories:=[\"${RHEL7_HREF}\"] path=/tmp/exports/)
if [ -z "$EXPORTER_HREF" ]; then exit; fi

# LIST all exporters
http GET :${EXPORTER_HREF}

