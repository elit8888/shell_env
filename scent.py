import os
from sniffer.api import file_validator
from sniffer.api import runnable

watch_paths = ['.']


@file_validator
def py_files(filename):
    return filename.endswith('.py') \
           and not os.path.basename(filename).startswith('.')


@runnable
def execute_tests(*args):
    test_dir = '.'
    cmd = 'python3 -B -m unittest discover -p "*_test.py" {}'.format(test_dir)
    ret = os.system(cmd)
    print('Return code: {ret}'.format(ret=ret))
    return ret == 0
