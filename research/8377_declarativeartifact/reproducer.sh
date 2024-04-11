pulp-admin login -u admin -p admin
pulp-admin rpm repo create --repo-id c8 --feed http://mirror.centos.org/centos/8/BaseOS/x86_64/os/ --download-policy immediate
pulp-admin rpm repo create --repo-id c8_apps_ks --feed http://mirror.centos.org/centos/8/AppStream/x86_64/kickstart/ --download-policy immediate
pulp-admin rpm repo sync run --repo-id c8
pulp-admin rpm repo sync run --repo-id c8_apps_ks

#
pulp migration plan create --plan '{"plugins": [{"type": "rpm"}]}'
pulp migration plan run --href /pulp/api/v3/migration-plans/bacd32cc-0730-4c3f-9ade-3a898162c712/
http :/pulp/api/v3/tasks/5768923c-dbfb-4f2f-8ba9-753b718ef965/


