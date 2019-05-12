#!/bin/sh
#
# Uncheckout all CC-managed files that have not changed with respect to /main/LATEST; 
# takes directories as arguments (default: current directory).
# Example:
# > unco.sh src inc
#

diff="cleartool diff -predecessor"
unco="cleartool unco -keep"

if [ 0 -eq $# ]; then
    paths="."
else
    echo $1
    if [ $1 == "-h" -o $1 == "--help" ]; then
        head -7 $0
        exit 0
    fi
    paths="$*"
fi

for path in $paths ; do 
    if [ ! -d "$path" ]; then
        echo "ERROR: cannot find directory $path"
        exit 1
    fi
    echo Path: $path
    files=`\find -P $path -xautofs -xdev -type f -not \( -name "*~" -o -name "*.keep" -o -name "*.keep.*" -o -name ".#*#" -o -name "#*#" \)`
    files_unco=
    for file in "$files" ; do
        `$diff $file >&/dev/null`
        if [ 0 -eq $? ]; then
            files_unco="$files_unco $file"
        fi
    done
    `$unco $files_unco`
done
