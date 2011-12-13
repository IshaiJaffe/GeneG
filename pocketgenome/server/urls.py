from django.conf.urls.defaults import patterns, include, url
from django.contrib.auth.decorators import login_required
from django.views.generic.list import ListView
from server.views import TestView, MainView

from tastypie.api import Api
from api import *

v1_api = Api(api_name='v1')
v1_api.register(EmailResource())
v1_api.register(ContactResource())

urlpatterns = patterns('server.views',
    (r'^test/',TestView.as_view()),
    (r'^emails/',ListView.as_view(model=Email)),
    (r'^api/', include(v1_api.urls)),
    (r'^facebook/autherize/', 'facebook_autherize'),
    (r'^facebook/access_token/', 'facebook_access_token'),
    (r'^/',login_required(MainView.as_view())),
)
