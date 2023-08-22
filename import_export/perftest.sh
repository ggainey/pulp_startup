# One large repo
pulp file remote create --name huge --policy immediate --url https://fixtures.pulpproject.org/file-perf/PULP_MANIFEST
pulp file repository create --name huge --remote huge
pulp file repository sync --name huge
pulp exporter pulp create --name huge --repository file:file:huge --path /tmp/huge
pulp export pulp run --exporter huge

# new code
"started_at": "2023-07-27T18:57:22.437363Z",
"finished_at": "2023-07-27T18:58:43.106329Z" : 1m23s
# ls -lh /tmp/huge/export-018998b6-780c-7998-8b7c-d84b4c3807b1-20230727_1857.tar.gz
-rw-r--r--. 1 pulp pulp 9.0M Jul 27 18:58 /tmp/huge/export-018998b6-780c-7998-8b7c-d84b4c3807b1-20230727_1857.tar.gz

# current code
"started_at": "2023-07-27T19:06:48.229384Z",
"finished_at": "2023-07-27T19:08:04.856740Z" : 1m16s
# ls -lh /tmp/huge/export-018998bf-1a2c-7447-a602-ee706c78ea8f-20230727_1906.tar.gz
-rw-r--r--. 1 pulp pulp 9.0M Jul 27 19:08 /tmp/huge/export-018998bf-1a2c-7447-a602-ee706c78ea8f-20230727_1906.tar.gz


# 10 large repos
pulp file remote create --name huge --policy immediate --url https://fixtures.pulpproject.org/file-perf/PULP_MANIFEST
for r in {0..9}; do \
  pulp file repository create --name "huge-${r}" --remote huge \
  HREF=(pulp -b file repository sync --name "huge-${r}" |& grep /pulp/api | cut -d " " -f 4) \
done
pulp task show --wait --href "${HREF}"
REPOS=""
for r in {0..9}; do REPOS="${REPOS} --repository=file:file:huge-${r}"; done
# the insert of REPOS below doesn't quite work ,but you get the idea...
pulp exporter pulp create --name ten-huge "${REPOS}" --path /tmp/ten-huge
pulp export pulp run --exporter ten-huge


# current code
"started_at": "2023-07-27T20:14:54.541848Z",
"finished_at": "2023-07-27T20:28:48.689774Z" : 13m50s
# ls -lh /tmp/ten-huge/export-018998fd-745b-7ceb-83bd-1fd6dce392fa-20230727_2014.tar.gz
-rw-r--r--. 1 pulp pulp 91M Jul 27 20:28 /tmp/ten-huge/export-018998fd-745b-7ceb-83bd-1fd6dce392fa-20230727_2014.tar.gz


# new code
# newer, working, code
"started_at": "2023-07-27T21:43:07.628458Z",
"finished_at": "2023-07-27T21:54:09.973836Z" : 11m02s
ls -lh /tmp/ten-huge/export-0189994e-3875-7dc8-ab04-012809ea93ca-20230727_2143.tar.gz
-rw-r--r--. 1 pulp pulp 31M Jul 27 21:54 /tmp/ten-huge/export-0189994e-3875-7dc8-ab04-012809ea93ca-20230727_2143.tar.gz


IMPORT SIDE, current code
    "progress_reports": [
        {
            "code": "import.artifacts",
            "done": 200000,
            "message": "Importing Artifacts",
            "state": "completed",
            "suffix": null,
            "total": null
        }
"started_at": "2023-07-28T00:42:33.966652Z",
"finished_at": "2023-07-28T01:05:34.281462Z" : 63m01s

IMPORT SIDE, new code:
    "progress_reports": [
        {
            "code": "import.artifacts",
            "done": 20000,
            "message": "Importing Artifacts",
            "state": "completed",
            "suffix": null,
            "total": null
        }
"started_at": "2023-07-28T01:11:03.498821Z",
"finished_at": "2023-07-28T01:13:24.435164Z" : 2m21s (!!!!)



new-less-new code
  "started_at": "2023-07-31T15:45:56.171352Z",
  "finished_at": "2023-07-31T15:55:49.231216Z",  9m53s
