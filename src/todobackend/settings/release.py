from base import *
import os

# Disable debug
if os.environ.get('DEBUG'):
    DEBUG = True
else:
    DEBUG = False

# Must be explicitly specified when Debug is disabled
ALLOWED_HOSTS = [os.environ.get('ALLOWED_HOST', '*')]


DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': os.environ.get('MYSQL_DATABASE', 'todobackend'),
        'USER': os.environ.get('MYSQL_USER', 'todo'),
        'PASSWORD': os.environ.get('MYSQL_PASSWORD', 'password'),
        'HOST': os.environ.get('MYSQL_HOST', 'localhost'),
        'PORT': os.environ.get('MYSQL_PORT', '3306'), 
        'OPTIONS': {
            'init_command': "SET sql_mode='STRICT_TRANS_TABLES'"
        }   
    }
}

STATIC_ROOT = os.environ.get('STATIC_ROOT', '/var/www/todobackend/static')
MEDIA_ROOT = os.environ.get('MEDIA_ROOT', '/var/www/todobackend/media')
