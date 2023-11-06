#!/usr/bin/bash
echo ">>> TRY: robert, create repo in default - ERR..."
pulp --username robert --password ${ROBERT_PWD} \
    rpm repository create --name ${PRIVATE_REPO}
#
echo ">>> TRY: robert, create repo in private - SUCCEED..."
pulp --domain ${PRIVATE_DOMAIN} --username robert --password ${ROBERT_PWD} \
    rpm repository create --name ${PRIVATE_REPO} --autopublish
pulp --domain ${PRIVATE_DOMAIN} --username robert --password ${ROBERT_PWD} \
    rpm distribution create \
    --name ${PRIVATE_REPO} --repository ${PRIVATE_REPO} --base-path ${PRIVATE_REPO}
#
echo ">>> TRY: norm, read repo in default - ERR..."
pulp --username norm --password ${NORM_PWD} \
    rpm repository show --name ${DEFAULT_REPO}
#
echo ">>> TRY: admin, copy content from default to private - ERR..."
export DEFAULT_REMOTE_HREF=$(pulp rpm remote show --name ${DEFAULT_REPO} | jq -r .pulp_href)
pulp --domain ${PRIVATE_DOMAIN} \
    rpm repository sync --repository ${PRIVATE_REPO} --remote ${DEFAULT_REMOTE_HREF}
#
echo ">>> TRY: admin, find package-by-name - SUCCEED..."
pulp rpm content list --name zebra
#
echo ">>> TRY: robert, find same name - ERR..."
pulp --username robert --password ${ROBERT_PWD} \
    rpm content list --name zebra
#
echo ">>> TRY: robert, upload same-name RPM to private repo, then access artifact - SUCCEED..."
pulp --domain ${PRIVATE_DOMAIN} --username robert --password ${ROBERT_PWD} \
    rpm content upload --repository ${PRIVATE_REPO} --file ./zebra-0.1-2.noarch.rpm
pulp --domain ${PRIVATE_DOMAIN} --username robert --password ${ROBERT_PWD} \
    rpm publication create --repository ${PRIVATE_REPO}
pulp --domain ${PRIVATE_DOMAIN} --username robert --password ${ROBERT_PWD} \
    rpm content list --name zebra
#
echo ">>> TRY: using wget on private-domain distribution - SUCCEED..."
http http://localhost:5001/pulp/content/private/private/
