eval 'exec perl -S $0 ${1+"$@"}'
if 0;
#------------------------------------------------------------------------------
#
# Author      : Thorsten Dworzak <thorstenx.dworzak@verilab.com>
# Description : Template for executable Perl script
#
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Global variables
#------------------------------------------------------------------------------
our($debug, $this);

#------------------------------------------------------------------------------
# Used packages, initialisation, commandline parameters etc.
#------------------------------------------------------------------------------
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use lib "$Bin/..";
use lib "$Bin/lib";
use Getopt::Std;
use File::Basename;
use Cwd;
use Data::Dumper;

BEGIN {
   $debug=1;     # debug mode off = 0, on = 1

   # initialisation and get commandline arguments
   $this = basename($0);

   $usage="
Usage        : $this\n
Description  :\n
Options      : 
";
};

#------------------------------------------------------------------------------
# Main part of script
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Subroutines
#------------------------------------------------------------------------------

1;
