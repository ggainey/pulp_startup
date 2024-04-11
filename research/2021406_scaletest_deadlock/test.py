import uuid
from django.db import models
from django_lifecycle import LifecycleModel


class TestModel(LifecycleModel):
    pulp_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    timestamp_of_interest = models.DateTimeField(auto_now=True)
