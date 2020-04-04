eval 'exec perl -S $0 ${1+"$@"}'
if 0;
#------------------------------------------------------------------------------
#
# Author      : Thorsten Dworzak <thorstenx.dworzak@verilab.com>
# Description : Display number of LSF jobs matching <pattern> as progress bar.
#               Example for using Term::Screen and sigtrap.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Global variables
#------------------------------------------------------------------------------
our($pattern) = 'tests'; # default pattern
our($usage) = "$0 [<pattern>] - show progress bar on LSF jobs by grepping bjobs output.
  <pattern> string pattern to grep for in bjobs output (default: $pattern)\n";

#------------------------------------------------------------------------------
# Used packages, initialisation, commandline parameters etc.
#------------------------------------------------------------------------------
use strict;
use warnings;
use FindBin qw($Bin);
# use lib "/home/chdworza/work/perl";
# use lib "/home/chdworza/work/perl/lib/site_perl/5.16.2";
use lib "$Bin/lib/site_perl/5.16.2";
require Term::Screen;
require toolbox;
use sigtrap qw(handler sig_handler normal-signals);

use constant _BAR_CHAR_ => '#';
use constant _TIMEOUT_IN_SECONDS_ => 1000;
use constant _SLEEP_SECONDS_ => 3;

toolbox::check_exe("bjobs") || die "bjobs executable not found.\n";

if (scalar(@ARGV)) {
   if ($ARGV[0] =~ m/\-h/) {
      print $usage;
      exit 1;
   } else {
      $pattern = shift @ARGV;
   }
}
our($scr) = Term::Screen->new();
$scr->curinvis();

#------------------------------------------------------------------------------
# Main part of script
#------------------------------------------------------------------------------

my $timeout = 0;
my $n = 0;
my $n_last;
my $bjobs_output;
my $pend_avg = 0;
my $run_avg = 0;
my $samples = 0;

while(1) {
   $n_last = $n;
   #if (toolbox::ext_system("bjobs | grep -e '$pattern'", \$bjobs_output, 0) > 1) {
   if (toolbox::ext_system("bjobs -w", \$bjobs_output, 0) > 1) {
      print "Some problem occurred.\n";
      goodbye();
   } else {
      my @ltemp = split(/\s*\n/, $bjobs_output);
      my @lbjobs_output = ();

      foreach my $line (@ltemp) {
         if ($line =~ /$pattern/) {
            push @lbjobs_output, $line;
         }
      }
      $n = scalar(@lbjobs_output);
      my $pend = scalar(grep ($_ =~ /\bPEND\b/, @lbjobs_output));
      my $run = scalar(grep ($_ =~ /\bRUN\b/, @lbjobs_output));
      if ($n == 0) {
         $timeout++;
      } else{
         $timeout=0;
      }
      if ($timeout > (_TIMEOUT_IN_SECONDS_/_SLEEP_SECONDS_)) {
         print "No more jobs, exiting at " . `date` . "\n";
         goodbye();
      }
      $scr->clrscr();
      $scr->resize();
      $pend_avg = $pend_avg + ($pend - $pend_avg) / ($samples + 1);
      $run_avg = $run_avg + ($run - $run_avg) / ($samples + 1);
      my $d = ($n - $n_last);
      my $avg_str = sprintf("<PEND %.1f RUN %.1f>", $pend_avg, $run_avg);
      print "LSF jobs matching \"$pattern\": <PEND ${pend} RUN ${run}> avg: $avg_str delta: <$d>";
      render_bars($pend, $run);
      sleep _SLEEP_SECONDS_;
      $samples ++;
   }
}

#------------------------------------------------------------------------------
# Subroutines
#------------------------------------------------------------------------------

sub render_bars {
   my ($pend, $run) = @_;
   my $cols = $scr->cols();
   # my $rows = $scr->rows();
   my $i = 0;
   foreach my $type (0, 1) {
      $scr->at($i+1, 0);
      my $val       = ($pend, $run)[$type];
      my $lead_char = ("P", "R")[$type];
      if ($val == 0) {
        print "-";
      } elsif ($val < $cols) {
        print $lead_char, _BAR_CHAR_ x ($val-1);
      } else {
        print $lead_char, _BAR_CHAR_ x ($cols-2), "*";
      }
      $i++;
   }
}

sub goodbye {
   if (defined $scr){
      $scr->curvis();
   };
   exit 1;
}

sub sig_handler {
   goodbye();
}
1;
