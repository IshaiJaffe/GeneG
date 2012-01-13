from celery.task import task
import datetime

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
    process_genome_file(fp)
    profile.is_processing = False
    profile.last_processed = datetime.datetime.now()
    profile.save()


def process_genome_file(fp):
    def process_vcf_chunk(v):
        print v
    vcf.VCFfilter(fp,None,process_vcf_chunk)

from django.test.testcases import TestCase

#class test_genome(TestCase):
#    path = 'C:/Users/Ishai/Downloads/test.vcf'
#    fp = open(path)
#    process_genome_file(fp)