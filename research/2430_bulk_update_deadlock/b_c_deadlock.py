from pulpcore.app.models.content import Artifact, ContentArtifact, RemoteArtifact
from pulp_file.app.models import FileContent, FileRemote
from hashlib import sha256
from django.db import connection, transaction
from multiprocessing import Process, Array
import statistics
from time import time, sleep
import _thread

# build artifacts
# build contentartifacts
# save all
# build RemoteArtifacts, foreach contentartifact
# bulk-save
artifacts = {}  # filename: Artifact
content = {}  # filename: FileContent
contentartifacts = {}  # filename: ContentArtifact

print(">>>BUILDING CONTENT/CA/ARTIFACTS...")
for i in range(5000):
  path = f'/tmp/{i:06d}.txt'
  content_path = f'{i:06d}.txt'
  with open(path, "w") as f:
    f.write(path)
  with open(path, "rb") as f:
    sum256 = sha256(f.read()).hexdigest()
  attrs = {"relative_path": content_path, "digest": sum256}
  fc = FileContent(**attrs)
  fc.save()
  content[path] = fc

  attrs = {"file": path, "sha256": sum256, "size": i}
  a = Artifact(**attrs)
  a.save()
  artifacts[path] = a

# create ContentArtifacts
for k in content.keys():
    attrs = {"content": fc, "relative_path": f'{content[k].relative_path}', "artifact": artifacts[k]}
    ca = ContentArtifact(**attrs)
    ca.save()
    contentartifacts[k] = ca

# create lists of RemoteArtifacts all pointing to the same contentartifacts, but with diff URLs
ra_lists = [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []]
for i in range(len(ra_lists)):
  attrs = {"name": f'FileRemote-{i}', "url": f'file:not-a-remote-{i}.com'}
  a_remote = FileRemote(**attrs)
  a_remote.save()
  for j in contentartifacts.keys():
    attrs = {
        "url": f'{a_remote.url}/{contentartifacts[j].relative_path}',
        "sha256": contentartifacts[j].content.digest,
        "content_artifact": contentartifacts[j],
        "remote": a_remote}
    ra = RemoteArtifact(**attrs)
    ra_lists[i].append(ra)

# DISorder the remoteartifacts
for j in range(len(ra_lists)):  # range(INNER):
  ra_lists[j].sort(key=lambda x: (x.content_artifact.pulp_id), reverse=(j % 2 == 0))


def bulk_doit(ndx, ra_list):
  print(f">>> ENTER {ndx}...")
  connection.close()
  connection.connect()
  RemoteArtifact.objects.bulk_create(ra_list, batch_size=300)
  print(f">>> EXIT {ndx}...")

processes = []
# Assign each list of RemoteArtifacts to its own process
for j in range(len(ra_lists)):  # range(INNER):
  p = Process(target=bulk_doit, args=(j, ra_lists[j],))
  processes.append(p)
  p.start()

sleep(3)
# Now bulk_create them all at the same time
for p in processes:
  p.join()
