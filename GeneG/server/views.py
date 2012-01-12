# Create your views here.
import urllib
from django.contrib.auth.models import User
from django.core.urlresolvers import reverse
from django.http import HttpResponseRedirect, HttpResponse
from django.shortcuts import render_to_response
from django.views.generic.base import TemplateView, View
from server import tasks
import settings
from tastypie import http

class CubicalView(TemplateView):
    pass

class TestView(CubicalView):
    template_name = 'test.html'

    def get_context_data(self, **kwargs):
        return {'msg':'hello'}

def test(request):
    return render_to_response('test.html')

def facebook_autherize(request):
    params = {}
    params["client_id"] = settings.FACEBOOK_APP_ID
    params["redirect_uri"] = request.build_absolute_uri('/facebook/access_token/')
    params['scope'] = settings.FACEBOOK_PERMISSIONS

    url = "https://graph.facebook.com/oauth/authorize?"+urllib.urlencode(params)

    return HttpResponseRedirect(url)

def facebook_access_token(request):
    code = request.GET['code']
    params = {}
    params["client_id"] = settings.FACEBOOK_APP_ID
    params["client_secret"] = settings.FACEBOOK_SECRET_KEY
    params["redirect_uri"] = request.build_absolute_uri('/facebook/access_token/')
    params["code"] = code

    url = "https://graph.facebook.com/oauth/access_token?"+urllib.urlencode(params)
    from cgi import parse_qs
    userdata = urllib.urlopen(url).read()
    res_parse_qs = parse_qs(userdata)
    # Could be a bot query
    if not res_parse_qs.has_key('access_token'):
        return None
    return HttpResponse(res_parse_qs['access_token'][-1])
    parse_data = res_parse_qs['access_token']
    uid = parse_data['uid'][-1]
    access_token = parse_data['access_token'][-1]

    return HttpResponse(access_token)

class MainView(CubicalView):
    template_name = 'index.html'

    def get_context_data(self, **kwargs):
        return {}

def process(request,user_id):
    if request.method != 'POST' and not settings.DEBUG:
        return http.HttpMethodNotAllowed()
    user = User.objects.get(id=user_id)
    tasks.process_genome(user)
    return HttpResponse('OK')
