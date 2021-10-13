#!/bin/sh
export USERNAME='admin'
export PASSWORD='admin'

if [ $# -lt 1 ]; then
    echo "Usage: $0 REPO"
    exit 1
fi

if [ -n $1 ]; then
    REPO=$1
    echo "Will list package groups from repo ${REPO}"
fi

export AUTH=`python -c 'import base64; print(base64.encodestring("admin:admin".encode())[:-1].decode())'`
SUSE_TOKENS=($SUSE_TOKEN_STR)
CONFIG="importer_config={\"query_auth_token\": \"${SUSE_TOKENS[2]}\" }"

curl -k -H "Authorization: Basic $AUTH" https://localhost/pulp/api/v2/repositories/${REPO}/
echo
echo
echo ${CONFIG}
echo $AUTH
echo
echo
curl -v -X PUT -k -F importer_config=\{\"foo\":\ \"bar\"\} -H "Authorization: Basic $AUTH" https://localhost/pulp/api/v2/repositories/${REPO}/
echo

