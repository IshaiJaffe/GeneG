from django.contrib import admin
from server.models import *
import tastypie

admin.site.register(Variant)
#admin.site.register(Phenotype)
#admin.site.register(PhenotypeFamily)
#admin.site.register(PhenotypeFamilyRelation)
admin.site.register(UserResult)
admin.site.register(tastypie.models.ApiKey)
admin.site.register(UserProfile)