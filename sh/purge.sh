#!/bin/sh
#
# Move backup files away
#

purgedir=~/temp/purge
recursive=1

if [[ $# -ge 1 && $1 == "-r" ]]; then
   recursive=999
   echo -n "recursive (y/n)? "
   read sure
   if [[ "$sure" != "y" ]]; then
      echo "aborting"
      exit
   fi
fi

if [[ ! -d $purgedir ]]; then
   mkdir -p  $purgedir
fi

\find -P . -maxdepth $recursive -xautofs -xdev  -not -path "*/`basename $purgedir`/*" -not -path "*/.snapshot/*" -type f \( -name "*~" \
-o -name "findmerge.log.*" \
-o -name "*.*.ann" \
-o -name "*.contrib" \
-o -name "*.contrib.?" \
-o -name "*.merge" \
-o -name "*.merge.?" \
-o -name "*.keep" \
-o -name "*.keep.?" \
-o -name ".??*~" \
-o -name "*.bak" \
-o -name ".#*#" \
-o -name "#*#" \) \
-exec mv --force --verbose '{}' $purgedir \;

# end
