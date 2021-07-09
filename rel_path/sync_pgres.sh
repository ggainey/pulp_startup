#!/bin/bash
VERSIONS=(9.5 9.6 10 11 12 13)
RHEL_VARIANTS=(rhel-6 rhel-6Server rhel-7 rhel-7Server rhel-7Client rhel-7Workstation rhel-8)
ARCHS=(x86_64)

for v in ${VERSIONS[@]}; do
    for r in ${RHEL_VARIANTS[@]}; do
        for a in ${ARCHS[@]}; do
            URL="https://download.postgresql.org/pub/repos/yum/${v}/redhat/${r}-${a}/"
            NAME="${v}-${r}-${a}"
            echo "$NAME : $URL"
            pulp rpm remote create --name ${NAME} --url ${URL} --policy on_demand | jq -r .pulp_href
            pulp rpm repository create --name ${NAME} --remote ${NAME} --autopublish | jq -r .pulp_href
            pulp -b rpm repository sync --name ${NAME}
        done
    done
done
