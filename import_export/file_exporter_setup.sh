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
FILE_HREF=$(http GET :/pulp/api/v3/repositories/file/file/ | jq -r ".results[0] | .pulp_href")
echo $FILE_HREF

# create exporter
EXPORTER_NAME="test-file"
EXPORTER_HREF=$(http POST :$EXPORTER_URL name="${EXPORTER_NAME}"-exporter repositories:=[\"${FILE_HREF}\"] path=/tmp/exports/) #"
echo $EXPORTER_HREF
if [ -z "$EXPORTER_HREF" ]; then exit; fi

# LIST all exporters
http GET $BASE_ADDR$EXPORTER_URL
