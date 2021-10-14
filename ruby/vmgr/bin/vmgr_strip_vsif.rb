#!/usr/bin/ruby
#
# Ruby Vmgr (Vmanager) library
#
# Reads a .vsif file (usually exported from the re-run dialog of a session)
# and removes all attributes not required to re-run it.
# ---
# Author: Thorsten Dworzak <thorsten.dworzak@verilab.com>
# ---

require 'getoptlong'
require 'find'
require File.expand_path('../lib/vmgr/collaterals.rb', File.dirname(__FILE__))
require File.expand_path('../lib/vmgr/testcontainer.rb', File.dirname(__FILE__))
require File.expand_path('../lib/vmgr/session.rb', File.dirname(__FILE__))

#
# Globals
#

$USAGE="Usage:
#{$0} [<options>] <vsif-file>

This script reads a .vsif file and strips it of all attributes not needed for re-run. The motivation
is to be able to use a .vsif file exported from any session (i.e. not necessarily the user's)..

<options>:
--help, -h:
   print usage

Example:
> #{$0} debug.vsif

"

#
# Module definition
#
module Vmgr

    ME = File.basename(__FILE__, ".rb")

    #
    # Main part of module
    #

    # Parse options
    vsif_file = ""
    opts = GetoptLong.new( [ '--help', '-h', GetoptLong::NO_ARGUMENT ]
                        )
    opts.each { | opt, arg |
      case opt
      when '--help'
          puts $USAGE
          exit 0
      end
    }

    if ARGV.size != 1 then
      puts "#{ME} [ERROR]: must supply one vsif file as input"
      puts $USAGE
      exit 1
    else
      vsif_file = ARGV[0];
    end

    session = Session.new("Re-run session");
    session.read_vsif(vsif_file);


end
