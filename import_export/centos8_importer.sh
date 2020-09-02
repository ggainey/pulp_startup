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

IMPORTER_URL="/pulp/api/v3/importers/core/pulp/"
CENTOS_NAME='new-centos8'
MAPPING='{"centos8-base": "new-centos8-base", "centos8-apps": "new-centos8-apps"}'

# create repo
CENTOS8_BASE_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name="${CENTOS_NAME}-base" | jq -r '.pulp_href')
echo "repo_href : " $CENTOS8_BASE_HREF
if [ -z "$CENTOS8_BASE_HREF" ]; then exit; fi

CENTOS8_APPS_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name="${CENTOS_NAME}-apps" | jq -r '.pulp_href')
echo "repo_href : " $CENTOS8_APPS_HREF
if [ -z "$CENTOS8_APPS_HREF" ]; then exit; fi

# create importer
IMPORT_NAME="test-centos8"
IMPORT_HREF=$(http POST :$IMPORTER_URL name="${IMPORT_NAME}"-importer repo_mapping:="${MAPPING}") 
echo "repo_href : " $IMPORT_HREF
if [ -z "$IMPORT_HREF" ]; then exit; fi

# LIST all importers
http GET :$IMPORTER_URL
