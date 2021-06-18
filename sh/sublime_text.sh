#!/bin/sh
#
# Wrapper to start sublime text
#

# _host=`bhosts | \grep greggie | \grep ok | cut -d ' ' -f 1 | head -1`
_host=gpurple05
_dbus=dbus-launch
_lsf_opts="-J sublime-text -q interactive"
_version=4
sublime_exe="bsub -Ip $_lsf_opts -m $_host $_dbus ~/data/sublime_text_${_version}/sublime_text -w"

# if [ -a "/etc/redhat-release" ]; then
# 	rh=`\awk '{ split($3, arr,"."); print arr[1] }' /etc/redhat-release`
# 	if [ $rh -lt 7 ]; then
# 		echo "[$0] ERROR: this must be executed on a RHEL7+ server!"
# 		exit 1
# 	fi
# fi

spid=0
output=`\ps -edf | \grep $USER | \grep -v grep | \grep sublime_text_${_version}\/sublime_text`
if [ $? -eq 0 ]; then
   spid=`echo $output | awk '{print $2;}'`
   echo "[$0] INFO: there is already a running sublime_text_${_version} process on this server (PID $spid)"
fi

export NO_AT_BRIDGE=1
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export SUBLIME=1
exec $sublime_exe $*

# end
