#!/usr/bin/env ruby
#
# Wrapper to enter shell in Inway/Camino/ICManage project
#
# Todo:
# - init projects list from file .xg_setup in home
#

require 'getoptlong'

module Xg

   # Module variable
   @debug        = false
   @ME           = $0
   @terminal_exe = "gnome-terminal --profile = My"

   # Container classes for project attributes, derived from Struct
   class Prj < Struct.new(:nicknames, :iversion, :iprj, :isubprj, :iunit)
   end

   # ------------------------------------------------------------------------------------------
   # Init list of projects (as module constant):
   #              [nicknames]     Project-tool/version   project     sub-project        default-unit/dir
   PROJECTS = [
       Prj.new(["phase2", "6m"], :icmanage,          "mxvideoss",      "dev6m_5",     "vvideoio"),
       Prj.new(["ver1", "4m"],   :icmanage,          "mxvideoss",      "dev4m_2",     "vvideoio"),
       Prj.new(["ver2"],         :icmanage,          "mxvideoss_ver2", "dev_4",       "vvideoio")

      #,Prj.new(["core", "ig32"],    :v99,          "ig32",     "core",            "ig32_cpu")
      #,Prj.new(["cc40"],            :v99,          "cc40",     "m5270",           ""        )
      #,Prj.new(["7upd", "debug"],   :v99,          "sevenup",  "debug",           ""        )
   ]

   # ------------------------------------------------------------------------------------------
   # Definitions
   #
   def Xg.print_projects
      temp = PROJECTS.collect { |prj| prj.nicknames.join(" or ")}
      return "[\n    " + temp.join("\n    ") + "\n]"
   end

   usage = "Wrapper to enter Inway project.
Usage: #{@ME} [-h] or [-d] <project> [<view/sub-dir>]
with -h           print usage and exit
     -d           print command and exit
<project>         nickname of project, available are\n#{print_projects}
<view/sub-dir>    give an optional view/subdirectory-name to enter
"

   # Extend Prj class
   class Prj
      # Method to get my Inway wrapper script depending on the procect-tool version
      def get_wrapper
         case iversion
         when :v4
            return "inway4_linux.sh"
         when :v5, :v6
            return "inway6_linux.sh"
         when :icmanage
            return "#{ENV['PROJMENUROOT']}/proj.menu.rb"
         else
            return "camino"
         end
      end
   end

   # Assemble command-string to launch the shell in the project
   def Xg.get_command_str(prj, view = "default")
      unit = ""
      if not prj.iunit.empty?
         unit = "-unit #{prj.iunit}"
      end
      if view == "default"
         subdir = prj.iunit
      else
         subdir = view
      end

      case prj.iversion
      when :v4
         command_str  = [prj.get_wrapper, prj.iprj, prj.isubprj, view, "-quiet -keepcs", unit, ARGV].join(" ");
      when :icmanage
         workspace    = [ENV['USER'], prj.iprj, prj.isubprj].join("_")
         dir          = ["/proj/gpfs/#{ENV['USER']}/workspaces", workspace, subdir].join("/")
         terminal_cmd = "/bin/sh -c 'export WORKSPACE=#{workspace}; cd #{dir}; exec tcsh'"
         command_str  = prj.get_wrapper + " -projset #{prj.iprj} > /dev/null 2>&1;" +
            prj.get_wrapper + " -projsetwa #{prj.isubprj};" + " #{@terminal_exe} -- #{terminal_cmd}"
      else
         command_str  = [prj.get_wrapper, prj.iprj, prj.isubprj, view, "-quiet -workarea keep", unit, ARGV].join(" ");
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
                  STDERR.puts "#{@ME} ERROR: given project name #{name.inspect} matches more than one project"
               end
            end
         end
      end
      if not found
         STDERR.puts "#{@ME} ERROR: given project name #{name.inspect} does not match known projects, one of #{print_projects}"
      end
      return result
   end

   # ------------------------------------------------------------------------------------------
   # Main script
   #
   if __FILE__ == @ME # prevent execution if imported by another module

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
      view = ARGV.shift if ARGV.length > 0

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
