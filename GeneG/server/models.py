from datetime import datetime
from django.db import models
from djangotoolbox import fields
from django_mongodb_engine.fields import GridFSField
from django.contrib.auth.models import User
from django.db.models.signals import post_save

MAX_FIELD_LENGTH = 400

TEST_SOURCES = (
    ('NCBI','NCBI'),
)

class UserProfile(models.Model):
    user = models.OneToOneField(User)
    genome = models.FileField(upload_to='genomes',null=True,blank=True)
    def __unicode__(self):
        return unicode(self.user)


def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance)
post_save.connect(create_user_profile, sender=User)

class Phenotype(models.Model):
    name = models.CharField(max_length=30)
    description = models.TextField(max_length=755,default='')
    def __unicode__(self):
        return self.name

class TestVariant(models.Model):

    name = models.CharField(max_length=30,unique=True)
    description = models.CharField(max_length=700,default='',blank=True)
    source = models.CharField(max_length=30,null=True,blank=True)
    #target_script = models.CharField(max_length=50,null=True, blank=True)
    phenotype = models.ForeignKey(Phenotype)
    pubmed_id = models.CharField(max_length=30,null=True,blank=True)
    p_value = models.FloatField(null=True,blank=True)
    meta = models.TextField(max_length=755,null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created = models.DateTimeField(default=datetime.now, editable=False)

    def __unicode__(self):
        return unicode(self.name)

class PhenotypeFamily(models.Model):
    name = models.CharField(max_length=30)
    description = models.TextField(max_length=755,default='')
    def __unicode__(self):
        return unicode(self.name)

class PhenotypeFamilyRelation(models.Model):
    family = models.ForeignKey(PhenotypeFamily)
    phenotype = models.ForeignKey(Phenotype)
    def __unicode__(self):
        return u'%u | %u' % (unicode(self.family),unicode(self.phenotype))


class UserTestResult(models.Model):
    user = models.ForeignKey(User)
    variant = models.ForeignKey(TestVariant)
    result = models.TextField(max_length=255,default='')
    meta= models.TextField(max_length=755,default='')
    modified = models.DateTimeField()

    def save(self, *args, **kwargs):
        self.modified = datetime.now()
        return super(UserTestResult,self).save(*args,**kwargs)

    def __unicode__(self):
        return u'%u | %u' % (unicode(self.user),unicode(self.test))

