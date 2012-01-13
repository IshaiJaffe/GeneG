import django
from django.conf.urls.defaults import patterns, include, url
from django.contrib.auth.decorators import login_required
from django.views.generic.list import ListView
from server.models import TestVariant
from server.views import TestView, MainView

from tastypie.api import Api
from api import *

v1_api = Api(api_name='v1')
v1_api.register(TestResource())
v1_api.register(TestResultResource())
v1_api.register(UserResource())

v1_api.register(PhenotypeFamilyResource())
v1_api.register(LoginResource())

gluz_api = Api(api_name='gluz')
gluz_api.register(VariantResource())
gluz_api.register(PhenotypeResource())

urlpatterns = patterns('server.views',
    (r'^test/',TestView.as_view()),
    (r'^emails/',ListView.as_view(model=TestVariant)),
    (r'^api/', include(v1_api.urls)),
    (r'^api/', include(gluz_api.urls)),
    (r'^facebook/autherize/', 'facebook_autherize'),
    (r'^facebook/access_token/', 'facebook_access_token'),
    (r'^/',login_required(MainView.as_view())),
    (r'^mobile/(.*)$', django.views.static.serve, {'document_root': '../www/'}),
    (r'^process/(?P<user_id>[0-9a-f]+)/', 'process'),
)
