REMOTES=(\
https://cdn.redhat.com/content/dist/rhel/server/6/6Server/x86_64/extras/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6Server/x86_64/optional/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6Server/x86_64/supplementary/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/extras/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/optional/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6Server/x86_64/rhscl/1/os \
https://cdn.redhat.com/content/dist/rhel8/8/x86_64/appstream/os \
https://cdn.redhat.com/content/dist/rhel8/8/x86_64/baseos/os \
https://cdn.redhat.com/content/dist/rhel8/8/x86_64/supplementary/os \
)

NAMES=(\
cdn.redhat.com_content_dist_rhel_server_6_6Server_x86_64_extras_os \
cdn.redhat.com_content_dist_rhel_server_6_6Server_x86_64_optional_os \
cdn.redhat.com_content_dist_rhel_server_6_6Server_x86_64_supplementary_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_extras_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_optional_os \
cdn.redhat.com_content_dist_rhel_server_6_6Server_x86_64_rhscl_1_os \
cdn.redhat.com_content_dist_rhel8_8_x86_64_appstream_os \
cdn.redhat.com_content_dist_rhel8_8_x86_64_baseos_os \
cdn.redhat.com_content_dist_rhel8_8_x86_64_supplementary_os \
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
