from pulpcore.client.pulpcore import (
    ApiClient as CoreApiClient,
    Configuration,
    TasksApi
)
from pulpcore.client.pulp_rpm import (
    ApiClient as RpmApiClient,
    ContentPackagesApi,
    RepositoriesRpmApi,
    RemotesRpmApi,
    RepositoriesRpmVersionsApi,
    RpmRepositorySyncURL,
    PublicationsRpmApi,
    DistributionsRpmApi,
)
from pulp_smash.pulp3.bindings import monitor_task


import socket

configuration = Configuration()
configuration.username = 'admin'
configuration.password = 'password'
configuration.host = 'http://{}:24817'.format(socket.gethostname())
configuration.safe_chars_for_path_param = '/'

core_client = CoreApiClient(configuration)
rpm_client = RpmApiClient(configuration)

# Create api clients for all resource types
rpm_repo_api = RepositoriesRpmApi(rpm_client)
rpm_repo_versions_api = RepositoriesRpmVersionsApi(rpm_client)
rpm_content_api = ContentPackagesApi(rpm_client)
rpm_remote_api = RemotesRpmApi(rpm_client)
rpm_publication_api = PublicationsRpmApi(rpm_client)
rpm_distributions_api = DistributionsRpmApi(rpm_client)


tasks_api = TasksApi(core_client)

# Sync test
# =========

FIXTURE = "https://fixtures.pulpproject.org/rpm-unsigned/"
FIXTURE_DISTRIBUTION_TREE = "https://fixtures.pulpproject.org/rpm-distribution-tree/"

FEDORA_33_RPMFUSION_URL = "https://download1.rpmfusion.org/free/fedora/releases/33/Everything/x86_64/os/"

CENTOS_7_URL = "http://mirror.centos.org/centos-7/7/os/x86_64/"

CENTOS_8_BASEOS_URL = 'http://mirror.centos.org/centos/8/BaseOS/x86_64/os/'
CENTOS_8_BASEOS_KICKSTART_URL = 'http://mirror.centos.org/centos/8/BaseOS/x86_64/kickstart/'

CENTOS_8_STREAM_BASEOS_URL = "http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/"
CENTOS_8_STREAM_APPSTREAM_URL = "http://mirror.centos.org/centos/8-stream/AppStream/x86_64/os/"

FEDORA_32_RELEASE_URL = 'https://dl.fedoraproject.org/pub/fedora/linux/releases/32/Everything/x86_64/os/'
FEDORA_33_RELEASE_URL = 'https://dl.fedoraproject.org/pub/fedora/linux/releases/33/Everything/x86_64/os/'

ALMA_8_BASEOS_URL = "https://repo.almalinux.org/almalinux/8/BaseOS/x86_64/os/"
ALMA_8_APPSTREAM_URL = "https://repo.almalinux.org/almalinux/8/AppStream/x86_64/os/"

RHEL_6_URL = "https://cdn.redhat.com/content/dist/rhel/server/6/6Server/x86_64/os/"
RHEL_7_URL = "https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/os/"
RHEL_8_BASEOS_URL = "https://cdn.redhat.com/content/dist/rhel8/8/x86_64/baseos/os/"
RHEL_8_APPSTREAM_URL = "https://cdn.redhat.com/content/dist/rhel8/8/x86_64/appstream/os/"

OL7_URL = "http://yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64/"

NVIDIA_CUDA_URL = "https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/"

HPE_RHEL_7 = "http://downloads.linux.hpe.com/SDR/repo/spp/redhat/7/x86_64/current/"
HPE_CENTOS_7 = "http://downloads.linux.hpe.com/SDR/repo/mcp/CentOS/7/x86_64/current/"

LOCAL = "http://localhost:8088/repos/centos7"
LOCAL_FILE = "file:///home/vagrant/devel/repos/centos7"

FEDORA_33_MIRRORLIST = "http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-33&arch=x86_64"

KATELLO_ZOO = "https://github.com/Katello/katello/tree/master/test/fixtures/test_repos/zoo"

RPM_REPO_URL = FIXTURE_DISTRIBUTION_TREE
RPM_REPO_NAME = "test"

rpm_remote = rpm_remote_api.create({'name': RPM_REPO_NAME, 'url': RPM_REPO_URL, 'policy': 'on_demand'})
rpm_repo = rpm_repo_api.create({'name': RPM_REPO_NAME, 'remote': rpm_remote.pulp_href, 'autopublish': True})

rpm_repo = rpm_repo_api.list(name=RPM_REPO_NAME).results[0]
rpm_remote = rpm_remote_api.list(name=RPM_REPO_NAME).results[0]


# RPM_REPO_NAME = "test2"

# rpm_remote2 = rpm_remote_api.create({'name': RPM_REPO_NAME, 'url': RPM_REPO_URL, 'policy': 'on_demand'})
# rpm_repo2 = rpm_repo_api.create({'name': RPM_REPO_NAME, 'remote': rpm_remote.pulp_href, 'autopublish': False})

# rpm_repo2 = rpm_repo_api.list(name=RPM_REPO_NAME).results[0]
# rpm_remote2 = rpm_remote_api.list(name=RPM_REPO_NAME).results[0]
# repository_sync_data = RpmRepositorySyncURL(remote=rpm_remote2.pulp_href, mirror=False)
# sync_response = rpm_repo_api.sync(rpm_repo2.pulp_href, repository_sync_data)


repository_sync_data = RpmRepositorySyncURL(remote=rpm_remote.pulp_href, mirror=True)

sync_response = rpm_repo_api.sync(rpm_repo.pulp_href, repository_sync_data)
task = monitor_task(sync_response.task)
time_diff = task.finished_at - task.started_at
print("Sync time: {} seconds".format(time_diff.seconds))

# resync_response = rpm_repo_api.sync(rpm_repo.pulp_href, repository_sync_data)
# task = monitor_task(resync_response.task)
# time_diff = task.finished_at - task.started_at
# print("Re-sync time: {} seconds".format(time_diff.seconds))

# fedora_repo = rpm_repo_api.create({'name': 'fedora'})

# fedora_repo = rpm_repo_api.list(name='fedora').results[0]
# fedora30_remote = rpm_remote_api.list(name='fedora30').results[0]
# fedora31_remote = rpm_remote_api.list(name='fedora31').results[0]

# repository_sync_data = RpmRepositorySyncURL(remote=fedora30_remote.pulp_href)

# sync_response = rpm_repo_api.sync(fedora_repo.pulp_href, repository_sync_data)
# task = monitor_task(sync_response.task)
# time_diff = task.finished_at - task.started_at
# print("Sync time: {} seconds".format(time_diff.seconds))

# repository_sync_data = RpmRepositorySyncURL(remote=fedora31_remote.pulp_href, mirror=True)

# sync_response = rpm_repo_api.sync(fedora_repo.pulp_href, repository_sync_data)
# task = monitor_task(sync_response.task)
# time_diff = task.finished_at - task.started_at
# print("Sync time: {} seconds".format(time_diff.seconds))


# Publish test
# ============

# publish_response = rpm_publication_api.create({'repository': rpm_repo.pulp_href})
# task = monitor_task(publish_response.task)
# publication_href = task.created_resources[0]

# Distribute test
# ===============

try:
    rpm_distribution = rpm_distributions_api.list(name=RPM_REPO_NAME).results[0]
except IndexError:
    rpm_distribution = rpm_distributions_api.create({
        "base_path": RPM_REPO_NAME,
        "name": RPM_REPO_NAME,
        "repository": rpm_repo.pulp_href
        # "publication": publication_href
    })

