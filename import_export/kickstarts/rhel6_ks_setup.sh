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

KICKSTART_URL="http://cdn.stage.redhat.com/content/dist/rhel/server/6/6Server/x86_64/kickstart/"
REPO_NAME="rhel6ks"

## create repos
BASE_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${REPO_NAME} | jq -r '.pulp_href')
echo "base_repo_href : " $BASE_HREF
if [ -z "$BASE_HREF" ]; then exit; fi
#
## add remote
http POST :/pulp/api/v3/remotes/rpm/rpm/ name=$REPO_NAME url=$KICKSTART_URL  policy='immediate'
## find remote's href
REMOTE_HREF=$(http :/pulp/api/v3/remotes/rpm/rpm/ | jq -r ".results[] | select(.name == \"${REPO_NAME}\") | .pulp_href")
echo "remote_href : " $REMOTE_HREF
if [ -z "$REMOTE_HREF" ]; then exit; fi
## sync
TASK_URL=$(http POST :$BASE_HREF'sync/' remote=$REMOTE_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
## wait for task
wait_until_task_finished :$TASK_URL
## find repo-version
REPOVERSION_HREF=$(http :$TASK_URL| jq -r '.created_resources | first')
echo "repoversion_href : " $REPOVERSION_HREF
if [ -z "$REPOVERSION_HREF" ]; then exit; fi
