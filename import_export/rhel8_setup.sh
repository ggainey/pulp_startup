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

RHEL8_BASE_URL="http://cdn.stage.redhat.com/content/dist/rhel8/8.2/x86_64/baseos/os/"
RHEL8_APPS_URL="http://cdn.stage.redhat.com/content/dist/rhel8/8.2/x86_64/appstream/os/"
RHEL8_NAME="rhel8"
RHEL8_BASE_NAME="rhel8-base"
RHEL8_APPS_NAME="rhel8-apps"

## FOR RHEL8-BASE
## create repos
RHEL8_BASE_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${RHEL8_BASE_NAME} | jq -r '.pulp_href')
echo "base_repo_href : " $RHEL8_BASE_HREF
if [ -z "$RHEL8_BASE_HREF" ]; then exit; fi
#
## add remote
http POST :/pulp/api/v3/remotes/rpm/rpm/ name=$RHEL8_BASE_NAME url=$RHEL8_BASE_URL  policy='on_demand'
## find remote's href
BASE_REMOTE_HREF=$(http :/pulp/api/v3/remotes/rpm/rpm/ | jq -r ".results[] | select(.name == \"${RHEL8_BASE_NAME}\") | .pulp_href")
echo "remote_href : " $BASE_REMOTE_HREF
if [ -z "$BASE_REMOTE_HREF" ]; then exit; fi
# sync
TASK_URL=$(http POST :$RHEL8_BASE_HREF'sync/' remote=$BASE_REMOTE_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
# wait for task
wait_until_task_finished :$TASK_URL
# find repo-version
REPOVERSION_HREF=$(http :$TASK_URL| jq -r '.created_resources | first')
echo "repoversion_href : " $REPOVERSION_HREF
if [ -z "$REPOVERSION_HREF" ]; then exit; fi
# publish
TASK_URL=$(http POST :/pulp/api/v3/publications/rpm/rpm/ repository=$RHEL8_BASE_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
wait_until_task_finished :$TASK_URL
# find latest publication
PUBLICATION_HREF=$(http :$TASK_URL| jq -r '.created_resources | first')
echo "publication_href : " $PUBLICATION_HREF
if [ -z "$PUBLICATION_HREF" ]; then exit; fi
# show it
http :$PUBLICATION_HREF

# APPSTREAM
RHEL8_APPS_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${RHEL8_APPS_NAME} | jq -r '.pulp_href')
echo "apps_repo_href : " $RHEL8_APPS_HREF
if [ -z "$RHEL8_APPS_HREF" ]; then exit; fi

# add remote
http POST :/pulp/api/v3/remotes/rpm/rpm/ name=$RHEL8_APPS_NAME url=$RHEL8_APPS_URL  policy='on_demand'
# find remote's href
APPS_REMOTE_HREF=$(http :/pulp/api/v3/remotes/rpm/rpm/ | jq -r ".results[] | select(.name == \"${RHEL8_APPS_NAME}\") | .pulp_href")
echo "remote_href : " $APPS_REMOTE_HREF
if [ -z "$APPS_REMOTE_HREF" ]; then exit; fi
# sync
TASK_URL=$(http POST :$RHEL8_APPS_HREF'sync/' remote=$APPS_REMOTE_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
# wait for task
wait_until_task_finished :$TASK_URL
# find repo-version
REPOVERSION_HREF=$(http :$TASK_URL| jq -r '.created_resources | first')
echo "repoversion_href : " $REPOVERSION_HREF
if [ -z "$REPOVERSION_HREF" ]; then exit; fi
# publish
TASK_URL=$(http POST :/pulp/api/v3/publications/rpm/rpm/ repository=$RHEL8_APPS_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
wait_until_task_finished :$TASK_URL
# find latest publication
PUBLICATION_HREF=$(http :$TASK_URL| jq -r '.created_resources | first')
echo "publication_href : " $PUBLICATION_HREF
if [ -z "$PUBLICATION_HREF" ]; then exit; fi
# show it
http :$PUBLICATION_HREF
