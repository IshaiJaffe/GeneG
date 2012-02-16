from celery.task import task
import datetime
import os
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from server.models import TestVariant, UserTestResult, UserProfile

__author__ = 'Ishai'

import vcf
import urllib2

@task
def say_hello(to='someone'):
    print 'hello %s' % to

#def check_genome_upload(sender,instance,created,**kwargs):
#    # if userprofile is created with genome or if genome file has changed => send genome to process
#    if instance.genome and instance.genome.url and \
#       instance.is_queueing and \
#       instance.was_genome_url != instance.genome.url:
#        print 'send genome to process for user %s' % instance.user.username
#        process_genome.delay(instance.user_id)
#
#post_save.connect(check_genome_upload,sender=UserProfile)

@task
def update_variant_db(phenoype=None):
    cmd = 'TestBuilder\phenotypes.pl'
    if phenoype:
        cmd += ' ' + phenoype
    os.system(os.path.normpath(cmd))

@task
def update_users_profile():
    print 'looking for users who need to have their results updated'
    users = list(UserProfile.objects.filter(last_processed__lt=datetime.datetime.now()-datetime.timedelta(days=30)))
    users.extend(list(UserProfile.objects.filter(last_processed=None).exclude(genome=None)))
    for user in users:
#        if not user.is_queueing and not user.is_processing:
        print 'send user %s for processing' % user.user_id
        user.is_queueing = True
        user.save()

@task
def process_genome(user_id):
    print 'processing genome for user %s' % user_id
    try:
        user = User.objects.get(id=user_id)
    except Exception as e:
        print e.message
        return
    print 'processing genome for user %s' % user.username
    try:
        profile = user.get_profile()
    except Exception as e:
        print 'exception: %s' % e.message
        return
    if not profile.is_queueing or not profile.genome:
        return
    profile.is_queueing = False
    profile.is_processing = True
    profile.save()
    # processing
    path = profile.genome.url
    print 'getting path %s' % path
    fp = urllib2.urlopen(path)
    process_genome_file(fp,user)
    profile.is_processing = False
    profile.last_processed = datetime.datetime.now()
    profile.save()


def process_genome_file(fp,user):
    all_variants = TestVariant.objects.all()
    variants_by_name = {}
    for variant in all_variants:
        if variant.name in variants_by_name:
            variants_by_name[variant.name].append(variant)
        else:
            variants_by_name[variant.name] = [variant]
    def process_vcf_chunk(v):
        for key,value in v.data.items():
            print 'processing variant in position ' + key
            variant_id = value['ID']
            print 'variant id is ' + variant_id
            variants = variants_by_name.get(variant_id,())
#            if not len(variants):
#                print 'no variants in DB, creating'
#                variant = TestVariant(name=variant_id)
#                variant.save()
#                variants = [variant]
            for variant in variants:
                phenotype = variant.phenotype
                test_result,created = UserTestResult.objects.get_or_create(user=user,variant=variant)
                test_result.phenotype = phenotype
                test_result.ref = value['REF']
                test_result.alt = value['ALT']
                risk_allel = variant.risk_allel
                if risk_allel:
                    if risk_allel.lower().strip() == value['ALT'].lower().strip():
                        test_result.at_risk = True
                    else:
                        test_result.at_risk = False
                else:
                    test_result.at_risk = True
                if test_result.at_risk and test_result.phenotype:
                    test_result.result = 'In risk of ' + phenotype.name
                else:
                    test_result.result = ''
                test_result.chrom = value['CHROM']
                test_result.position = value['POS']
                test_result.save()

    vcf.VCFfilter(fp,None,process_vcf_chunk)

from django.test import TestCase

def test_genome():
    path = 'C:/Users/Ishai/Downloads/test.vcf'
    fp = open(path)
    process_genome_file(fp,User.objects.all()[0])
