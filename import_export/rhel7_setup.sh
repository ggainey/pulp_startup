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

RHEL7_URL="http://cdn.stage.redhat.com/content/dist/rhel/server/7/7Server/x86_64/os/"
RHEL7_NAME="rhel7"
# FOR RHEL7
# create repos
RHEL7_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=$RHEL7_NAME | jq -r '.pulp_href')
echo "repo_href : " $RHEL7_HREF
if [ -z "$RHEL7_HREF" ]; then exit; fi
 add remote
http POST :/pulp/api/v3/remotes/rpm/rpm/ name=$RHEL7_NAME url=$RHEL7_URL  policy='immediate'
# find remote's href
REMOTE_HREF=$(http :/pulp/api/v3/remotes/rpm/rpm/ | jq -r ".results[] | select(.name == \"${RHEL7_NAME}\") | .pulp_href")
echo "remote_href : " $REMOTE_HREF
if [ -z "$REMOTE_HREF" ]; then exit; fi
# sync
TASK_URL=$(http POST :$RHEL7_HREF'sync/' remote=$REMOTE_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
# wait for task
wait_until_task_finished :$TASK_URL
# find repo-version
REPOVERSION_HREF=$(http :$TASK_URL| jq -r '.created_resources | first')
echo "repoversion_href : " $REPOVERSION_HREF
if [ -z "$REPOVERSION_HREF" ]; then exit; fi
# publish
TASK_URL=$(http POST :/pulp/api/v3/publications/rpm/rpm/ repository=$RHEL7_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
wait_until_task_finished :$TASK_URL
# find latest publication
PUBLICATION_HREF=$(http :$TASK_URL| jq -r '.created_resources | first')
echo "publication_href : " $PUBLICATION_HREF
if [ -z "$PUBLICATION_HREF" ]; then exit; fi
# show it
http :$PUBLICATION_HREF

# create exporter
EXPORTER_NAME="test"
EXPORTER_HREF=$(http POST :$EXPORTER_URL name="${EXPORTER_NAME}"-exporter repositories:=[\"${RHEL7_HREF}\"] path=/tmp/exports/) #"
if [ -z "$EXPORTER_HREF" ]; then exit; fi

# LIST all exporters
http GET :$EXPORTER_URL

