#!/bin/sh
#
# Script to start Emacs with emacsclient if a client is available.
# Author: Thorsten Dworzak
# Description:
#   Wrapper script for Emacs and emacsclient.
#   Starts either Emacs (on current host) or emacsclient, depending on whether there is
#   already an Emacs process; this is determined by looking for the process or a tag file
#   in user's home directory.
#   With -n option, starts a new Emacs process, skipping the emacsclient functionality.
#   With -d commands are only printed, not executed
#
#   Usage: em.sh [-n] [-d] [emacs-option(s)] [file(s)]
#

# Setup
emacs="emacs"
emacs_options=""
client="emacsclient"
emacsclient_options="-a $emacs"
ehfile=~/.emacshost

# create a title/color for new XEmacs processes
title=""
# https://en.wikipedia.org/wiki/X11_color_names
colour="OldLace"

while [ $# -gt 0 ]; do
   case "$1" in
      -n) new_emacs=true; shift;;
      -d) debug=true; shift;;
      *) break;;
   esac
done

# Start a new emacs process and exit
if [ "$new_emacs" == true ]; then
   echo starting new Emacs process requested by -n option...
   colour="DeepSkyBlue"
   cmd="${emacs} -bg $colour ${emacs_options} $title $*"
   if [ "$debug" == true ]; then
      echo $cmd
   else
      (nohup $cmd > /dev/null 2>&1 &) > /dev/null
   fi
   exit 0
fi

# search running emacs process
if pgrep -U $(id -u) emacsclient > /dev/null; then
   running=true;
fi

hostname=`uname -n`

# Usually emacs handles interrupts, but sometimes they end up here
trap "{ \mv ${ehfile} ${ehfile}.last ; exit 255; }" HUP INT

if [[ "$running" != true && ! -f $ehfile ]]; then
   # create new tagfile
   echo $hostname > ${ehfile}
   # start new emacs process and wait until it's finished
   echo no running Emacs found, starting new process...
   cmd="${emacs} -bg $colour ${emacs_options} $title $*"
   if [ "$debug" == true ]; then
      echo $cmd
   else
      eval $cmd
      wait
      # remove tagfile after application quits
      \mv ${ehfile} ${ehfile}.last
   fi
else
   if [[ "$running" == true && ! -f $ehfile && "$debug" != true ]]; then
      # if emacs is running but no tagfile, create tagfile
      echo $hostname > ${ehfile}
   fi

   cmd="$client $emacsclient_options $*"
   other_host=$hostname

   # get the server host
   if [ -f $ehfile ]; then
      other_host=`cat $ehfile`
   fi

   # is this host the server host?
   if [ $other_host != $hostname ]; then
      cmd="ssh -Y $other_host -f $cmd"
   else
      cmd="nohup $cmd > /dev/null 2>&1 &"
   fi

   # make it so

   if [ "$debug" == true ]; then
      echo $cmd
   else
      eval $cmd
      if [ "$?" -ne 0 ]; then
         echo "ERROR occurred."
         echo "Note: DISPLAY is currently set to $DISPLAY"
      fi
   fi
fi
# end
