#!/bin/bash
URLS=(\
    https://download.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/ \
    https://download.rockylinux.org/pub/rocky/9/BaseOS/x86_64/kickstart/ \
    https://download.rockylinux.org/pub/rocky/9/AppStream/x86_64/os/ \
    https://download.rockylinux.org/pub/rocky/9/AppStream/x86_64/kickstart/ \
)
NAMES=(\
    base \
    base-ks \
    appstream \
    appstream-ks \
)

# Make sure we're concurrent-enough
num_workers=`sudo systemctl status pulpcore-worker* | grep "service - Pulp Worker" | wc -l`
echo "Current num-workers ${num_workers}"
if [ ${num_workers} -lt 20 ]
then
    for (( i=${num_workers}+1; i<=20; i++ ))
    do
        echo "Starting worker ${i}"
        sudo systemctl start pulpcore-worker@${i}
    done
fi

echo "CLEANUP"
for n in ${!NAMES[@]}
do
    for i in {1..1}
    do
        pulp rpm remote destroy --name ${NAMES[$n]}-${i}
        pulp rpm repository destroy --name ${NAMES[$n]}-${i}
    done
done
pulp orphan cleanup --protection-time 0


echo "SETUP URLS AND REMOTES"
for n in ${!NAMES[@]}
do
    for i in {1..1}
    do
        pulp rpm remote create --name ${NAMES[$n]}-${i} --url ${URLS[$n]} --policy on_demand | jq .pulp_href
        pulp rpm repository create --name ${NAMES[$n]}-${i} --remote ${NAMES[$n]}-${i} | jq .pulp_href
    done
done
starting_failed=`pulp task list --limit 10000 --state failed | jq length`
echo "SYNCING..."
for i in {1..1}
do
    for n in ${!NAMES[@]}
    do
        pulp -b rpm repository sync --name ${NAMES[$n]}-${i}
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
