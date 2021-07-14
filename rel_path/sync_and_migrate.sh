#!/bin/bash
PROBLEM_NAMES=(\
grafana \
centos-ops \
sles12-backport-sp5-standard \
sles12-backport-sp5-product \
sles12-backport-sp4-standard \
sles12-backport-sp4-product \
)
PROBLEM_URLS=(\
https://packages.grafana.com/oss/rpm \
http://ftp.cs.stanford.edu/centos/7/opstools/x86_64/ \
https://updates.suse.com/SUSE/Backports/SLE-12-SP5_x86_64/standard/ \
https://updates.suse.com/SUSE/Backports/SLE-12-SP5_x86_64/product/ \
https://updates.suse.com/SUSE/Backports/SLE-12-SP4_x86_64/standard/ \
https://updates.suse.com/SUSE/Backports/SLE-12-SP4_x86_64/product/ \
)
# ordered list of repo-auth-tokens matching the URLs above. Fill from your own
# account-access. For non-SUSE-repos, use "NULL"
SUSE_TOKENS=($SUSE_TOKEN_STR)
echo AUTH : ${SUSE_AUTH}
echo TOKENS : ${SUSE_TOKENS[@]}

cleanup=
p2setup=
migrate="yes"
resync="yes"

pulp-admin login -u admin -p admin

# cleanup
if [ -n "$cleanup" ]; then
    echo ">>> REPO/REMOTE CLEANUP"
    for i in ${!PROBLEM_NAMES[@]}
    do
        echo clean ${PROBLEM_NAMES[$i]}
        pulp rpm remote destroy --name ${PROBLEM_NAMES[$i]}
        pulp rpm repository destroy --name ${PROBLEM_NAMES[$i]}
        pulp-admin rpm repo delete --repo-id ${PROBLEM_NAMES[$i]}
    done
    echo ">> ORPHAN CLEANUP"
    pulp orphans delete | jq .pulp_href
    pulp-admin orphan remove --all
fi

if [ -n "$p2setup" ]; then
    # setup and sync into pulp2
    echo ">>> SYNC"
    for i in ${!PROBLEM_NAMES[@]}
    do
        echo ${PROBLEM_NAMES[$i]} : ${PROBLEM_URLS[$i]}
        echo Token : ${SUSE_TOKENS[$i]}
        if [[ "NULL" != ${SUSE_TOKENS[$i]} ]]
        then
            URL="${PROBLEM_URLS[$i]}?${SUSE_TOKENS[$i]}"
        else
            URL=${PROBLEM_URLS[$i]}
        fi
        pulp-admin rpm repo create --repo-id ${PROBLEM_NAMES[$i]} \
            --feed ${URL} --download-policy on_demand
        pulp-admin rpm repo sync run --repo-id ${PROBLEM_NAMES[$i]}
        TASKS_OUTPUT=""
        echo -n "Waiting on sync "
        while [ -z "${TASKS_OUTPUT}" ]; do
            TASKS_OUTPUT=$(pulp-admin tasks list | grep "No tasks found")
            echo -n "."; sleep 5
        done
        echo
    done
fi

if [ -n "$migrate" ]; then
    # 2to3 migration
    echo "MIGRATING"
    PLAN_HREF=$(pulp migration plan create --plan '{"plugins": [{"type": "rpm"}]}' | jq -r .pulp_href)
    echo "Plan: $PLAN_HREF"
    pulp -T 0 migration plan run --href ${PLAN_HREF}
    sleep 5
fi

# syncing SUSE repos post-migration fails due to https://pulp.plan.io/issues/9088
if [ -n "$resync" ]; then
    # sync in pulp3
    echo ">>> SYNC AUTOPUBLISH"
    for i in ${!PROBLEM_NAMES[@]}
    do
        echo ${PROBLEM_NAMES[$i]} : ${PROBLEM_URLS[$i]}
        echo Token : ${SUSE_TOKENS[$i]}
        REMOTE_HREF=$(pulp rpm repository show --name ${PROBLEM_NAMES[$i]} | jq -r .remote)
        echo "Remote-href: ${REMOTE_HREF}"
        pulp rpm repository sync --name ${PROBLEM_NAMES[$i]}
    done
fi

