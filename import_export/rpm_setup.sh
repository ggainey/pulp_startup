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
                echo "Task in final state: ${state}"
                exit 1
                ;;
            completed)
                echo "$task_url complete."
                break
                ;;
            *)
                #echo "Waiting..."
                echo -n "."
                sleep 1
                ;;
        esac
    done
    echo ""
}

#BASE_ADDR="admin:password@localhost:24817"
BASE_ADDR=":"

# RPM fixtures
#rpm-advisory-diff-repo
#rpm-advisory-diffpkgs
#rpm-advisory-no-update-date
#rpm-alt-layout
#rpm-invalid-rpm
#rpm-invalid-updateinfo
#rpm-kickstart
#rpm-long-updateinfo
#rpm-packages-updateinfo
#rpm-pkglists-updateinfo
#rpm-references-updateinfo
#rpm-richnweak-deps
#rpm-signed
#rpm-string-version-updateinfo
#rpm-unsigned
#rpm-unsigned-modified
#rpm-updated-updateinfo
#rpm-updated-updateversion
#rpm-with-modular
#rpm-with-modules
#rpm-with-modules-modified
#rpm-with-non-ascii
#rpm-with-non-utf-8
#rpm-with-pulp-distribution
#rpm-with-sha-1-modular
#rpm-with-sha-512
#rpm-with-vendor
#rpm-with-md5
#ZOO_URL="https://fixtures.pulpproject.org/rpm-with-modules/"
ZOO_URL="https://fixtures.pulpproject.org/rpm-with-md5/"
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
# Distribute it
TASK_URL=$(http POST $BASE_ADDR/pulp/api/v3/distributions/rpm/rpm/ name=$ZOO_NAME base_path=$ZOO_NAME publication=$PUBLICATION_HREF | jq -r '.task')
echo $TASK_URL
if [ -z "$TASK_URL" ]; then exit; fi
# wait for task
wait_until_task_finished $BASE_ADDR$TASK_URL
# find latest distribution
DISTRIBUTION_HREF=$(http $BASE_ADDR$TASK_URL | jq -r '.created_resources | first')
echo "distribution href : " $DISTRIBUTION_HREF
if [ -z "$DISTRIBUTION_HREF" ]; then exit; fi
# show it
http $BASE_ADDR$DISTRIBUTION_HREF
