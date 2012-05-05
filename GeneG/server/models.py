from datetime import datetime
from django.db import models
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from djangotoolbox.fields import ListField, EmbeddedModelField
from tastypie.models import create_api_key

MAX_FIELD_LENGTH = 400

SOURCES = (
    ('pharm','PharmGKB'),
    ('gwas','GWAS')
)

class UserProfile(models.Model):
    user = models.OneToOneField(User)
    genome = models.FileField(upload_to='genomes',null=True)
    is_processing = models.BooleanField(default=False)
    is_queueing = models.BooleanField(default=True)
    last_processed = models.DateTimeField(null=True,editable=False)

    def __unicode__(self):
        return unicode(self.user)

    def __init__(self, *args, **kwargs):
        super(UserProfile,self).__init__(*args,**kwargs)
        self.was_genome_url = None
        if self.genome:
            self.was_genome_url = self.genome.url

    def save(self,*args,**kwargs):
        if self.genome and self.was_genome_url != self.genome.url:
            self.is_queueing = True
        return super(UserProfile,self).save(*args,**kwargs)


def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance)

post_save.connect(create_user_profile, sender=User)
post_save.connect(create_api_key,sender=User)

#class Phenotype(models.Model):
#    name = models.CharField(max_length=30)
#    description = models.TextField(max_length=755,default='')
##    phenotype_families = ListField()
#
#    def __unicode__(self):
#        return unicode(self.name)

class AllelPhenotype(models.Model):
    allel = models.CharField(max_length=5)
    phenotype = models.TextField()

class Variant(models.Model):

    name = models.CharField(max_length=30)
    allel_phenotypes = ListField(EmbeddedModelField(AllelPhenotype), editable=False)
    drugs = ListField(models.CharField(max_length=30))
    diseases = ListField(models.CharField(max_length=30))
#    description = models.CharField(max_length=700,default='',blank=True)
    source = models.CharField(max_length=30,null=True,blank=True, choices=SOURCES)
    pubmed_id = models.CharField(max_length=30,null=True,blank=True)
    p_value = models.FloatField(null=True,blank=True)
    related_genes = ListField(models.CharField(max_length=30), editable=False)
    trait = models.CharField(max_length=30)
    OR = models.CharField(max_length=30)
    #target_script = models.CharField(max_length=50,null=True, blank=True)
#    phenotype = models.ForeignKey(Phenotype,null=True,blank=False)
    meta = models.TextField(max_length=755,null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created = models.DateTimeField(default=datetime.now, editable=False)
#    risk_allel = models.CharField(max_length=5,null=True,blank=True)

    def __unicode__(self):
        return unicode(self.name)

#class PhenotypeFamily(models.Model):
#    name = models.CharField(max_length=30)
#    description = models.TextField(max_length=755,default='')
#    is_active = models.BooleanField(default=True)
#    def __unicode__(self):
#        return unicode(self.name)
#
#class PhenotypeFamilyRelation(models.Model):
#    family = models.ForeignKey(PhenotypeFamily)
#    phenotype = models.ForeignKey(Phenotype)
#    def __unicode__(self):
#        return u'%s | %s' % (unicode(self.family),unicode(self.phenotype))


class UserResult(models.Model):
    user = models.ForeignKey(User)
    variant = models.ForeignKey(Variant)
    variant_ref = models.CharField(max_length=20)
    pos = models.CharField(max_length=5,null=True,blank=True,verbose_name='Reference Base(s)')
    alt = models.CharField(max_length=5,null=True,blank=True,verbose_name='Detected Base(s)')
    chrom = models.IntegerField(null=True,blank=True,verbose_name='Chromosome')
    position = models.IntegerField(null=True,blank=True,verbose_name='Position in chromosome')
    at_risk = models.BooleanField(default=False)
#    phenotype = models.ForeignKey(Phenotype,null=True)
    result = models.TextField(max_length=255,default='')
    meta= models.TextField(max_length=755,null=True,blank=True)
    modified = models.DateTimeField(auto_now=True)

    def __unicode__(self):
        return u'%s | %s' % (unicode(self.user),unicode(self.variant_ref))

