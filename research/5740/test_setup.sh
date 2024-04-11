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

NAMES=("A0" "B0" "DEST0")
URLS=("http://localhost:8000/rpm-updated-updateversion/" "http://localhost:8000/rpm-advisory-diffpkgs/")
REPO_HREFS=()
REMOTE_HREFS=()

for i in ${!NAMES[@]}; do
  echo "NAMES[$i] : " ${NAMES[$i]}
  # create repos
  echo "http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${NAMES[$i]}| jq -r '.pulp_href'"
  REPO_HREFS[$i]=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${NAMES[$i]}| jq -r '.pulp_href')
  echo "repo_href : " ${REPO_HREFS[$i]}
  if [ -z "${REPO_HREFS[$i]}" ]; then exit; fi
  if [[ ${i} -eq 2 ]]; then break; fi
  # add remote
  echo "http POST :/pulp/api/v3/remotes/rpm/rpm/ name=${NAMES[$i]} url=${URLS[$i]}  policy='immediate'"
  http POST :/pulp/api/v3/remotes/rpm/rpm/ name=${NAMES[$i]} url=${URLS[$i]}  policy='immediate'
  # find remote's href
  REMOTE_HREFS[$i]=$(http :/pulp/api/v3/remotes/rpm/rpm/ | jq -r ".results[] | select(.name == \"${NAMES[$i]}\") | .pulp_href")
  echo "remote_href : " ${REMOTE_HREFS[$i]}; if [ -z "${REMOTE_HREFS[$i]}" ]; then exit; fi
  # sync
  TASK_URL=$(http POST :${REPO_HREFS[$i]}'sync/' remote=${REMOTE_HREFS[$i]} | jq -r '.task')
  echo "Task url : " $TASK_URL; if [ -z "$TASK_URL" ]; then exit; fi
  wait_until_task_finished :$TASK_URL
done

echo "REPO_HREFS   = " ${REPO_HREFS[@]}
echo "REMOTE_HREFS = " ${REMOTE_HREFS[@]}

# copy A and B into DEST
echo "http POST :/pulp/api/v3/rpm/copy/ config:=[{\"source_repo_version\": \"${REPO_HREFS[0]}\" , \"dest_repo\": \"${REPO_HREFS[2]}\"}, {\"source_repo_version\": \"${REPO_HREFS[1]}\" , \"dest_repo\": \"${REPO_HREFS[2]}\"}] dependency_solving=False"
http POST :/pulp/api/v3/rpm/copy/ config:=[{"source_repo_version": \"${REPO_HREFS[0]}\" , "dest_repo": \"${REPO_HREFS[2]}\" }, {"source_repo_version": \"${REPO_HREFS[1]}\" , "dest_repo": \"${REPO_HREFS[2]}\" }] dependency_solving=False
