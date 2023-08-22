#!/bin/bash
REPO_NAME="ks"
EXPORT_DIR=/home/vagrant/devel/pulp_startup/import_export/disttreefun/exports/
EXPORT_FILE=$(ls -t ${EXPORT_DIR}export-*.tar.gz | head -1)
# cleanup
pulp rpm repository destroy --name ${REPO_NAME}
IMPORTER_HREF=$(http :/pulp/api/v3/importers/core/pulp/?name=${REPO_NAME} | jq -r '.results[0].pulp_href')
http DELETE :${IMPORTER_HREF}
# create repo/importer/import
pulp rpm repository create --name ${REPO_NAME} 
IMPORTER_HREF=$(http POST :/pulp/api/v3/importers/core/pulp/ name=${REPO_NAME} | jq -r '.pulp_href')
echo "IMPORTER_HREF : ${IMPORTER_HREF}"
http POST :${IMPORTER_HREF}imports/ path=${EXPORT_FILE}
pulp rpm repository version show --repository ${REPO_NAME} --version 1
