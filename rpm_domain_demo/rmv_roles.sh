# Remove all rpm-perms from U1 in 'D1'
U1_PWD="i234567!"
pulp user role-assignment remove --username U1 --role "rpm.admin" --domain "D1" --object ""
pulp user role-assignment remove --username U1 --role "rpm.viewer" --domain "D1" --object ""
# Show U1 *cannot* see R-D1
pulp --username U1 --password ${U1_PWD} rpm repository show --name "R-D1"
