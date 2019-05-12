#!/bin/sh
#
# set a user config-spec using naming convention <user>.<view-tag> for the file
#
my_cs=$WORKAREA/config/user/vih/${USER}.${WORKSPACEID}

if [ ! -r "$my_cs" ]; then
    echo "ERROR: file not found: $my_cs"
    exit 1
else
    echo "setting config-spec $my_cs..."
    cleartool setcs $my_cs
fi
