# Django settings for pocketgenome project.
from datetime import timedelta
import os

PRODUCTION = 'MONGOLAB_URI' in os.environ
CODE_ROOT = 'C:/Uni/GeneG/GeneG/'

BASE_URL = 'http://dev.empeeric.com/'

if PRODUCTION:
    BASE_URL = 'http://geneg.herokuapp.com/'

DEBUG = True
TEMPLATE_DEBUG = DEBUG

ADMINS = (
    # ('Your Name', 'your_email@example.com'),
)

MANAGERS = ADMINS

import urlparse
if PRODUCTION:
    _DB_PARAMS = urlparse.urlparse(os.environ['MONGOLAB_URI'].replace('mongodb', 'http'))
    DATABASES = {
        'default': {
            'ENGINE': 'django_mongodb_engine',
            'NAME': _DB_PARAMS[2][1:],
            'USER': _DB_PARAMS.username,
            'PASSWORD': _DB_PARAMS.password,
            'HOST': _DB_PARAMS.hostname,
            'PORT': _DB_PARAMS.port,
        }
    }
else:
    DATABASES = {
        'default': {
            'ENGINE': 'django_mongodb_engine',
            'NAME': 'geneg',
            'USER': '',
            'PASSWORD': '',
            'HOST': 'localhost',
            'PORT': 27017,
        }
    }

# Local time zone for this installation. Choices can be found here:
# http://en.wikipedia.org/wiki/List_of_tz_zones_by_name
# although not all choices may be available on all operating systems.
# On Unix systems, a value of None will cause Django to use the same
# timezone as the operating system.
# If running in a Windows environment this must be set to the same as your
# system time zone.
TIME_ZONE = 'America/Chicago'

# Language code for this installation. All choices can be found here:
# http://www.i18nguy.com/unicode/language-identifiers.html
LANGUAGE_CODE = 'en-us'

SITE_ID=u'4ee7dc145c5aac0a80000019'

MESSAGE_STORAGE = 'django.contrib.messages.storage.cookie.CookieStorage'


HTTP_BASE_URL = 'dev.empeeric.com/'

# If you set this to False, Django will make some optimizations so as not
# to load the internationalization machinery.
USE_I18N = True

# If you set this to False, Django will not format dates, numbers and
# calendars according to the current locale
USE_L10N = True

# Absolute filesystem path to the directory that will hold user-uploaded files.
# Example: "/home/media/media.lawrence.com/"
MEDIA_ROOT = '/media/'

# URL that handles the media served from MEDIA_ROOT. Make sure to use a
# trailing slash if there is a path component (optional in other cases).
# Examples: "http://media.lawrence.com", "http://example.com/media/"
MEDIA_URL = '/media/'

# Absolute path to the directory static files should be collected to.
# Don't put anything in this directory yourself; store your static files
# in apps' "static/" subdirectories and in STATICFILES_DIRS.
# Example: "/home/media/media.lawrence.com/static/"
STATIC_ROOT = '/static/'

if not PRODUCTION:
    STATIC_ROOT = CODE_ROOT + STATIC_ROOT

# URL prefix for static files.
# Example: "http://media.lawrence.com/static/"
STATIC_URL = '/static/'

# URL prefix for admin static files -- CSS, JavaScript and images.
# Make sure to use a trailing slash.
# Examples: "http://foo.com/static/admin/", "/static/admin/".
ADMIN_MEDIA_PREFIX = '/static/admin/'

# Additional locations of static files
STATICFILES_DIRS = (
    # Put strings here, like "/home/html/static" or "C:/www/django/static".
    # Always use forward slashes, even on Windows.
    # Don't forget to use absolute paths, not relative paths.
)

# List of finder classes that know how to find static files in
# various locations.
STATICFILES_FINDERS = (
    'django.contrib.staticfiles.finders.FileSystemFinder',
    'django.contrib.staticfiles.finders.AppDirectoriesFinder',
#    'django.contrib.staticfiles.finders.DefaultStorageFinder',
)

# Make this unique, and don't share it with anybody.
SECRET_KEY = 'l#7i=9a66_y90y&8fc22mi5q%=)_9foy9w5)@$_#=8g=5$c3s7'

# List of callables that know how to import templates from various sources.
TEMPLATE_LOADERS = (
    'django.template.loaders.filesystem.Loader',
    'django.template.loaders.app_directories.Loader',
#     'django.template.loaders.eggs.Loader',
)

MIDDLEWARE_CLASSES = (
	'mediagenerator.middleware.MediaMiddleware',
 #   'django.middleware.common.CommonMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
 #   'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
)

ROOT_URLCONF = 'GeneG.urls'

TEMPLATE_DIRS = (
	'server/templates/',
    # Put strings here, like "/home/html/django_templates" or "C:/www/django/templates".
    # Always use forward slashes, even on Windows.
    # Don't forget to use absolute paths, not relative paths.
)

INSTALLED_APPS = (
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sites',
    'django.contrib.sessions',
    'django.contrib.admin',
    'django_mongodb_engine',
    'djangotoolbox',
    'server',
	'tastypie',
	'mediagenerator',
    'djcelery',
#    'djkombu',

    # Uncomment the next line to enable admin documentation:
    # 'django.contrib.admindocs',
)

MEDIA_DEV_MODE = not PRODUCTION
DEV_MEDIA_URL = '/devmedia/'
PRODUCTION_MEDIA_URL = '/media/'

GLOBAL_MEDIA_DIRS = (os.path.join(os.path.dirname(__file__), 'static'),)

COPY_MEDIA_FILETYPES = ('gif', 'jpg', 'jpeg', 'png', 'svg', 'svgz',
                        'ico', 'swf', 'ttf', 'otf', 'eot','mp3')

_base_css_bundle = (
    'css/reset.css',
    'css/design.css',
    )

MEDIA_BUNDLES = (
    ('main.css',) + _base_css_bundle,
    ('main-ie.css',) + _base_css_bundle + ('css/ie.css',),
    ('main.js',
        'js/jquery-1.7.1.min.js',
        'js/jquery.cookie.js',
        'js/jquery.jqote2.js',
        'js/main.js',
        'js/dialogs.js',
        'js/templates.js',
    ),
)

ROOT_MEDIA_FILTERS = {
    'js': 'mediagenerator.filters.yuicompressor.YUICompressor',
    'css': 'mediagenerator.filters.yuicompressor.YUICompressor',
}

YUICOMPRESSOR_PATH = os.path.join(os.pardir,'tools','yuicompressor.jar')
								  
# A sample logging configuration. The only tangible logging
# performed by this configuration is to send an email to
# the site admins on every HTTP 500 error.
# See http://docs.djangoproject.com/en/dev/topics/logging for
# more details on how to customize your logging configuration.
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'mail_admins': {
            'level': 'ERROR',
            'class': 'django.utils.log.AdminEmailHandler'
        }
    },
    'loggers': {
        'django.request': {
            'handlers': ['mail_admins'],
            'level': 'ERROR',
            'propagate': True,
        },
    }
}
EMAIL_HOST_USER = 'peeri.empeeric@gmail.com'

EMAIL_HOST = 'smtp.gmail.com'

EMAIL_HOST_PASSWORD = 'peeriempeeri'

EMAIL_PORT = 587

EMAIL_USE_TLS = True

SERVER_EMAIL = EMAIL_HOST_USER

DEFAULT_FROM_EMAIL = EMAIL_HOST_USER

LOGIN_URL = '/login/'

REGISTER_URL = '/register/'

LOGIN_REDIRECT_URL = '/'

#Storage
DEFAULT_FILE_STORAGE = 'storages.backends.s3boto.S3BotoStorage'
AWS_ACCESS_KEY_ID = 'AKIAIK5YCK53XZM33RPA'
AWS_SECRET_ACCESS_KEY = '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'
AWS_STORAGE_BUCKET_NAME = 'geneg-genomes'
#AWS_S3_CUSTOM_DOMAIN = 'd1hg4pg1k1dk6u.cloudfront.net'



#AWS_ACCESS_KEY_ID = 'AKIAIK5YCK53XZM33RPA'

#AWS_SECRET_ACCESS_KEY = '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'

#AWS_URL = 'https://s3-bucket.s3.amazonaws.com'

AUTH_PROFILE_MODULE = 'server.UserProfile'

import djcelery
djcelery.setup_loader()
BROKER_URL = 'redis://redistogo:02045d854b5940530480ed33e8f106ae@dogfish.redistogo.com:9517/'
if not PRODUCTION:
    BROKER_URL = 'redis://localhost:6379/'

#BROKER_BACKEND = "djkombu.transport.DatabaseTransport"
CELERY_RESULT_BACKEND = 'mongodb'
CELERY_MONGODB_BACKEND_SETTINGS = {
    "host": DATABASES['default']['HOST'],
    "port": DATABASES['default']['PORT'],
    "database": DATABASES['default']['NAME'],
    "taskmeta_collection": "taskmeta",
    }
#CELERY_RESULT_DBURI = DATABASES['default']

CELERY_IMPORTS = ("server.tasks", )

CELERYBEAT_SCHEDULER = 'djcelery.schedulers.DatabaseScheduler'

#CELERYBEAT_SCHEDULE = {
#    "runs-every-3-seconds": {
#        "task": "server.tasks.say_hello",
#        "schedule": timedelta(seconds=3),
#        "args": ('hardcoded',)
#    },
#}