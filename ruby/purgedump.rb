#!/usr/bin/ruby
#
# Author: Thorsten Dworzak
# 
# Description: Removes all files in directories matching patterns <dir_patterns>
# and below that are older than <days>.
# TODO: use config file to define directories, patterns, days
#

#
# User setup
#

# Common directories to purge
dir_patterns = [
   {"~/temp"      => ["*"]},
   {"~/.lsbatch"  => ["*"]},
]

# project dependent
ies_patterns = [
   "*.log", "*.out", ".DEFAULT", "*.vsof", "ncsim_*.err", "*.dsn", "*.trn", "*.elog"
]
questa_patterns = [
   "*.wlf","*.ucm", "*.ucd", "*.ucdb", "transcript"
]
ack_patterns = [
   "*.job", "*.log", "*.cache", "*.ELF", "*.o", "*.o.s"
]

if ENV["WORKAREA"]
  dir_patterns.push(
    {"#{ENV["MY_REGRESSION_AREA"]}"                               => ies_patterns}
  )
end

if ENV["IRIS_VERIFICATION"]
  # project dependent directories to purge
  dir_patterns.push(
    {"#{ENV["IRIS_VERIFICATION"]}/tb/e/fme_iris_mgp"              => ies_patterns },
    {"#{ENV["IRIS_VERIFICATION"]}/tb/e/fme_iris_mgp/*/INCA_libs"  => ["*"] }
  )
end

# max age of files
days = 37

# Shell command(s)
find = "/usr/bin/find -P"

# helper method
def sizeup(str)
  return str.size>80 ? str[0..9]+"[...]"+str[-65..-1] : str
end

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
      puts "deleting #{pattern} files in #{sizeup(dir)} ..."
      cmd = %Q/#{find} #{dir} -xautofs -xdev -type f -name "#{pattern}" -mtime +#{days} -delete/
      `#{cmd}`
    }

    # Delete empty dirs below <dir>
    puts "deleting empty dirs in #{sizeup(dir)} ..."
    cmd = %Q/#{find} #{dir} -xautofs -xdev -type d -empty -delete/
    `#{cmd}`
  }
end
