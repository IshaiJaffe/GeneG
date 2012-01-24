from django.core.management.base import NoArgsCommand
from server.tasks import test_genome, process_genome_file

__author__ = 'Ishai'


class Command(NoArgsCommand):

    def handle_noargs(self, **options):
        test_genome()