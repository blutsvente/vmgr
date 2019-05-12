#!/bin/sh
# clearcase: shows private files in current directory and below;
# exclude XEmacs backup files

cleartool lspriv -other . | \egrep -v --regexp '[#~]$'

# end

