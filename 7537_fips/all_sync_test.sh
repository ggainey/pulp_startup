wait_until_task_finished() {
    echo "Polling the task until it has reached a final state."
    local task_url=$1
    while true
    do
        local response=$(http $task_url)
        local state=$(jq -r .state <<< ${response})
        local started=$(jq -r .started_at <<< ${response})
        local finished=$(jq -r .finished_at <<< ${response})
        #jq . <<< "${response}"
        #echo "State: [${state}] Start: [${started}] Finish: [${finished}]"
        case ${state} in
            failed|canceled)
                echo "Task in final state: ${state}"
                break
                ;;
            completed)
                echo "$task_url complete."
                echo "State: [${state}] Start: [${started}] Finish: [${finished}]"
                break
                ;;
            *)
                echo -n "."
                sleep 5
                ;;
        esac
    done
}

REMOTES=(\
https://cdn.redhat.com/content/dist/rhel/server/6/6Server/x86_64/extras/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6Server/x86_64/optional/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6Server/x86_64/supplementary/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/extras/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/optional/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6Server/x86_64/rhscl/1/os \
http://mirror.centos.org/centos-7/7/extras/x86_64/ \
http://mirror.centos.org/centos-7/7/sclo/x86_64/sclo/ \
https://cdn.redhat.com/content/eus/rhel/server/6/6.6/x86_64/optional/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7.7/x86_64/kickstart \
https://cdn.redhat.com/content/dist/rhel8/8.0/x86_64/baseos/kickstart \
https://mirrors.kernel.org/fedora-epel/7/x86_64/ \
https://cdn.redhat.com/content/dist/rhel/server/6/6.7/x86_64/kickstart \
https://cdn.redhat.com/content/eus/rhel/server/6/6.6/x86_64/rhscl/1/os \
https://cdn.redhat.com/content/eus/rhel/server/6/6.6/x86_64/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7.3/x86_64/kickstart \
https://cdn.redhat.com/content/dist/rhel8/8.0/x86_64/appstream/kickstart \
https://cdn.redhat.com/content/eus/rhel/server/7/7.3/x86_64/optional/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.3/x86_64/supplementary/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.3/x86_64/rhscl/1/os \
http://mirror.centos.org/centos-6/6/os/x86_64/ \
https://cdn.redhat.com/content/dist/rhel/server/6/6Server/x86_64/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/ansible/2.5/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/rhgs-server-nfs/3.1/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7.6/x86_64/kickstart \
https://cdn.redhat.com/content/dist/rhel/workstation/7/7.5/x86_64/kickstart \
https://mirrors.kernel.org/fedora-epel/8/Everything/x86_64/ \
https://cdn.redhat.com/content/dist/rhel/workstation/7/7Workstation/x86_64/insights/3/os \
https://cdn.redhat.com/content/dist/rhel/workstation/7/7Workstation/x86_64/optional/os \
https://cdn.redhat.com/content/dist/rhel/workstation/7/7Workstation/x86_64/rh-common/os \
https://cdn.redhat.com/content/dist/rhel/workstation/7/7Workstation/x86_64/os \
https://cdn.redhat.com/content/dist/rhel/workstation/7/7Workstation/x86_64/extras/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/rh-gluster-samba/3.1/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/rhgs-server/3.1/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6.10/x86_64/kickstart \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/rhgs-nagios/3.1/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/rhscon-agent/2/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/rhscon-installer/2/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/rhscon-main/2/os \
http://mirror.centos.org/centos-6/6/updates/x86_64/ \
https://cdn.redhat.com/content/dist/rhel/server/6/6Server/x86_64/rhs-client/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/rhs-client/os \
http://mirror.centos.org/centos-7/7/sclo/x86_64/rh/ \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/supplementary/os \
https://cdn.redhat.com/content/dist/rhel/workstation/7/7Workstation/x86_64/rhscl/1/os \
https://cdn.redhat.com/content/dist/rhel/workstation/7/7.6/x86_64/kickstart \
http://mirror.centos.org/centos-7/7/updates/x86_64/ \
https://cdn.redhat.com/content/dist/rhel/server/6/6.8/x86_64/kickstart \
https://cdn.redhat.com/content/dist/rhel/server/6/6.9/x86_64/kickstart \
https://cdn.redhat.com/content/eus/rhel/server/6/6.6/x86_64/sat-tools/6.2/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/rhscl/1/os \
http://mirror.centos.org/centos-7/7/os/x86_64/ \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/ansible/2.7/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.3/x86_64/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.6/x86_64/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7.4/x86_64/kickstart \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/sat-maintenance/6/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7.5/x86_64/kickstart \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/rhgs-server-bigdata/3.1/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/rhgs-server-splunk/3.1/os \
https://cdn.redhat.com/content/dist/rhel/workstation/7/7Workstation/x86_64/supplementary/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/ansible/2.6/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/dotnet/1/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6.10/x86_64/optional/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7Server/x86_64/sat-tools/6.5/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.5/x86_64/sat-tools/6.5/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7.7/x86_64/optional/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7.4/x86_64/optional/os \
https://cdn.redhat.com/content/eus/rhel/server/6/6.7/x86_64/supplementary/os \
https://cdn.redhat.com/content/eus/rhel/server/6/6.7/x86_64/optional/os \
https://cdn.redhat.com/content/eus/rhel/server/6/6.7/x86_64/rhscl/1/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.5/x86_64/rhscl/1/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.5/x86_64/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6.7/x86_64/optional/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6.10/x86_64/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6.8/x86_64/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6.6/x86_64/os \
https://cdn.redhat.com/content/eus/rhel/server/6/6.7/x86_64/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.5/x86_64/supplementary/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.5/x86_64/sat-tools/6.4/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.5/x86_64/optional/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.3/x86_64/sat-tools/6.4/os \
https://cdn.redhat.com/content/dist/rhel8/8/x86_64/appstream/os \
https://cdn.redhat.com/content/dist/rhel8/8/x86_64/baseos/os \
https://cdn.redhat.com/content/dist/rhel8/8/x86_64/supplementary/os \
https://cdn.redhat.com/content/dist/rhel8/8/x86_64/baseos/kickstart \
https://cdn.redhat.com/content/dist/rhel8/8/x86_64/appstream/kickstart \
https://mirrors.kernel.org/fedora-epel/6Server/x86_64/ \
https://cdn.redhat.com/content/dist/rhel/server/7/7.6/x86_64/optional/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7.3/x86_64/optional/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6.9/x86_64/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6.8/x86_64/optional/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6.7/x86_64/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6.9/x86_64/optional/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7.5/x86_64/optional/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7.2/x86_64/optional/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7.6/x86_64/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7.5/x86_64/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7.3/x86_64/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.6/x86_64/sat-tools/6.5/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.6/x86_64/optional/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/sat-capsule/6.6/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6Server/x86_64/sat-tools/6.6/os \
https://cdn.redhat.com/content/dist/layered/rhel8/x86_64/sat-tools/6.6/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/ansible/2.8/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.6/x86_64/sat-tools/6.6/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7.7/x86_64/os \
https://cdn.redhat.com/content/dist/rhel8/8.1/x86_64/appstream/kickstart \
https://cdn.redhat.com/content/dist/rhel/server/7/7.4/x86_64/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7.2/x86_64/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.6/x86_64/supplementary/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.6/x86_64/rhscl/1/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/sat-tools/6.6/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.5/x86_64/sat-tools/6.6/os \
https://cdn.redhat.com/content/dist/rhel8/8.1/x86_64/baseos/kickstart \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/highavailability/os \
https://packages.vmware.com/tools/releases/10.3.5/rhel6/x86_64/ \
https://cdn.redhat.com/content/dist/rhel/server/7/7.8/x86_64/kickstart \
https://cdn.redhat.com/content/eus/rhel/server/7/7.7/x86_64/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.7/x86_64/supplementary/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.7/x86_64/rhscl/1/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.7/x86_64/optional/os \
https://cdn.redhat.com/content/eus/rhel/server/7/7.7/x86_64/sat-tools/6.6/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/sat-capsule/6.7/os \
https://cdn.redhat.com/content/dist/rhel/server/6/6Server/x86_64/sat-tools/6.7/os \
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/sat-tools/6.7/os \
https://cdn.redhat.com/content/dist/layered/rhel8/x86_64/sat-tools/6.7/os \
https://cdn.redhat.com/content/dist/rhel8/8.2/x86_64/appstream/kickstart \
https://cdn.redhat.com/content/dist/rhel8/8.2/x86_64/baseos/kickstart \
http://mirror.centos.org/centos-8/8/BaseOS/x86_64/os/ \
http://mirror.centos.org/centos-8/8/AppStream/x86_64/os/ \
)

NAMES=(\
cdn.redhat.com_content_dist_rhel_server_6_6Server_x86_64_extras_os \
cdn.redhat.com_content_dist_rhel_server_6_6Server_x86_64_optional_os \
cdn.redhat.com_content_dist_rhel_server_6_6Server_x86_64_supplementary_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_extras_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_optional_os \
cdn.redhat.com_content_dist_rhel_server_6_6Server_x86_64_rhscl_1_os \
mirror.centos.org_centos-7_7_extras_x86_64 \
mirror.centos.org_centos-7_7_sclo_x86_64_sclo \
cdn.redhat.com_content_eus_rhel_server_6_6.6_x86_64_optional_os \
cdn.redhat.com_content_dist_rhel_server_7_7.7_x86_64_kickstart \
cdn.redhat.com_content_dist_rhel8_8.0_x86_64_baseos_kickstart \
mirrors.kernel.org_fedora-epel_7_x86_64 \
cdn.redhat.com_content_dist_rhel_server_6_6.7_x86_64_kickstart \
cdn.redhat.com_content_eus_rhel_server_6_6.6_x86_64_rhscl_1_os \
cdn.redhat.com_content_eus_rhel_server_6_6.6_x86_64_os \
cdn.redhat.com_content_dist_rhel_server_7_7.3_x86_64_kickstart \
cdn.redhat.com_content_dist_rhel8_8.0_x86_64_appstream_kickstart \
cdn.redhat.com_content_eus_rhel_server_7_7.3_x86_64_optional_os \
cdn.redhat.com_content_eus_rhel_server_7_7.3_x86_64_supplementary_os \
cdn.redhat.com_content_eus_rhel_server_7_7.3_x86_64_rhscl_1_os \
mirror.centos.org_centos-6_6_os_x86_64 \
cdn.redhat.com_content_dist_rhel_server_6_6Server_x86_64_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_ansible_2.5_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_rhgs-server-nfs_3.1_os \
cdn.redhat.com_content_dist_rhel_server_7_7.6_x86_64_kickstart \
cdn.redhat.com_content_dist_rhel_workstation_7_7.5_x86_64_kickstart \
mirrors.kernel.org_fedora-epel_8_Everything_x86_64 \
cdn.redhat.com_content_dist_rhel_workstation_7_7Workstation_x86_64_insights_3_os \
cdn.redhat.com_content_dist_rhel_workstation_7_7Workstation_x86_64_optional_os \
cdn.redhat.com_content_dist_rhel_workstation_7_7Workstation_x86_64_rh-common_os \
cdn.redhat.com_content_dist_rhel_workstation_7_7Workstation_x86_64_os \
cdn.redhat.com_content_dist_rhel_workstation_7_7Workstation_x86_64_extras_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_rh-gluster-samba_3.1_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_rhgs-server_3.1_os \
cdn.redhat.com_content_dist_rhel_server_6_6.10_x86_64_kickstart \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_rhgs-nagios_3.1_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_rhscon-agent_2_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_rhscon-installer_2_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_rhscon-main_2_os \
mirror.centos.org_centos-6_6_updates_x86_64 \
cdn.redhat.com_content_dist_rhel_server_6_6Server_x86_64_rhs-client_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_rhs-client_os \
mirror.centos.org_centos-7_7_sclo_x86_64_rh \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_supplementary_os \
cdn.redhat.com_content_dist_rhel_workstation_7_7Workstation_x86_64_rhscl_1_os \
cdn.redhat.com_content_dist_rhel_workstation_7_7.6_x86_64_kickstart \
mirror.centos.org_centos-7_7_updates_x86_64 \
cdn.redhat.com_content_dist_rhel_server_6_6.8_x86_64_kickstart \
cdn.redhat.com_content_dist_rhel_server_6_6.9_x86_64_kickstart \
cdn.redhat.com_content_eus_rhel_server_6_6.6_x86_64_sat-tools_6.2_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_rhscl_1_os \
mirror.centos.org_centos-7_7_os_x86_64 \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_ansible_2.7_os \
cdn.redhat.com_content_eus_rhel_server_7_7.3_x86_64_os \
cdn.redhat.com_content_eus_rhel_server_7_7.6_x86_64_os \
cdn.redhat.com_content_dist_rhel_server_7_7.4_x86_64_kickstart \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_sat-maintenance_6_os \
cdn.redhat.com_content_dist_rhel_server_7_7.5_x86_64_kickstart \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_rhgs-server-bigdata_3.1_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_rhgs-server-splunk_3.1_os \
cdn.redhat.com_content_dist_rhel_workstation_7_7Workstation_x86_64_supplementary_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_ansible_2.6_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_dotnet_1_os \
cdn.redhat.com_content_dist_rhel_server_6_6.10_x86_64_optional_os \
cdn.redhat.com_content_eus_rhel_server_7_7Server_x86_64_sat-tools_6.5_os \
cdn.redhat.com_content_eus_rhel_server_7_7.5_x86_64_sat-tools_6.5_os \
cdn.redhat.com_content_dist_rhel_server_7_7.7_x86_64_optional_os \
cdn.redhat.com_content_dist_rhel_server_7_7.4_x86_64_optional_os \
cdn.redhat.com_content_eus_rhel_server_6_6.7_x86_64_supplementary_os \
cdn.redhat.com_content_eus_rhel_server_6_6.7_x86_64_optional_os \
cdn.redhat.com_content_eus_rhel_server_6_6.7_x86_64_rhscl_1_os \
cdn.redhat.com_content_eus_rhel_server_7_7.5_x86_64_rhscl_1_os \
cdn.redhat.com_content_eus_rhel_server_7_7.5_x86_64_os \
cdn.redhat.com_content_dist_rhel_server_6_6.7_x86_64_optional_os \
cdn.redhat.com_content_dist_rhel_server_6_6.10_x86_64_os \
cdn.redhat.com_content_dist_rhel_server_6_6.8_x86_64_os \
cdn.redhat.com_content_dist_rhel_server_6_6.6_x86_64_os \
cdn.redhat.com_content_eus_rhel_server_6_6.7_x86_64_os \
cdn.redhat.com_content_eus_rhel_server_7_7.5_x86_64_supplementary_os \
cdn.redhat.com_content_eus_rhel_server_7_7.5_x86_64_sat-tools_6.4_os \
cdn.redhat.com_content_eus_rhel_server_7_7.5_x86_64_optional_os \
cdn.redhat.com_content_eus_rhel_server_7_7.3_x86_64_sat-tools_6.4_os \
cdn.redhat.com_content_dist_rhel8_8_x86_64_appstream_os \
cdn.redhat.com_content_dist_rhel8_8_x86_64_baseos_os \
cdn.redhat.com_content_dist_rhel8_8_x86_64_supplementary_os \
cdn.redhat.com_content_dist_rhel8_8_x86_64_baseos_kickstart \
cdn.redhat.com_content_dist_rhel8_8_x86_64_appstream_kickstart \
mirrors.kernel.org_fedora-epel_6Server_x86_64 \
cdn.redhat.com_content_dist_rhel_server_7_7.6_x86_64_optional_os \
cdn.redhat.com_content_dist_rhel_server_7_7.3_x86_64_optional_os \
cdn.redhat.com_content_dist_rhel_server_6_6.9_x86_64_os \
cdn.redhat.com_content_dist_rhel_server_6_6.8_x86_64_optional_os \
cdn.redhat.com_content_dist_rhel_server_6_6.7_x86_64_os \
cdn.redhat.com_content_dist_rhel_server_6_6.9_x86_64_optional_os \
cdn.redhat.com_content_dist_rhel_server_7_7.5_x86_64_optional_os \
cdn.redhat.com_content_dist_rhel_server_7_7.2_x86_64_optional_os \
cdn.redhat.com_content_dist_rhel_server_7_7.6_x86_64_os \
cdn.redhat.com_content_dist_rhel_server_7_7.5_x86_64_os \
cdn.redhat.com_content_dist_rhel_server_7_7.3_x86_64_os \
cdn.redhat.com_content_eus_rhel_server_7_7.6_x86_64_sat-tools_6.5_os \
cdn.redhat.com_content_eus_rhel_server_7_7.6_x86_64_optional_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_sat-capsule_6.6_os \
cdn.redhat.com_content_dist_rhel_server_6_6Server_x86_64_sat-tools_6.6_os \
cdn.redhat.com_content_dist_layered_rhel8_x86_64_sat-tools_6.6_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_ansible_2.8_os \
cdn.redhat.com_content_eus_rhel_server_7_7.6_x86_64_sat-tools_6.6_os \
cdn.redhat.com_content_dist_rhel_server_7_7.7_x86_64_os \
cdn.redhat.com_content_dist_rhel8_8.1_x86_64_appstream_kickstart \
cdn.redhat.com_content_dist_rhel_server_7_7.4_x86_64_os \
cdn.redhat.com_content_dist_rhel_server_7_7.2_x86_64_os \
cdn.redhat.com_content_eus_rhel_server_7_7.6_x86_64_supplementary_os \
cdn.redhat.com_content_eus_rhel_server_7_7.6_x86_64_rhscl_1_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_sat-tools_6.6_os \
cdn.redhat.com_content_eus_rhel_server_7_7.5_x86_64_sat-tools_6.6_os \
cdn.redhat.com_content_dist_rhel8_8.1_x86_64_baseos_kickstart \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_highavailability_os \
packages.vmware.com_tools_releases_10.3.5_rhel6_x86_64 \
cdn.redhat.com_content_dist_rhel_server_7_7.8_x86_64_kickstart \
cdn.redhat.com_content_eus_rhel_server_7_7.7_x86_64_os \
cdn.redhat.com_content_eus_rhel_server_7_7.7_x86_64_supplementary_os \
cdn.redhat.com_content_eus_rhel_server_7_7.7_x86_64_rhscl_1_os \
cdn.redhat.com_content_eus_rhel_server_7_7.7_x86_64_optional_os \
cdn.redhat.com_content_eus_rhel_server_7_7.7_x86_64_sat-tools_6.6_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_sat-capsule_6.7_os \
cdn.redhat.com_content_dist_rhel_server_6_6Server_x86_64_sat-tools_6.7_os \
cdn.redhat.com_content_dist_rhel_server_7_7Server_x86_64_sat-tools_6.7_os \
cdn.redhat.com_content_dist_layered_rhel8_x86_64_sat-tools_6.7_os \
cdn.redhat.com_content_dist_rhel8_8.2_x86_64_appstream_kickstart \
cdn.redhat.com_content_dist_rhel8_8.2_x86_64_baseos_kickstart \
mirror.centos.org_centos-8_8_BaseOS_x86_64_os \
mirror.centos.org_centos-8_8_AppStream_x86_64_os \
)

for r in ${!REMOTES[@]}; do 
  echo ">>>>> " TESTING [${REMOTES[$r]}] INTO [${NAMES[$r]}];
  # create repo
  REPO_HREF=$(http POST :/pulp/api/v3/repositories/rpm/rpm/ name=${NAMES[$r]} | jq -r '.pulp_href')
  echo "repo_href : " $REPO_HREF
  if [ -z "$REPO_HREF" ]; then echo ">>>>> " FAILED REPO; continue; fi

  # create remote
  if  [[ ${NAMES[$r]} == cdn* ]] ; then
    REMOTE_HREF=$(http POST :/pulp/api/v3/remotes/rpm/rpm/ name=${NAMES[$r]} url=${REMOTES[$r]} policy='on_demand' download_concurrency=5 client_cert=@/home/vagrant/devel/pulp_startup/CDN_cert/cdn.crt client_key=@/home/vagrant/devel/pulp_startup/CDN_cert/cdn.key ca_cert=@/home/vagrant/devel/pulp_startup/CDN_cert/redhat-uep.pem | jq -r '.pulp_href')
  else 
    REMOTE_HREF=$(http POST :/pulp/api/v3/remotes/rpm/rpm/ name=${NAMES[$r]} url=${REMOTES[$r]}  policy='on_demand' download_concurrency=5 | jq -r '.pulp_href')
  fi
  ###REMOTE_HREF=$(http :/pulp/api/v3/remotes/rpm/rpm/ | jq -r ".results[] | select(.name == \"${NAMES[$r]}\") | .pulp_href")
  echo "remote_href : " $REMOTE_HREF
  if [ -z "$REMOTE_HREF" ]; then echo FAILED REMOTE; continue; fi

  # sync repo using that remote
  TASK_URL=$(http POST :$REPO_HREF'sync/' remote=$REMOTE_HREF | jq -r '.task')
  echo "Task url : " $TASK_URL
  if [ -z "$TASK_URL" ]; then FAILED TASK; continue; fi
  wait_until_task_finished :$TASK_URL

  echo ""
done


