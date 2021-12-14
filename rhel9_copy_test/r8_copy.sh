#!/bin/bash
APPS_SRC_VERS=$(pulp rpm repository show --name rhel_8_x86_64_appstream | jq -r '.latest_version_href')
echo "APPS_SRC_VERS ${APPS_SRC_VERS}"
DEST=$(pulp rpm repository show --name "dest" | jq -r '.pulp_href')
echo "DEST ${DEST}"
DEST2=$(pulp rpm repository show --name "dest2" | jq -r '.pulp_href')
echo "DEST2 ${DEST2}"
BASE_SRC_VERS=$(pulp rpm repository show --name rhel_8_x86_64_baseos | jq -r '.latest_version_href')
echo "BASE_SRC_VERS ${BASE_SRC_VERS}"
MODULE=$(http :"/pulp/api/v3/content/rpm/modulemds/?repository_version=${APPS_SRC_VERS}" | jq -r '.results | .[] | select(.name == "scala") | .pulp_href')
echo "MODULE ${MODULE}"
CONFIG=$(cat<<EOF
[
    {
        "source_repo_version": "${APPS_SRC_VERS}",
        "dest_repo": "${DEST}",
        "content": [
            "${MODULE}"
        ]
    },
    {
        "source_repo_version": "${BASE_SRC_VERS}",
        "dest_repo": "${DEST2}",
        "content": []
    }
]
EOF
)
echo "CONFIG ${CONFIG}"
http POST :/pulp/api/v3/rpm/copy/ config:="${CONFIG}" dependency_solving=True
