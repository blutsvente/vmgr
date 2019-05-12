eval 'exec perl -S $0 ${1+"$@"}'
if 0;
#------------------------------------------------------------------------------
#
# Author      : Thorsten Dworzak <thorsten.dworzak@verilab.com>
# Description : Convert VHDL entity/component file into Verilog instantiation
#
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Global variables
#------------------------------------------------------------------------------
our($debug, $this, $usage, $filename, %hopts);

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
use toolbox;
use Tie::IxHash;

BEGIN {
   $debug=1;     # debug mode off = 0, on = 1

   # initialisation and get commandline arguments
   $this = basename($0);

   $usage="
Usage        : $this -v <vhdl-file>\n
Description  : Convert VHDL entity/component file into Verilog instantiation\n
Options      : -v <vhdl-file> - input containing a VHDL-93 entity/component declaration
";
};
my $n_args = scalar(@ARGV);
getopts('hv:', \%hopts);
if (($n_args < 2) || exists $hopts{'h'}) {
   print $usage;
   exit;
};

$filename = $hopts{'v'};

#------------------------------------------------------------------------------
# Main part of script
#------------------------------------------------------------------------------
my @linp;
my %hports;
tie %hports, 'Tie::IxHash';

toolbox::attach_file_to_list($filename, \@linp) || die "File error\n";

#
# Primitive parser for entity/component
#
my $nesting = 0;
foreach my $line (@linp) {
 _consume_:
   $line =~ s/^\s*//;
   # print "$nesting>", $line,"\n";
   my ($signal, $direction, $type, $range) = ("", "", "", "");
   if ($line eq "" || $line =~ m/^--/) {
      next;
   };
   if ($nesting == 0 and $line =~ m/(entity|component)/i) {
      $nesting = 1;
      $line = $';
      goto _consume_;
   };
   if ($nesting == 1) {
      if ($line =~ m/port\s*\(/i) {
         $nesting++;
         $line = $';
         goto _consume_;
      };
   };
   if ($nesting == 2) {
      if ($line =~ m/^\s*;+/) {
         $line = $';
         goto _consume_;
      }
      if ($line =~ m/^(\w+)\s*:\s*(inout|out|in)\s+([\w]+)/i) {
         $signal = lc($1);
         $direction = lc($2);
         $type = $3;
         $line = $';
         # type with range?
         if ($line =~ m/\s*\(\s*(.+\s+(downto|to)\s+.?+)\s*\)\s*/i) {
            $range = lc($1);
            $line = $';
         };
         $hports{$signal} = [$direction, $type, $range];
         goto _consume_;
      };
      if ($line =~ m/^\)/) {
         $nesting--;
         $line = $';
         next;
      };
   };
};

#
# Generate output
#
my $max_width = 0;
foreach my $port (keys %hports) {
   if (length($port) > $max_width) {
      $max_width = length($port);
   };
};

print "(\n";
my @linst;
foreach my $port (keys %hports) {
   my $port_str = $port;
   toolbox::pad_str($max_width, \$port_str);
   my $wire = "";
   my $type = ${$hports{$port}}[1];
   if ($type =~ m/std_logic/i) {
      $type = "logic";
   }
   my $range = ${$hports{$port}}[2];
   $range =~ s/\s*(to|downto)\s*/:/;
   if (${$hports{$port}}[0] eq "out") {
      if ($range  ne "") {
         $wire = "/* open [$range] */";
      } else {
         $wire = "/* open */";
      };
   } else {
      if ($range  ne "") {
         $wire = "/* drive ${type}[$range] */";
      } else {
         $wire = "/* drive $type */";
      };
   };
   push @linst, " .${port_str} ($wire)";
};
print join(",\n", @linst);
print "\n);\n";

#------------------------------------------------------------------------------
# Subroutines
#------------------------------------------------------------------------------

1;
