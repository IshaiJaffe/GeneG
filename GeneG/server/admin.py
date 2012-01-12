from django.contrib import admin
from server.models import *
import tastypie

admin.site.register(TestVariant)
admin.site.register(Phenotype)
admin.site.register(PhenotypeFamily)
admin.site.register(PhenotypeFamilyRelation)
admin.site.register(UserTestResult)
admin.site.register(tastypie.models.ApiKey)
admin.site.register(UserProfile)