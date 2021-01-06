#!/bin/bash

# Poll a Pulp task until it is finished.
wait_until_task_finished() {
    echo "Polling the task until it has reached a final state."
    local task_url=$1
    while true
    do
        local response=$(http $task_url)
        local state=$(jq -r .state <<< ${response})
        #jq . <<< "${response}"
        case ${state} in
            failed|canceled)
                echo
                echo "Task in final state: ${state}"
                exit 1
                ;;
            completed)
                echo
                echo "$task_url complete."
                break
                ;;
            *)
                echo -n "."
                sleep 5
                ;;
        esac
    done
}

RHEL8_BASE_URL="https://cdn.redhat.com/content/dist/rhel8/8/x86_64/baseos/os/"
RHEL8_APPS_URL="https://cdn.redhat.com/content/dist/rhel8/8/x86_64/appstream/os/"
RHEL8_NAME="rhel8"
RHEL8_BASE_NAME="rhel8-base"
RHEL8_APPS_NAME="rhel8-apps"
CREATE_SOURCES=

if [ $CREATE_SOURCES ]; then
    echo ">>> CREATE SOURCES!"
    ## create repos
    #
    #
    # BASEOS
    #
    RHEL8_BASE_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${RHEL8_BASE_NAME} | jq -r '.pulp_href')
    echo "base_repo_href : " $RHEL8_BASE_HREF
    if [ -z "$RHEL8_BASE_HREF" ]; then exit; fi
    #
    # add remote
    BASE_REMOTE_HREF=$(http POST :/pulp/api/v3/remotes/rpm/rpm/ name=$RHEL8_BASE_NAME url=$RHEL8_BASE_URL  policy='immediate' client_cert=@/home/vagrant/devel/pulp_startup/CDN_cert/cdn.crt client_key=@/home/vagrant/devel/pulp_startup/CDN_cert/cdn.key ca_cert=@/home/vagrant/devel/pulp_startup/CDN_cert/redhat-uep.pem | jq -r '.pulp_href')
    echo "remote_href : " $BASE_REMOTE_HREF
    if [ -z "$BASE_REMOTE_HREF" ]; then exit; fi
    #
    # sync
    TASK_URL=$(http POST :$RHEL8_BASE_HREF'sync/' remote=$BASE_REMOTE_HREF | jq -r '.task')
    echo "Task url : " $TASK_URL
    if [ -z "$TASK_URL" ]; then exit; fi
    #
    # wait for task
    wait_until_task_finished :$TASK_URL
    #
    # find repo-version
    BASE_REPOVERSION_HREF=$(http :$TASK_URL| jq -r '.created_resources | first')
    echo "base-repoversion_href : " $BASE_REPOVERSION_HREF
    if [ -z "$BASE_REPOVERSION_HREF" ]; then exit; fi
    #
    #
    # APPSTREAM
    #
    RHEL8_APPS_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${RHEL8_APPS_NAME} | jq -r '.pulp_href')
    echo "apps_repo_href : " $RHEL8_APPS_HREF
    if [ -z "$RHEL8_APPS_HREF" ]; then exit; fi
    #
    # add remote
    APPS_REMOTE_HREF=$(http POST :/pulp/api/v3/remotes/rpm/rpm/ name=$RHEL8_APPS_NAME url=$RHEL8_APPS_URL  policy='on_demand' client_cert=@/home/vagrant/devel/pulp_startup/CDN_cert/cdn.crt client_key=@/home/vagrant/devel/pulp_startup/CDN_cert/cdn.key ca_cert=@/home/vagrant/devel/pulp_startup/CDN_cert/redhat-uep.pem | jq -r '.pulp_href')
    echo "remote_href : " $APPS_REMOTE_HREF
    if [ -z "$APPS_REMOTE_HREF" ]; then exit; fi
    #
    # sync
    TASK_URL=$(http POST :$RHEL8_APPS_HREF'sync/' remote=$APPS_REMOTE_HREF | jq -r '.task')
    echo "Task url : " $TASK_URL
    if [ -z "$TASK_URL" ]; then exit; fi
    #
    # wait for task
    wait_until_task_finished :$TASK_URL
    #
    # find repo-version
    APPS_REPOVERSION_HREF=$(http :$TASK_URL| jq -r '.created_resources | first')
    echo "apps-repoversion_href : " $APPS_REPOVERSION_HREF
    if [ -z "$APPS_REPOVERSION_HREF" ]; then exit; fi
fi

ADVISORY="RHSA-2020:4059"

## create new repos
NEW_BASE_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${RHEL8_BASE_NAME}-new-3 | jq -r '.pulp_href')
echo "${RHEL8_BASE_NAME}-new : " $NEW_BASE_HREF
if [ -z "$NEW_BASE_HREF" ]; then exit; fi
NEW_APPS_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${RHEL8_APPS_NAME}-new-3 | jq -r '.pulp_href')
echo "${RHEL8_APPS_NAME}-new : " $NEW_APPS_HREF
if [ -z "$NEW_APPS_HREF" ]; then exit; fi

## find advisory-href
ADVISORY_HREF=$(http :/pulp/api/v3/content/rpm/advisories/?id=${ADVISORY} | jq -r '.results[] | .pulp_href')
echo "ADVISORY ${ADVISORY_HREF}"
