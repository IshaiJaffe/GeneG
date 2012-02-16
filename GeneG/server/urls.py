import django
from django.conf.urls.defaults import patterns, include
from django.contrib.auth.decorators import login_required
from server.views import MainView, LoginView, RegisterView, logout_view, UploadView,process_genomes
import settings

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
    (r'^api/', include(v1_api.urls)),
    (r'^api/', include(gluz_api.urls)),
    (r'^login/',LoginView.as_view()),
    (r'^register/',RegisterView.as_view()),
    (r'^upload/',UploadView.as_view()),
    (r'^logout/',logout_view),
    (r'^process/',process_genomes),
    (r'^',login_required(MainView.as_view())),
    (r'^mobile/(.*)$', django.views.static.serve, {'document_root': settings.CODE_ROOT + 'www/'}),
)
