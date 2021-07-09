#!/bin/bash

ZOO_URL="https://fixtures.pulpproject.org/rpm-signed/"
RPM_NAME="zoo-1"
pulp rpm remote create --name $RPM_NAME --url $ZOO_URL --policy immediate
pulp rpm repository create --name $RPM_NAME --remote $RPM_NAME
pulp rpm repository sync --name $RPM_NAME

ISO_URL="https://fixtures.pulpproject.org/file/PULP_MANIFEST"
FILE_NAME="iso-1"
pulp file remote create --name $FILE_NAME --url $ISO_URL --policy immediate
pulp file repository create --name $FILE_NAME --remote $FILE_NAME
pulp file repository sync --name $FILE_NAME
