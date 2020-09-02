#!/bin/bash -v
IMPORTER_URL="/pulp/api/v3/importers/core/pulp/"
NAME='new-rhel6'
MAPPING='{"rhel6ks": "new-rhel6"}'
# create repos
echo "http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${NAME} | jq -r '.pulp_href'"
HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${NAME} | jq -r '.pulp_href')
echo "repo_href : " ${HREF}
if [ -z "${HREF}" ]; then exit; fi
# create importer
IMPORT_NAME="test"
IMPORT_HREF=$(http POST :${IMPORTER_URL} name="${IMPORT_NAME}"-importer repo_mapping:="${MAPPING}") 
echo "import_href : " ${IMPORT_HREF}
if [ -z "${IMPORT_HREF}" ]; then exit; fi
# LIST all importers
http GET :${IMPORTER_URL}
