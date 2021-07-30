#!/bin/bash
REPOS=(\
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/sat-maintenance/6/os/ \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/ansible/2.9/os/ \
)
NAMES=(\
sat-maint \
ansible-2.9 \
)

NUM_dups=2
NUM_CYCLES=6
echo "CLEANUP"
for n in ${!NAMES[@]}
do
    for i in {1..2}
    do
        pulp rpm remote destroy --name ${NAMES[$n]}-${i}
        pulp rpm repository destroy --name ${NAMES[$n]}-${i}
    done
done
pulp orphans delete


echo "CYCLE-START"
for c in {1..6}
do
    echo "SETUP REPOS AND REMOTES"
    for n in ${!NAMES[@]}
    do
        for i in {1..2}
        do
            pulp rpm remote create --name ${NAMES[$n]}-${i} --url ${REPOS[$n]} --policy on_demand \
            --ca-cert "${CDN_CA_CERT}" --client-key "${CDN_CLIENT_KEY}" --client-cert "${CDN_CLIENT_CERT}" | jq .pulp_href
            pulp rpm repository create --name ${NAMES[$n]}-${i} --remote ${NAMES[$n]}-${i} | jq .pulp_href
        done
    done
    echo "SYNCING..."
    for n in ${!NAMES[@]}
    do
        for i in {1..2}
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
    if [ ${failed} -gt 0 ]
    then
      exit
    fi
    echo "CLEANUP FOR NEXT"
    for n in ${!NAMES[@]}
    do
        for i in {1..2}
        do
            pulp rpm remote destroy --name ${NAMES[$n]}-${i}
            pulp rpm repository destroy --name ${NAMES[$n]}-${i}
        done
    done
    pulp orphans delete
done

