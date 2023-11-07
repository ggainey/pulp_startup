#!/usr/bin/bash
# Delete created repos, users, and domains
echo ">>> Destroy default-domain Repository..."
pulp rpm repository destroy --name ${DEFAULT_REPO}
echo ">>> Destroy ${PRIVATE_DOMAIN}-domain Remote..."
pulp rpm remote destroy --name ${DEFAULT_REPO}
echo ">>> Destroy ${PRIVATE_DOMAIN}-domain Distribution..."
pulp --domain ${PRIVATE_DOMAIN} rpm distribution destroy --name ${PRIVATE_REPO}
echo ">>> Destroy ${PRIVATE_DOMAIN}-domain Repository..."
pulp --domain ${PRIVATE_DOMAIN} rpm repository destroy --name ${PRIVATE_REPO}
echo ">>> Destroy ${PRIVATE_DOMAIN}..."
pulp domain destroy --name ${PRIVATE_DOMAIN}
echo ">>> Destroy Users..."
pulp user destroy --username robert
pulp user destroy --username norm
