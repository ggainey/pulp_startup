import os
import requests
from time import sleep


def get_gem_versions(gem_name):
    print(f'GEM {gem_name}', flush=True)
    url = f"https://rubygems.org/api/v1/versions/{gem_name}.json"
    response = requests.get(url)
    response.raise_for_status()
    return response.json()


def delete_dev_versions(gem_name, versions):
    for version in versions:
        print(f'VERSION {version["number"]}', flush=True)
        if '.dev' in version['number']:
            delete_version(gem_name, version['number'])
            sleep(5)

def delete_version(gem_name, version):
    print(f'...DELETING {gem_name}-{version}', flush=True)

    url = f"https://rubygems.org/api/v1/gems/yank"
    api_token = os.getenv("RUBYGEMS_API_TOKEN")

    headers = {
        'Authorization': api_token,
    }

    data = {
        'gem_name': gem_name,
        'version': version,
    }

    response = requests.delete(url, headers=headers, data=data)


    if response.status_code == 200:
        print(f"Deleted version {version} of {gem_name}", flush=True)
    elif response.status_code == 429:
        print(f"Failed to delete version {version} of {gem_name}. Status code: {response.status_code}", flush=True)
        sleep(310)
        delete_version(gem_name, version)



def main():
    gem_name = input("Enter the name of the gem: ")
    all_names = ["pulp_rpm_client", "pulpcore_client", "pulp_file_client", "pulp_maven_client", "pulp_ansible_client", "pulp_docker_client", "pulp_deb_client", "pulp_container_client", "pulp_certguard_client", "pulp_npm_client", "pulp_python_client", "pulp_ostree_client", "pulp_cookbook_client", "pulp_gem_client"]
    remaining_names = ["pulp_ansible_client", "pulp_docker_client", "pulp_deb_client", "pulp_container_client", "pulp_certguard_client", "pulp_npm_client", "pulp_python_client", "pulp_ostree_client", "pulp_cookbook_client"]

    versions = get_gem_versions(gem_name)

    if versions:
        delete_dev_versions(gem_name, versions)
    else:
        print(f"No versions found for {gem_name}", flush=True)


if __name__ == "__main__":
    main()


