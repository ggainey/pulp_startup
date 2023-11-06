#!/usr/bin/bash
# Create rpm-repo default in 'default', as admin-user
echo ">>> Create default Remote"
pulp rpm remote create \
    --name ${DEFAULT_REPO} \
    --url https://fixtures.pulpproject.org/rpm-signed/ \
    --policy on_demand
echo ">>> Create default Repository"
pulp rpm repository create --name ${DEFAULT_REPO} --remote ${DEFAULT_REPO} --autopublish
echo ">>> Sync default Repository"
pulp rpm repository sync --name ${DEFAULT_REPO}
# Create user robert
echo ">>> Create user 'robert'"
pulp user create --username robert --password ${ROBERT_PWD}
# Create user norm
echo ">>> Create user 'norm'"
pulp user create --username norm --password ${NORM_PWD}
# Create domain
echo ">>> Create Domain ${PRIVATE_DOMAIN}"
pulp domain create \
    --name ${PRIVATE_DOMAIN} \
    --description "robert's domain" \
    --storage-class pulpcore.app.models.storage.FileSystem \
    --storage-settings "{\"MEDIA_ROOT\": \"/var/lib/pulp/media/\"}"
# Give robert rpm-admin perms in 'private'
echo ">>> Give 'robert' rpm.admin in ${PRIVATE_DOMAIN}"
pulp user role-assignment add --username robert --role "rpm.admin" \
    --domain ${PRIVATE_DOMAIN}
# show role-assignments for robert and norm
echo ">>> Role Assignments:"
for u in robert norm
do
    echo "USER ${u}:"
    pulp user role-assignment list --username ${u} | jq '.[] | .role, .domain'
done
