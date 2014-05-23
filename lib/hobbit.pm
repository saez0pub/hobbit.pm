#!/usr/bin/perl
package hobbit;

=head1 NAME

  hobbit - check management

=head1 SYNOPSIS

  use hobbit;

  my $check=hobbit->new( name => "myCheck");

  $check->messageHeader("part 1","This part shows dummy outputs.");
  $check->messageLevel("green","everything works fine");
  $check->messageLevel("yellow","not that much");
  $check->messageLevel("red","something went really bad");
  $check->messageFooter;

  $check->messageHeader("part 2","shows how to send multiple lines at once.");
  $check->messageLevel("green","good","red","bad");
  $check->messageFooter;

  $check->finalOutput;

  the above statements issues the following output :

  'status .myCheck clear Wed Nov 13 16:29:22 2013 - no data

  <hr>
  <h3>part 1</h3>
  This part shows dummy outputs.<br>
  <table width=10 height=10 cellspacing=1 cellpadding=0>
  <tr><td bgcolor=#004000>everything works fine</td></tr>
  <tr><td bgcolor=#404000>not that much</td></tr>
  <tr><td bgcolor=#400000>something went really bad</td></tr>
  </table>

  <hr>
  <h3>part 2</h3>
  shows how to send multiple lines at once.<br>
  <table width=10 height=10 cellspacing=1 cellpadding=0>
  <tr><td bgcolor=#004000>good</td></tr>
  <tr><td bgcolor=#400000>bad</td></tr>
  </table>

  <br>
  output generated in 0.000201940536499023 secs<br>
  '

=head1 DESCRIPTION

  This hobbit modules implements an easy way to create hobbit checks with perl.
  It produces output as HTML, each line being colored regarding its level.

  Available levels are :
    green
    yellow
    red
    clear
    purple
  Initial levl defaults to clear.
  
  Available exported functions are :

=over
=cut

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter AutoLoader);
our $VERSION = 0.01;
our @EXPORT_OK = qw( messageHeader, messageFooter, messageLevel, finalOutput );
our @EXPORT    = qw( );

# Uses hires time if available
eval "require Time::HiRes";
unless ($@) { use Time::HiRes qw ( time ) }

###############################################################################

use constant GREEN => "green";
use constant YELLOW => "yellow";
use constant RED => "red";
use constant CLEAR => "clear";
use constant PURPLE => "purple";

sub print { print @_; }
sub system { system(@_); }

my $defaultCheckName="check";
my %levelMessages = ( clear => "no data", green => "OK", yellow => "warning", red => "ERREUR" );
my %levelHierarchy = ( clear => -1, green => 0, yellow => 1, red => 3 );
my %levelColors = ( clear => "#C0C0C0", green => "#000000", yellow => "#404000" , red => "#400000" );
my %levelTxtColors = ( clear => "#0C0C0C", green => "#D8D8BF", yellow => "#FFFFFF" , red => "#FFFFFF" );

###############################################################################

BEGIN { # Module initiator

}

END { # Module terminator

}

###############################################################################

=item new()

  This function constructs a new object. Only argument is "name", which sets
  the check name in its output.

=cut

sub new {
  my ($class, %initValues) = @_;
  my $this = {};
  bless ($this, $class);

  # fixed initialisations
  $this->{checkColor} = CLEAR;
  $this->{checkData} = "";
  $this->{globalOutput} = \&print;
  $this->{globalOutput} = \&system if $ENV{BB};
  $this->{levelMessages} = \%levelMessages;
  $this->{levelHierarchy} = \%levelHierarchy;
  $this->{levelColors} = \%levelColors;
  $this->{levelTxtColors} = \%levelTxtColors;
  $this->{levels} = keys %levelHierarchy;
  $this->{startTime} = time;

  # initialisation from parameters
  $this->{checkName} = $initValues{name};
  $this->{checkName} = $defaultCheckName if not defined $initValues{name};
  #$this->{attributeName} = $initValues{parameterName}; 
  #$this->{attributeName} = $defaultValue if not defined $initValues{parameterName};

  return $this;
}

###############################################################################

# Internal functions
sub getLevelMessages {
  (my $this, my $level) = @_;
  my $levelMessages = $this->{levelMessages};
  return $levelMessages->{$level};
}

sub getLevelHierarchy {
  (my $this, my $level) = @_;
  my $levelHierarchy = $this->{levelHierarchy};
  return $levelHierarchy->{$level};
}

sub getLevelColors {
  (my $this, my $level) = @_;
  my $levelColors = $this->{levelColors};
  return $levelColors->{$level};
}

sub getLevelTxtColors {
  (my $this, my $level) = @_;
  my $levelTxtColors = $this->{levelTxtColors};
  return $levelTxtColors->{$level};
}

sub increaseLevel {
  (my $this, my $wantedLevel) = @_;
  my $currentLevel = $this->{checkColor};
  my $changedLevel=0;
  my $newLevel = $currentLevel;
  my %levelHierarchy = %{$this->{levelHierarchy}};
  $newLevel = $wantedLevel if $levelHierarchy{$wantedLevel} > $levelHierarchy{$currentLevel};
  $changedLevel = 1 if $newLevel ne $currentLevel;
  $this->{checkColor}=$newLevel if $changedLevel == 1;
  return $changedLevel;
}

###############################################################################

=item messageHeader()

  messageHeader starts an output part. As long as output is html formated, this
  corresponds to a table header. It may be useful to organize output to get
  multiple parts. To get this, you can use multiple times messageHeader and
  messageFooter. messageHeader first argument is a title for the section. Every
  other argument is printed on a separated line to give a description of the
  current part.

=cut

sub messageHeader {
  (my $this, my $msgHeader, my @msgHeaderLines) = @_; 

  my $msgTxtHeader="<hr>\n";
  $msgTxtHeader.="<h3>".$msgHeader."</h3>\n";
  foreach my $msgHeaderLine (@msgHeaderLines) {
    $msgTxtHeader.=$msgHeaderLine."<br>\n";
  }
  $msgTxtHeader.="<table width=10 height=10 cellspacing=1 cellpadding=0>\n"; 
  $this->{checkData} .= $msgTxtHeader;
  return 0;
}

###############################################################################

=item messageFooter()

  messageFooter ends a previously started part. No arguement needed.

=cut

sub messageFooter {
  (my $this) = @_;
  $this->{checkData} .= "</table>\n\n";
  return 0;
}

###############################################################################

=item messageLevel()

  messageLevel adds one or more colored line to the message. Arguement is a
  list, organized in pairs. Each pair represents a line, first item giving the
  level of the line, second the printed text.

=cut

sub messageLevel {
  (my $this, my @msgLevel) = @_;
  my $msgTxtLvl;
  @msgLevel = ( @msgLevel , "green" , "OK" ) if @msgLevel == ();
  while ( (my $msgLvl,my $msgTxt, @msgLevel ) = @msgLevel ) {
    $msgTxt.="&nbsp;" if ! $msgTxt=~ m/^$/;
    $msgTxtLvl .= "<tr><td bgcolor=".$this->getLevelColors($msgLvl)."><font color=".$this->getLevelTxtColors($msgLvl).">".${msgTxt}."</font></td></tr>\n";
    $this->increaseLevel( $msgLvl );
  }
  $this->{checkData} .= $msgTxtLvl;
  return 0;
}

###############################################################################

=item finalOutput()

  Prints the current state. Wether check is called by hobbit or from the
  command line, it will use bbcmd or a simple print output.

=cut

sub finalOutput {
  (my $this) = @_;

  # gets objects current values
  my $outputFunction=$this->{globalOutput};
  my $bbTestColor = $this->{checkColor};
  my $bbTestName = $this->{checkName};
  my $bbData = $this->{checkData};
  my $startTime = $this->{startTime};

  # generate some
  my $bbTestDate = localtime;
  my $bbTestStatus = $this->getLevelMessages($bbTestColor);
  my $hostName=`hostname`;
  my $duration = time - $startTime;
  chomp $hostName;
  $bbData .= "<br>\n";
  $bbData .= "output generated on ".$hostName." ";
  $bbData .= "in ".$duration." secs ";
  $bbData .= "using perl ".$^V.".<br>\n";

  # output
  #print "$bbTestName $bbTestStatus\n";
  &$outputFunction("$ENV{BB} $ENV{BBDISP} 'status $ENV{MACHINE}.$bbTestName $bbTestColor $bbTestDate - $bbTestStatus\n\n$bbData'\n");
}


###############################################################################

=back
=cut

1;

__END__
