#!/bin/bash
URLS=(\
    https://fixtures.pulpproject.org/rpm-distribution-tree/ \
)
NAMES=(\
    rdt \
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

echo "CLEANUP"
for n in ${!NAMES[@]}
do
    for i in {1..5}
    do
        pulp rpm remote destroy --name ${NAMES[$n]}-${i}
        pulp rpm repository destroy --name ${NAMES[$n]}-${i}
        pulp rpm distribution destroy --name ${NAMES[$n]}-${i}
    done
done
pulp orphan cleanup --protection-time 0


echo "SETUP URLS AND REMOTES"
for n in ${!NAMES[@]}
do
    for i in {1..5}
    do
        pulp rpm remote create --name ${NAMES[$n]}-${i} --url ${URLS[$n]} --policy on_demand | jq .pulp_href
        #pulp rpm repository create --name ${NAMES[$n]}-${i} --remote ${NAMES[$n]}-${i} --autopublish | jq .pulp_href
        pulp rpm repository create --name ${NAMES[$n]}-${i} --remote ${NAMES[$n]}-${i} | jq .pulp_href
        pulp rpm distribution create --repository ${NAMES[$n]}-${i} --name ${NAMES[$n]}-${i} --base-path ${NAMES[$n]}-${i}
    done
done
starting_failed=`pulp task list --limit 10000 --state failed | jq length`
echo "SYNCING..."
for i in {1..5}
do
    for n in ${!NAMES[@]}
    do
        pulp -b rpm repository sync --name ${NAMES[$n]}-${i} --sync-policy mirror_complete
        #pulp -b rpm repository sync --name ${NAMES[$n]}-${i}
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
#echo "PUBLISHING..."
#for i in {1..5}
#do
#    for n in ${!NAMES[@]}
#    do
#        pulp -b rpm publication create --repository ${NAMES[$n]}-${i}
#    done
#done
#sleep 5
#echo "WAIT FOR COMPLETION...."
#while true
#do
#    running=`pulp task list --limit 10000 --state running | jq length`
#    echo -n "."
#    sleep 5
#    if [ ${running} -eq 0 ]
#    then
#        echo "DONE"
#        break
#    fi
#done
failed=`pulp task list --limit 10000 --state failed | jq length`
echo "FAILURES : ${failed}"
if [ ${failed} -gt ${starting_failed} ]
then
  echo "FAILED: " ${failed} - ${starting_failed}
  exit
fi


for i in {1..5}
do
    http --check-status -h :/pulp/content/rdt-${i}/Dolphin/dolphin-3.10.232-1.noarch.rpm 
    #http --check-status -h :/pulp/content/rdt-${i}/Dolphin/Packages/d/dolphin-3.10.232-1.noarch.rpm 
done
