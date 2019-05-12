#!/bin/sh
# recursive grep; uses find/xargs
arch=`uname`
this=`basename $0`
names=""
_RGREP_OPTION=${_RGREP_OPTION:=""}

if [ $# -lt 2 ]; then
        echo $this: error: needs two arguments
        echo "usage: rgrep <search-pattern> <file-pattern>"
        exit 1
fi

names="-name \"$2\""

if [ "$arch" = "Linux" ]; then
   eval \find . -type f $names -print0 | xargs -0 \grep $_RGREP_OPTION "$1"
else
   eval \find . -type f $names -print | xargs \grep $_RGREP_OPTION "$1"
fi

exit 0
# end
