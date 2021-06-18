#!/bin/sh
#
# Tells me if my home dir or any other dir with a quota is about to run full.
# First parameter is limit for usage (in percent). Prints warning if limit exceeded.
# Second (optional) parameter is a directory path; uses $HOME if none given.
#
limit=${1%"%"}
dir=$HOME
if [ ! -z "$2" ]; then
   dir="$2"
fi
quota=`df -k $dir | tail -1 | awk '{sub(/%/,"");i=NF-1;print $i}'`

# check if the result is a number before comparing with the limit
if [ -n "quota" ] && [ "$quota" -eq "$quota" ] 2>/dev/null; then
   if [ $quota -gt $limit ]; then
      echo "*** WARNING: directory $dir almost full at ${quota}% ***"
   fi
else
    echo "? no quota available for $dir"
    exit 0
fi

exit 1