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
#for major in 30 ; do
for major in {29..31} ; do
  for variant in server updates ; do
    REPO_NAME="2-fedora-$major-$variant-x86_64"
    echo "repo_name : " $REPO_NAME
    if [ -z "$REPO_NAME" ]; then break 2; fi
    URL_PART=''
    [[ $variant = 'server' ]] && URL_PART=releases/$major/Server/x86_64/os/ || URL_PART=updates/$major/Everything/x86_64/
    echo "url_part : " $URL_PART
    if [ -z "$URL_PART" ]; then break 2; fi
    # create repo
    REPO_HREF=$(http POST $BASE_ADDR/pulp/api/v3/repositories/rpm/rpm/ name=$REPO_NAME | jq -r '.pulp_href')
    echo "repo_href : " $REPO_HREF
    if [ -z "$REPO_HREF" ]; then break 2; fi
    # add remote
    http POST $BASE_ADDR/pulp/api/v3/remotes/rpm/rpm/ name=$REPO_NAME url=https://mirrors.rit.edu/fedora/fedora/linux/$URL_PART  policy='on_demand'
    # find remote's href
    REMOTE_HREF=$(http $BASE_ADDR/pulp/api/v3/remotes/rpm/rpm/ | jq -r ".results[] | select(.name == \"${REPO_NAME}\") | .pulp_href")
    echo "remote_href : " $REMOTE_HREF
    if [ -z "$REMOTE_HREF" ]; then break 2; fi
    # sync
    TASK_URL=$(http POST $BASE_ADDR$REPO_HREF'sync/' remote=$REMOTE_HREF | jq -r '.task')
    echo "Task url : " $TASK_URL
    if [ -z "$TASK_URL" ]; then break 2; fi
    # wait for task
    wait_until_task_finished $BASE_ADDR$TASK_URL
    # find newest version of repo
    REPOVERSION_HREF=$(http $BASE_ADDR$TASK_URL| jq -r '.created_resources | first')
    echo "repoversion_href : " $REPOVERSION_HREF
    if [ -z "$REPOVERSION_HREF" ]; then break 2; fi
    # publish
    TASK_URL=$(http POST $BASE_ADDR/pulp/api/v3/publications/rpm/rpm/ repository=$REPO_HREF | jq -r '.task')
    echo "Task url : " $TASK_URL
    if [ -z "$TASK_URL" ]; then break 2; fi
    # wait for task
    wait_until_task_finished $BASE_ADDR$TASK_URL
    # find latest publication
    PUBLICATION_HREF=$(http $BASE_ADDR$TASK_URL| jq -r '.created_resources | first')
    echo "publication_href : " $PUBLICATION_HREF
    if [ -z "$PUBLICATION_HREF" ]; then break 2; fi
    # show it
    http $BASE_ADDR$PUBLICATION_HREF
  done
done
