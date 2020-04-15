#!/bin/bash

# Poll a Pulp task until it is finished.
wait_until_task_finished() {
    echo "Polling the task until it has reached a final state."
    local task_url=$1
    while true
    do
        local response=$(http $task_url)
        local state=$(jq -r .state <<< ${response})
        jq . <<< "${response}"
        case ${state} in
            failed|canceled)
                echo "Task in final state: ${state}"
                exit 1
                ;;
            completed)
                echo "$task_url complete."
                break
                ;;
            *)
                echo "Still waiting..."
                sleep 1
                ;;
        esac
    done
}

BASE_ADDR="admin:password@localhost:24817"
IMPORTER_URL="/pulp/api/v3/importers/core/pulp/"
ZOO_NAME='new-zoo'
ISO_NAME='new-file'
MAPPING='{"iso": "new-file", "zoo": "new-zoo"}'

# create repos
ZOO_HREF=$(http POST $BASE_ADDR/pulp/api/v3/repositories/rpm/rpm/ name=$ZOO_NAME | jq -r '.pulp_href')
echo "repo_href : " $ZOO_HREF
if [ -z "$ZOO_HREF" ]; then exit; fi

ISO_HREF=$(http POST $BASE_ADDR/pulp/api/v3/repositories/file/file/ name=$ISO_NAME | jq -r '.pulp_href')
echo "repo_href : " $ISO_HREF
if [ -z "$ISO_HREF" ]; then exit; fi

# create exporter
IMPORT_NAME="test"
IMPORT_HREF=$(http POST $BASE_ADDR$IMPORTER_URL name="${IMPORT_NAME}"-importer repo_mapping:="${MAPPING}") 
echo "repo_href : " $IMPORT_HREF
if [ -z "$IMPORT_HREF" ]; then exit; fi

# LIST all exporters
http GET $BASE_ADDR$IMPORTER_URL
