#!/opt/perl_5.8.8/bin/perl -w
# Hello World

# some useful flags
use 5.8.0;
use strict;
use warnings;

# use of Perl modules, see http://search.cpan.org/~gbarr/IO-1.25/lib/IO/File.pm
use YAML;
use IO::File;

our $header = "file_header.txt";
our ($copydate, $project, $author);

# This section is executed first, regardless of the position in the code; use for 
# commandline parsing, initialization etc.
BEGIN {
    $copydate = `date +%Y`; # exec shell command
    chomp($copydate);
    $author   = $ENV{"USER"}; # Unix environment variable are stored in global hash variable %ENV
    $project  = "hello-world";
};

#
# Define subroutines
#
sub copyright {
    return "(c) " . $copydate . " by " . $project . "\n"; 
};

#
# Main part of script
#
print "\"Hello World\" says ",$author,"\n ", copyright(); 

# Example: read input from stdin and process line by line
# my $file;
# {
#     local($/) = undef; # undefine the line-separator
#     $file = <>;
# };
# my @lines = split(/\n$/, $file);
# foreach (@lines) {
#     print $_, "\n";
# };


# Mandatory exit code
1;





