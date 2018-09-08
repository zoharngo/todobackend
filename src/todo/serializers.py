# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from rest_framework import serializers
from todo.models import TodoItem 

class TdoItemSerialize(serializers.HyperlinkedModelSerializer):
    url = serializers.ReadOnlyField()
    class Meta:
        model = TodoItem
        fields = ('url', 'title', 'completed' , 'order') 