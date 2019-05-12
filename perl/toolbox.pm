###############################################################################
#
#  File          :  toolbox.pl $Revision: 1.8 $
#  Related Files :  <none>
#
#  Author(s)     :  Thorsten Lutscher
#  Email         :  thorsten.lutscher@micronas.com
#
#  Project       :  <none>
#
#  Creation Date :  25.01.2002
#
#  Contents      :  Perl subroutines
#
###############################################################################
#
# $Log: toolbox.pm,v $
# Revision 1.8  2005/07/12 11:43:16  lutscher
# added sext()
#
# Revision 1.7  2005/06/20 11:34:13  lutscher
# changed VERSION to take integer
#
# Revision 1.6  2005/06/20 11:31:17  lutscher
# fixed VERSION export
#
# Revision 1.5  2005/06/20 11:26:32  lutscher
# added VERSION export
#
# Revision 1.4  2005/06/17 12:52:08  lutscher
# added exporter stuff and removed unused functions
#
#
################################################################################

package toolbox;
require Exporter;

# helper functions to find objects in DSS database
@ISA=qw(Exporter);
@EXPORT_OK = qw (
				 VERSION
				 check_exe
				 ext_system
				 print_hashtree
				 get_date
				 searchstring
				 attach_file_to_list
				 max
				 pad_str
				 val2hex
				 sext
				 ld
				 nxt_pow2
				 read_config_file
);
# export version (update manually whenever deemed necessary, e.g. method added)
our($VERSION) = '1.2';

# check_exe()
# checks for existence of an executable (copied from lcdctrlsim.pl)
sub check_exe {
   if( -f "@_" )
	 {
		return 1;
	 }
   elsif( "@_" =~ /^\// && ! -f "@_" )    {
      return 0;
   }
   elsif (`which @_` =~ /.* in .*/ ) {
	  return 0;
   }
   else {
	  return 1;
   }
}

# ext_system()
# Calls 'system()' with passed string and returns the error code;
# Stores the output of the command in the passed string reference.
# If the third param. is 1, output to stderr is suppressed
sub ext_system {
  my ($execstr, $ref_result, $suppress_stderr)=@_;
  if ($suppress_stderr) {
    open(SAVEERR, ">&STDERR"); # suppress stderr
    open(STDERR,">/dev/null");
  }
  open(HANDLE,"${execstr}|");
  my($sep)=$/;
  undef $/;
  if (ref $ref_result eq "SCALAR") {
    $$ref_result=<HANDLE>;
  };
  $/=$sep;
  close(HANDLE);
  my($result)=$?>>8;
  if ($suppress_stderr) {
    close(STDERR);
    open(STDERR, ">&SAVEERR");
    close(SAVEERR);
  }
  return $result;
}; # ext_system


# print_hashtree()
# prints hash whose values can also be hashes
sub print_hashtree{
  my($href, $level)=@_;
  my($key, $i);

  foreach $key (keys %$href) {
    print "\n";
    for ($i=0; $i<$level; $i++) {
      print "\t";
    }
    print "$key => ";
    if (scalar(%{$href->{$key}})) {
      print "(";
      print_hashtree(\%{$href->{$key}}, $level+1);
      print " )";
    }else {
      print "$href->{$key}";
    }
  }
};

# get_date()
sub get_date {
  my($date);
  open(SHANDLE,"date|") or die; # need to pipe output of command, did not work otherwise !?
  $date=<SHANDLE>;
  close(SHANDLE);
  chop($date);
  return $date;
};

# searchstring() - stolen from carsten
# looks for string $search_string in file $filename
sub searchstring{
  my ($filename,$search_string)=@_;
  my $search="false";
  my $count=0;

  open(INFILE,"<$filename");
  while(<INFILE>){
    if(/$search_string/){
      $search="true";
      $count++;
    }
    else{
      if( $search eq "true" ){
	$search="true";
      }
      else{
	$search="false";
      }
    }
  }
  close(INFILE);
  return $count;
}

# attach_file_to_list()
# Attaches lines in a text-file to a given list
# input: filename
#        list reference
# returns 0 if not successful
sub attach_file_to_list{
  my($filename,$lref)=@_;
  my($line);

  open(INFILE,"$filename") || return 0;
  while (<INFILE>) {
    push @$lref,$_;
  }
  close(INFILE);
  chomp @$lref;
  1;
};

# max() - get max value of two values
sub max {
  @c=@_;
  if ($c[0] >= $c[1]) {
    return $c[0];
  }else {
    return $c[1];
  }
};

# pad_str - add whitespaces to end of str until it has specified size
sub pad_str {
  my($size, $ref) = @_;
  my($i);
  for ($i=length($$ref); $i < $size; $i++) {
    $$ref = $$ref." ";
  }
  1;
}

#------------------------------------------------------------------------------
# val2hex()
# converts a positive integer value to a hex string (without pre- or postfix)
# input: size (in bits, minimum is 4)
#        value
#------------------------------------------------------------------------------
our(@ch)=('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f');
sub val2hex{
  my($size, $val)=@_;
  #my(@ch)=('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f');
  #my(@lstr)=();
  my($result)="";
  my($i);

  $size = ($size < 4) ? 4 : $size;
  my($hsize) = (($size+3) >> 2) - 1;
  for ($i=0; $i<=$hsize; $i++) {
	 $result = "$ch[$val%16]${result}";
	 $val/=16;
  };
  # map scalar to array of characters
  #while ($#lstr != $hsize) {
  #  push @lstr,$ch[$val%16];
  #  $val/=16;
  #};
  # revert order
  #grep ($result = $_.$result,@lstr);
  return $result;
}; # dword2hex

# performs a signed extension of a bit vector to 32-bit, using the MSB
sub sext {
	my($size, $val) = @_;
	my $msb = $val & (0x1 << ($size-1));
	my $result = $val;

	if(!$msb) {
		return $result; # MSB==0
	} else {
		do {
			$msb = $msb << 1;
			$result |= $msb;
		} until $msb == 0x80000000;
	};
	return $result;
};

# performs int(ld(n))
sub ld {
  my($n)= @_;
  my($result)=-1;

  if (int($n/2) > 0) {
    $result = ld(int($n/2));
  }
  return $result + 1;
}

# gets the next higher number which is a power of 2 (useful for binary encoding)
sub nxt_pow2 {
  my($n) = @_;
  my($i) = 1;
  while (1) {
    if ($i >= $n) {
      last;
    }
    else {
      $i = $i * 2;
    }
  }
  return $i;
}

# reads a file of the format
# <key> [<param> <param>*]
# into the hash passed as reference. If a key is followed by more than one parameter then
# the value of the key is a string with the parameters separated by spaces.
sub read_config_file {
   my($filename, $href_config)=@_;
   my($result) = 1;
   my(@ltemp)=();
   my($line);
   my($joint_line) = "";

   if(!open(HANDLE, $filename)) {
	  print STDERR "WARNING: could not read config file \'$filename\'\n";
	  $result = 0;
   }else{
	  while(<HANDLE>) {
		 $line = $_;
		 $line =~ s/[ \t]+/ /g;	# remove multiple TAB's or spaces
		 $line =~ s/^[ ]//;		# remove leading space
		 $line =~ s/[ ]$//;		# remove ending space
		 if($line =~ m/^\s*$/ || $line =~ m/^\#/ ){      # skip empty or comment line
			$line = "";
			next;
		 };
		 chomp($line);
		 if($line =~ m/\\$/) {
			# if line has a backslash, store it and continue with next line
			chop($line);
			$joint_line = $joint_line . $line;
			next;
		 }else{
			if ($joint_line ne "") {
			   $line = $joint_line . $line;
			}
			#print "line $line\n";
			@ltemp = split(" ", $line);
			if(scalar(@ltemp)==1) {
			   $href_config->{shift @ltemp} = "";
			}elsif (scalar(@ltemp)>1) {
			   $href_config->{$ltemp[0]} = join(" ", splice (@ltemp, 1, scalar(@ltemp)-1));
			}
			$line = "";
		 }
	  }
	  # check if the last line has been processed
	  if ($line ne "") {
		 @ltemp = split(" ", $line);
		 if(scalar(@ltemp)==1) {
			$href_config->{shift @ltemp} = "";
		 }elsif (scalar(@ltemp)>1) {
			$href_config->{$ltemp[0]} = join(" ", splice (@ltemp, 1, scalar(@ltemp)-1));
		 }
	  };
   }
   $result;
};
#------------------------------------------------------------------------------
# end of package
#------------------------------------------------------------------------------
1;
