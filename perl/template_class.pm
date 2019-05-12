#------------------------------------------------------------------------------
#
# Author      : Thorsten Dworzak <thorstenx.dworzak@verilab.com>
# Description : Template for OO-Perl class
#
#------------------------------------------------------------------------------

package template; # the class-name

#------------------------------------------------------------------------------
# Used packages
#------------------------------------------------------------------------------
use strict;
use FindBin qw($Bin);
use lib "$Bin";
use lib "$Bin/..";
use lib "$Bin/lib";
use Data::Dumper;
use CGI::Carp;

#------------------------------------------------------------------------------
# Class members
#------------------------------------------------------------------------------
# <define static members here>

# Generic Class Properties
our $package   = __PACKAGE__;
our $instances = 0;
our $debug     = 0;

# version of this package
our($VERSION) = "1.0";

#------------------------------------------------------------------------------
# Constructor
# returns a blessed hash reference to the data members of this class
# package; does NOT call the subclass constructors.
# Input: hash for setting member variables with <field-name> => <field-value> (optional)
#------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my %params = @_;

	# data members and their default values
	my $this  = {                      
                 # debug switch
                 'debug' => 0,
                 
                 # Version of class package
                 'version' => $VERSION
                };

	# init data members w/ parameters from constructor call
	foreach (keys %params) {
		$this->{$_} = $params{$_};
	};
    
   $instances++;
	bless $this, $class;
   $this->_parameters( @_ ); # processes arguments passed to constructor 
   return $this;
};

#------------------------------------------------------------------------------
# Public attributes access methods
#------------------------------------------------------------------------------

our $AUTOLOAD;
sub AUTOLOAD {
    my $this = shift;
    my $name = $AUTOLOAD;
    my $type = ref($this) or croak "ERROR: $this is not an object";

    $name =~ s/.*://; # strip fully qualified portion
    croak "can\'t access field $name in class $type" unless (exists $this->{$name});
    
    if (@_) {
        return $this->{$name} = shift;
    } else {
        return $this->{$name};
    };
};
# need to declare this to avoid AUTOLOAD being called
sub DESTROY { --$instances };

#------------------------------------------------------------------------------
# Initialize members
#------------------------------------------------------------------------------
sub _parameters() {
  my $this = shift;

  my %params = @_;

  # <optionally check for required number of params>
  # if ( scalar (keys %params) < 1 ) {
  #    croak;
  # };

  # init data members w/ parameters from constructor call
  foreach (keys %params) {
      $this->{$_} = $params{$_};
  };

};

#------------------------------------------------------------------------------
# Methods
# First parameter passed to method is implicit and is the object reference 
# ($this) if the method 
# is called in <object> -> <method>() fashion.
#------------------------------------------------------------------------------

# display method for debugging (every class should have one)
sub display {
	my $this = shift;
	my $dump  = Data::Dumper->new([$this]);
	$dump->Sortkeys(1);
	print $dump->Dump;
};

1;
