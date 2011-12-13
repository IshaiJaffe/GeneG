from datetime import datetime
from django.db import models
from djangotoolbox import fields
from django_mongodb_engine.fields import GridFSField
from django.contrib.auth.models import User

MAX_FIELD_LENGTH = 400

TEST_SOURCES = (
    ('NCBI','NCBI'),
)

class Test(models.Model):

    name = models.CharField(max_length=30)
    description = models.CharField(max_length=700)
    source = models.CharField(max_length='10',choices=TEST_SOURCES, default='NCBI')
    target_script = models.CharField(max_length='50',null=True, blank=True)
    meta = models.TextField(max_length=755,null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created = models.DateTimeField(default=datetime.now, editable=False)

    def __unicode__(self):
        return self.name

class UserTestResult(models.Model):
    user = models.ForeignKey(User)
    test = models.ForeignKey(Test)
    result = models.TextField(max_length=255,default='')
    meta= models.TextField(max_length=755,default='')
    modified = models.DateTimeField()

    def save(self, *args, **kwargs):
        self.modified = datetime.now()
        return super(UserTestResult,self).save(*args,**kwargs)

    def __unicode__(self):
        return u'%u | %u' % (unicode(self.user),unicode(self.test))

