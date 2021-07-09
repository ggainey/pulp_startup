REMOTES=(\
https://cdn.redhat.com/content/dist/rhel8/8/x86_64/baseos/kickstart \
https://cdn.redhat.com/content/dist/rhel8/8/x86_64/appstream/kickstart \
)

NAMES=(\
cdn.redhat.com_content_dist_rhel8_8_x86_64_baseos_kickstart \
cdn.redhat.com_content_dist_rhel8_8_x86_64_appstream_kickstart \
)

for r in ${!REMOTES[@]}; do
  echo ">>>>> " TESTING [${REMOTES[$r]}] INTO [${NAMES[$r]}];
  # create repo
  REPO_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${NAMES[$r]} | jq -r '.pulp_href')
  echo "repo_href : " $REPO_HREF
  if [ -z "$REPO_HREF" ]; then echo ">>>>> " FAILED REPO; continue; fi

  # create remote
  REMOTE_HREF=$(http POST :/pulp/api/v3/remotes/rpm/rpm/ name=${NAMES[$r]} url=${REMOTES[$r]} policy='immediate' download_concurrency=10 client_cert=@/home/vagrant/devel/pulp_startup/CDN_cert/cdn.crt client_key=@/home/vagrant/devel/pulp_startup/CDN_cert/cdn.key ca_cert=@/home/vagrant/devel/pulp_startup/CDN_cert/redhat-uep.pem | jq -r '.pulp_href')
  echo "remote_href : " $REMOTE_HREF
  if [ -z "$REMOTE_HREF" ]; then echo "FAILED REMOTE"; continue; fi

  # sync repo using that remote
  TASK_URL=$(http POST :$REPO_HREF'sync/' remote=$REMOTE_HREF | jq -r '.task')
  echo "Task url : " $TASK_URL
  if [ -z "$TASK_URL" ]; then echo "FAILED TASK"; continue; fi
  echo ""
done


