#!/usr/bin/python
# EASY-INSTALL-ENTRY-SCRIPT: 'barpyrus==0.0.0','console_scripts','barpyrus'
__requires__ = 'barpyrus==0.0.0'
import re
import sys
from pkg_resources import load_entry_point

if __name__ == '__main__':
    sys.argv[0] = re.sub(r'(-script\.pyw?|\.exe)?$', '', sys.argv[0])
    sys.exit(
        load_entry_point('barpyrus==0.0.0', 'console_scripts', 'barpyrus')()
    )
