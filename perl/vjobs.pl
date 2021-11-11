eval 'exec perl -S $0 ${1+"$@"}'
if 0;
#------------------------------------------------------------------------------
#
# Author      : Thorsten Dworzak <thorstenx.dworzak@verilab.com>
# Description : Display number of LSF jobs matching <pattern> as progress bar.
#               Example for using Term::Screen, Term::ANSIColor and sigtrap.
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
use lib "$Bin/lib/site_perl/5.16.2";
require Term::Screen;
require toolbox;
use sigtrap qw(handler sig_handler normal-signals);
use Term::ANSIColor qw(:constants :pushpop);
use constant _BAR_CHAR_ => '#';
use constant _TIMEOUT_IN_SECONDS_ => 1000;
use constant _REFRESH_RATE_SECONDS_ => 3;
use constant _REFRESH_RATE_SECONDS_WHEN_IDLE_MAX_ => 60;
use constant _MAX_RETRIES_FOR_ERRORS_ => 3;

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
my $first_samples_seen = 0;
my $samples = 0;
my $max_retries_for_errors = _MAX_RETRIES_FOR_ERRORS_;
my $sleep_for = _REFRESH_RATE_SECONDS_;
my $old_cols = 0;
my $old_rows = 0;

while(1) {
   $n_last = $n;
   EXEC_BJOBS:
   if (toolbox::ext_system("bjobs -w", \$bjobs_output, 0) > 1) {
      if ($max_retries_for_errors == 0) {
         print "Some problem occurred with bjobs command (giving up after $max_retries_for_errors retries).\n";
         goodbye();
      } else {
         sleep _REFRESH_RATE_SECONDS_;
         $max_retries_for_errors--;
         goto EXEC_BJOBS;
      }

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
      $first_samples_seen = 1 if ($pend || $run);

      if ($n == 0) {
         $timeout += $sleep_for;
      } else{
         $timeout=0;
      }
      if ($timeout > _TIMEOUT_IN_SECONDS_) {
         print "No more jobs, exiting at " . `date` . "\n";
         goodbye();
      }
      $scr->clrscr();
      $scr->resize();

      # Render header
      $pend_avg = $pend_avg + ($pend - $pend_avg) / ($samples + 1);
      $run_avg = $run_avg + ($run - $run_avg) / ($samples + 1);
      my $avg_str = sprintf("avg: <PEND %.1f RUN %.1f>", $pend_avg, $run_avg);
      my $delta = ($n - $n_last);
      my $pattern_str = $pattern;
      my $delta_str = "delta/${sleep_for}s: <$delta>";
      if (length($pattern) > 14) {
         $pattern_str = sprintf("%.10s[..]", $pattern);
      }
      print "LSF jobs matching \"$pattern_str\": <", LOCALCOLOR RED, "PEND ${pend}" , " ", LOCALCOLOR BLUE, "RUN ${run}", RESET, "> $avg_str $delta_str";

      # Render progress bars
      render_bars($pend, $run);

      # Slow-down refresh if nothing happens
      if (($delta == 0) && !needs_redraw()) {
         if ($sleep_for < _REFRESH_RATE_SECONDS_WHEN_IDLE_MAX_) {
            $sleep_for++;
         }
      } else {
         $sleep_for = _REFRESH_RATE_SECONDS_;
      }

      sleep $sleep_for;
      $samples ++ if ($first_samples_seen);
   }
}

#------------------------------------------------------------------------------
# Subroutines
#------------------------------------------------------------------------------

sub render_bars {
   my ($pend, $run) = @_;
   my $cols = $scr->cols();
   my $rows = $scr->rows();
   my $i = 0;
   foreach my $type (0, 1) {
      $scr->at($i+1, 0);
      my $val       = ($pend, $run)[$type];
      my $lead_char = ("P", "R")[$type];
      my $col = (RED, BLUE)[$type];
      if ($val == 0) {
        print "-";
      } elsif ($val < $cols) {
        print LOCALCOLOR $col, $lead_char, _BAR_CHAR_ x ($val-1);
      } else {
        print LOCALCOLOR $col, $lead_char, _BAR_CHAR_ x ($cols-2), "*";
      }
      $i++;
   }
   $old_cols = $cols;
   $old_rows = $rows;
}

sub needs_redraw {
   $old_cols != $scr->cols() || $old_rows != $scr->rows();
}

sub goodbye {
   if (defined $scr){
      $scr->curvis();
   };
   exit 0;
}

sub sig_handler {
   goodbye();
}
1;
