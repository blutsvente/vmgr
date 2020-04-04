#!/bin/sh
# $Id:$
#
# Diff a working copy of a subversion-managed file to its previous revision
# using the specified comparison tool (-m option). Depending on whether the
# working copy is modified, it will automatically compare it against the BASE
# revision or the PREV revision.
# Alternatively you diff against specified revision (-r option).
#
# Author: Thorsten Dworzak <thorsten.dworzak@verilab.com>
#

tool="meld"
this=`basename $0`
temp=${TMPDIR:-/tmp}/$this/$$
revision=PREV
opts="$@"
native_diff="diff --ignore-all-space --ignore-blank-lines"

usage() {
  echo "usage  : $this [-t <tool>] [-r <revision>] <file>"
  echo "options: -h|help       : print this and exit"
  echo "         -t <tool>     : m = meld (default), k = kompare, n = native diff"
  echo "         -r <revision> : use <revision to compare local file against, instead of BASE/PREV"
}

if [ $# -lt 1 ]; then
    echo $this: "ERROR: needs an arguments"
    printf '%s\n' "$(usage)"
    exit 1
fi

file=
tool_select=
use_specific_revision=0
for opt in $opts; do
    case "$1" in
        -t|-tool|--diff-program) tool_select=$2; shift 2 ;; # --diff-program can be used by svn diff if configured, see config
        -r|-revision) revision=$2; shift 2; use_specific_revision=1;;
        -h|-help) printf '%s\n' "$(usage)"; exit 0;;
        *) file=$1; shift ; break ;;
    esac
done

if [ -z "$file" ]; then
    echo $this: "ERROR: <file> argument required"
    printf '%s\n' "$(usage)"
    exit 1
fi

if [ -n "$tool_select" ]; then
    case "$tool_select" in
        m) tool="meld";;
        k) tool="kompare";;
        n) tool=$native_diff;;
        *) echo $this: "ERROR: unsupported tool spec: $tool_select"; printf '%s\n' "$(usage)"; exit 1;;
    esac
fi

# Check if file is in subversion
if [ ! -r "$file" ]; then
    echo $this: ERROR: file does not exist
    exit 1
fi

# Warn if link because it is maybe not what you want
if [ -L "$file" ]; then
    echo $this: WARNING: file is a symbolic link
    \ls -l "$file"
fi

current_str=
file_info=`svn info --show-item last-changed-revision $file`
if [ $? -ne 0 ]; then
    echo $this: ERROR: file not managed by subversion
    exit 1
else
    current_str=$file_info
fi

if [ $use_specific_revision -eq 0 ]; then
  # If the file is locally modified, compare with BASE revision instead
  file_stat=`svn status $file | cut -b 1`
  if [ "$file_stat" == "M" ]; then
      revision=BASE
      current_str="(modified) $current_str"
  fi
fi

# Retrieve the version to compare against
outfile=${TMPDIR:-/tmp}/`basename ${file}`.${this}.diff1
svn cat -r $revision $file >| $outfile

if [ $? -eq 0 ]; then
    echo comparing $current_str with $revision revision in file $outfile...
    $tool $file $outfile
    \rm -f $outfile
else
    echo $this: ERROR from command \"$tool\", aborting.
    exit 1
fi
exit 0

# end
