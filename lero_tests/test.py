#!/usr/bin/env python3

import sys
import os
import pprint
import csv
import logging
import redis
import json
import subprocess

from yaml import load
try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader

sys.path.append(os.path.dirname(os.path.abspath(__file__)) + '/modules')
from katelloerrata.katelloerrata import katelloErrata
from katelloerrata.katello import Katello

# Define some variables
all_erratas = []
all_repositories = {}

if __name__ == '__main__':
    nb_errata = 0

    # Configure PP object
    pp = pprint.PrettyPrinter(indent=2)

    # Create the logger object
    logger = logging.getLogger()
    # Set logger level to DEBUG
    logger.setLevel(logging.DEBUG)

    # Create a formatter object
    formatter = logging.Formatter('%(asctime)s :: %(levelname)s :: %(message)s')

    # Console handler
    steam_handler = logging.StreamHandler()
    steam_handler.setFormatter(formatter)
    steam_handler.setLevel(logging.DEBUG)
    logger.addHandler(steam_handler)

    # Read configuration file
    with open("config.yaml", 'r') as yaml_file:
        conf_data = load(yaml_file, Loader=Loader)
        yaml_file.close()

    ###########################################
    # 1. Read errata's information from Redis #
    ###########################################

    redis_client = redis.StrictRedis(host=conf_data['redis']['server'], port=conf_data['redis']['port'], db=0)
    for errata_id in redis_client.scan_iter(match='CE*'):
        local_errata = katelloErrata(errata_id.decode('utf-8'))
        errata_redis_data = json.loads(redis_client.get(errata_id).decode('utf-8'))
        local_errata.bulk_create(errata_redis_data)
        all_erratas.append(local_errata)
        nb_errata += 1
    logger.info('Number of errata loaded from Redis %d' % nb_errata)

    #############################################################
    # 2. Get data for repositories listed in configuration file #
    #############################################################

    logger.info('Check that all specified repositories in config file really exist in Katello...')
    # Create the Katello object
    katello = Katello({'conf_file': 'config.yaml'})

    # First, get all repositories present in Katello and filter them
    # to keep only the ones defined in the configuration file
    katello_repositories = katello.get_repositories()
    for conf_repo in conf_data['repositories']:
        repo_found = False
        for kat_repo in katello_repositories['results']:
            if conf_repo == kat_repo['label']:
                repo_found = True
                break
        if repo_found is False:
            logger.info("%s doesn't exits in Katello/Satellite" % conf_repo)
            sys.exit(1)

    logger.info('Get repositories information from Katello/Satellite and configuration file...')
    # Get repositories information from Katello/Satellite and configuration file
    for repo in katello_repositories['results']:
        if repo['label'] not in conf_data['repositories']:
            logger.info("Repository %s skipped, not in the configuration file" % repo['label'])
            continue
        if conf_data['repositories'][repo['label']]['os_release'] not in all_repositories:
            all_repositories[conf_data['repositories'][repo['label']]['os_release']] = {}
        all_repositories[conf_data['repositories'][repo['label']]['os_release']][repo['label']] = {}
        all_repositories[conf_data['repositories'][repo['label']]['os_release']][repo['label']]['id'] = repo['id']
        all_repositories[conf_data['repositories'][repo['label']]['os_release']][repo['label']]['checksumType'] = katello.get_repository_details(repo['id'])['checksum_type']
        all_repositories[conf_data['repositories'][repo['label']]['os_release']][repo['label']]['pulp'] = conf_data['repositories'][repo['label']]['pulp_id']
    # pp.pprint(katello_repositories['results'])

    #############################################################
    # 3. Get errata packages data for the selected repositories #
    #############################################################

    logger.info('Get errata packages data for the selected repositories...')
    for repo_release in all_repositories:
        for repo in all_repositories[repo_release]:
            all_repositories[repo_release][repo]['packages'] = {}
            all_repositories[repo_release][repo]['packages_set'] = []
            all_repositories[repo_release][repo]['nb_erratas'] = 0
            all_repositories[repo_release][repo]['erratas'] = []

            # Get all erratas
            erratas = katello.get_repository_erratas(all_repositories[repo_release][repo]['id'])
            for errata in erratas['results']:
                all_repositories[repo_release][repo]['erratas'].append(errata['errata_id'])

            # Get all packages
            rpms = katello.get_repository_packages(all_repositories[repo_release][repo]['id'])
            for rpm in rpms['results']:
                all_repositories[repo_release][repo]['packages'][rpm['filename'].replace('Packages/', '')] = {
                    'version': rpm['version'],
                    'release': rpm['release'],
                    'epoch': rpm['epoch'],
                    'arch': rpm['arch'],
                    'checksum': rpm['checksum'],
                    'name': rpm['name'],
                    'filename': rpm['filename'].replace('Packages/', ''),
                    'nvra': rpm['nvra'],
                    'nvrea': rpm['nvrea'],
                }
                all_repositories[repo_release][repo]['packages_set'].append(rpm['filename'].replace('Packages/', ''))
                #all_repositories[repo_release][repo]['packages_set'].append(rpm['filename'])
                #print(all_repositories[repo_release][repo]['packages_set'])
                #print(all_repositories[repo_release][repo]['packages'][rpm['filename'])
    # pp.pprint(all_repositories)
    # sys.exit(0)

    #########################
    # 4. Create the  errata #
    #########################

    # Loop over all errata to create them in Katello
    # For each repository, we are checking if the errata's packages matching the os release
    # are present in the repository

    for errata in all_erratas:
        logger.debug("Processing errata %s" % errata.errata_id)

        pkg_found = False
        errata_packages_details = {'packages': []}
        # Loop over all os release
        for repository_release in all_repositories:
            logger.debug("Working on OS release %d" % repository_release)
            # Get errata's packages matching the os release of the current repository
            errata_packages = errata.get_packages_for_os_release(repository_release)
            logger.debug("Packages list for errata %s for OS release %d: %s" % (errata.errata_id, repository_release, errata_packages))
            if errata_packages is not None:
                # Loop over all repositories for a given os release
                for repository_label in all_repositories[repository_release]:
                    logger.debug("Working on repository %s" % repository_label)

                    if errata.errata_id in all_repositories[repository_release][repository_label]['erratas']:
                        logger.debug("Skipping errata %s (already present)" % errata.errata_id)
                        break

                    for errataPkg in errata_packages:
                        if errataPkg in all_repositories[repository_release][repository_label]['packages_set']:
                            pkg_found = True
                            # print('%s found in %s' % (errataPkg, repository_label))
                            errata_packages_details['packages'].append(all_repositories[repository_release][repository_label]['packages'][errataPkg])
                    if pkg_found is True:
                        errata_packages_details['repository_label'] = repository_label
                        all_repositories[repository_release][repository_label]['nb_erratas'] += 1
                        break
                if pkg_found is True:
                    errata_packages_details['repository_release'] = repository_release
                    break
        if pkg_found is True:
            pkglist = []
            packages = []

            for p in errata_packages_details['packages']:
                packages.append({'arch': p['arch'], 
                                 'epoch': p['epoch'],
                                 'filename': p['filename'],
                                 'release': p['release'],
                                 'name': p['name'],
                                 'sum': p['checksum'],
                                 'sum_type': 'sha256'})

            pkglist.append({'packages': packages})

            references = []
            for ref in errata.get_references():
                references.append({'href': ref,
                                   'ref_id': errata.errata_id,
                                   'title': errata.get_synopsis(),
                                   'ref_type': errata.get_errata_type()})
           
            bla = {
              "title": errata.get_synopsis(),
              "type": errata.get_errata_type(),
              "description": errata.get_description(),
              "release": 'el' + str(errata_packages_details['repository_release']),
              "version": str(errata.get_release()),
              "severity": errata.get_severity(),
              "status": "final",
              "updated": errata.get_issue_date(),
              "issued": errata.get_issue_date(),
              "pkglist": pkglist,
              "id": errata.get_errata_id(),
              "from": errata.get_email(),
              "references": references
            }

            references_file = "/tmp/bla/" + errata.errata_id
            with open(references_file, 'w') as outfile:
                json.dump(bla, outfile)

            #print(bla)
            repo_id=all_repositories[errata_packages_details['repository_release']][errata_packages_details['repository_label']]['pulp']
            repo='repository=/pulp/api/v3/repositories/rpm/rpm/{}/'.format(repo_id)
            #print(repo)

            http_cmd = []
            http_cmd.append('http')
            http_cmd.append('--cert')
            http_cmd.append('/etc/pki/katello/certs/pulp-client.crt')
            http_cmd.append('--cert-key')
            http_cmd.append('/etc/pki/katello/private/pulp-client.key')
            http_cmd.append('-a')
            http_cmd.append('admin:ler0ler0')
            http_cmd.append('--form')
            http_cmd.append('POST')
            http_cmd.append('https://katello.local.int/pulp/api/v3/content/rpm/advisories/')
            http_cmd.append('file@{}'.format(references_file))
            http_cmd.append(repo)
            print(http_cmd)

            subprocess.call(http_cmd)

    for repo_release in all_repositories:
        for repo in all_repositories[repo_release]:
            logger.info("%s errata(s) added to %s" % (all_repositories[repo_release][repo]['nb_erratas'], repo))
            logger.info("Start the synchonization for %s" % repo)
            res = katello.start_repo_sync(all_repositories[repo_release][repo]['id'])
            logger.info("Task id: %s, started at: %s, state: %s" % (res['id'], res['started_at'], res['state']))
