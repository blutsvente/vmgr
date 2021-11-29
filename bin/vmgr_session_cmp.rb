#!/usr/bin/ruby
#
# Ruby Vmgr (Vmanager) library
#
# Compares the .vsof files of two vManager sessions
# ---
# Author: Thorsten Dworzak <thorsten.dworzak@verilab.com>
# ---

require 'getoptlong'
require 'find'
require File.expand_path('../lib/vmgr/collaterals.rb', File.dirname(__FILE__))
require File.expand_path('../lib/vmgr/runcontainer.rb', File.dirname(__FILE__))
require File.expand_path('../lib/vmgr/session.rb', File.dirname(__FILE__))

#
# Globals
#

$REGRESSION_DIR = ENV['MY_REGRESSION_AREA'] + '/fme_iris_mgp'
$VSOF_NAME      = "export0.vsof"

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
E.g. session name is projectname.username.18_08_09_17_13_08_0120 -> id = 0120

Example:
> #{$0} -l 6780 -r 4523

"

#
# Module definition
#
module Vmgr

   ME = File.basename(__FILE__, ".rb")

   #
   # Class storing comparison result
   #
   class ComparisonResult
      attr_reader :time_delta

      def initialize(test_name_, seed_, simulation_time_1_, simulation_time_2_)
         @test_name  = test_name_
         @seed       = seed_
         @time_delta = (simulation_time_1_.to_i - simulation_time_2_.to_i) / 1000000
      end

      def print
         printf("Test: %40s, Seed: %13s, Simulation Time Delta: %14d\n", @test_name.sizeup(40), @seed, @time_delta)
      end
   end

   #
   # Main part of module
   #

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
      puts "#{ME} [ERROR]: can't find all sessions matching the supplied IDs: #{session_ids.values.join(' ')} (found #{session_names.size}"
      exit 1
   end

   # Now get two session data sets for comparison
   sessions = Array.new(0)

   session_names.keys.sort.each { |kind|
      session_name = session_names[kind]
      # Note: the line below is vmanager version-dependent
      tests_dir    = $REGRESSION_DIR + '/' + session_name + "/chain_*/run_*/"
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
      other_idx = sessions[1].runs.find_index { |item| (item.seed == run.seed) && (item.test_name == run.test_name) }
      if other_idx != nil then
         # if sessions[1].runs[other_idx].test_name != run.test_name
         #    puts "#{ME} [ERROR]: runs with matching seeds #{run.seed } must have the same test_name attribute"
         #    exit 1
         # end
         # Store comparison result only if there is a simulation-time difference
         compare = ComparisonResult.new(run.test_name, run.seed, run.simulation_time, sessions[1].runs[other_idx].simulation_time)
         if compare.time_delta != 0
            results << compare
         end
         compared_sessions += 1
      else
         puts "#{ME} [WARNING]: could not find seed #{run.seed} in session #{sessions[0].kind} - skipping run of #{run.test_name}"
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
