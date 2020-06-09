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

ZOO_URL="https://fixtures.pulpproject.org/rpm/"
ZOO_NAME="zoo"
# FOR ZOO
# create repos
ZOO_HREF=$(http POST $BASE_ADDR/pulp/api/v3/repositories/rpm/rpm/ name=$ZOO_NAME | jq -r '.pulp_href')
echo "repo_href : " $ZOO_HREF
if [ -z "$ZOO_HREF" ]; then exit; fi
# add remote
http POST $BASE_ADDR/pulp/api/v3/remotes/rpm/rpm/ name=$ZOO_NAME url=$ZOO_URL  policy='immediate'
# find remote's href
REMOTE_HREF=$(http $BASE_ADDR/pulp/api/v3/remotes/rpm/rpm/ | jq -r ".results[] | select(.name == \"${ZOO_NAME}\") | .pulp_href")
echo "remote_href : " $REMOTE_HREF
if [ -z "$REMOTE_HREF" ]; then exit; fi
# sync
TASK_URL=$(http POST $BASE_ADDR$ZOO_HREF'sync/' remote=$REMOTE_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
# wait for task
wait_until_task_finished $BASE_ADDR$TASK_URL
# find repo-version
REPOVERSION_HREF=$(http $BASE_ADDR$TASK_URL| jq -r '.created_resources | first')
echo "repoversion_href : " $REPOVERSION_HREF
if [ -z "$REPOVERSION_HREF" ]; then exit; fi
# publish
TASK_URL=$(http POST $BASE_ADDR/pulp/api/v3/publications/rpm/rpm/ repository=$ZOO_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
wait_until_task_finished $BASE_ADDR$TASK_URL
# find latest publication
PUBLICATION_HREF=$(http $BASE_ADDR$TASK_URL| jq -r '.created_resources | first')
echo "publication_href : " $PUBLICATION_HREF
if [ -z "$PUBLICATION_HREF" ]; then exit; fi
# show it
http $BASE_ADDR$PUBLICATION_HREF

ISO_URL="https://fixtures.pulpproject.org/file/PULP_MANIFEST"
ISO_NAME="iso"
# FOR ISO
# create repo
ISO_HREF=$(http POST $BASE_ADDR/pulp/api/v3/repositories/file/file/ name=$ISO_NAME | jq -r '.pulp_href')
echo "repo_href : " $ISO_HREF
if [ -z "$ISO_HREF" ]; then exit; fi
# add remote
http POST $BASE_ADDR/pulp/api/v3/remotes/file/file/ name=$ISO_NAME url=$ISO_URL
# find remote's href
REMOTE_HREF=$(http $BASE_ADDR/pulp/api/v3/remotes/file/file/ | jq -r ".results[] | select(.name == \"${ISO_NAME}\") | .pulp_href")
echo "remote_href : " $REMOTE_HREF
if [ -z "$REMOTE_HREF" ]; then exit; fi
# sync
TASK_URL=$(http POST $BASE_ADDR$ISO_HREF'sync/' remote=$REMOTE_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
# wait for task
wait_until_task_finished $BASE_ADDR$TASK_URL
# find repo-version
REPOVERSION_HREF=$(http $BASE_ADDR$TASK_URL| jq -r '.created_resources | first')
echo "repoversion_href : " $REPOVERSION_HREF
if [ -z "$REPOVERSION_HREF" ]; then exit; fi
# publish
TASK_URL=$(http POST $BASE_ADDR/pulp/api/v3/publications/file/file/ repository=$ISO_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
wait_until_task_finished $BASE_ADDR$TASK_URL
# find latest publication
PUBLICATION_HREF=$(http $BASE_ADDR$TASK_URL| jq -r '.created_resources | first')
echo "publication_href : " $PUBLICATION_HREF
if [ -z "$PUBLICATION_HREF" ]; then exit; fi
# show it
http $BASE_ADDR$PUBLICATION_HREF

