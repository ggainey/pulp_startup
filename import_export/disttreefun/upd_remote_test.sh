#!/bin/bash
REPO_NAME="rhel7-ks"
REMOTE_URL=https://cdn.redhat.com/content/dist/rhel/server/7/7.9/x86_64/kickstart
pulp rpm remote create --name ${REPO_NAME} --url ${REMOTE_URL} --policy 'immediate' \
  --ca-cert "MY CA CERT" \
  --client-key "MY CLIENT KEY" \
  --client-cert "MY CLIENT CERT" \
  --tls-validation false
psql -U pulp -d pulp --host 127.0.0.1 -c "select client_key from core_remote where name='rhel7-ks';"
pulp rpm remote update --name ${REPO_NAME} --client-cert "NOT A CERT"
pulp rpm remote show --name rhel7-ks
pulp rpm remote update --name ${REPO_NAME} --ca-cert "NOT A CA CERT"
pulp rpm remote show --name rhel7-ks
pulp rpm remote update --name ${REPO_NAME} --client-key "NOT A KEY"
psql -U pulp -d pulp --host 127.0.0.1 -c "select client_key from core_remote where name='rhel7-ks';"
