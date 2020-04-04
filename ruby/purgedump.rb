#!/usr/bin/ruby
#
# Author: Thorsten Dworzak
#
# Description: Removes all files in directories matching patterns <dir_patterns>
# and below that are older than <days>.
# TODO: use config file to define directories, patterns, days
#

# expects RUBYLIB to be set
require 'vmgr/collaterals.rb'

#
# User setup
#

# max age of files
days = 67

# Common directories to purge
dir_patterns = [
   {"~/temp"      => ["*"]},
   {"~/.lsbatch"  => ["*"]},
]

# project dependent
ies_patterns = [
   "*.ucm", "*.log", "*.out", ".DEFAULT", "*.vsof", "ncsim_*.err", "*.dsn", "*.trn", "*.elog"
]
questa_patterns = [
   "*.tl", "*.log", "*.out", "*.err", "*.acc", "*.ocf", "*.com", "*.dbg" "*.wlf","*.ucm", "*.ucd", "*.ucdb", "transcript",
   "Status.csv",
   "Status.html",
   "VRMDATA",
   "filtered_files.txt",
   "output",
   "report",
   "vms.checksum",
   "vms.replay*",
   "vms2_ucdbadd.do",
   "vms_trash",
   "vms_ucdbadd.do",
   "vms_vrun_*"
]
ack_patterns = [
   "*.job", "*.log", "*.cache", "*.ELF", "*.o", "*.o.s"
]

dir_patterns.push(
  { "/proj/gpfs/thdx/workspaces/*/vmanager_sessions"              => ies_patterns }
)

if ENV["IRIS_VERIFICATION"]
  # project dependent directories to purge
  dir_patterns.push(
    {"#{ENV["IRIS_VERIFICATION"]}/tb/e/fme_iris_mgp"              => ies_patterns },
    {"#{ENV["IRIS_VERIFICATION"]}/tb/e/fme_iris_mgp/*/INCA_libs"  => ["*"] }
  )
end

if ENV["MXVIDEOSS_VERIFICATION"]
  dir_patterns.push(
    {"#{ENV["MXVIDEOSS_VERIFICATION"]}/tb/fnv/run"  => questa_patterns }
  )
end

# Shell command(s)
find = "/usr/bin/find -P"

# helper method
# def sizeup(str)
#   return str.size>80 ? str[0..9]+"[...]"+str[-65..-1] : str
# end

#
# Makeitso
#
for entry in dir_patterns
  entry.each { |dir, patterns|
    dir = dir.delete " "

    if dir.empty? or dir == "/" or dir[0] == "*" or dir[0..1] == "/*"
      puts "#{$0}: ERROR: dangerous path: #{dir}"
      exit
    end

    # Delete Files in <dir> matching <pattern>
    patterns.delete_if { |pattern| pattern.empty? }.each { |pattern|
      puts "deleting #{pattern} files in #{dir.sizeup(65)} ..."
      cmd = %Q/#{find} #{dir} -xautofs -xdev -type f -name "#{pattern}" -mtime +#{days} -delete/
      `#{cmd}`
    }

    # Delete empty dirs below <dir>
    puts "deleting empty dirs in #{dir.sizeup(65)} ..."
    cmd = %Q/#{find} #{dir} -xautofs -xdev -type d -empty -delete/
    `#{cmd}`
  }
end
