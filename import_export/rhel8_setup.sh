#!/bin/bash
#RHEL_BASE_URL="https://cdn.redhat.com/content/dist/RHEL/8.6/x86_64/baseos/os/"
RHEL_URL="https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/os/"
#RHEL_APPS_URL="https://cdn.redhat.com/content/dist/RHEL/8.6/x86_64/appstream/os/"
RHEL_APPS_URL="https://cdn.redhat.com/content/dist/RHEL/8.0/x86_64/appstream/os/"
RHEL_NAME="RHEL"
RHEL_BASE_NAME="RHEL-base"
RHEL_APPS_NAME="RHEL-apps"
#pulp rpm remote create --name ${RHEL_BASE_NAME} --url ${RHEL_BASE_URL} --policy 'immediate' \
#  --ca-cert @/home/vagrant/devel/pulp_startup/CDN_cert/redhat-uep.pem \
#  --client-key @/home/vagrant/devel/pulp_startup/CDN_cert/cdn.key \
#  --client-cert @/home/vagrant/devel/pulp_startup/CDN_cert/cdn.pem
#pulp rpm repository create --name ${RHEL_BASE_NAME} --remote ${RHEL_BASE_NAME}
pulp rpm remote create --name ${RHEL_NAME} --url ${RHEL_URL} --policy 'immediate' \
  --ca-cert @/home/vagrant/devel/pulp_startup/CDN_cert/redhat-uep.pem \
  --client-key @/home/vagrant/devel/pulp_startup/CDN_cert/cdn.key \
  --client-cert @/home/vagrant/devel/pulp_startup/CDN_cert/cdn.pem
pulp rpm repository create --name ${RHEL_NAME} --remote ${RHEL_NAME}
pulp -b rpm repository sync --name ${RHEL_NAME}
#pulp rpm repository sync --name ${RHEL_NAME}
#pulp exporter pulp create --name ${RHEL_NAME} --repository rpm:rpm:${RHEL_NAME} --repository rpm:rpm:${RHEL_APPS_NAME} --path /home/vagrant/devel/exports/
#pulp exporter pulp create --name ${RHEL_NAME} --repository rpm:rpm:${RHEL_NAME} --path /home/vagrant/devel/external_exports/
#pulp exporter pulp create --name ${RHEL_NAME} --repository rpm:rpm:${RHEL_NAME} --path /home/vagrant/devel/external_exports/
#pulp export pulp run --exporter ${RHEL_NAME}
