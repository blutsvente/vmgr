#!/bin/sh
#
# Kill the latest LSF job. Will ask for confirmation unless -f is given.
#

job=`bjobs -u $USER | sort -rnk1 | head -1`

if [[ $# -ne 1 || $1 != "-f" ]]; then
  echo -n "kill \"$job\" (y/n)? "
  read sure
   if [[ "$sure" != "y" ]]; then
      echo "aborting" 
      exit
   fi
fi
bkill `echo $job | cut -d " " -f 1`

# end

