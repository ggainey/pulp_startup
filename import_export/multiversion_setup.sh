#!/bin/bash

# Poll a Pulp task until it is finished.
wait_until_task_finished() {
    echo "Polling the task until it has reached a final state."
    local task_url=$1
    while true
    do
        local response=$(http $task_url)
        local state=$(jq -r .state <<< ${response})
        # jq . <<< "${response}"
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
                #echo "Still waiting..."
                echo -n "."
                sleep 1
                ;;
        esac
    done
}

ISO_URL="https://fixtures.pulpproject.org/file/PULP_MANIFEST"
EXPORTER_URL="/pulp/api/v3/exporters/core/pulp/"

ISO_NAME="iso-multi-7"
COPY_NAME="${ISO_NAME}-copy"

# FOR ISO
# create two repos, one to sync and one to copy to
ISO_HREF=$(http POST :/pulp/api/v3/repositories/file/file/ name=$ISO_NAME | jq -r '.pulp_href')
if [ -z "$ISO_HREF" ]; then exit; fi
COPY_HREF=$(http POST :/pulp/api/v3/repositories/file/file/ name=${COPY_NAME} | jq -r '.pulp_href')
if [ -z "$COPY_HREF" ]; then exit; fi
echo "COPY_HREF " $COPY_HREF

# add remote
http POST :/pulp/api/v3/remotes/file/file/ name=$ISO_NAME url=$ISO_URL
# find remote's href
REMOTE_HREF=$(http :/pulp/api/v3/remotes/file/file/ | jq -r ".results[] | select(.name == \"${ISO_NAME}\") | .pulp_href")
if [ -z "$REMOTE_HREF" ]; then exit; fi
# sync
TASK_URL=$(http POST :$ISO_HREF'sync/' remote=$REMOTE_HREF | jq -r '.task')
if [ -z "$TASK_URL" ]; then exit; fi
# wait for task
wait_until_task_finished :$TASK_URL

# find file content
FILES=$(http GET :/pulp/api/v3/content/file/files/ | jq -r '.results[] | .pulp_href')
echo "FILES $FILES"
# loop over content, modify -copy by adding content-unit
for f in $FILES
do
    echo "...FILE " $f
    RESULT=$(http POST :$COPY_HREF'modify/' add_content_units:=[\"${f}\"]) #"
    TASK_URL=$(echo $RESULT | jq -r '.task')
    if [ -z "$TASK_URL" ]; then exit; fi
    wait_until_task_finished :$TASK_URL
done

# create an exporter for COPY
RESULT=$(http POST :$EXPORTER_URL name="${COPY_NAME}-exporter" repositories:=[\"${COPY_HREF}\"] path=/tmp/exports/) #"
echo "CREATE EXPORTER RESULT " $RESULT
EXPORTER_HREF=$(echo $RESULT | jq -r '.pulp_href')
echo "EXPORTER " $EXPORTER_HREF
if [ -z "$EXPORTER_HREF" ]; then exit; fi

# export diff-1-to-2
RESULT=$(http POST :$EXPORTER_HREF'exports/' start_versions:=[\"${COPY_HREF}versions/1/\"] versions:=[\"${COPY_HREF}versions/2/\"] full=False) #"
TASK_URL=$(echo $RESULT | jq -r '.task')
if [ -z "$TASK_URL" ]; then exit; fi
wait_until_task_finished :$TASK_URL
sleep 1
exit

# export diff-1-to-1
RESULT=$(http POST :$EXPORTER_HREF'exports/' start_versions:=[\"${COPY_HREF}versions/1/\"] versions:=[\"${COPY_HREF}versions/1/\"] full=False) #"
TASK_URL=$(echo $RESULT | jq -r '.task')
if [ -z "$TASK_URL" ]; then exit; fi
wait_until_task_finished :$TASK_URL
sleep 1

# export-full-latest
TASK_URL=$(http POST :$EXPORTER_HREF'exports/' | jq -r '.task')
if [ -z "$TASK_URL" ]; then exit; fi
wait_until_task_finished :$TASK_URL
sleep 1

# export diff-1-to-latest
RESULT=$(http POST :$EXPORTER_HREF'exports/' start_versions:=[\"${COPY_HREF}versions/1/\"] full=False) #"
TASK_URL=$(echo $RESULT | jq -r '.task')
if [ -z "$TASK_URL" ]; then exit; fi
wait_until_task_finished :$TASK_URL
sleep 1


