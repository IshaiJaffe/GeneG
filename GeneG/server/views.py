# Create your views here.
import urllib
from boto.utils import Password
import os
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.core.context_processors import auth
from django.core.urlresolvers import reverse
from django.forms import fields
from django.forms.forms import Form
from django.forms.models import ModelForm
from django.forms.widgets import PasswordInput
from django.http import HttpResponseRedirect, HttpResponse
from django.shortcuts import render_to_response, redirect
from django.views.generic.base import TemplateView, View
from server import tasks
from server.models import UserProfile
import settings
from tastypie import http




class MainView(TemplateView):
    template_name = 'index.html'

    def get_context_data(self, **kwargs):
        return {}

class RegisterForm(ModelForm):
    class Meta:
        model = User
        fields = ('username','password','email','first_name','last_name')


class RegisterView(TemplateView):
    template_name = 'login.html'

    def post(self,request,*args,**kwargs):
        form = RegisterForm(request.POST)
        if form.is_valid():
            user = User.objects.create_user(form.data.get('username'),form.data.get('email'),form.data.get('password'))
            for key,value in form.data.items():
                if key not in ('password','username','email'):
                    setattr(user,key,value)
            user.save()
            u = authenticate(username=user.username,password=form.data.get('password'))
            login(request,u)
            next = request.GET.get('next',settings.LOGIN_REDIRECT_URL)
            return redirect('/upload/')
        else:
            return self.get(request,*args,form=form)

    def get_context_data(self, form=None,**kwargs):
        return {'form':form or RegisterForm()}


class LoginForm(Form):
    username = fields.CharField(max_length=50)
    password = fields.CharField(max_length=30,widget=PasswordInput)


    def is_valid(self):
        if super(LoginForm,self).is_valid():
            self.user = authenticate(username=self.data['username'],password=self.data['password'])
            if not self.user:
                self.errors['__all__'] = 'Username/Password are incorrect'
                return False
            return True
        return False


class LoginView(TemplateView):
    template_name = 'login.html'

    def post(self,request,*args,**kwargs):
        form = LoginForm(request.POST)
        if form.is_valid():
            login(request,form.user)
            next = request.GET.get('next',settings.LOGIN_REDIRECT_URL)
            return redirect(next)
        else:
            return self.get(request,*args,form=form)

    def get_context_data(self, form=None,**kwargs):
        return {'form':form or LoginForm()}

def logout_view(request):
    logout(request)
    return render_to_response('logout.html',{})


class UploadForm(ModelForm):
    class Meta:
        model = UserProfile
        fields = ('genome',)

class UploadView(TemplateView):
    template_name = 'upload.html'

    def post(self,request,*args,**kwargs):
        form = UploadForm(request.POST,request.FILES,instance=request.user.get_profile())
        if form.is_valid():
            form.save()
            user_id = request.user.id
            tasks.process_genome.delay(user_id)
            return self.get(request,*args,form=form)
        else:
            return self.get(request,*args,form=form,**kwargs)

    def get(self, request, *args, **kwargs):
        kwargs['form'] = UploadForm(instance=request.user.get_profile())
        return super(UploadView,self).get(request,*args,**kwargs)

    def get_context_data(self,form=None ,**kwargs):
        return {'form':form}

def process_genomes(request):
    tasks.update_users_profile()