# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from todo.models import TodoItem
from todo.serializers import TdoItemSerialize
from rest_framework import status
from rest_framework import viewsets
from rest_framework.reverse import reverse
from rest_framework.decorators import list_route
from rest_framework.response import Response

class TodoItemViewSet(viewsets.ModelViewSet):
    queryset = TodoItem.objects.all()
    serializer_class  = TdoItemSerialize

    # Save instance to get primery key and then update URL
    def perform_create(self, serialzer):
        instance = serialzer.save()
        instance.url = reverse('todoitem-detail', args=[instance.pk], request = self.request)
        instance.save()

    # Delete all todo items 
    def delete(self, request):
        TodoItem.objects.all().delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
