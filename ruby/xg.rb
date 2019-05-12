#!/usr/bin/ruby
#
# Wrapper to enter Inway/Camino project
#
# Todo:
# - init projects list from file .inway_projects in home

require 'getoptlong'

module Xg

   # Module variable
   @debug = false

   # Container class for project attributes, derived from Struct
   class InwayPrj < Struct.new(:nicknames, :iversion, :iprj, :isubprj, :iunit)
   end

   # ------------------------------------------------------------------------------------------
   # Init list of projects (as module constant):
   #              [nicknames]          Inway-version   project     sub-project          default-unit
   PROJECTS = [
      InwayPrj.new(["core", "ig32"],    99,            "ig32",     "core",            "ig32_cpu" ),
      InwayPrj.new(["cc40"],           99,             "cc40",     "m5270",           ""            ),
      InwayPrj.new(["7upd", "debug"],  99,             "sevenup",  "debug",           ""            )
   ]

   # ------------------------------------------------------------------------------------------
   # Definitions
   #
   def Xg.print_projects
      temp = PROJECTS.collect { |prj| prj.nicknames.join("/")}
      return "[\n    " + temp.join("\n    ") + "\n]"
   end

   usage = "Wrapper to enter Inway project.
Usage: #{$0} [-h] or [-d] <project> [<view>]
with -h   print usage and exit
     -d   print command and exit
<project> one of #{print_projects}
<view>    give an optional view-name for the project (default: default)
"

   # Extend InwayPrj class
   class InwayPrj
      # Method to get my Inway wrapper script depending on the Inway version
      def get_inway_wrapper
         case iversion
         when 4
            return "inway4_linux.sh"
         when 5, 6
            return "inway6_linux.sh"
         else
            return "camino"
         end
      end
   end

   # Assemble command-string to launch the Inway shell
   def Xg.get_command_str(prj, view = "default")
      unit = ""
      if not prj.iunit.empty?
         unit = "-unit #{prj.iunit}"
      end

      if prj.iversion == 4
         command_str = [prj.get_inway_wrapper, prj.iprj, prj.isubprj, view, "-quiet -keepcs", unit, ARGV].join(" ");
      else
         command_str = [prj.get_inway_wrapper, prj.iprj, prj.isubprj, view, "-quiet -workarea keep", unit, ARGV].join(" ");
      end
      return command_str
   end

   # Get matching project by its nickname; returns nil if not exactly one is found.
   def Xg.get_project(name = "")
      found = false
      result = nil
      for prj in PROJECTS
         for nickname in prj.nicknames
            if name == nickname
               if not found
                  found = true; result = prj
               else
                  puts "ERROR: given project name #{name.inspect} matches more than one project"
               end
            end
         end
      end
      if not found
         puts "ERROR: given project name #{name.inspect} does not match known projects, one of #{print_projects}"
      end
      return result
   end

   # ------------------------------------------------------------------------------------------
   # Main script
   #
   if __FILE__ == $0 # prevent execution if imported by another module

      # Parse Options
      opts = GetoptLong.new(
                            [ "--help",  "-h", GetoptLong::NO_ARGUMENT ],
                            [ "--debug", "-d", GetoptLong::NO_ARGUMENT ]
                            )
      opts.each do |opt, arg|
         if opt == "--help"
            print usage
            exit
         end
         if opt == "--debug"
            @debug = true
         end
      end

      # Remaining arguments
      name = ARGV.shift
      view = "default"
      if ARGV.length > 0
         view = ARGV.shift
      end

      # Make it so
      matching_project = get_project(name)
      if matching_project != nil
         command_str = get_command_str(matching_project, view)
         puts command_str
         if not @debug
            system(command_str)
         end
      else
         exit 1
      end
   end
end
