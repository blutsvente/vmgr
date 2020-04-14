#!/bin/sh
# Helper script to create a meaningful prompt for projects/ClearCase vobs.
# Returns a string of the format <subprojectname> or <subprojectname>.<workspaceid> if <workspaceid> is != "default"
#
result=
if [ -n "$PROJ" ]; then
    result=`$PROJMENUROOT/proj.menu.rb -hdr  | \grep Dir: | sed -e "s/^\s//; s/\s\s*/ /g" | cut -d " " -f 2`
    result=`basename $result`
elif [ -n "$WORKAREA" ]; then
    result="${SUBPROJECTNAME}"
    if [ -n "$WORKSPACEID" ]; then
       # note: the pwv command is more reliable than the WORKSPACEID variable
       pwv=(`cleartool pwv -short | sed -e 's/\./ /g'`)
       let pwv_last_index=${#pwv[*]}-1
       workspace="${pwv[$pwv_last_index]}"
       if [ "$workspace" != "default" ]; then
          result="$result.$workspace"
       fi
    else
       # old Camino versions(?)
       if [ -n "$HWPROJECTCS" ]; then
          if [ "$HWPROJECTCS" != "default" ]; then
             result="$result.$HWPROJECTCS"
          fi
       fi
    fi
fi

echo $result
# end