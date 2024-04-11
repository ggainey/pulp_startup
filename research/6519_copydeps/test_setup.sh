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
SRC_URL="https://jlsherrill.fedorapeople.org/fake-repos/needed-errata/"
SRC_NAME="src-4"
DST_NAME="dst-4"
# create repos
SRC_HREF=$(http POST $BASE_ADDR/pulp/api/v3/repositories/rpm/rpm/ name=$SRC_NAME | jq -r '.pulp_href')
echo "src repo_href : " $SRC_HREF
if [ -z "$SRC_HREF" ]; then exit; fi
DST_HREF=$(http POST $BASE_ADDR/pulp/api/v3/repositories/rpm/rpm/ name=$DST_NAME | jq -r '.pulp_href')
echo "dst repo_href : " $DST_HREF
if [ -z "$DST_HREF" ]; then exit; fi

# add src-remote
http POST $BASE_ADDR/pulp/api/v3/remotes/rpm/rpm/ name=$SRC_NAME url=$SRC_URL  policy='immediate'
# find remote's href
REMOTE_HREF=$(http $BASE_ADDR/pulp/api/v3/remotes/rpm/rpm/ | jq -r ".results[] | select(.name == \"${SRC_NAME}\") | .pulp_href")
echo "remote_href : " $REMOTE_HREF
if [ -z "$REMOTE_HREF" ]; then exit; fi
# sync
TASK_URL=$(http POST $BASE_ADDR$SRC_HREF'sync/' remote=$REMOTE_HREF | jq -r '.task')
echo "Task url : " $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
# wait for task
wait_until_task_finished $BASE_ADDR$TASK_URL
# show src-repo-version, dst-repo, and src-repo-packages
SRC_REPOVERSION_HREF=$(http $BASE_ADDR$TASK_URL| jq -r '.created_resources | first')
echo "src-repo-version_href : " $SRC_REPOVERSION_HREF
if [ -z "$SRC_REPOVERSION_HREF" ]; then exit; fi
echo "dst repo_href : " $DST_HREF

PACKAGES=$(http $BASE_ADDR/pulp/api/v3/content/rpm/packages/?repository_version=$SRC_REPOVERSION_HREF | jq -r ".results[] | .pulp_href")
echo "PACKAGES : \n"
echo $PACKAGES
ADVISORIES=$(http $BASE_ADDR/pulp/api/v3/content/rpm/advisories/?repository_version=$SRC_REPOVERSION_HREF | jq -r ".results[] | .pulp_href")
echo "ADVISORIES : \n"
echo $ADVISORIES
