#!/bin/bash
# https://cdn.redhat.com/content/dist/rhel8/8/x86_64/appstream/os \
REPOS=( \
https://cdn.redhat.com/content/eus/rhel/server/7/7.7/x86_64/os \
)
#http://ftp.cs.stanford.edu/centos/7/opstools/x86_64/ \
#http://mirror.siena.edu/fedora/linux/updates/34/Everything/x86_64/ \
#http://yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64 \

# rhel8apps \
NAMES=( \
rhel77_eus \
)
#centosopstools \
#f34-all \
#ol7 \

for n in ${!NAMES[@]}
do
    pulp rpm repository destroy --name ${NAMES[$n]}
    pulp rpm remote destroy --name ${NAMES[$n]}
done
pulp orphan cleanup

starting_failed=`pulp task list --state failed | jq length`
for n in ${!NAMES[@]}
do
    echo "${NAMES[$n]}..."
    if [ ${n} -eq 0 ]
    then
        pulp rpm remote create --name ${NAMES[$n]} --url ${REPOS[$n]} --policy immediate \
        --ca-cert "${CDN_CA_CERT}" --client-key "${CDN_CLIENT_KEY}" --client-cert "${CDN_CLIENT_CERT}" | jq .pulp_href
    else
        pulp rpm remote create --name ${NAMES[$n]} --url ${REPOS[$n]} --policy immediate | jq .pulp_href
    fi
    pulp rpm repository create --name ${NAMES[$n]} --remote ${NAMES[$n]} --autopublish | jq .pulp_href
    pulp rpm repository sync --name ${NAMES[$n]}
    failed=`pulp task list --state failed | jq length`
    echo "FAILURES : ${failed}"
    if [ ${failed} -gt ${starting_failed} ]
    then
        echo "FAILED: " ${failed} - ${starting_failed}
        exit
    fi
    pulp rpm repository destroy --name ${NAMES[$n]}
    pulp orphan cleanup
done
