REMOTES=(\
"https://cdn.redhat.com/content/dist/rhel/server/6/6.1/x86_64/os"
)

NAMES=(\
"cdn_redhat_com_content_dist_rhel_server_6_6_1_x86_64"
)
pulp-admin login -u admin -p admin
for r in ${!REMOTES[@]}; do
  echo ">>>>> " TESTING [${REMOTES[$r]}] INTO [${NAMES[$r]}];
  if  [[ ${NAMES[$r]} == cdn* ]] ; then
    pulp-admin rpm repo create --repo-id ${NAMES[$r]} --feed ${REMOTES[$r]} \
        --download-policy on_demand \
        --generate-sqlite false --repoview false \
        --feed-ca-cert /home/vagrant/devel/pulp_startup/CDN_cert/redhat-uep.pem \
        --feed-cert /home/vagrant/devel/pulp_startup/CDN_cert/cdn.crt \
        --feed-key /home/vagrant/devel/pulp_startup/CDN_cert/cdn.key
  else
    pulp-admin rpm repo create --repo-id ${NAMES[$r]} --feed ${REMOTES[$r]} \
        --download-policy on_demand
  fi
  pulp-admin rpm repo sync run --repo-id ${NAMES[$r]}
done
