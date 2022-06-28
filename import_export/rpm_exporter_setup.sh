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

# get an RPM repo UUID
RPM_HREF=$(http GET http://localhost:24817/pulp/api/v3/repositories/rpm/rpm/ | jq -r ".results[0] | .pulp_href")
RPM_HREF="/pulp/api/v3/repositories/rpm/rpm/b2040c17-2d77-41e2-abdc-6f1ff0bc6734/"

# create exporter
EXPORTER_NAME="test-rpm-1"
EXPORTER_HREF=$(http POST $BASE_ADDR$EXPORTER_URL name="${EXPORTER_NAME}"-exporter repositories:=[\"${RPM_HREF}\"] path=/tmp/exports/) #"
echo $EXPORTER_HREF
if [ -z "$EXPORTER_HREF" ]; then exit; fi

# LIST all exporters
http GET $BASE_ADDR$EXPORTER_URL
