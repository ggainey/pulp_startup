#!/bin/bash
PROBLEM_NAMES=(\
grafana \
centos-ops \
mysql \
sles12-backport-sp5-standard \
sles12-backport-sp5-product \
sles12-backport-sp4-standard \
sles12-backport-sp4-product \
sles12-update-sp5 \
sles12-debug-update-sp5 \
)
PROBLEM_URLS=(\
https://packages.grafana.com/oss/rpm \
http://ftp.cs.stanford.edu/centos/7/opstools/x86_64/ \
http://repo.mysql.com/yum/mysql-tools-community/el/7/x86_64/ \
https://updates.suse.com/SUSE/Backports/SLE-12-SP5_x86_64/standard/ \
https://updates.suse.com/SUSE/Backports/SLE-12-SP5_x86_64/product/ \
https://updates.suse.com/SUSE/Backports/SLE-12-SP4_x86_64/standard/ \
https://updates.suse.com/SUSE/Backports/SLE-12-SP4_x86_64/product/ \
https://updates.suse.com/SUSE/Updates/SLE-SERVER/12-SP5/x86_64/update/ \
https://updates.suse.com/SUSE/Updates/SLE-SERVER/12-SP5/x86_64/update_debug/ \
)
# SUSE_TOKENS is assumed to be a string which is an ordered list of repo-auth-tokens matching the 
# URLs above. Fill from your own account-access. For non-SUSE-repos, use "NULL"
SUSE_TOKENS=($SUSE_TOKEN_STR)
echo TOKENS : ${SUSE_TOKENS[@]}
export PULP2_AUTH=`python -c 'import base64; print(base64.encodestring("admin:admin".encode())[:-1].decode())'`

cleanup=""
p2setup=""
migrate="yes"
resync="yes"
mirror="yes"

pulp-admin login -u admin -p admin

# cleanup
if [ -n "$cleanup" ]; then
    echo ">>> REPO/REMOTE CLEANUP"
    for i in ${!PROBLEM_NAMES[@]}
    do
        if [ $i -gt 2 ]
        then
            continue
        fi
        echo clean ${PROBLEM_NAMES[$i]}
        REMOTE_HREF=$(pulp rpm repository show --name ${PROBLEM_NAMES[$i]} | jq -r .remote)
        pulp rpm remote destroy --href ${REMOTE_HREF}
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
        if [ $i -gt 2 ]
        then
            continue
        fi
        echo ${PROBLEM_NAMES[$i]} : ${PROBLEM_URLS[$i]}
        echo Token : ${SUSE_TOKENS[$i]}
        pulp-admin rpm repo create --repo-id ${PROBLEM_NAMES[$i]} \
            --feed ${PROBLEM_URLS[$i]} --download-policy immediate
        if [[ "NULL" != ${SUSE_TOKENS[$i]} ]]
        then
            CONFIG="{\"query_auth_token\": \"${SUSE_TOKENS[$i]}\" }"
            echo Config : ${CONFIG}
            http --verify no --auth admin:admin \
                PUT https://localhost/pulp/api/v2/repositories/${PROBLEM_NAMES[$i]}/ \
                importer_config:="${CONFIG}"
        fi
        pulp-admin rpm repo sync run --repo-id ${PROBLEM_NAMES[$i]}
        TASKS_OUTPUT=""
        echo -n "Waiting on sync "
        while [ -z "${TASKS_OUTPUT}" ]; do
            TASKS_OUTPUT=$(pulp-admin tasks list | grep "No tasks found")
            echo -n "."; sleep 5
        done
        echo -e "\n\n"
    done
fi

if [ -n "$migrate" ]; then
    # 2to3 migration
    echo "MIGRATING"
    PLAN_HREF=$(pulp migration plan create --plan '{"plugins": [{"type": "rpm"}]}' | jq -r .pulp_href)
    echo "Plan: $PLAN_HREF"
    pulp migration plan run --href ${PLAN_HREF}
    # The plan's child-tasks can take some time to complete after the plan declares itself done...
    echo WAITING...
    sleep 180
fi

if [ -n "$resync" ]; then
    # sync in pulp3
    echo ">>> SYNC AUTOPUBLISH"
    for i in ${!PROBLEM_NAMES[@]}
    do
        if [ $i -gt 2 ]
        then
            continue
        fi
        echo ${PROBLEM_NAMES[$i]} : ${PROBLEM_URLS[$i]}
        echo Token : ${SUSE_TOKENS[$i]}
        REMOTE_HREF=$(pulp rpm repository show --name ${PROBLEM_NAMES[$i]} | jq -r .remote)
        echo "Remote-href: ${REMOTE_HREF}"
        pulp rpm repository sync --name ${PROBLEM_NAMES[$i]}
        echo -e "\n\n"
    done
fi

if [ -n "$mirror" ]; then
    # sync in pulp3
    echo ">>> SYNC MIRROR"
    for i in ${!PROBLEM_NAMES[@]}
    do
        if [ $i -gt 2 ]
        then
            continue
        fi
        echo ${PROBLEM_NAMES[$i]} : ${PROBLEM_URLS[$i]}
        echo Token : ${SUSE_TOKENS[$i]}
        REMOTE_HREF=$(pulp rpm repository show --name ${PROBLEM_NAMES[$i]} | jq -r .remote)
        echo "Remote-href: ${REMOTE_HREF}"
        pulp rpm repository update --name ${PROBLEM_NAMES[$i]} --no-autopublish
        pulp rpm repository sync --name ${PROBLEM_NAMES[$i]} --mirror
        echo -e "\n\n"
    done
fi

