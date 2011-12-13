from django.contrib import admin
from server.models import Test, UserTestResult
import tastypie

admin.site.register(Test)
admin.site.register(UserTestResult)
admin.site.register(tastypie.models.ApiKey)