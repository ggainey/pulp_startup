#!/bin/bash
#https://cdn.redhat.com/content/dist/rhel8/8/x86_64/baseos/os/
REPO="https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/os"
NAME="rhel7-1"

sync="yes"
repeat=1
create_dest="yes"
create_cfgs="yes"
issue_copy="yes"

# Sync RHEL7
if [ -n "$sync" ]; then
    # Source
    echo ">>> SETUP SOURCE AND REMOTES"
    pulp rpm remote create --name ${NAME} --url ${REPO} --policy on_demand \
        --ca-cert "${CDN_CA_CERT}" \
        --client-key "${CDN_CLIENT_KEY}" \
        --client-cert "${CDN_CLIENT_CERT}" | jq .pulp_href
    pulp rpm repository create \
        --name ${NAME} \
        --remote ${NAME} \
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
MAX_UNITS_PER=5000
if [ -n "$create_cfgs" ]; then
    echo ">>> CREATING CONFIGS"
    echo ">>> ...BASE RPMS"
    echo """[
    {
    \"source_repo_version\": "${SRC_VERSION}",
    \"dest_repo\": "${DEST_REPO}",
    \"content\": [""" > tmp_cfg
    # config-1: just base packages/groups/envs/lang
    psql -U pulp -d pulp --host 127.0.0.1 -P tuples_only \
        -c "select '\"/pulp/api/v3/content/rpm/packages/' || p.content_ptr_id || '/\",' from rpm_package p inner join core_repositorycontent rc on rc.content_id = p.content_ptr_id inner join core_repository r on r.pulp_id = rc.repository_id where r.name = '${NAME}' and not exists (select 1 from rpm_updatecollectionpackage ucp where ucp.name = p.name and ucp.epoch = p.epoch and ucp.version = p.version and ucp.release = p.release and ucp.arch = p.arch)" >> tmp_cfg
    echo """] } ]""" >> tmp_cfg
    cat tmp_cfg | tr -s '\n' '\r' | sed -e 's/,\r]/]/g' | tr '\r' '\n' > cfg_01

    # find ALL the packages
    # Find out how many "all" is, and then create one cfg per-MAX-UNITS possible
    echo ">>> ...FINDING ALL-RPM COUNT..."
    UNITS_TO_COPY=$(psql -U pulp -d pulp --host 127.0.0.1 -P tuples_only -c "select count(p.content_ptr_id) from rpm_package p inner join core_repositorycontent rc on rc.content_id = p.content_ptr_id inner join core_repository r on r.pulp_id = rc.repository_id where r.name = '${NAME}'")
    echo ">>> PREPARING CFGS TO COPY ${UNITS_TO_COPY} UNITS..."
    OFFSET=0
    PAGE=2 # First file we'll write is cfg_2
    while [ ${OFFSET} -lt ${UNITS_TO_COPY} ]
    do
        LZ_page=$(printf "%02d" ${PAGE})
        echo "PAGE/OFFSET: $PAGE/$OFFSET"
        echo """[
        {
        \"source_repo_version\": "${SRC_VERSION}",
        \"dest_repo\": "${DEST_REPO}",
        \"content\": [""" > tmp_cfg
        psql -U pulp -d pulp --host 127.0.0.1 -P tuples_only -c "select '\"/pulp/api/v3/content/rpm/packages/' || p.content_ptr_id || '/\",' from rpm_package p inner join core_repositorycontent rc on rc.content_id = p.content_ptr_id inner join core_repository r on r.pulp_id = rc.repository_id where r.name = '${NAME}' LIMIT ${MAX_UNITS_PER} OFFSET ${OFFSET}" >> tmp_cfg
        echo """] } ]""" >> tmp_cfg
        # Punt extraneous comma and newline at resulting from the query/>> above
        echo ">>> EDIT cfg_${PAGE}..."
        cat tmp_cfg | tr -s '\n' '\r' | sed -e 's/,\r]/]/g' | tr '\r' '\n' > cfg_${LZ_page}
        OFFSET=$(($OFFSET+$MAX_UNITS_PER))
        PAGE=$(($PAGE+1))
    done
fi


# Actually Do the Deed
if [ -n "$issue_copy" ]; then
    echo ">>> ISSUING COPY COMMANDS FOR ALL cfg_* FOUND"
    # Issue first copy
    TASK=$(http POST :/pulp/api/v3/rpm/copy/ dependency_solving=True config:=@./cfg_01 | jq -r .task)
    echo ">>> FIRST TASK ${TASK}"
    pulp task show --href ${TASK} --wait

    for f in $(ls cfg_??)
    do
        # Issue copy-cmd
        TASK=$(http POST :/pulp/api/v3/rpm/copy/ dependency_solving=True config:=@./$f | jq -r .task)
        echo ">>> $f TASK ${TASK}"
    done
fi
