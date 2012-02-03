from celery.task import task
import datetime
from django.contrib.auth.models import User
from server.models import TestVariant, UserTestResult

__author__ = 'Ishai'

import vcf
import urllib2

@task
def process_genome(user):
    profile = user.get_profile()
    profile.place_in_line = 0
    profile.save()
    # processing
    path = profile.genome.url

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
