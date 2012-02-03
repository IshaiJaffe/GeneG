from django.contrib.auth.models import User
from django.core.management.base import NoArgsCommand
from server.tasks import test_genome, process_genome_file, process_genome
from server.tests import test_zip

__author__ = 'Ishai'


class Command(NoArgsCommand):

    def handle_noargs(self, **options):
        process_genome(User.objects.all()[1])
        #test_genome()
        #test_zip()