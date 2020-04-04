#!/tools/apps/ruby/ruby.2.1
#
# Reads a .vsif file and creates a sanity .vsif file with all tests
# running once with seed 1.
# Author: Thorsten Dworzak <thorsten.dworzak@verilab.com>
#

require 'getoptlong'
require 'find'
require File.expand_path('../lib/vmgr/collaterals.rb', File.dirname(__FILE__))
require File.expand_path('../lib/vmgr/testcontainer.rb', File.dirname(__FILE__))
require File.expand_path('../lib/vmgr/groupcontainer.rb', File.dirname(__FILE__))
require File.expand_path('../lib/vmgr/session.rb', File.dirname(__FILE__))

#
# Globals
#

$USAGE="Usage:
#{$0} [<options>] <vsif-file>

This script reads a .vsif file and creates a sanity .vsif file with all tests
running once with seed 1.

<options>:
--help, -h:
   print usage
--out, -o:
   name of output file (extension .vsif not required)

Example:
> #{$0} main.vsif -o sanity

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
   vsif_out = "sanity.vsif"
   opts = GetoptLong.new( [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
                          [ '--out' , '-o', GetoptLong::OPTIONAL_ARGUMENT]
                         )
   opts.each { | opt, arg |
      case opt
      when '--help'
         puts $USAGE
         exit 0
      when '--out'
         vsif_out = File.dirname(arg) + "/" + File.basename(arg, ".vsif") + ".vsif"
      end
   }

   if ARGV.size != 1 then
      puts "#{ME} [ERROR]: must supply one vsif file as input"
      puts $USAGE
      exit 1
   else
       vsif_file = ARGV[0];
   end

   session = Session.new();
   session.read_vsif(vsif_file);

   session.write_vsif(vsif_out);

end
