#!/usr/bin/bash -v
U1_PWD="i234567!"
# Create rpm-repo R-default in 'default', as admin-user
pulp --domain default rpm repository create --name "R-default"
# Save R-default href
R_DEFAULT_HREF=$(pulp rpm repository show --name "R-default" | jq -r .pulp_href)
# Create user U1
pulp user create --username U1 --password ${U1_PWD}
#  Show their "global" RBAC permissions
pulp user role-assignment list --username U1
# Show they CANNOT see R-default
pulp --username U1 --password ${U1_PWD} rpm repository show --name "R-default"
# Give them perms to view rpm-repos
pulp user role-assignment add --username U1 --role "rpm.viewer" --domain "default"
# Show U1 CAN see repo R-default
pulp --username U1 --password ${U1_PWD} rpm repository show --name "R-default"
# Create domains D1
pulp domain create --name D1 --description D1 --storage-class pulpcore.app.models.storage.FileSystem --storage-settings "{\"MEDIA_ROOT\": \"/var/lib/pulp/media/\"}"
# Give U1 rpm-perms in D1
pulp user role-assignment add --username U1 --role "rpm.admin" --domain D1
# Show U1 create R-D1, remote-D1, sync R-D1
pulp --username U1 --password ${U1_PWD} --domain D1 rpm remote create --name "R-D1" --url https://fixtures.pulpproject.org/rpm-signed/
# Save R-D1 remote href
R_D1_REMOTE_HREF=$(pulp --username U1 --password ${U1_PWD} --domain D1 rpm remote show --name "R-D1" | jq -r .pulp_href)
pulp --username U1 --password ${U1_PWD} --domain D1 rpm repository create --name "R-D1" --remote "R-D1"
pulp --username U1 --password ${U1_PWD} --domain D1 rpm repository sync --name "R-D1"
pulp --username U1 --password ${U1_PWD} --domain D1 rpm repository show --name "R-D1"
# Show U1 cannot sync using R-default repo, due to lack of sync-permissions on that repo
pulp --username U1 --password ${U1_PWD} rpm repository sync --repository ${R_DEFAULT_HREF} --remote ${R_D1_REMOTE_HREF}
# Show admin CAN see repo R-D1
pulp --domain D1 rpm repository show --name "R-D1"
# Show admin cannot combine repo R-default and remote R-D1
pulp --domain D1 rpm repository sync --repository ${R_DEFAULT_HREF} --remote ${R_D1_REMOTE_HREF}
# Show that a repo named R-default CAN be created in domain D1
pulp --domain D1 rpm repository create --name "R-default"
# Show repos in D1
pulp --domain D1 repository list | jq '.[] | .name'
# Show repos in (explicit) default-domain
pulp --domain default repository list | jq '.[] | .name'
# Show repos in (implicit) default-domain
pulp repository list | jq '.[] | .name'
