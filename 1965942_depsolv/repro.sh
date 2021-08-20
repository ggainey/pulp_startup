#!/bin/bash
#https://cdn.redhat.com/content/dist/rhel8/8/x86_64/baseos/os/
REPO="https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/os"
NAME="rhel7-1"

sync=
repeat=3
create_dest=
create_cfgs=
issue_copy="yes"

# Sync RHEL7
if [ -n "$sync" ]; then
    # Source
    echo ">>> SETUP SOURCE AND REMOTES"
    pulp rpm remote create --name ${NAME} --url ${REPO} --policy on_demand \
        --ca-cert "${CDN_CA_CERT}" \
        --client-key "${CDN_CLIENT_KEY}"
        --client-cert "${CDN_CLIENT_CERT}" | jq .pulp_href
    pulp rpm repository create \
        --name ${NAME} \
        --remote ${NAME}
        --autopublish | jq .pulp_href
    pulp rpm repository sync --name ${NAME}
fi

# Dest creation
if [ -n "$create_dest" ]; then
    pulp rpm repository create --name "dest-${NAME}-${repeat}"
fi

# Find src-vers and dest-repo
SRC_VERSION=$(pulp rpm repository version show --repository ${NAME} | jq .pulp_href)
echo ">>> SRC_VERSION ${SRC_VERSION}"
DEST_REPO=$(pulp rpm repository show --name "dest-${NAME}-${repeat}" | jq .pulp_href)
echo ">>> DEST_REPO ${DEST_REPO}"


# Create the configs
if [ -n "$create_cfgs" ]; then
    echo ">>> CREATING CONFIGS"
    echo """[
    {
    \"source_repo_version\": "${SRC_VERSION}",
    \"dest_repo\": "${DEST_REPO}",
    \"content\": [""" > cfg_1
    # config-1: just base packages/groups/envs/lang
    psql -U pulp -d pulp --host 127.0.0.1 -P tuples_only \
        -c "select '\"/pulp/api/v3/content/rpm/packages/' || p.content_ptr_id || '/\",' from rpm_package p inner join core_repositorycontent rc on rc.content_id = p.content_ptr_id inner join core_repository r on r.pulp_id = rc.repository_id where r.name = '${NAME}' and not exists (select 1 from rpm_updatecollectionpackage ucp where ucp.name = p.name and ucp.epoch = p.epoch and ucp.version = p.version and ucp.release = p.release and ucp.arch = p.arch)" >> cfg_1
    echo """        ]
    }
    ]""" >> cfg_1

    # config-2: ALL packages (ie there will be dups)
    echo """[
    {
    \"source_repo_version\": "${SRC_VERSION}",
    \"dest_repo\": "${DEST_REPO}",
    \"content\": [""" > cfg_2
    psql -U pulp -d pulp --host 127.0.0.1 -P tuples_only \
        -c "select '\"/pulp/api/v3/content/rpm/packages/' || p.content_ptr_id || '/\",' from rpm_package p inner join core_repositorycontent rc on rc.content_id = p.content_ptr_id inner join core_repository r on r.pulp_id = rc.repository_id where r.name = '${NAME}'" >> cfg_2
    echo """        ]
    }
    ]""" >> cfg_2
fi


# Actually Do the Deed
if [ -n "$issue_copy" ]; then
    echo ">>> ISSUING COPY COMMANDS"
    # Issue first copy
    TASK=$(http POST :/pulp/api/v3/rpm/copy/ dependency_solving=True config:=@./cfg_1 | jq -r .task)
    echo ">>> FIRST TASK ${TASK}"
    pulp task show --href ${TASK} --wait

    # Issue second copy
    TASK=$(http POST :/pulp/api/v3/rpm/copy/ dependency_solving=True config:=@./cfg_2 | jq -r .task)
    echo ">>> SECOND TASK ${TASK}"
    pulp task show --href ${TASK} --wait
fi
