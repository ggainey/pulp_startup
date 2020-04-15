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
EXPORTER_URL="/pulp/api/v3/exporters/core/pulp/"

# get a FILE repo UUID
FILE_HREF=$(http GET http://localhost:24817/pulp/api/v3/repositories/file/file/ | jq -r ".results[0] | .pulp_href")
FILE_UUID=${FILE_HREF##/pulp/api/v3/repositories/file/file/}
FILE_UUID=${FILE_UUID%%/}
# get an RPM repo UUID
RPM_HREF=$(http GET http://localhost:24817/pulp/api/v3/repositories/rpm/rpm/ | jq -r ".results[0] | .pulp_href")
RPM_UUID=${RPM_HREF##/pulp/api/v3/repositories/rpm/rpm/}
RPM_UUID=${RPM_UUID%%/}

# create exporter
EXPORT_NAME="test"
EXPORT_HREF=$(http POST $BASE_ADDR$EXPORTER_URL name="${EXPORT_NAME}"-exporter repositories:=[\"${FILE_UUID}\",\"${RPM_UUID}\"] path=/tmp/exports/) #"
echo "repo_href : " $EXPORT_HREF
if [ -z "$EXPORT_HREF" ]; then exit; fi

# LIST all exporters
http GET $BASE_ADDR$EXPORTER_URL
