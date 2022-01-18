#!/bin/bash
source /home/vagrant/.bashrc.d/alias.bashrc
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
if [ ${num_workers} -lt 20 ]
then
    for (( i=${num_workers}+1; i<=20; i++ ))
    do
        echo "Starting worker ${i}"
        sudo systemctl start pulpcore-worker@${i}
    done
fi

NUM_dups=3
REPO_HREF_ARR=()
echo "SETUP REPOS AND REMOTES"
for n in ${!NAMES[@]}
do
    for i in {1..6}
    do
        echo "NAME ${NAMES[$n]}-${i}..."
        pulp file remote create --name ${NAMES[$n]}-${i} --url ${REPOS[$n]} --policy immediate | jq .pulp_href
        REPO_HREF_ARR+=(\"$(pulp file repository create --name ${NAMES[$n]}-${i} --remote ${NAMES[$n]}-${i} | jq -r .pulp_href)\")
    done
done
data_string="${REPO_HREF_ARR[*]}"
REPO_HREF_LIST=$(echo "${data_string//${IFS:0:1}/,}")

echo "SYNCING..."
SYNC_TASKS=()
for i in {1..6}
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
exit # REMOVE ME
echo "SETTING UP EXPORTER..."
EXPORTER_HREF=$(http POST :/pulp/api/v3/exporters/core/pulp/ name="TEST" repositories:=[${REPO_HREF_LIST}] path=/tmp/exports | jq -r .pulp_href)

echo "EXPORTING..."
EXPORT_TASK=$(http POST :${EXPORTER_HREF}/exports/ | jq -r '.task')

echo "WAITING FOR ${EXPORT_TASK}..."
pulp task show --href ${EXPORT_TASK} --wait
EXPORT_RESOURCE=$(pulp task show --href ${EXPORT_TASK} | jq -r .created_resources[0])
echo "EXPORT_RESOURCE ${EXPORT_RESOURCE}..."
EXPORT_TOC=$(http :${EXPORT_RESOURCE} | jq -r .toc_info.file)
echo "EXPORT_TOC ${EXPORT_TOC}..."

echo "RESET PULP3..."
pclean
prestart

# Make sure we're concurent-enough
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

echo "SETTING UP REPOS..."
for n in ${!NAMES[@]}
do
    for i in {1..6}
    do
        pulp file repository create --name ${NAMES[$n]}-${i} | jq .pulp_href
    done
done

echo "SETTING UP IMPORTER..."
IMPORTER_HREF=$(http POST :/pulp/api/v3/importers/core/pulp/ name="TEST" | jq -r .pulp_href)
echo "IMPORTER-HREF ${IMPORTER_HREF}"

echo "IMPORTING..."
http POST :${IMPORTER_HREF}/imports/ toc=${EXPORT_TOC}
