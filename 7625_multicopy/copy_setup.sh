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

RHEL8_NAME="rhel8"
RHEL8_BASE_NAME="rhel8-base"
RHEL8_APPS_NAME="rhel8-apps"
ADVISORY="RHSA-2020:4059"

## create new repos
NEW_BASE_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${RHEL8_BASE_NAME}-new3 | jq -r '.pulp_href')
echo "${RHEL8_BASE_NAME}-new : " $NEW_BASE_HREF
if [ -z "$NEW_BASE_HREF" ]; then exit; fi
NEW_APPS_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${RHEL8_APPS_NAME}-new3 | jq -r '.pulp_href')
echo "${RHEL8_APPS_NAME}-new : " $NEW_APPS_HREF
if [ -z "$NEW_APPS_HREF" ]; then exit; fi

## find advisory-href
ADVISORY_HREF=$(http :/pulp/api/v3/content/rpm/advisories/?id=${ADVISORY} | jq -r '.results[] | .pulp_href')
echo "ADVISORY ${ADVISORY_HREF}"

