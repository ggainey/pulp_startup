#!/usr/bin/bash
echo ">>> Show USERS:"
echo "pulp user list | jq '.[] | .username'"
pulp user list | jq '.[] | .username'
#
echo ">>> Show DOMAINS:"
echo "pulp domain list | jq '.[] | {name, description}'"
pulp domain list | jq '.[] | {name, description, pulp_href}'
#
echo ">>> Show ROLES:"
for u in robert norm
do
    echo ">>> USER ${u}:"
    echo "pulp user role-assignment list --username ${u} | jq '.[] | .role, .domain'"
    pulp user role-assignment list --username ${u} | jq '.[] | {role, domain}'
done
#
echo ">>> Show REPOSITORIES:"
for d in $(pulp domain list | jq -r '.[] | .name')
do
    echo "pulp --domain ${d} repository list | jq '.[] | {name, pulp_href}'"
    pulp --domain "${d}" repository list | jq '.[] | {name, pulp_href}'
done
