from django.conf.urls.defaults import url
from django.contrib.auth import login, authenticate
from django.contrib.auth.models import User, AnonymousUser
from django.db.utils import IntegrityError
from server.models import TestVariant, UserTestResult, PhenotypeFamily, PhenotypeFamilyRelation, Phenotype
from tastypie import fields, http
from tastypie.models import ApiKey
from tastypie.authentication import Authentication, ApiKeyAuthentication
from tastypie.authorization import Authorization
from tastypie.bundle import Bundle
from tastypie.cache import SimpleCache
from tastypie.constants import ALL_WITH_RELATIONS, ALL
from tastypie.resources import ModelResource, Resource


#
# return only objects that related to the calling user
#
from tastypie.utils.urls import trailing_slash

class UserOnlyAuthorization(Authorization):
    user_field = 'user'
    # Optional but useful for advanced limiting, such as per user.
    def apply_limits(self, request, object_list):
        if request and hasattr(request, 'user'):
            params = { self.user_field : request.user }
            return object_list.filter(**params)
        return object_list.none()

    def __init__(self,user_field=None):
        if user_field:
            self.user_field = user_field
        super(UserOnlyAuthorization,self).__init__()

class LoginResource(Resource):
    username = fields.CharField(attribute='username')
    password = fields.CharField(attribute='password')
    class Meta:
        always_return_data = True
        resource_name = 'login'
        login_allowed_methods = register_allowed_methods = ['post']
        authorization = Authorization()

    def override_urls(self):
        return [
            url(r"^(?P<resource_name>%s)%s$" % (self._meta.resource_name, trailing_slash()), self.wrap_view('login'), name="api_dispatch_list"),
            url(r"^(?P<resource_name>%s)/register%s$" % (self._meta.resource_name, trailing_slash()), self.wrap_view('register'), name="api_register"),
            ]
    def login(self,request,**kwargs):
        return self.dispatch('login',request,**kwargs)

    def post_login(self,request,**kwargs):
        username = request.POST.get('username')
        password = request.POST.get('password')
        u = authenticate(username=username, password=password)
        if u:
            login(request,u)
            apikey = ApiKey.objects.get(user=u)
            return self.create_response(request,{'status':'success','username':username,'api_key':apikey.key})
        else:
            return http.HttpNotFound()

    def register(self,request,**kwargs):
        return self.dispatch('register',request,**kwargs)

    def post_register(self,request,**kwargs):
        try:
            username = request.POST.get('username')
            email = request.POST.get('email')
            if User.objects.filter(username=username).count():
                raise IntegrityError()
            password = request.POST.get('password')
            u = User.objects.create_user(username,email,password)
            apikey = ApiKey.objects.get(user=u)
            return self.create_response(request,{
                    'status':'success',
                    'username':u.username,
                    'email':u.email,
                    'api_key':apikey.key})
        except IntegrityError:
            return http.HttpMultipleChoices()


class MyResource(ModelResource):
    def obj_get_list(self, request=None, **kwargs):
        """
        A version of ``obj_get_list`` that uses the cache as a means to get
        commonly-accessed data faster.
        """
        cache_key = self.generate_cache_key('list', **kwargs)
        obj_list = self._meta.cache.get(cache_key)

        if obj_list is None:
            obj_list = super(MyResource,self).obj_get_list(request=request, **kwargs)
            self._meta.cache.set(cache_key, obj_list)

        return obj_list

    def obj_get(self, request=None, **kwargs):
        """
        A version of ``obj_get`` that uses the cache as a means to get
        commonly-accessed data faster.
        """
        cache_key = self.generate_cache_key('detail', **kwargs)
        bundle = self._meta.cache.get(cache_key)

        if bundle is None:
            bundle = super(MyResource,self).obj_get(request=request, **kwargs)
            self._meta.cache.set(cache_key, bundle)

        return bundle

class MyCache(SimpleCache):
    expire = 60

    def __init__(self,expire=60):
        self.expire = expire
        super(MyCache,self).__init__()

    def set(self, key, value, timeout=None):
        timeout = timeout or self.expire
        return super(MyCache,self).set(key,value,timeout)

class UserResource(MyResource):

    def obj_get(self, request=None, **kwargs):
        return request.user

    class Meta:
        queryset = User.objects.all()
        exclude = ('password','is_active','is_staff')
        resource_name = 'user'
        authentication = ApiKeyAuthentication()
        filtering = {
                "username"  :   ALL
            }




class PhenotypeFamilyResource(MyResource):
    class Meta:
        queryset = PhenotypeFamily.objects.filter(is_active=True)
        allowed_methods = ['get']
        fields = ('name','description')
        cache = MyCache(expire=60*60)

    # returns all phenotypes of a phenotype family - cached
    @staticmethod
    def get_phenotypes(family_name):
        cache = MyCache(expire=60*60)
        key = 'phenotypes_of_' + family_name
        obj = cache.get(key)
        if not obj:
            try:
                family = PhenotypeFamily.objects.get(name=family_name)
                relations = PhenotypeFamilyRelation.objects.filter(family=family)
                ids = [r.phenotype_id for r in relations]
                phenotypes = Phenotype.objects.filter(pk__in=ids)
                obj = phenotypes
            except PhenotypeFamily.DoesNotExist:
                obj = []
            obj = list(obj)
            if not len(obj):
                obj = []
            cache.set(key,obj)
        return obj



class CheckUserProcessed(UserOnlyAuthorization):

    def is_authorized(self, request, object=None):
        profile = request.user.get_profile()
        if profile.is_processing:
            place_in_line = ''
            if profile.place_in_line:
                place_in_line = 'Your place in line is %d' % profile.place_in_line
            return http.HttpNotFound('Still processing genome. ' + place_in_line)
        return True


class TestResultResource(MyResource):
    def build_filters(self, filters=None):
        if filters is None:
            filters = {}

        orm_filters = super(MyResource, self).build_filters(filters)

        if "phenotype_family" in filters:
            sqs = PhenotypeFamilyResource.get_phenotypes(filters['phenotype_family'])

            orm_filters["phenotype__in"] = sqs

        return orm_filters

    class Meta:
        queryset = UserTestResult.objects.all()
        allowed_methods = ['get']
        fields = ('phenotype','result')
        filtering = ('phenotype_family',)
        authentication = ApiKeyAuthentication()
        authorization =  CheckUserProcessed()

class TestResource(MyResource):

    class Meta:
        queryset = TestVariant.objects.all()
        allowed_methods = ['get']
        authentication = ApiKeyAuthentication()

