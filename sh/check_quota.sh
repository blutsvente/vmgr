#!/bin/sh
#
# Tells me if my home dir is about to run full.
# First parameter is limit for usage (in percent).
#
limit=${1%"%"}
quota=`df -k $HOME | tail -1 | awk '{sub(/%/,"");i=NF-1;print $i}'`
if [ $quota -gt $limit ]; then
    echo "*** WARNING: home directory almost full at ${quota}% ***"
fi

