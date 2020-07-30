#!/bin/bash

# Poll a Pulp task until it is finished.
wait_until_task_finished() {
    echo "Polling the task until it has reached a final state."
    local task_url=$1
    while true
    do
        local response=$(http $task_url)
        local state=$(jq -r .state <<< ${response})
        local started=$(jq -r .started_at <<< ${response})
        local finished=$(jq -r .finished_at <<< ${response})
        #jq . <<< "${response}"
        #echo "State: [${state}] Start: [${started}] Finish: [${finished}]"
        case ${state} in
            failed|canceled)
                echo "Task in final state: ${state}"
                exit 1
                ;;
            completed)
                echo "$task_url complete."
                echo "State: [${state}] Start: [${started}] Finish: [${finished}]"
                break
                ;;
            *)
                echo "Still waiting..."
                sleep 1
                ;;
        esac
    done
}

CENTOS7_URL="http://mirror.fileplanet.com/centos/7/os/x86_64/"
CENTOS7_NAME="centos7"

# create repos
CENTOS7_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=$CENTOS7_NAME | jq -r '.pulp_href')
echo "repo_href : " $CENTOS7_HREF
if [ -z "$CENTOS7_HREF" ]; then exit; fi
# add remote
http POST :/pulp/api/v3/remotes/rpm/rpm/ name=$CENTOS7_NAME url=$CENTOS7_URL  policy='immediate' download_concurrency=7
# find remote's href
REMOTE_HREF=$(http :/pulp/api/v3/remotes/rpm/rpm/ | jq -r ".results[] | select(.name == \"${CENTOS7_NAME}\") | .pulp_href")
echo "remote_href : " $REMOTE_HREF
if [ -z "$REMOTE_HREF" ]; then exit; fi
# sync
TASK_URL=$(http POST :$CENTOS7_HREF'sync/' remote=$REMOTE_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
# wait for task
wait_until_task_finished :$TASK_URL
