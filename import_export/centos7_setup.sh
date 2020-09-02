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

BASE_ADDR="admin:password@localhost:24817"
EXPORTER_URL="/pulp/api/v3/exporters/core/pulp/"

CENTOS7_URL="http://mirror.fileplanet.com/centos/7/os/x86_64/"
CENTOS7_NAME="centos7"
# FOR CENTOS7
# create repos
CENTOS7_HREF=$(http POST $BASE_ADDR/pulp/api/v3/repositories/rpm/rpm/ name=$CENTOS7_NAME | jq -r '.pulp_href')
echo "repo_href : " $CENTOS7_HREF
if [ -z "$CENTOS7_HREF" ]; then exit; fi
# add remote
http POST $BASE_ADDR/pulp/api/v3/remotes/rpm/rpm/ name=$CENTOS7_NAME url=$CENTOS7_URL  policy='immediate' download_concurrency=7
# find remote's href
REMOTE_HREF=$(http $BASE_ADDR/pulp/api/v3/remotes/rpm/rpm/ | jq -r ".results[] | select(.name == \"${CENTOS7_NAME}\") | .pulp_href")
echo "remote_href : " $REMOTE_HREF
if [ -z "$REMOTE_HREF" ]; then exit; fi
# sync
TASK_URL=$(http POST $BASE_ADDR$CENTOS7_HREF'sync/' remote=$REMOTE_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
# wait for task
wait_until_task_finished $BASE_ADDR$TASK_URL
## find repo-version
#REPOVERSION_HREF=$(http $BASE_ADDR$TASK_URL| jq -r '.created_resources | first')
#echo "repoversion_href : " $REPOVERSION_HREF
#if [ -z "$REPOVERSION_HREF" ]; then exit; fi
## publish
#TASK_URL=$(http POST $BASE_ADDR/pulp/api/v3/publications/rpm/rpm/ repository=$CENTOS7_HREF | jq -r '.task')
#echo "Task url : " $TASK_URL
#if [ -z "$TASK_URL" ]; then exit; fi
#wait_until_task_finished $BASE_ADDR$TASK_URL
## find latest publication
#PUBLICATION_HREF=$(http $BASE_ADDR$TASK_URL| jq -r '.created_resources | first')
#echo "publication_href : " $PUBLICATION_HREF
#if [ -z "$PUBLICATION_HREF" ]; then exit; fi
## show it
#http $BASE_ADDR$PUBLICATION_HREF
#
## create exporter
#EXPORTER_NAME="test"
#EXPORTER_HREF=$(http POST $BASE_ADDR$EXPORTER_URL name="${EXPORTER_NAME}"-exporter repositories:=[\"${CENTOS7_HREF}\"] path=/tmp/exports/) #"
#if [ -z "$EXPORTER_HREF" ]; then exit; fi
#
## LIST all exporters
#http GET $BASE_ADDR$EXPORTER_URL
#
