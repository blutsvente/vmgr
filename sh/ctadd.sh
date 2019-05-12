#!/bin/sh
#
# Script to add a view-private file or directory to current ClearCase vob.
# The enclosing directory will automatically be checked out. If the enclosing
# directory is also view-private, it will be added as well, and so on.
#
# Note: this script does _not_ perform a check-in of the added files,
# I deliberately did not want to automate this because without admin rights that
# operation is irreversible.
#
# Author: Thorsten Dworzak <thorsten.dworzak@verilab.com>
#

# Returns 1 if the first argument is a view-private file/directory
isPrivate() {
  local _describe="`cleartool describe $1 | head -1 | cut -c1-12`"
  if [ "$_describe" == "View private" ]; then
    echo 1
  else
    echo 0
  fi
  return 0
}

isInVob() {
  local _describe="`cleartool describe $1 | head -1 | cut -c1-13`"
  if [ "$_describe" == "Non-MVFS file" ]; then
    echo 0
  else
    echo 1
  fi
  return 0
}

# Return 1 if the first argument is a checked-out file/directory
isCheckedOut() {
  local _state=`cleartool ls -d $1 | awk '/CHECKEDOUT/'`
  if [ -n "$_state" ]; then
    echo 1
  else
    echo 0
  fi
  return 0
}

addElement() {
  local -r _elem=$1
  local _cmd=
  local _dir=
  local -i _isFile=0

  if [ $(isInVob $_elem) -eq 0 ]; then
    echo $this: ERROR: not in a VOB
    exit 1
  fi

  if [ -d $_elem ]; then
      _cmd="cleartool mkelem -eltype directory -c \"created by $this\" -mkp $_elem"
  else
    if [ -f $_elem ]; then
      _isFile=1
      _cmd="cleartool mkelem -c \"created by $this\" $_elem"
    else
      echo $this: WARNING: no such file or directory $_elem - ignoring it
      return 0
    fi
  fi

  if [ $(isPrivate $_elem) -eq 0 ]; then
    if [ $_isFile -eq 1 ]; then
      echo $this: WARNING: ignoring file that is not view private: $_elem
    fi
  else
    _dir=`dirname $_elem`;

    if [ $(isCheckedOut $_dir) -eq 0 ]; then
      `cleartool co -nc $_dir >&/dev/null`
      if [ $? -ne 0 ]; then
        if [ $(isPrivate $_dir) -eq 1 ]; then
          echo $this: adding parent directory `basename $_dir` because it is a view private file...
          addElement `readlink -e $_dir`
        fi
      else
        echo $this: checked out parent directory ${_dir}
      fi
    fi
    eval $_cmd
  fi
  return 0
}

#
# Main program
#

this=`basename $0`

if [ $# -eq 0 ]; then
  echo "[$this]: ERROR: supply at least one argument!"
  echo "Usage: $this <file|directory>[ <file|directory>*]"
  echo "       adds <file|directory> to ClearCase vob"
fi

for elem in $*
do
  addElement ${elem%/}
done

# end
