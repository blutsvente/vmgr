#!/usr/bin/ruby
#
# Removes all files in directories matching patterns <dir_patterns>
# and below that are older than <days>.
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
  # project dependent directories to purge
  dir_patterns.push(
    {"#{ENV["WORKAREA"]}/units/tb_ig32_ack/simulation"                   => ies_patterns},
    {"#{ENV["WORKAREA"]}/units/tb_ig32_ack/simulation/ncsim/INCA*libs"   => ["*"]},
    {"#{ENV["WORKAREA"]}/units/ig32_cpu/simulation"                      => ies_patterns},
    {"#{ENV["WORKAREA"]}/units/ig32_cpu/simulation/ncsim/INCA*libs"      => ["*"]},
    {"#{ENV["AVKRUN_HOME"]}/../*/jobs"        => ["*"]},
    {"#{ENV["AVKRUN_HOME"]}/../*/suites"      => ["*"]},
    {"#{ENV["AVKRUN_HOME"]}/../*/tests"       => ["*"]},
    {"#{ENV["AVKRUN_HOME"]}/../*/"            => ack_patterns},
    {"#{ENV["WORKAREA"]}/units/ig32_cpu/source/sc/models/win_release_*"  => ["*"]},
    {"/opt/tmp_share/#{ENV["USER"]}/val_tmp/*.VAL"                       => ["*"]}
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
