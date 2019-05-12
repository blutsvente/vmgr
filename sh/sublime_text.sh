#!/bin/sh
#
# Wrapper to start sublime text
# note: LSF submission did not work because sublime spawns a sub-process ("plugin_host") that
# causes LSF to think the original process finished.
#
if [ -a "/etc/redhat-release" ]; then
	rh=`awk -f ~chdworza/bin/redhat_major_version.awk /etc/redhat-release`
	if [ $rh -lt 6 ]; then
		echo "[$0] ERROR: this must be executed on a RHEL6 server!"
		exit 1
	fi
fi

spid=0
output=`ps -edf | \grep $USER | \grep -v grep | \grep sublime_text_3\/sublime_text`
if [ $? -eq 0 ]; then
   spid=`echo $output | awk '{print $2;}'`
   echo "[$0] INFO: there is already a running sublime_text_3 process on this server (PID $spid)"
fi

export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export SUBLIME=1
~/data/sublime_text_3/sublime_text $*

# end

# /// trials ///
# ifxlsf -eh_lsfopts "-R 'select[type==X64LIN && clearcase && osrel==60 && pf=static_hi]'"
# /opt/camino/subflows/ncsim/1.5.0/bin/ifxexecsession.pl
# //////////////
