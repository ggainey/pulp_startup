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

EXPORTER_URL="/pulp/api/v3/exporters/core/pulp/"

#CENTOS8_BASE_URL="http://centos.mirror.rafal.ca/8.2.2004/BaseOS/x86_64/kickstart/"
CENTOS8_BASE_URL="http://mirror.linux.duke.edu/pub/centos/8/BaseOS/x86_64/kickstart/"
CENTOS8_NAME="centos8"
CENTOS8_BASE_NAME="centos8-base"

# create repo
CENTOS8_BASE_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${CENTOS8_BASE_NAME} | jq -r '.pulp_href')
echo "base_repo_href : " $CENTOS8_BASE_HREF
if [ -z "$CENTOS8_BASE_HREF" ]; then exit; fi

# add remote
http POST :/pulp/api/v3/remotes/rpm/rpm/ name=$CENTOS8_BASE_NAME url=$CENTOS8_BASE_URL  policy='immediate'
# find remote's href
BASE_REMOTE_HREF=$(http :/pulp/api/v3/remotes/rpm/rpm/ | jq -r ".results[] | select(.name == \"${CENTOS8_BASE_NAME}\") | .pulp_href")
echo "remote_href : " $BASE_REMOTE_HREF
if [ -z "$BASE_REMOTE_HREF" ]; then exit; fi
# sync
TASK_URL=$(http POST :$CENTOS8_BASE_HREF'sync/' remote=$BASE_REMOTE_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
# wait for task
wait_until_task_finished :$TASK_URL
# find repo-version
REPOVERSION_HREF=$(http :$TASK_URL| jq -r '.created_resources | first')
echo "repoversion_href : " $REPOVERSION_HREF
if [ -z "$REPOVERSION_HREF" ]; then exit; fi
