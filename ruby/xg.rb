#!/usr/bin/env ruby
#
# Wrapper to enter shell in Inway/Camino/ICManage project
#
# TODO:
# - init projects list from file YAML/JSON file in home
#

require 'getoptlong'

module Xg

   # Module variables - User setup
   @debug        = false
   @terminal_exe = "gnome-terminal --profile=My"

   # Other module variables
   @ME           = $0

   # Container classes for project attributes, derived from Struct
   class Prj < Struct.new(:nicknames, :iversion, :iprj, :isubprj, :iunit, :comment)
   end

   # ------------------------------------------------------------------------------------------
   # Init list of projects (as module constant):
   #              [nicknames]          Project-tool/version   project      sub-project     default-unit/ddc    comment
   PROJECTS = [
       Prj.new(["phase2", "p2"],   :icmanage,       "mxvideoss",           "dev6m_8",     "vmxvideoss"                                           ) ,
       # Prj.new(["phase2e", "p2e"],     :icmanage,       "mxvideoss",       "dev6m_5",     "vvideoio"                                             ) ,
       Prj.new(["ver1", "4m"],     :icmanage,       "mxvideoss",           "dev4m_2",     "vvideoio"                                             ) ,
       Prj.new(["ddre"],           :icmanage,       "mxvideoss_ddr",       "dev_10",      "vmxvideoss_ddr"  , "old ws with Specman/e repo checkouts" ) ,
       Prj.new(["ddr"],            :icmanage,       "mxvideoss_ddr",       "dev_13",      "vmxvideoss_ddr"  , "main ws for vmxvideoss_ddr"           ) ,
       Prj.new(["ddrd"],           :icmanage,       "mxvideoss_ddr",       "dev_12",      "mxvideoss_ddr"   , "design-only ws (dev_all config)"      ) ,
       Prj.new(["ddricm"],         :icmanage,       "mxvideoss_ddr",       "dev_16",      "vmxvideoss_ddr"  , "for ICM release/vaulting"             ) ,
       Prj.new(["iop"],            :icmanage,       "mxvideoss_ddr",       "dev_17",      "vmxvideoss_ddr"  , "for IOP testbench"                ),
       Prj.new(["gfx"],            :icmanage,       "mxs22gfxss",          "1.0-dev_18",  "vmxs22gfxss"     , "main ws for vmxs22gfxss"          )
   ]

   # ------------------------------------------------------------------------------------------
   # Definitions
   #
   def Xg.print_projects
      temp = PROJECTS.collect { |prj| prj.nicknames.join(" or ")}
      max_str_width = 0
      temp.each { |l|
         if l.size > max_str_width
            max_str_width = l.size
         end
      }
      temp.each_with_index { |l, index|
         if nil != PROJECTS[index].comment and not PROJECTS[index].comment.empty?
            temp[index] = l + ' ' * (max_str_width - l.size) + ' > ' + PROJECTS[index].comment
         end
      }
      return "[\n    " + temp.join("\n    ") + "\n]"
   end

   usage = "Wrapper to enter IcManage/Inway/Camino project.
Usage: #{@ME} [-h] or [-d] <project> [<view/sub-dir>]
with -h           print usage and exit
     -d           print command(s) and exit
<project>         nickname of project, available are\n#{print_projects}
<view/sub-dir>    give an optional view/subdirectory-name to enter
"

   # Extend Prj class
   class Prj
      # Method to get project-entry script depending on Prj members
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
         # remove version from variant, the workspace naming is not consistent; if e.g. variant 1.0-dev
         # then the workspace name is dev_<id>
         wa_id        = prj.isubprj.sub(/^.*(dev_.+$)/, '\1')

         # 1. set the project in the current shell 2. set the workspace 3. launch a new terminal
         # note: if the workspace is new, user must first call projupdate; this is currently not handled by the script
         command_str  = prj.get_wrapper + " -projset #{prj.iprj} > /dev/null 2>&1;" \
                      + prj.get_wrapper + " -projsetwa #{wa_id};" + " #{@terminal_exe} --title #{workspace} -- #{terminal_cmd}"
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
         system(command_str) if not @debug
      else
         exit 1
      end
   end
end
