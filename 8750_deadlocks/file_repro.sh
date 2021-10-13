#!/bin/bash
REPOS=(\
    https://fixtures.pulpproject.org/file-dl-forward/PULP_MANIFEST \
    https://fixtures.pulpproject.org/file-dl-reverse/PULP_MANIFEST \
)
NAMES=(\
    file-dl-forward \
    file-dl-reverse \
)

# Make sure we're concurent-enough
num_workers=`sudo systemctl status pulpcore-worker* | grep "service - Pulp Worker" | wc -l`
echo "Current num-workers ${num_workers}"
if [ ${num_workers} -lt 10 ]
then
    for (( i=${num_workers}+1; i<=10; i++ ))
    do
        echo "Starting worker ${i}"
        sudo systemctl start pulpcore-worker@${i}
    done
fi

NUM_dups=5
NUM_CYCLES=2
echo "CLEANUP"
for n in ${!NAMES[@]}
do
    for i in {1..5}
    do
        pulp file remote destroy --name ${NAMES[$n]}-${i}
        pulp file repository destroy --name ${NAMES[$n]}-${i}
    done
done
pulp orphans delete


echo "CYCLE-START"
for c in {1..3}
do
    echo "SETUP REPOS AND REMOTES"
    for n in ${!NAMES[@]}
    do
        for i in {1..5}
        do
            pulp file remote create --name ${NAMES[$n]}-${i} --url ${REPOS[$n]} --policy immediate | jq .pulp_href
            pulp file repository create --name ${NAMES[$n]}-${i} --remote ${NAMES[$n]}-${i} | jq .pulp_href
        done
    done
    starting_failed=`pulp task list --limit 10000 --state failed | jq length`
    echo "SYNCING..."
    for i in {1..5}
    do
        for n in ${!NAMES[@]}
        do
            pulp -b file repository sync --name ${NAMES[$n]}-${i}
        done
    done
    sleep 5
    echo "WAIT FOR COMPLETION...."
    while true
    do
        running=`pulp task list --limit 10000 --state running | jq length`
        echo -n "."
        sleep 5
        if [ ${running} -eq 0 ]
        then
            echo "DONE"
            break
        fi
    done
    failed=`pulp task list --limit 10000 --state failed | jq length`
    echo "FAILURES : ${failed}"
    if [ ${failed} -gt ${starting_failed} ]
    then
      echo "FAILED: " ${failed} - ${starting_failed}
      exit
    fi
    echo "CLEANUP FOR NEXT"
    for n in ${!NAMES[@]}
    do
        for i in {1..5}
        do
            pulp file remote destroy --name ${NAMES[$n]}-${i}
            pulp file repository destroy --name ${NAMES[$n]}-${i}
        done
    done
    pulp orphans delete
done

