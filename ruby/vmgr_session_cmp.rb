#!/usr/bin/ruby
#
# Compares the .vsof files of two vManager sessions
# Author: Thorsten Dworzak <thorsten.dworzak@verilab.com>
#

require 'getoptlong'
require 'find'

#
# Globals
#

$USAGE="Usage:
#{$0} <options>

This script compares the .vsof files of two vManager sessions. The sessions must use the same seeds,
i.e. typically one is the re-run of the other. Currently the only supported comparison attribute is
the simulation time, which is a good indicator of whether to runs differ.

<options>:
--help, -h:
   print usage
--left<session_id>, -l <session_id>:
   supply first vmanager session-id
--right<session_id>, -r <session_id>:
   supply next vmanager session-id
where <session_id> is a unique 4-digit number which must match the trailing digits of a vManager session-name.
E.g. session name is yourbelovedprojectname.yourbelovedusername.18_08_09_17_13_08_0120 -> id = 0120

Example:
> #{$0} -l 6780 -r 4523

"
$REGRESSION_DIR = "yourbeloveddir" + ENV['USER'] + "yourotherbeloveddir"
$VSOF_NAME      = "export0.vsof"

#
# Module definition
#
module VmanagerSessionCompare

   ME = File.basename(__FILE__, ".rb")

   #
   # Struct representing only the interesting run-container attributes
   # Just add more to the struct constructor call if required.
   #
   class RunContainer < Struct.new(:test_name, :sv_seed, :simulation_time)
      def method_missing(name, *args, &block)
         # puts "ignored #{name}"
      end
   end

   #
   # Class storing comparison result
   #
   class ComparisonResult
      attr_reader :time_delta

      def initialize(test_name_, sv_seed_, simulation_time_1_, simulation_time_2_)
         @test_name  = test_name_
         @sv_seed    = sv_seed_
         @time_delta = (simulation_time_1_.to_i - simulation_time_2_.to_i) / 1000000
      end

      def print
         printf("Test: %40s, Seed: %13s, Simulation Time Delta: %14d\n", @test_name.sizeup(40), @sv_seed, @time_delta)
      end
   end

   #
   # Class collecting all run-containers of a vmanager session
   #
   class Session
      attr_reader   :name
      attr_reader   :kind
      attr_accessor :runs

      # Initialize
      def initialize(name_="new_session", kind_="kind")
         @name      = name_
         @kind      = kind_
         @@block_re = Regexp.new(/(\w+)\s+([\w"]+)\s+\{/)
         @@entry_re = Regexp.new(/(\w+)\s+:\s+(<text>\s*)*([^;<]+)(<\/text>\s*)*;/)
         @runs      = Array.new()
      end

      # Read all unique .vsof files of a session
      def read_vsofs(filenames)
         # Iterate over all .vsof files of a session and extract a run-container for each
         @runs = Array.new()
         filenames.each {|filename|
            run_container = get_single_run_container(filename)
            if run_container != nil then
               # puts run_container.inspect
               @runs.push(run_container)
            else
               puts "#{ME} [ERROR]: no single-run container found in vsof file #{filename}"
            end
         }
      end

      # Parse a single-run vsof file and return its run-container
      def get_single_run_container(filename)
         block_lvl     = 0
         run_container = nil
         block_name    = ""
         block_val     = ""
         n_line        = -1;
         # Iterated over all lines and parse the {... } block entries
         IO.foreach(filename) {|line|
            n_line += 1
            match = @@block_re.match(line);
            if match != nil then
              # Block start
              block_name = match[1];
              block_val  = match[2];
              block_lvl += 1
              # print "block \"#{block_name}\" value \"#{block_val}\" level #{block_lvl}\n"
              next
            elsif line =~ /^\s*\}\s*$/ then
              # Block end
              block_lvl -= 1
              return run_container if run_container != nil
              next
            elsif block_lvl == 1 then
               match  = @@entry_re.match(line)
               if (match != nil) and (match[1] != nil) then
                  attrib = match[1]
                  value  = match[3]
                  case block_name
                  when "run"
                     # extract the real testname that is hidden in the parent_run attribute
                     next if (attrib == "test_name")
                     if (attrib == "parent_run")
                        attrib = "test_name"
                        if /(\w+)@\d+/.match(value)
                           value = $+
                        else
                           puts "#{ME} [ERROR]: could not extract testname from parent_run attribute (file #{filename} line #{n_line})"
                           value = "UNKNOWN"
                        end
                     end
                     if !run_container then
                        run_container = RunContainer.new()
                     end
                     # some Ruby magic: send all attributes to the RunContainer object by invoking an accessor method
                     # which is ignored if the object does not care about
                     run_container.send("#{attrib}=", value)
                  when "session_output"
                     # check if this is the correct file-type
                     if (attrib == "session_type" && value != "single_run")
                        puts "#{ME} [ERROR]: session_type #{value} not supported (file #{filename} line #{n_line}; must be single_run.)"
                        return nil
                     end
                  end
               end
            end
         }
         return nil
      end
   end


   #
   # Main part of module
   #

   # helper methods in String class
   class ::String
      def sizeup(max_len=80)
         return (max_len>15 and size>max_len) ? self[0..max_len/10]+"[...]"+self[-(max_len-max_len/10-6)..-1] : self
      end

      def red; "\e[31m#{self}\e[0m" end
   end

   # Parse options, get session IDs
   session_ids = {}
   opts = GetoptLong.new( [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
                          [ '--left', '-l', GetoptLong::REQUIRED_ARGUMENT ],
                          [ '--right', '-r', GetoptLong::REQUIRED_ARGUMENT ]
                         )
   opts.each { | opt, arg |
      case opt
      when '--help'
         puts $USAGE
         exit 0
      when '--left'
         session_ids["left"] = arg
      when '--right'
         session_ids["right"] = arg
      end
   }

   if session_ids.size != 2 then
      puts "#{ME} [ERROR]: must supply 2 session IDs"
      puts $USAGE
      exit 1
   end

   # Find the actual session names
   session_names = {}
   Find.find($REGRESSION_DIR) { |path|
      if FileTest.directory?(path) then
         session_ids.each { |kind, session_id|
            if path =~ /#{session_id}$/ then
               session_names[kind] = File.basename(path)
            end
         }
         if path != $REGRESSION_DIR
             Find.prune # don't descend into sub-dirs
         end
      else
         next
      end
   }


   if session_names.size != 2 then
      puts "#{ME} [ERROR]: can't find all sessions matching the supplied IDs: #{session_ids.values.join(' ')}"
      exit 1
   end

   # Now get two session data sets for comparison
   sessions = Array.new(0)

   session_names.keys.sort.each { |kind|
      session_name = session_names[kind]
      tests_dir    = $REGRESSION_DIR + session_name + "/chain_*/tests"
      pipe         = IO.popen("find -L " + tests_dir + " -type f -name #{$VSOF_NAME}")
      vsof_files   = pipe.readlines.map { |file| file.chomp }
      if vsof_files != nil and vsof_files.size != 0 then
         session = Session.new(session_name, kind);
         puts "#{ME} [INFO]: reading session #{session.kind}..."
         session.read_vsofs(vsof_files)
         sessions.push(session)
      end
   }

   if sessions.size != 2
      puts "#{ME} [ERROR]: failed to read one or both session .vsof files"
      exit 1
   end

   if sessions[0].runs.size != sessions[1].runs.size
      puts "#{ME} [WARNING]: number of runs differs between sessions: #{sessions[0].kind} #{sessions[0].runs.size} vs. #{sessions[1].kind} #{sessions[1].runs.size}"
      # exit 1
   end

   # Sort by seed, assuming the seeds are unique, and store in new list
   puts "#{ME} [INFO]: diffing #{sessions[0].kind} <-> #{sessions[1].kind}..."
   results = Array.new(0)
   compared_sessions = 0
   sessions[0].runs.each { |run|
      other_idx = sessions[1].runs.find_index { |item| (item.sv_seed == run.sv_seed) && (item.test_name == run.test_name) }
      if other_idx != nil then
         # if sessions[1].runs[other_idx].test_name != run.test_name
         #    puts "#{ME} [ERROR]: runs with matching seeds #{run.sv_seed } must have the same test_name attribute"
         #    exit 1
         # end
         # Store comparison result only if there is a simulation-time difference
         compare = ComparisonResult.new(run.test_name, run.sv_seed, run.simulation_time, sessions[1].runs[other_idx].simulation_time)
         if compare.time_delta != 0
            results << compare
         end
         compared_sessions += 1
      else
         puts "#{ME} [WARNING]: could not find seed #{run.sv_seed} in session #{sessions[0].kind} - skipping run of #{run.test_name}"
      end
   }

   # Display results, sorted by abs value of time difference
   printf("%s (%s) <-> %s (%s)\n", sessions[0].name.sizeup(40), sessions[0].kind, sessions[1].name.sizeup(40), sessions[1].kind)
   any_diffs = 0
   results.sort { |a,b| a.time_delta.abs <=> b.time_delta.abs }.each {|it|
      any_diffs += 1
      it.print
   }

   puts "#{ME} [INFO]: compared #{compared_sessions} out of #{sessions[1].runs.size} runs."
   puts "#{ME} [INFO]: no differences found!" unless (any_diffs >0)
   puts "#{ME} [INFO]: #{any_diffs} runs are different!" unless (any_diffs == 0)

end
