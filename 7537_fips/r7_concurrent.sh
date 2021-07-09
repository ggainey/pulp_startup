wait_until_task_finished() {
    echo "Polling the task until it has reached a final state."
    local task_url=$1
    while true
    do
        local response=$(http $task_url)
        local state=$(jq -r .state <<< ${response})
        local started=$(jq -r .started_at <<< ${response})
        local finished=$(jq -r .finished_at <<< ${response})
        #jq . <<< "${response}"
        #echo "State: [${state}] Start: [${started}] Finish: [${finished}]"
        case ${state} in
            failed|canceled)
                echo "Task in final state: ${state}"
                break
                ;;
            completed)
                echo "$task_url complete."
                echo "State: [${state}] Start: [${started}] Finish: [${finished}]"
                break
                ;;
            *)
                echo -n "."
                sleep 5
                ;;
        esac
    done
}

REMOTES=(\
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/extras/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/optional/os \
)

NAMES=(\
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_extras_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_optional_os \
)

for r in ${!REMOTES[@]}; do
  echo ">>>>> " TESTING [${REMOTES[$r]}] INTO [${NAMES[$r]}];
  # create repo
  REPO_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${NAMES[$r]} | jq -r '.pulp_href')
  echo "repo_href : " $REPO_HREF
  if [ -z "$REPO_HREF" ]; then echo ">>>>> " FAILED REPO; continue; fi

  # create remote
  if  [[ ${NAMES[$r]} == cdn* ]] ; then
    REMOTE_HREF=$(http POST :/pulp/api/v3/remotes/rpm/rpm/ name=${NAMES[$r]} url=${REMOTES[$r]} policy='on_demand' download_concurrency=10 client_cert=@/home/vagrant/devel/pulp_startup/CDN_cert/cdn.crt client_key=@/home/vagrant/devel/pulp_startup/CDN_cert/cdn.key ca_cert=@/home/vagrant/devel/pulp_startup/CDN_cert/redhat-uep.pem | jq -r '.pulp_href')
  else
    REMOTE_HREF=$(http POST :/pulp/api/v3/remotes/rpm/rpm/ name=${NAMES[$r]} url=${REMOTES[$r]}  policy='on_demand' download_concurrency=10 | jq -r '.pulp_href')
  fi
  ###REMOTE_HREF=$(http :/pulp/api/v3/remotes/rpm/rpm/ | jq -r ".results[] | select(.name == \"${NAMES[$r]}\") | .pulp_href")
  echo "remote_href : " $REMOTE_HREF
  if [ -z "$REMOTE_HREF" ]; then echo FAILED REMOTE; continue; fi

  # sync repo using that remote
  TASK_URL=$(http POST :$REPO_HREF'sync/' remote=$REMOTE_HREF | jq -r '.task')
  echo "Task url : " $TASK_URL
  if [ -z "$TASK_URL" ]; then FAILED TASK; continue; fi
  #wait_until_task_finished :$TASK_URL

  # create a distribution for that repo

  # publish the repo
  echo ""
done


