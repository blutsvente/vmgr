#!/usr/bin/env sh
# $Id:$
#
# Display files not in depot or locally modified files in perforce workspace
#
# Author: Thorsten Dworzak <thorsten.dworzak@verilab.com>
#

# Default values for variables
this=`basename $0`
dir=.


usage() {
  echo "usage  : $this -h | [<dir>]"
  echo "options: -h|help       : print this and exit"
  echo "         <dir>         : (optional) get p4 status of <dir> (default is .)"
}

# Handle options
if [ $# -gt 0 ]; then
   opt=$1
   if [[ "$opt" = -h ]]; then
      printf '%s\n' "$(usage)"; exit 0;
   else
      dir=$opt
   fi
fi

pwd=`pwd`/


find $dir -type f -not -path "*vsi_test_porting*" -not -path "*/run/*" -not -path "*/lib/*" -print | \
icmp4 -x - diff -f -sa 2>&1 | \
sed -e '/not on client./!s@'$pwd'@M @' -e '/not on client.$/s/^/? /' -e 's/- file(s) not on client.$//'

# end