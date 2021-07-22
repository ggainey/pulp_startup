#!/bin/bash
#VERSIONS=(9.5 9.6 10 11 12 13)
VERSIONS=(11 12)
#RHEL_VARIANTS=(rhel-6 rhel-6Server rhel-7 rhel-7Server rhel-7Client rhel-7Workstation rhel-8)
RHEL_VARIANTS=(rhel-7 rhel-8)
ARCHS=(x86_64)

cleanup="yes"
p2setup="yes"
migrate="yes"
resync="yes"

pulp-admin login -u admin -p admin

if [ -n "$cleanup" ]; then
    echo "CLEAN UP PREV RUN"
    # Clean up previous data in pulp2 and pulp3
    for v in ${VERSIONS[@]}; do
        for r in ${RHEL_VARIANTS[@]}; do
            for a in ${ARCHS[@]}; do
                URL="https://download.postgresql.org/pub/repos/yum/${v}/redhat/${r}-${a}/"
                NAME="${v}-${r}-${a}"
                echo "$NAME : $URL"
                pulp-admin rpm repo delete --repo-id ${NAME}
                pulp rpm repository destroy --name ${NAME}
                pulp rpm remote destroy --name ${NAME}
            done
        done
    done
    pulp-admin orphan remove --all
    pulp orphans delete
fi

if [ -n "$p2setup" ]; then
    echo "SET UP/SYNC PULP2"
    # Sync repos into pulp2
    for v in ${VERSIONS[@]}; do
        for r in ${RHEL_VARIANTS[@]}; do
            for a in ${ARCHS[@]}; do
                URL="https://download.postgresql.org/pub/repos/yum/${v}/redhat/${r}-${a}/"
                NAME="${v}-${r}-${a}"
                echo "$NAME : $URL"
                pulp-admin rpm repo create --repo-id ${NAME} --feed ${URL} --download-policy on_demand
                pulp-admin rpm repo sync run --bg --repo-id ${NAME}
            done
        done
    done
    # Wait for Pulp2 to finish syncing
    TASKS_OUTPUT=""
    echo -n "Waiting on sync "
    while [ -z "${TASKS_OUTPUT}" ]; do
        TASKS_OUTPUT=$(pulp-admin tasks list | grep "No tasks found")
        echo -n "."; sleep 5
    done
    echo
fi

if [ -n "$migrate" ]; then
    # migrate to pulp3
    echo "MIGRATING"
    PLAN_HREF=$(pulp migration plan create --plan '{"plugins": [{"type": "rpm"}]}' | jq -r .pulp_href)
    echo "Plan: $PLAN_HREF"
    pulp migration plan run --href ${PLAN_HREF}
    sleep 5
fi

if [ -n "$resync" ]; then
    echo "RESYNC REPOS"
    # Modify remotes to 'immediate' in pulp3, re-sync
    for v in ${VERSIONS[@]}; do
        for r in ${RHEL_VARIANTS[@]}; do
            for a in ${ARCHS[@]}; do
                URL="https://download.postgresql.org/pub/repos/yum/${v}/redhat/${r}-${a}/"
                NAME="${v}-${r}-${a}"
                echo "$NAME : $URL"
                REMOTE_HREF=$(pulp rpm repository show --name ${NAME} | jq -r .remote)
                echo "Remote-href: ${REMOTE_HREF}"
                #pulp rpm remote update --href ${REMOTE_HREF} --policy immediate
                pulp --background rpm repository sync --name ${NAME}
            done
        done
    done
fi
