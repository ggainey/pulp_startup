#!/bin/bash
PROBLEM_NAMES=(\
alma-8.4-arch64-ks \
rocky-8-aarch64-ks \
)
#alma-8.4-aarch64-os \
#rocky-8-aarch64-os \
PROBLEM_URLS=(\
http://mirror.phx1.us.spryservers.net/almalinux/8.4/BaseOS/aarch64/kickstart/ \
https://mirror.slu.cz/rocky/8.4/BaseOS/aarch64/kickstart/ \
)
#http://mirror.phx1.us.spryservers.net/almalinux/8.4/BaseOS/aarch64/os/ \
#https://mirror.slu.cz/rocky/8.4/BaseOS/aarch64/os/ \
# ordered list of repo-auth-tokens matching the URLs above. Fill from your own
# account-access. For non-SUSE-repos, use "NULL"
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
    pulp rpm remote create \
        --name ${PROBLEM_NAMES[$i]} --url ${PROBLEM_URLS[$i]} --policy on_demand | jq .pulp_href
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
