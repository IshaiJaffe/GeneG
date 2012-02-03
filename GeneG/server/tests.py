"""
This file demonstrates writing tests using the unittest module. These will pass
when you run "manage.py test".

Replace this with more appropriate tests for your application.
"""
import os

from django.test import TestCase
import settings


class SimpleTest(TestCase):
    def test_basic_addition(self):
        """
        Tests that 1 + 1 always equals 2.
        """
        self.assertEqual(1 + 1, 2)

import zipfile
import urllib
import StringIO

def test_zip():
#    fp = urllib.urlopen('http://www.vbaccelerator.com/home/vb/code/libraries/subclassing/SSubTimer/VB6_Graduated_Title_Bar_Sample.zip')
    fp = open(settings.CODE_ROOT + 'django.zip','rb')
    target = settings.CODE_ROOT + '/tmp.zip'
    target_file = file(target,mode='wb')
    buffer = 1<<10
    data = fp.read(buffer)
    fake_file = StringIO.StringIO()
    while data:
        fake_file.write(data)
        target_file.write(data)
        data = fp.read(buffer)
    target_file.close()
    fp.close()
    zp = zipfile.ZipFile(target)
    for zname in zp.namelist():
        uncomp = zp.read(zname)