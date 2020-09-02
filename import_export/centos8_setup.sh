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

#CENTOS8_BASE_URL="http://repo.miserver.it.umich.edu/centos/8-stream/BaseOS/x86_64/os/"
CENTOS8_BASE_URL="http://centos.mirror.rafal.ca/8.2.2004/BaseOS/x86_64/os/"
#CENTOS8_APPS_URL="http://repo.miserver.it.umich.edu/centos/8-stream/AppStream/x86_64/os/"
CENTOS8_APPS_URL="http://centos.mirror.rafal.ca/8.2.2004/AppStream/x86_64/os/"
CENTOS8_NAME="centos8"
CENTOS8_BASE_NAME="centos8-base"
CENTOS8_APPS_NAME="centos8-apps"

# FOR CENTOS8-BASE
# create repos
CENTOS8_BASE_HREF=$(http POST $BASE_ADDR/pulp/api/v3/repositories/rpm/rpm/ name=${CENTOS8_BASE_NAME} | jq -r '.pulp_href')
echo "base_repo_href : " $CENTOS8_BASE_HREF
if [ -z "$CENTOS8_BASE_HREF" ]; then exit; fi

# add remote
http POST $BASE_ADDR/pulp/api/v3/remotes/rpm/rpm/ name=$CENTOS8_BASE_NAME url=$CENTOS8_BASE_URL  policy='immediate'
# find remote's href
BASE_REMOTE_HREF=$(http $BASE_ADDR/pulp/api/v3/remotes/rpm/rpm/ | jq -r ".results[] | select(.name == \"${CENTOS8_BASE_NAME}\") | .pulp_href")
echo "remote_href : " $BASE_REMOTE_HREF
if [ -z "$BASE_REMOTE_HREF" ]; then exit; fi
# sync
TASK_URL=$(http POST $BASE_ADDR$CENTOS8_BASE_HREF'sync/' remote=$BASE_REMOTE_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
# wait for task
wait_until_task_finished $BASE_ADDR$TASK_URL
# find repo-version
REPOVERSION_HREF=$(http $BASE_ADDR$TASK_URL| jq -r '.created_resources | first')
echo "repoversion_href : " $REPOVERSION_HREF
if [ -z "$REPOVERSION_HREF" ]; then exit; fi
# publish
TASK_URL=$(http POST $BASE_ADDR/pulp/api/v3/publications/rpm/rpm/ repository=$CENTOS8_BASE_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
wait_until_task_finished $BASE_ADDR$TASK_URL
# find latest publication
PUBLICATION_HREF=$(http $BASE_ADDR$TASK_URL| jq -r '.created_resources | first')
echo "publication_href : " $PUBLICATION_HREF
if [ -z "$PUBLICATION_HREF" ]; then exit; fi
# show it
http $BASE_ADDR$PUBLICATION_HREF

# APPSTREAM
CENTOS8_APPS_HREF=$(http POST $BASE_ADDR/pulp/api/v3/repositories/rpm/rpm/ name=${CENTOS8_APPS_NAME} | jq -r '.pulp_href')
echo "apps_repo_href : " $CENTOS8_APPS_HREF
if [ -z "$CENTOS8_APPS_HREF" ]; then exit; fi

# add remote
http POST $BASE_ADDR/pulp/api/v3/remotes/rpm/rpm/ name=$CENTOS8_APPS_NAME url=$CENTOS8_APPS_URL  policy='immediate'
# find remote's href
APPS_REMOTE_HREF=$(http $BASE_ADDR/pulp/api/v3/remotes/rpm/rpm/ | jq -r ".results[] | select(.name == \"${CENTOS8_APPS_NAME}\") | .pulp_href")
echo "remote_href : " $APPS_REMOTE_HREF
if [ -z "$APPS_REMOTE_HREF" ]; then exit; fi
# sync
TASK_URL=$(http POST $BASE_ADDR$CENTOS8_APPS_HREF'sync/' remote=$APPS_REMOTE_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
# wait for task
wait_until_task_finished $BASE_ADDR$TASK_URL
# find repo-version
REPOVERSION_HREF=$(http $BASE_ADDR$TASK_URL| jq -r '.created_resources | first')
echo "repoversion_href : " $REPOVERSION_HREF
if [ -z "$REPOVERSION_HREF" ]; then exit; fi
# publish
TASK_URL=$(http POST $BASE_ADDR/pulp/api/v3/publications/rpm/rpm/ repository=$CENTOS8_APPS_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
wait_until_task_finished $BASE_ADDR$TASK_URL
# find latest publication
PUBLICATION_HREF=$(http $BASE_ADDR$TASK_URL| jq -r '.created_resources | first')
echo "publication_href : " $PUBLICATION_HREF
if [ -z "$PUBLICATION_HREF" ]; then exit; fi
# show it
http $BASE_ADDR$PUBLICATION_HREF
