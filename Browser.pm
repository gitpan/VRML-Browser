# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

require 'GLBackEnd.pm';
require 'Parser.pm';
require 'Scene.pm';
require 'Events.pm';

package VRML::Browser;
use strict vars;
use POSIX;

sub new {
	my($type,$pars) = @_;
	my $this = bless {
		Verbose => delete $pars->{Verbose},
		BE => new VRML::GLBackEnd(),
		EV => new VRML::EventMachine(),
	}, $type;
	return $this;
}

sub clear_scene {
	my($this) = @_;
	delete $this->{Scene};
}

# use Data::Dumper;
# $Data::Dumper::Indent = 1;
# Discards previous scene
sub load_file {
	my($this,$file) = @_;
	my $t;
	{local $/; undef $/;
	open F, $file;
	$t = <F>;
	close F;
	}
	$this->clear_scene();
	$this->{Scene} = VRML::Scene->new($this->{EV});
	VRML::Parser::parse($this->{Scene},$t);
	$this->{Scene}->make_executable();
	# print Dumper($this->{Scene});
	$this->{Scene}->make_backend($this->{BE});
	$this->{Scene}->setup_routing($this->{EV},$this->{BE});
	$this->{EV}->print;
	# print Dumper($this->{EV});
}

sub eventloop {
	my($this) = @_;
	while(1) {
		$this->{BE}->update_scene();
		$this->{EV}->propagate_events(get_timestamp(),$this->{BE});
	}
}

{
my $ind = 0; 
my $start = (POSIX::times())[0] / &POSIX::CLK_TCK;
my $add = time() - $start;
sub get_timestamp {
	my $ticks = (POSIX::times())[0] / &POSIX::CLK_TCK; # Get clock ticks
	$ticks += $add;
	print "TICK: $ticks\n"
		if $VRML::verbose;
	if(!$_[0]) {
		$ind++;;
		if($ind == 25) {
			$ind = 0;
			print "Fps: ",25/($ticks-$start),"\n";
			pmeasures();
			$start = $ticks;
		}
	}
	return $ticks;
}

{
my %h; my $cur; my $curt;
sub tmeasure_single {
	my($name) = @_;
	my $t = get_timestamp(1);
	if(defined $cur) {
		$h{$cur} += $t - $curt;
	}
	$cur = $name;
	$curt = $t;
}
sub pmeasures {
	my $s = 0;
	for(values %h) {$s += $_}
	print "TIMES NOW:\n";
	for(sort keys %h) {printf "$_\t%3.3f\n",$h{$_}/$s}
}
}
}


1;
