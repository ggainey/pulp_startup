#!/usr/bin/python
from time import sleep

from pulpcore.client.pulpcore import (
    ApiClient as CoreApiClient,
    Configuration,
    TasksApi
)
from pulpcore.client.pulp_rpm import (
    ApiClient as RpmApiClient,
    ContentAdvisoriesApi,
    Copy,
    RepositoriesRpmApi,
    RemotesRpmApi,
    RpmCopyApi,
    RepositoriesRpmVersionsApi,
    RpmRepositorySyncURL,
    PublicationsRpmApi,
)

configuration = Configuration()
configuration.username = 'admin'
configuration.password = 'password'
configuration.host = 'http://localhost:24817'
configuration.safe_chars_for_path_param = '/'

core_client = CoreApiClient(configuration)
rpm_client = RpmApiClient(configuration)

# Create api clients for all resource types
rpm_repo_api = RepositoriesRpmApi(rpm_client)
rpm_copy_api = RpmCopyApi(rpm_client)
rpm_remote_api = RemotesRpmApi(rpm_client)
rpm_advisories_api = ContentAdvisoriesApi(rpm_client)

tasks_api = TasksApi(core_client)

TEST_ADVISORY = 'RHEA-2012:0056'
entities = {
    "A5": {"url": "http://localhost:8000/rpm-updated-updateversion/", "repo": "", "remote": ""},
    "B5": {"url": "http://localhost:8000/rpm-advisory-diffpkgs/", "repo": "", "remote": ""},
    "DEST5": {"url": "", "repo": "", "remote": ""},
}

advisory_list = []

for name in sorted(entities.keys()):
    print("NAME {}".format(name))
    entities[name]["repo"] = rpm_repo_api.create({'name':name})
    print("REPO {}".format(entities[name]["repo"].pulp_href))
    if name.startswith('DEST'):
        continue
    entities[name]["remote"] = rpm_remote_api.create(
        {'name':name, 
         'url': entities[name]["url"],
         'policy':'immediate'})
    print("REMOTE {}".format(entities[name]["remote"].pulp_href))
    repository_sync_data = RpmRepositorySyncURL(remote=entities[name]["remote"].pulp_href)
    sync_response = rpm_repo_api.sync(entities[name]["repo"].pulp_href, repository_sync_data)

sleep(10)

advisories = rpm_advisories_api.list(id=TEST_ADVISORY)
print("ADVISORIES {}".format(advisories))
advisory_list = [advisory.pulp_href for advisory in rpm_advisories_api.list(id=TEST_ADVISORY).results]
print("ADVISORY_LIST {}".format(advisory_list))

data = {
    "config": [
        {
            "source_repo_version": "{}versions/1/".format(entities["A5"]["repo"].pulp_href),
            "dest_repo": entities["DEST5"]["repo"].pulp_href,
        },
        {
            "source_repo_version": "{}versions/1/".format(entities["B5"]["repo"].pulp_href),
            "dest_repo": entities["DEST5"]["repo"].pulp_href,
        }
    ],
    "dependency_solving": True
}

copy = Copy(config=data["config"], dependency_solving=False)
print("COPY {}".format(copy))
copy_task = rpm_copy_api.create(copy)
#copy_task = rpm_copy_api.create(data)
print(copy_task)
