#!/bin/bash
# https://cdn.redhat.com/content/eus/rhel/server/7/7.7/x86_64/os
REPOS=(\
https://cdn.redhat.com/content/dist/rhel/server/7/7.7/x86_64/kickstart \
https://cdn.redhat.com/content/dist/rhel/server/7/7.7/x86_64/os
)
# rhel77-eus
NAMES=(\
rhel77-kickstart \
rhel77
)

NUM_dups=3
NUM_CYCLES=4
echo "CLEANUP"
for n in ${!NAMES[@]}
do
    for i in {1..3}
    do
        pulp rpm remote destroy --name ${NAMES[$n]}-${i}
        pulp rpm repository destroy --name ${NAMES[$n]}-${i}
    done
done
pulp orphans delete


echo "CYCLE-START"
for c in {1..4}
do
    echo "SETUP REPOS AND REMOTES"
    for n in ${!NAMES[@]}
    do
        for i in {1..3}
        do
            pulp rpm remote create --name ${NAMES[$n]}-${i} --url ${REPOS[$n]} --policy on_demand \
            --ca-cert "${CDN_CA_CERT}" --client-key "${CDN_CLIENT_KEY}" --client-cert "${CDN_CLIENT_CERT}" | jq .pulp_href
            pulp rpm repository create --name ${NAMES[$n]}-${i} --remote ${NAMES[$n]}-${i} --autopublish | jq .pulp_href
        done
    done
    starting_failed=`pulp task list --state failed | jq length`
    echo "SYNCING..."
    for n in ${!NAMES[@]}
    do
        for i in {1..3}
        do
            pulp -b rpm repository sync --name ${NAMES[$n]}-${i}
        done
    done
    sleep 5
    echo "WAIT FOR COMPLETION...."
    while true
    do
        running=`pulp task list --state running | jq length`
        echo -n "."
        sleep 5
        if [ ${running} -eq 0 ]
        then
            echo "DONE"
            break
        fi
    done
    failed=`pulp task list --state failed | jq length`
    echo "FAILURES : ${failed}"
    if [ ${failed} -gt ${starting_failed} ]
    then
      echo "FAILED: " ${failed} - ${starting_failed}
      exit
    fi
    echo "CLEANUP FOR NEXT"
    for n in ${!NAMES[@]}
    do
        for i in {1..3}
        do
            pulp rpm remote destroy --name ${NAMES[$n]}-${i}
            pulp rpm repository destroy --name ${NAMES[$n]}-${i}
        done
    done
    pulp orphans delete
done

