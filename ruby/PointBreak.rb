#
# Description: Ruby module to create set NCSim breakpoints via new command-line interface
# Author: Thorsten Dworzak <thorsten.dworzak@verilab.com>
#

require 'readline'

# Public: Script that takes user input using TAB completion. The set of strings for completions
# are filenames in SV directories. The set of directories is taken from the HDAEXE search list.
#
module PointBreak

   attr_writer(:output_filename, :hdaexe_search_paths, :hdaexe_take_keys, :file_extensions, :common_file_prefixes)

   ME = File.basename(__FILE__, ".rb")

   def initialize
      #
      # Default setup for breakpoints in SystemVerilog code in IG32 project
      #

      # File that will contain the breakpoint commands (if empty, dump to stdout)
      @output_filename         = ""

      # Public: string of absolute file-name of HDAEXE search list
      @hdaexe_search_paths     = "./hdaexe_search_paths.lst"

      # Public: hash keys that will be considered in HDAEXE search list
      @hdaexe_take_keys        = %w(sv_include_dirs)

      # Public: string list with file extensions that are considered for auto-completion
      @file_extensions         = %w(sv svh)

      # Public: string list with file-name prefixes that are used in auto-completion
      @common_file_prefixes    = %w(isg_ ig32_ ig32_isg_ tb_ ifx_)
   end

   # Internal: class representing a NCSim breakpoint
   class BreakPoint

      # Public: constructor
      #
      # file - string filename
      # line - int line number
      # time - string time
      #
      def initialize(file, line, time = "")
         @at_file = file.strip
         @at_line = line
         @at_time = time
      end

      def to_s
         result = ""
         if @at_time.size > 0
            @at_time.strip!
            result << "stop -create -time -absolute #{@at_time} -delbreak 0 -execute { "
         end
         result << "stop -create -line #{@at_line} -file #{@at_file} -all"
         if @at_time.size > 0 then result << " } -noexecout" end
         result
      end
   end

   # Internal: Get a list of Unix paths extracted from the HDAEXE search list
   #
   # The HDAEXE search list is a Perl script. We execute it, printing the directories that
   # we are interested in and store them in a ruby list
   #
   # Returns list of strings
   def get_search_paths
      if ! (File.exists?(@hdaexe_search_paths) || File.symlink?(@hdaexe_search_paths))
         $stderr.puts "#{ME}:ERROR: file \"#{@hdaexe_search_paths}\" not found"
         sleep 2
         exit 1
      end

      exec_cmd = "perl -e \'require \"#{@hdaexe_search_paths}\"; print join(\" \","
      @hdaexe_take_keys.each { |key| exec_cmd << "@{$HdaexeInputs::searchPathsHdaexe->{\'#{key}\'}}," }
      exec_cmd.chop!
      exec_cmd << ") . \"\\n\"\'"

      search_paths = `#{exec_cmd}`.chomp.split
   end

   # Internal: Get all files in dir with pre-defined extensions from list file_extensions
   #
   # dir - The string containing directory to search
   #
   # Returns list of files
   def get_files(dir)
      exec_cmd = "find -H #{dir} -type f \\( "
      exec_cmd << @file_extensions.map { |e| "-name \"*.#{e}\" " }.join("-o ")
      exec_cmd << "\\)"
      files=`#{exec_cmd}`.split
   end

   # Internal: Build hash with all files in search directores where basename(filename) => dirname(filename)
   #
   # dirs - list with search dirs
   #
   # Returns hash
   def get_files_from_search_dirs(dirs)
      # puts "\'#{dirs}\'"
      # puts get_files(dirs.at(0)).size

      # Create hash with basename(filename) => dirname(filename)
      files = Hash.new
      dirs.each { |s| get_files(s).map { |f| files.store(File.basename(f), File.dirname(f)) } }
      # puts files.keys.join("\n")
      return files
   end

   # Public: Create a breakpoint and dump it to file/stdout
   def create_breakpoint()
      search_paths = get_search_paths
      all_files    = get_files_from_search_dirs(search_paths)

      # Call readline to get user input
      prefixes = "(" << @common_file_prefixes.join("|") << ")"
      compare  = proc { |s| all_files.keys.grep(/^#{prefixes}*#{Regexp.escape(s)}/) }

      Readline.completion_append_character     = " "
      Readline.completer_word_break_characters = ""
      Readline.completion_proc                 = compare
      puts "Welcome to Point Break.\nEnter part of filename where breakpoint should be set,\n<TAB> will complete the filename,\n<ENTER> confirms,\n. (dot) takes last breakpoint, if any."
      input = Readline.readline("file: ", true)

      if input == "."
         return # do nothing, keep old file
      end

      at_file = input.strip!
      at_line = 0
      at_time = ""
      bp      = nil

      if !all_files.has_key?(at_file)
         $stderr.puts "#{ME}:ERROR: no such file"
         sleep 2
         return
      end

      at_file = all_files[at_file] + "/" + at_file
      line_str = Readline.readline("line: ", false)
      if line_str.size > 0
         line_str.strip!
         at_line = line_str.to_i
         if at_line.to_s == line_str # is numeric?
            while bp == nil do
               Readline.completion_append_character = ""
               at_time = Readline.readline("after time [0 ns]: ", false)
               if (at_time.size =~ /\s*/)
                  at_time = ""
               elsif (at_time =~ /\d+\s*\D\D?/)
                  at_time.strip!
               else
                  $stderr.puts "#{ME}:WARNING: invalid timespec, should be e.g. \"10000 ns\""
                  next
               end
               bp = BreakPoint.new(at_file, at_line, at_time)
            end
         else
            $stderr.puts "#{ME}:ERROR: line must be numeric"
            sleep 2
            return
         end
      else
         $stderr.puts "#{ME}:ERROR: line is mandatory"
         sleep 2
         return
      end

      if @output_filename.size > 0
         fh = File.new("#{@output_filename}", "w")
      else
         fh = $stdout
      end
      fh.puts "#{bp.to_s}"
   end
end

# Exec hdaexe_search_paths.lst
# perl -e 'require "hdaexe_search_paths.lst"; print "content:" . join(",", @{$HdaexeInputs::searchPathsHdaexe->{'sv_include_dirs'}}) . "\n"'

# Example break-points
# ncsim> stop -create -time 30000 ns -delbreak 0 -absolute -execute \
#   {stop -create -file /var/vob/ig32/core/vob/units/ig32_cpu/source/sv/tb_cpu/include/sequences/pfu2ic_if_seq/ig32_pfu2ic_if_default_ic_seq.svh -line 257 -all}
# ncsim> stop -create -file /var/vob/ig32/core/vob/units/ig32_cpu/source/sv/tb_cpu/include/ig32_tb_monitor.svh -line 1207 -all
# ncsim> stop -create -file /var/vob/ig32/core/vob/units/ig32_cpu/source/sv/tb_cpu/include/sequences/pfu2ic_if_seq/ig32_pfu2ic_if_default_ic_seq.svh -line 214 -all
# ncsim> stop -create -file /var/vob/ig32/core/vob/sv_packs/tb/ig32_common/sv/ig32_fault.svh -line 93 -all
