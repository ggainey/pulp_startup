#!/bin/bash
REPO_NAME="rhel7-ks"
REMOTE_URL=https://cdn.redhat.com/content/dist/rhel/server/7/7.9/x86_64/kickstart
EXPORT_DIR=/home/vagrant/devel/pulp_startup/import_export/disttreefun/exports/
pulp rpm repository destroy --name ${REPO_NAME}
pulp rpm remote destroy --name ${REPO_NAME}
pulp exporter pulp destroy --name ${REPO_NAME}
pulp rpm remote create --name ${REPO_NAME} --url ${REMOTE_URL} --policy 'immediate' \
  --ca-cert @/home/vagrant/devel/pulp_startup/CDN_cert/redhat-uep.pem \
  --client-key @/home/vagrant/devel/pulp_startup/CDN_cert/cdn.key \
  --client-cert @/home/vagrant/devel/pulp_startup/CDN_cert/cdn.pem \
  --tls-validation false
pulp rpm repository create --name ${REPO_NAME} --remote ${REPO_NAME} | jq -r .pulp_href
pulp rpm repository sync --name ${REPO_NAME}
pulp exporter pulp create --name ${REPO_NAME} --repository "rpm:rpm:${REPO_NAME}" --path ${EXPORT_DIR}
pulp export pulp run --exporter ${REPO_NAME} --full true
