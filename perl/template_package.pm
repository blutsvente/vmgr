#------------------------------------------------------------------------------
#
# Author      : Thorsten Dworzak <thorstenx.dworzak@verilab.com>
# Description : Template for non-OO Perl package
#
#------------------------------------------------------------------------------

package <package_name>;

#------------------------------------------------------------------------------
# Used packages
#------------------------------------------------------------------------------
use strict;
use FindBin qw($Bin);
use lib "$Bin";
use lib "$Bin/..";
use lib "$Bin/lib";

require Exporter;
@ISA=qw(Exporter);
@EXPORT_OK = qw ( VERSION <exported symbols> );

#------------------------------------------------------------------------------
# Global variables
#------------------------------------------------------------------------------

# export version (update manually whenever deemed necessary, e.g. method added)
our($VERSION) = '0.1';

our($debug) = 0;

#------------------------------------------------------------------------------
# Subroutines
#------------------------------------------------------------------------------

1;
