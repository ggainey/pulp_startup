pulp file repository create --name "fileA"
pulp file repository create --name "fileB"
pulp file remote create --name fileA --url https://fixtures.pulpproject.org/file/PULP_MANIFESTpulp file repository sync --name fileA --remote fileA
for fhref in `pulp file content list | jq -r '.[] | .pulp_href'`; do echo $fhref; a_str=`pulp file content show --href $fhref | jq -r '{"sha256": .sha256 , "relative_path": .relative_path}'`; echo $a_str; done
# pulp file repository add --name fileB --sha256 ... --relative-path ...
pulp exporter pulp create --name fileB --path /tmp/exports --repository fileB file
pulp export pulp run --exporter fileB --versions fileB file 1
