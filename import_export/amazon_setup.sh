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
        jq . <<< "${response}"
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

BASE_ADDR=":"
#http://amazonlinux.us-east-1.amazonaws.com/2/core/latest/x86_64/mirror.list"
AMAZON_URL="http://amazonlinux.us-east-1.amazonaws.com/2/core/2.0/x86_64/35c6cb980fb37ade35d6bf08c25249754c0833617182395eda0a5d6cf7e981d9/"
AMAZON_NAME="amazon4"
AMAZON_HREF=$(http POST $BASE_ADDR/pulp/api/v3/repositories/rpm/rpm/ name=$AMAZON_NAME | jq -r '.pulp_href')
echo "repo_href : " $AMAZON_HREF
if [ -z "$AMAZON_HREF" ]; then exit; fi
# add remote
http POST $BASE_ADDR/pulp/api/v3/remotes/rpm/rpm/ name=$AMAZON_NAME url=$AMAZON_URL  policy='immediate' download_concurrency=7
# find remote's href
REMOTE_HREF=$(http $BASE_ADDR/pulp/api/v3/remotes/rpm/rpm/ | jq -r ".results[] | select(.name == \"${AMAZON_NAME}\") | .pulp_href")
echo "remote_href : " $REMOTE_HREF
if [ -z "$REMOTE_HREF" ]; then exit; fi
# sync
TASK_URL=$(http POST $BASE_ADDR$AMAZON_HREF'sync/' remote=$REMOTE_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
# wait for task
wait_until_task_finished $BASE_ADDR$TASK_URL

AMAZON_URL="http://amazonlinux.us-east-1.amazonaws.com/2/core/2.0/x86_64/35c6cb980fb37ade35d6bf08c25249754c0833617182395eda0a5d6cf7e981d9/../../../../../blobstore/7c996fe24814bbd6ec92af3c497a155667ffd2062965255e64e4bb44ccf0d7a0/java-11-amazon-corretto-javadoc-11.0.8+10-1.amzn2.x86_64.rpm
