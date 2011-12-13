from django.contrib.auth.models import User, AnonymousUser
from server.models import Test, UserTestResult
from tastypie.authentication import Authentication, ApiKeyAuthentication
from tastypie.authorization import Authorization
from tastypie.constants import ALL_WITH_RELATIONS, ALL
from tastypie.resources import ModelResource


#
# return only objects that related to the calling user
#
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


class UserResource(ModelResource):

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






class TestResultResource(ModelResource):

    class Meta:
        queryset = UserTestResult.objects.all()
        allowed_methods = ['get']
        authentication = ApiKeyAuthentication()
        authorization =  UserOnlyAuthorization()

class TestResource(ModelResource):

    class Meta:
        queryset = Test.objects.all()
        allowed_methods = ['get']
        authentication = ApiKeyAuthentication()

