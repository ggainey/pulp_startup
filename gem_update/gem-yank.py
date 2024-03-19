import requests
from time import sleep


def get_gem_versions(gem_name):
    url = f"https://rubygems.org/api/v1/versions/{gem_name}.json"
    response = requests.get(url)
    response.raise_for_status()
    return response.json()


def delete_dev_versions(gem_name, versions):
    for version in versions:
        if '.dev' in version['number']:
            delete_version(gem_name, version['number'])
            sleep(5)

def delete_version(gem_name, version):
    url = f"https://rubygems.org/api/v1/gems/yank"

    headers = {
        'Authorization': 'rubygems_fffffffffffffffffffffffffffffffffffffffffffffffff',
    }

    data = {
        'gem_name': gem_name,
        'version': version,
    }

    response = requests.delete(url, headers=headers, data=data)

    if response.status_code == 200:
        print(f"Deleted version {version} of {gem_name}")
    elif response.status_code == 429:
        print(f"Failed to delete version {version} of {gem_name}. Status code: {response.status_code}")
        sleep(310)
        delete_version(gem_name, version)



def main():
    #gem_name = input("Enter the name of the gem: ")
    gem_name = "pulp_rpm_client"
    versions = get_gem_versions(gem_name)

    if versions:
        delete_dev_versions(gem_name, versions)
    else:
        print(f"No versions found for {gem_name}")


if __name__ == "__main__":
    main()


