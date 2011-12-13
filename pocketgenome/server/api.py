from django.contrib.auth.models import User, AnonymousUser
from tastypie.authentication import Authentication
from tastypie.authorization import Authorization
from tastypie.resources import ModelResource
from models import Email, Contact


class UserResource(ModelResource):
    class Meta:
        model = User
        exclude = ('password','is_active','is_staff')
        resource_name = 'user'

def get_user_wrapper_data(user_id):
    return User.objects.filter(id=user_id).values('first_name','last_name','username','email')[0]

#
# Allow only users who are authentication with django session
#
class SessionAuthentication(Authentication):
    def is_authenticated(self,request,**kwargs):
        if request.user and not isinstance(request.user,AnonymousUser):
            return True
        else:
            return False

    def get_identifier(self, request):
        return request.user.username

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

#
# Attaches user data if needed
#
class CubiclResource(ModelResource):
    return_user = True

    def dispatch(self, request_type, request, **kwargs):
        return super(CubiclResource, self).dispatch(request_type, request, **kwargs)

    def create_response(self,request,data, *args, **kwargs):
        if request.method=='GET' and self.return_user and '_auth_user_id' in request.session and 'omit_user' not in request.GET:
            data['meta']['user'] = get_user_wrapper_data(request.session['_auth_user_id'])
            if data['meta']['next']:
                data['meta']['next'] += '&omit_user=true'
        return super(CubiclResource,self).create_response(request,data,*args,**kwargs)


class EmailResource(CubiclResource):
    class Meta:
        queryset = Email.objects.all()
        allowed_methods = ['get']
        fields = ('MailBox','From','To','Date','Subject')
        authentication = SessionAuthentication()
        authorization =  UserOnlyAuthorization('CubiclUser')

class ContactResource(CubiclResource):
    class Meta:
        queryset = Contact.objects.all()
        allowed_methods = ['get']
        authentication = SessionAuthentication()
        authorization =  UserOnlyAuthorization('CubiclUser')
