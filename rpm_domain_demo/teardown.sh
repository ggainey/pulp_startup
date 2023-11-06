#!/usr/bin/bash
# Delete created repos, users, and domains
echo ">>> Destroy ${PRIVATE_DOMAIN}-domain objects..."
pulp rpm repository destroy --name ${DEFAULT_REPO}
pulp rpm remote destroy --name ${DEFAULT_REPO}
echo ">>> Destroy ${PRIVATE_DOMAIN}-domain objects..."
pulp --domain ${PRIVATE_DOMAIN} rpm distribution destroy --name ${PRIVATE_REPO}
pulp --domain ${PRIVATE_DOMAIN} rpm repository destroy --name ${PRIVATE_REPO}
echo ">>> Destroy ${PRIVATE_DOMAIN}..."
pulp domain destroy --name ${PRIVATE_DOMAIN}
echo ">>> Destroy Users..."
pulp user destroy --username robert
pulp user destroy --username norm
