# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

# Events.pm -- event handling code for VRML::Browser.
#
# We take all the nodes referenced by events in the scenegraph
# and at each timestep ask each node able to produce events
# whether it wants to right now.
#
# Then we propagate the events along the routes. 

package VRML::EventMachine;

sub new {
	my($type) = @_;
	bless {
		First => {},
	},$type;
}

sub print {
	my($this) = @_;
	print "DUMPING EVENTMODEL\nFIRST:\n";
	for(values %{$this->{First}}) {
		print "\t$_:\t$_->{TypeName}\n";
	}
	print "ROUTES:\n";
	for my $fn (keys %{$this->{Route}}) {
		print "\t$fn $this->{Route}{$fn}{TypeName}\n";
		for my $ff (keys %{$this->{Route}{$fn}}) {
			print "\t\t$ff\n";
			for (@{$this->{Route}{$fn}{$ff}}) {
				print "\t\t\t$_->[0]:\t$_->[0]{TypeName}\t$_->[1]\n";
			}
		}
	}
	print "ISS:\n";
	for my $pn (keys %{$this->{PIs}}) {
		print "\t$pn $this->{PIsN}{$pn}{TypeName}\n";
		for my $pf (keys %{$this->{PIs}{$pn}}) {
			print "\t\t$pf\n";
			for(@{$this->{PIs}{$pn}{$pf}}) {
				print "\t\t\t$_->[0]:\t$_->[0]{TypeName}\t$_->[1]\n";
			}
		}
	}
}

# XXX Softref
sub add_first {
	my($this,$node) = @_;
	$this->{First}{$node} = $node;
}

sub remove_first {
	my($this,$node) = @_;
	delete $this->{First}{$node};
}

sub add_route {
	my($this,$fn, $ff, $tn, $tf) = @_;
	print "ADD_ROUTE $fn $ff $tn $tf\n";
	push @{$this->{Route}{$fn}{$ff}}, [$tn, $tf]
}

sub add_is {
	my($this,$pn, $pf, $cn, $cf) = @_;
	$this->{PIsN}{$pn} = $pn;
	push @{$this->{PIs}{$pn}{$pf}}, [$cn,$cf];
	$this->{CIs}{$cn}{$cf} = [$pn,$pf];
}

# get_firstevent returns [$node, fieldName, value]
sub propagate_events {
	my($this,$timestamp,$be) = @_;
	my @e;
	my @ne;
	my %sent; # to prevent sending twice, always set bit here
	$this->{Queue} = [];
	for(values %{$this->{First}}) {
		# print "GETFIRST $_\n" if $VRML::verbose::events;
		push @e, $_->get_firstevent($timestamp);
	}
	for(@{$this->{Mouse}}) {
		print "MEV $_->[0] $_->[1] $_->[2]\n";
		$_->[0]->{Type}{Actions}{__mouse__}->($_->[0], $_->[0]{RFields},
			$timestamp,
			$_->[2], $_->[1], 1, undef, undef, undef);
	}
	push @e, @{$this->{Queue}};
	$this->{Mouse} = [];
	print "GOT ",scalar(@e)," FIRSTEVENTS\n" if $VRML::verbose::events;
	while(1) {
		my %ep; # All nodes for which ep must be called
		# Propagate our events as long as they last
		while(@e) {
			$this->{Queue} = [];
			@ne = ();
			for my $e (@e) {
				print "SEND $e->[0] $e->[0]{TypeName} $e->[1] $e->[2]\n" if $VRML::verbose::events;
				# don't send same event again
				next if($sent{$e->[0]}{$e->[1]}++);

				for(@{$this->{Route}{$e->[0]}{$e->[1]}}) {
					$_->[0]->receive_event($_->[1],
							$e->[2],$timestamp);
					$ep{$_->[0]} = $_->[0];
				}
				my $c;
				if($c = $this->{CIs}{$e->[0]}{$e->[1]}) {
					print "CHILD_IS! Send from P\n"
					 if $VRML::verbose::events;
					push @ne, [
						$c->[0], $c->[1], $e->[2]
					];
				}
				for(@{$this->{PIs}{$e->[0]}{$e->[1]}}) {
					print "P_IS: send to $_\n"
					 if $VRML::verbose::events;
					$_->[0]->receive_event($_->[1],
						$e->[2], $timestamp);
				}
			}
			@e = (@ne,@{$this->{Queue}});
		}
		$this->{Queue} = [];
		@ne = ();
		# Call eventsprocessed
		for(values %ep) {
			push @ne,$_->events_processed($timestamp,$be);
		}
		if(!@ne) {last}
		@e = (@ne,@{$this->{Queue}}); # Here we go again ;)
	}
}

sub put_event {
	my($this,$node,$field,$value) = @_;
	push @{$this->{Queue}}, [$node, $field, $value];
}

sub handle_touched {
	my($this,$node,$but,$move) = @_;
	print "HTOUCH: $node $but $move\n";
	push @{$this->{Mouse}}, [$node, $but, $move];
}

1;
