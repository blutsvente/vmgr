#!/usr/bin/env sh
# $Id:$
#
# Diff a working copy of a perforce-managed file to its previous revision
# using the specified comparison tool (-t option). Depending on whether the
# working copy is modified, it will automatically compare it against the Head
# revision or the previous (depot) revision.
# Alternatively you diff against specified revision (-r option).
#
# Author: Thorsten Dworzak <thorsten.dworzak@verilab.com>
#

# Site-specific setup
temp=${TMPDIR:-/tmp}/$this/$$
native_diff="diff --ignore-all-space --ignore-blank-lines"
lsf_cmd="bsub -Ip -q interactive -R 'select[os==centos6]' dbus-launch"

# diff_local="icmp4 diff -dlbu -f "
# diff_depot="icmp4 diff2 -dlb -u "
# kompare="kompare -o -"


# Default values for variables
this=`basename $0`
tool="tkdiff"
opts="$@"
use_lsf=0

# Handle options
usage() {
  echo "usage  : $this -h | [-t <tool>] [-r <revision>] <file>"
  echo "options: -h|help       : print this and exit"
  echo "         -t <tool>     : t = tkdiff (default),"
  echo "                         m = meld,"
  echo "                         k = kompare,"
  echo "                         n = native diff"
  echo "         -r <revision> : use <revision> to compare local file against, instead of BASE/PREV; e.g. -r 6"
}

if [ $# -lt 1 ]; then
    echo $this: "ERROR: needs an argument"
    printf '%s\n' "$(usage)"
    exit 1
fi

file=
use_specific_revision=0
for opt in $opts; do
    case "$1" in
        -t|-tool|--diff-program) tool_select=$2; shift 2 ;; # --diff-program can be used by svn diff if configured, see config
        -r|-revision) revision=$2; shift 2; use_specific_revision=1;;
        -h|-help) printf '%s\n' "$(usage)"; exit 0;;
        *) file=$1; shift ; break ;;
    esac
done

if [ -n "$tool_select" ]; then
    case "$tool_select" in
        t) tool="tkdiff"; use_lsf=1;;
        m) tool="meld"; use_lsf=1;;
        k) tool="kompare"; use_lsf=1;;
        n) tool=$native_diff;;
        *) echo $this: "ERROR: unsupported tool spec: $tool_select"; printf '%s\n' "$(usage)"; exit 1;;
    esac
fi

if [ -z "$file" ]; then
    echo $this: "ERROR: <file> argument required"
    printf '%s\n' "$(usage)"
    exit 1
fi

if [ ! -r "$file" ]; then
    echo $this: "ERROR: file $file not found"
    printf '%s\n' "$(usage)"
    exit 1
fi

# Warn if link because it is maybe not what you want
if [ -L "$file" ]; then
    echo $this: WARNING: file is a symbolic link
    \ls -l "$file"
fi

# Get file information
file_is_local=0
head_rev=0

# Check if file is opened for editing
file_stat=$(icmp4 fstat $file 2>&1)

if echo $file_stat | grep "no such file" >/dev/null; then
    echo $this: ERROR: file not managed by perforce
    exit 1
fi

head_rev=`echo $file_stat | tr -s '...' '\n' | grep headRev | sed -n 's/.*headRev \(\d*\)/\1/p'`

# echo $file_stat | grep "action edit"
if echo $file_stat | grep "action edit" >/dev/null; then
    file_is_local=1
fi

current_str=$file

if [ $use_specific_revision -eq 0 ]; then
  # If the file is locally modified, compare with HEAD revision instead
  if [ $file_is_local -eq 1 ]; then
      revision=head
      current_str="(modified) $current_str"
  else
    if [ $head_rev -lt 2 ]; then
        echo $this: INFO $file is a new file and not opened
        exit 0
    fi
    let revision=head_rev-1
  fi
fi

# Retrieve the version to compare against
outfile=${TMPDIR:-/tmp}/`basename ${file}`.${this}.diff1
(icmp4 print ${file}#$revision | tail -n+2) > $outfile

if [ $? -eq 0 ]; then
    echo "comparing $current_str with #$revision revision ..."
    if [ $use_lsf -eq 1 ]; then
      $lsf_cmd $tool $file $outfile
    else
      $tool $file $outfile
    fi
    rm $outfile
else
    echo $this: ERROR from command \"$tool\", aborting.
    rm -f $outfile
    exit 1
fi

exit 0

# end
