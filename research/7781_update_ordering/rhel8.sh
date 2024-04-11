REMOTES=(\
https://cdn.redhat.com/content/dist/rhel8/8/x86_64/appstream/os \
https://cdn.redhat.com/content/dist/rhel8/8/x86_64/baseos/os \
https://cdn.redhat.com/content/dist/rhel8/8/x86_64/supplementary/os \
)

NAMES=(\
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
