from pulpcore.app.models.content import Artifact, ContentArtifact
from pulp_file.app.models import FileContent
from hashlib import sha256
from django.db import connection, transaction
from multiprocessing import Process, Array
import statistics
from time import time, sleep
import _thread

artifacts = {}  # filename: Artifact
content = {}  # filename: FileContent
print(">>>BUILDING CONTENT/CA/ARTIFACTS...")
for i in range(10000):
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

# lists of ContentArtifacts
ca_lists = [[], [], [], [], []]
#ca_lists = [[]]
for k in content.keys():
  for i in range(len(ca_lists)):
    attrs = {"content": fc, "relative_path": f'{i}/{content[k].relative_path}'}
    ca = ContentArtifact(**attrs)
    ca.save()
    ca.artifact = artifacts[k]
    ca_lists[i].append(ca)

# UNTIMED
OUTER=5
INNER=4
def bulk_doit(ca_list):
  print(">>> ENTER...")
  connection.close()
  connection.connect()
  ContentArtifact.objects.bulk_update(ca_list, ["artifact"], batch_size=500)
  print(">>> EXIT...")

for r in range(5):
  print("Try round: %s" % str(r + 1))
  # Ensure there are something to update when rerunning this part
  connection.connect()
  ContentArtifact.objects.filter().update(artifact_id=None)
  processes = []
  for i in range(OUTER):
    for j in range(INNER):
      p = Process(target=bulk_doit, args=(ca_lists[0], ))
      processes.append(p)
      p.start()
    sleep(3)
  for p in processes:
    p.join()


# TIMED
OUTER=5
INNER=len(ca_lists)
durations = Array('d', (OUTER*INNER), lock=False)
def bulk_doit(ca_list, arr, index):
  print(">>> ENTER...")
  connection.close()
  connection.connect()
  start = time()
  ContentArtifact.objects.bulk_update(ca_list, ["artifact"], batch_size=500)
  end = time()
  arr[index] = (end-start)
  print(f">>> EXIT {arr[index]}...")

for r in range(5):
  print("Try round: %s" % str(r + 1))
  # Ensure there are something to update when rerunning this part
  connection.connect()
  ContentArtifact.objects.filter().update(artifact_id=None)
  processes = []
  for i in range(OUTER):
    for j in range(INNER):
      p = Process(target=bulk_doit, args=(ca_lists[j], durations, (j+(i*INNER))))
      processes.append(p)
      p.start()
    sleep(3)
  for p in processes:
    p.join()

print(f'len durations : {len(durations)}')
print("Avg time : {}".format(sum(durations) / len(durations)))
print("Median time : {}".format(statistics.median(durations)))
print("StdDev : {}".format(statistics.stdev(durations)))

len durations : 20
Avg time : 8.919582724571228
Median time : 8.41960322856903
StdDev : 4.554325167261483


# TIMED S-F-U
OUTER=5
INNER=len(ca_lists)
durations = [] #  Array('d', (OUTER*INNER), lock=False)

def bulk_doit(ca_list, arr, index):
  print(">>> ENTER...")
  ids = [k.pulp_id for k in ca_list]
  connection.close()
  connection.connect()
  start = time()
  with transaction.atomic():
    #sub_q = ContentArtifact.objects.filter(pulp_id__in=ids).order_by("pulp_id").select_for_update()
    len(ContentArtifact.objects.filter(pulp_id__in=ids).only("pulp_id").order_by("pulp_id").select_for_update().values_list())
    ContentArtifact.objects.bulk_update(ca_list, ["artifact"], batch_size=500)
  end = time()
  #arr[index] = (end-start)
  print(f">>> EXIT {end-start}...")  # {arr[index]}...")

for r in range(5):
  print("Try round: %s" % str(r + 1))
  # Ensure there are something to update when rerunning this part
  connection.connect()
  ContentArtifact.objects.filter().update(artifact_id=None)
  processes = []
  for i in range(OUTER):
    for j in range(INNER):
      #ca_lists[j].sort(key=lambda x: x.pulp_id)
      p = Process(target=bulk_doit, args=(ca_lists[j], durations, (j+(i*INNER))))
      processes.append(p)
      p.start()
    #sleep(3)
  for p in processes:
    p.join()

print(f'len durations : {len(durations)}')
print("Avg time : {}".format(sum(durations) / len(durations)))
print("Median time : {}".format(statistics.median(durations)))
print("StdDev : {}".format(statistics.stdev(durations)))


##
## Final script
##
from pulpcore.app.models.content import Artifact, ContentArtifact
from pulp_file.app.models import FileContent
from hashlib import sha256
from django.db import connection, transaction
from multiprocessing import Process, Array
import statistics
from time import time, sleep
import _thread

artifacts = {}  # filename: Artifact
content = {}  # filename: FileContent
print(">>>BUILDING CONTENT/CA/ARTIFACTS...")
for i in range(10000):
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

# lists of ContentArtifacts
ca_lists = [[], [], [], [], []]
#ca_lists = [[]]
for k in content.keys():
  for i in range(len(ca_lists)):
    attrs = {"content": fc, "relative_path": f'{i}/{content[k].relative_path}'}
    ca = ContentArtifact(**attrs)
    ca.save()
    ca.artifact = artifacts[k]
    ca_lists[i].append(ca)

OUTER=5
INNER=len(ca_lists)

def bulk_doit(ca_list):
  print(">>> ENTER...")
  ids = [k.pulp_id for k in ca_list]
  connection.close()
  connection.connect()
  start = time()
  with transaction.atomic():
    subq =  ContentArtifact.objects.filter(pulp_id__in=ids).only("pulp_id").order_by("pulp_id").select_for_update()
    len(
        ContentArtifact.objects.filter(pk__in=subq)
        .values_list()
    )
    ContentArtifact.objects.bulk_update(ca_list, ["artifact"], batch_size=500)
    #len(ContentArtifact.objects.filter(pulp_id__in=ids).only("pulp_id").order_by("pulp_id").select_for_update().values_list())
    #ContentArtifact.objects.bulk_update(ca_list, ["artifact"], batch_size=500)
  end = time()
  print(f">>> EXIT {end-start}...")

for r in range(5):
  print("Try round: %s" % str(r + 1))
  # Ensure there are something to update when rerunning this part
  connection.connect()
  ContentArtifact.objects.filter().update(artifact_id=None)
  processes = []
  for i in range(OUTER):
    for j in range(INNER):
      p = Process(target=bulk_doit, args=(ca_lists[j],))
      processes.append(p)
      p.start()
    sleep(3)
  for p in processes:
    p.join()
