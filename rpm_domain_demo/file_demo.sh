#!/usr/bin/bash
U1_PWD="i123456789!"
pulp user role-assignment add --username U1 --role "file.admin" --domain D1
pulp user role-assignment add --username U1 --domain D1 --role "file.filerepository_creator"
pulp user role-assignment add --username U1 --domain D1 --role "file.filerepository_owner"
pulp user role-assignment add --username U1 --domain D1 --role "file.fileremote_creator"
pulp user role-assignment add --username U1 --domain D1 --role "file.fileremote_owner"
pulp user role-assignment add --username U1 --domain D1 --role "file.filepublication_creator"
pulp user role-assignment add --username U1 --domain D1 --role "file.filepublication_owner"
pulp user role-assignment add --username U1 --domain D1 --role "file.filedistribution_creator"
pulp user role-assignment add --username U1 --domain D1 --role "file.filedistribution_owner"
pulp --username U1 --password ${U1_PWD} --domain D1 file remote create --name file --url https://fixtures.pulpproject.org/file/PULP_MANIFEST
pulp --username U1 --password ${U1_PWD} --domain D1 file repository create --name file --remote file
pulp --username U1 --password ${U1_PWD} --domain D1 file repository sync --name file
pulp --username U1 --password ${U1_PWD} --domain D1 file publication create --repository file
pulp --username U1 --password ${U1_PWD} --domain D1 file distribution  create --repository file --name file --base-path file
http :5001/pulp/content/D1/
http :5001/pulp/content/D1/file/
curl -o 1.iso http://localhost:5001/pulp/content/D1/file/1.iso
