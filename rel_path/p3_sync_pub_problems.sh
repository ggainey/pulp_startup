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

# cleanup
echo ">>> REPO/REMOTE CLEANUP"
for i in ${!PROBLEM_NAMES[@]}
do
    echo clean ${PROBLEM_NAMES[$i]}
    pulp rpm remote destroy --name ${PROBLEM_NAMES[$i]}
    pulp rpm repository destroy --name ${PROBLEM_NAMES[$i]}
done
echo ">> ORPHAN CLEANUP"
pulp orphans delete | jq .pulp_href

# setup and sync autopub
echo ">>> SYNC AUTOPUBLISH"
for i in ${!PROBLEM_NAMES[@]}
do
    echo ${PROBLEM_NAMES[$i]} : ${PROBLEM_URLS[$i]}
    echo Token : ${SUSE_TOKENS[$i]}
    if [[ "NULL" != ${SUSE_TOKENS[$i]} ]]
    then
        http POST :/pulp/api/v3/remotes/rpm/rpm/ \
            name=${PROBLEM_NAMES[$i]} \
            url=${PROBLEM_URLS[$i]} \
            policy='on_demand' \
            sles_auth_token=${SUSE_TOKENS[$i]} | jq .pulp_href
    else
        pulp rpm remote create \
            --name ${PROBLEM_NAMES[$i]} --url ${PROBLEM_URLS[$i]} --policy on_demand | jq .pulp_href
    fi
    pulp rpm repository create \
        --name ${PROBLEM_NAMES[$i]} --remote ${PROBLEM_NAMES[$i]} --autopublish | jq .pulp_href
    pulp rpm repository sync \
        --name ${PROBLEM_NAMES[$i]}
done

# cleanup
echo ">>> REPO/REMOTE CLEANUP"
for i in ${!PROBLEM_NAMES[@]}
do
    echo clean ${PROBLEM_NAMES[$i]}
    pulp rpm repository destroy --name ${PROBLEM_NAMES[$i]}
done
echo ">> ORPHAN CLEANUP"
pulp orphans delete | jq .pulp_href

# setup and sync mirror
echo ">>> SYNC MIRROR"
for i in ${!PROBLEM_NAMES[@]}
do
    echo ${PROBLEM_NAMES[$i]} : ${PROBLEM_URLS[$i]}
    pulp rpm repository create --name ${PROBLEM_NAMES[$i]} --remote ${PROBLEM_NAMES[$i]} | jq .pulp_href
    pulp rpm repository sync --name ${PROBLEM_NAMES[$i]} --mirror | jq .pulp_href
done
