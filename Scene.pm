# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

# Scene.pm
#
# Implement a scene model, with the specified parser interface.


# The idea here has been to try to preserve as much as possible
# of the original file structure -- that may not be the best approach
# in the end, but all dependencies on that decision should be in this file.
# It would be pretty easy, therefore, to write a new version that would
# just discard the original structure (USE, DEF, IS).
#
# At some point, this file should be redone so that it uses softrefs
# for circular data structures.

use strict vars;

package VRML::FieldHash;
@VRML::FieldHash::ISA=Tie::StdHash;

sub TIEHASH {
	my($type,$node) = @_;
	bless \$node, $type;
}

{my %DEREF = map {($_=>1)} qw/VRML::IS/;
my %REALN = map {($_=>1)} qw/VRML::DEF VRML::USE/;
sub FETCH {
	my($this, $k) = @_;
	my $node = $$this;
	my $v = $node->{Fields}{$k};
	print "TIEH: FETCH $k $node $v\n" if $VRML::verbose::tief;
	while($DEREF{ref $v}) {
		$v = ${$v->get_ref};
		print "DEREF: $v\n" if $VRML::verbose::tief;
	}
	if($REALN{ref $v}) {
		$v = $v->real_node;
	}
	return $v;
}

sub STORE {
	my($this, $k, $value) = @_;
	print "TIEH: STORE $k $value\n" if $VRML::verbose::tief;
	my $node = $$this;
	my $v = \$node->{Fields}{$k};
	while($DEREF{ref $$v}) {
		$v = ${$v}->get_ref;
		print "DEREF: $v\n" if $VRML::verbose::tief;
	}
	$$v = $value;
	$node->{EventModel}->put_event($node, $k, $value);
	# $node->set_backend_fields($k);
}
}

sub FIRSTKEY {
	return undef
}

package VRML::IS;
sub new {bless [$_[1]],$_[0]}
sub copy {my $a = $_[0][0]; bless [$a], ref $_[0]}
sub make_executable {
	my($this,$scene,$node,$field) = @_;
}
sub iterate_nodes {
	my($this,$sub) = @_;
	&$sub($this);
}
sub name { $_[0][0] }
sub set_ref { $_[0][1] = $_[1] }
sub get_ref { if(!defined $_[0][1]) {die("IS not def!")} $_[0][1] }


package VRML::DEF;
sub new {bless [$_[1],$_[2]],$_[0]}
sub copy {(ref $_[0])->new($_[0][0], $_[0][1]->copy)}
sub make_executable {
	$_[0][1]->make_executable($_[1]);
}
sub make_backend {
	return $_[0][1]->make_backend($_[1],$_[2]);
}
sub iterate_nodes {
	my($this,$sub,$parent) = @_;
	print "ITERATE_NODES $this $this->[0]\n";
	&$sub($this,$parent);
	$this->[1]->iterate_nodes($sub,$parent);
}
sub name { return $_[0][0]; }
sub def { return $_[0][1]; }
sub set_name { $_[0][1]->set_name($_[1]) }
sub get_ref { $_[0][1] }

sub real_node { return $_[0][1]->real_node(); }

package VRML::USE;
sub new {bless [$_[1]],$_[0]}
sub copy {(ref $_[0])->new(@{$_[0]})}
sub make_executable {
}
sub set_used {
	my($this, $node) = @_;
	$this->[1] = $node;
}
sub make_backend {
	return $_[0][1]->make_backend($_[1], $_[2]);
}
sub iterate_nodes {
	my($this,$sub,$parent) = @_;
	&$sub($this,$parent);
}
sub name { return $_[0][0]; }
sub set_name { $_[0][1]->set_name($_[1]) }
sub real_node { return $_[0][1]->real_node(); }
sub get_ref { $_[0][1] }

package NULL; # ;)
sub make_backend {return ()}
sub make_executable {}
sub iterate_nodes {}

package VRML::Node;


sub new {
	my($type, $scene, $ntype, $fields,$eventmodel) = @_;
	my %rf;
	my $this = bless {
		TypeName => $ntype,
		Fields => $fields,
		EventModel => $eventmodel,
	}, $type;
	tie %rf, VRML::FieldHash, $this;
	$this->{RFields} = \%rf;
	my $t;
	if(!defined ($t = $VRML::Nodes{$this->{TypeName}})) {
		# PROTO
		$this->{IsProto} = 1;
		$this->{Type} = $scene->get_proto($this->{TypeName});
	} else {
		# REGULAR
		$this->{Type} = $t;
	}
	$this->do_defaults();
	return $this;
}

sub new_script {
	my($type, $scene, $stype, $fields, $eventmodel) = @_;
	my %rf;
	my $this = bless {
		TypeName => $stype->{Name},
		Type => $stype,
		Fields => $fields,
		EventModel => $eventmodel,
	}, $type;
	tie %rf, VRML::FieldHash, $this;
	$this->do_defaults();
	return $this;
}

sub do_defaults {
	my($this) = @_;
	for(keys %{$this->{Type}{Defaults}}) {
		if(!exists $this->{Fields}{$_}) {
			$this->{Fields}{$_} = $this->{Type}{Defaults}{$_};
		}
	}
}

sub real_node {
	my($this) = @_;
	if($this->{IsProto}) {
		return $this->{ProtoExp}{Nodes}[0]->real_node;
	} else {
		return $this;
	}
}

sub get_firstevent {
	my($this,$timestamp) = @_;
	print "GFE $this $this->{TypeName} $timestamp\n" if $VRML::verbose;
	if($this->{Type}{Actions}{ClockTick}) {
		print "ACT!\n" if $VRML::verbose;
		my @ev = &{$this->{Type}{Actions}{ClockTick}}($this, $this->{RFields},
			$timestamp);
		for(@ev) {
			$this->{Fields}{$_->[1]} = $_->[2];
		}
		return @ev;
	}
	return ();
}

sub receive_event {
	my($this,$field,$value,$timestamp) = @_;
	if(!exists $this->{Fields}{$field}) {
		die("Invalid event received: $this->{TypeName} $field")
		unless($field =~ s/^set_// and
		       exists($this->{Fields}{$field})) ;
	}
	print "REC $this $this->{TypeName} $timestamp ",
		("ARRAY" eq ref $value? (join ', ',@$value):$value),"\n" if $VRML::verbose::events;
	$this->{RFields}{$field} = $value;
	if($this->{Type}{Actions}{$field}) {
		print "RACT!\n" if $VRML::verbose;
		my @ev = &{$this->{Type}{Actions}{$field}}($this,$this->{RFields},
			$value,$timestamp);
		for(@ev) {
			$this->{Fields}{$_->[1]} = $_->[2];
		}
		return @ev;
	}  elsif($this->{Type}{Actions}{__any__}) {
		my @ev = &{$this->{Type}{Actions}{__any__}}(
			$this,
			$this->{RFields},
			$value,
			$timestamp,
			$field,
		);
		for(@ev) {
			$this->{Fields}{$_->[1]} = $_->[2];
		}
		return @ev;
	}
}

sub events_processed {
	my($this,$timestamp,$be) = @_;
	print "EP: $this $timestamp $be\n" if $VRML::verbose;
	if($this->{Type}{Actions}{EventsProcessed}) {
		print "PACT!\n" if $VRML::verbose;
		return &{$this->{Type}{Actions}{EventsProcessed}}($this, 
			$this->{RFields},
			$timestamp);
	}
	$this->set_backend_fields($be);
}

sub set_name {
	my($this,$name) = @_;
	push @{$this->{Names}}, $name; # Could have several...
}

# Copy a deeper struct
sub ccopy {
	my($v) = @_;
	if(!ref $v) { return $v }
	elsif("ARRAY" eq ref $v) { return [map {ccopy($_)} @$v] }
	else { return $v->copy }
}

# Copy me
sub copy {
	my($this) = @_;
	my $new = {};
	$new->{Type} = $this->{Type};
	$new->{TypeName} = $this->{TypeName};
	$new->{EventModel} = $this->{EventModel} ;
	my %rf;
	$new->{IsProto} = $this->{IsProto};
	tie %rf, VRML::FieldHash, $new;
	$new->{RFields} = \%rf;
	for(keys %{$this->{Fields}}) {
		my $v = $this->{Fields}{$_};
		$new->{Fields}{$_} = ccopy($v);
	}
	return bless $new,ref $this;
}

sub iterate_nodes {
	my($this, $sub,$parent) = @_;
	print "ITERATE_NODES $this $this->{TypeName}\n";
	&$sub($this,$parent);
	for(keys %{$this->{Fields}}) {
		if($this->{Type}{FieldTypes}{$_} =~ /SFNode$/) {
			print "FIELDI: SFNode\n";
			$this->{Fields}{$_}->iterate_nodes($sub,$this);
		} elsif($this->{Type}{FieldTypes}{$_} =~ /MFNode$/) {
			print "FIELDT: MFNode\n";
			for(@{$this->{Fields}{$_}}) {
				$_->iterate_nodes($sub,$this);
			}
		} else {
		}
	}
}

sub make_executable {
	my($this,$scene) = @_;
	for(keys %{$this->{Fields}}) {
		if(ref $this->{Fields}{$_} and 
		   "ARRAY" ne ref $this->{Fields}{$_}) {
			print "EFIELDT: SFReference\n";
			$this->{Fields}{$_}->make_executable($scene,
				$this, $_);
		} elsif( $this->{Type}{FieldTypes}{$_} =~ /^MF/) {
			print "EFIELDT: MF\n";
			for (@{$this->{Fields}{$_}})
			 {
			 	$_->make_executable($scene)
				 if(ref $_ and "ARRAY" ne ref $_);
			 } 
		} else {
			# Nada
		}
	}
	if($this->{IsProto}) {
		print "MAKE_EXECUTABLE_PROTOEXP $this $this->{TypeName}
			$this->{Type} $this->{Type}{Name}\n";
		$this->{ProtoExp} = $this->{Type}->get_copy();
		print "MAKE_EXECUTABLE_PROTOEXP_EXP $this->{ProtoExp}\n";
		$this->{ProtoExp}->set_parentnode($this);
		$this->{ProtoExp}->make_executable();
	} 
	if($this->{Type}{Actions}{Initialize}) {
		&{$this->{Type}{Actions}{Initialize}}($this,$this->{RFields});
	}
}

sub set_backend_fields {
	my($this, $be, @fields) = @_;
	if(!@fields) {@fields = keys %{$this->{Fields}}}
	my %f;
	for(@fields) {
		my $v = $this->{RFields}{$_};
		print "SBEF: $this $_ '",("ARRAY" eq ref $v ?
			(join ' ,',@$v) : $v),"' \n" if $VRML::verbose;
		if($this->{Type}{FieldTypes}{$_} =~ /SFNode$/) {
			$f{$_} = $v->make_backend($be);
		} elsif($this->{Type}{FieldTypes}{$_} =~ /MFNode$/) {
			$f{$_} = [
				map {$_->make_backend($be)} @{$v}
			];
		} else {
			$f{$_} = $v;
		}
	}
	$be->set_fields($this->{BackNode},\%f);
}

{
my %NOT = map {($_=>1)} qw/WorldInfo TimeSensor TouchSensor
	ScalarInterpolator ColorInterpolator
	PositionInterpolator
	OrientationInterpolator
	NavigationInfo
	/;

sub make_backend {
	my($this,$be,$parentbe) = @_;
	print "Node::make_backend\n" if $VRML::verbose;
	if(defined $this->{BackNode}) {return $this->{BackNode}}
	if($NOT{$this->{TypeName}} or $this->{TypeName} =~ /^__script/) {
		return ();
	}
	if($this->{IsProto}) {
		return $this->{ProtoExp}->make_backend($be,$parentbe);
	}
	my $ben = $be->new_node($this->{TypeName});
	$this->{BackNode} = $ben;
	$this->set_backend_fields($be);
	return $ben;
}
}

package VRML::Scene;
#
# Pars - parameters for proto, hashref
# Nodes - arrayref of toplevel nodes
# Protos - hashref of prototypes
# Routes - arrayref of routes [from,fromf,to,tof]
#
# Expansions:
#  - expand_protos = creates actual copied nodes for all prototypes
#    the copied nodes are stored in the field ProtoExp of the Node
#    
#  - expand_usedef

sub new {
	my($type,$eventmodel) = @_;
	bless {
		EventModel => $eventmodel,
	},$type;
}

sub newp {
	my ($type,$pars,$parent,$name) = @_;
	my $this = $type->new;
	$this->{Pars} = $pars;
	$this->{Name} = $name;
# Extract the field types
	$this->{FieldTypes} = {map {$_ => $this->{Pars}{$_}[1]} keys %{$this->{Pars}}};
	$this->{Parent} = $parent;
	$this->{EventModel} = $parent->{EventModel};
	$this->{Defaults} = {map {$_ => $this->{Pars}{$_}[2]} keys %{$this->{Pars}}};
	return $this;
}

#############################
# This is the public interface

{my $cnt;
sub new_node {
	my($this, $type, $fields) = @_;
	if($type eq "Script") {
		# Special handling for Script which has an interface.
		my $t = "__script__".$cnt++;
		my %f = 
		(url => [MFString, []],
		 directOutput => [SFBool, 0, ""], # not exposedfields
		 mustEvaluate => [SFBool, 0, ""]);
		for(keys %$fields) {
			$f{$_} = [
				$fields->{$_}[1],
				$fields->{$_}[2],
				$fields->{$_}[0],
			];
		}
		my $type = VRML::NodeType->new($t,\%f,
			$VRML::Nodes{Script}{Actions});
		my $node = VRML::Node->new_script(
			$this, $type, {}, $this->{EventModel});
		return $node;
	}
	my $node = VRML::Node->new($this,$type,$fields, $this->{EventModel});
	# Check if it is bindable..
	if($VRML::Nodes::bindable{$type} &&
	   !defined $this->{Bindable}{$type}) {
		$this->{Bindable}{$type} = $node;
	}
	return $node;
}
}

sub new_route {
	my $this = shift;
	print "NEW_ROUTE $_[0][0] $_[0][1] $_[0][2] $_[0][3]\n";
	push @{$this->{Routes}}, $_[0];
}

sub new_def {
	my($this,$name,$node) = @_;
	my $def = VRML::DEF->new($name,$node);
	$this->{TmpDef}{$name} = $def;
	return $def;
}

sub new_use {
	my($this,$name) = @_;
	return VRML::USE->new($name, $this->{TmpDef}{$name});
}

sub new_is {
	my($this, $name) = @_;
	return VRML::IS->new($name);
}

sub new_proto {
	my($this,$name,$pars) = @_;
	print "NEW_PROTO $this $name\n";
	my $p = $this->{Protos}{$name} = (ref $this)->newp($pars,$this,$name);
	return $p;
}

sub topnodes {
	my($this,$nodes) = @_;
	$this->{Nodes} = $nodes;
}

sub get_proto {
	my($this,$name) = @_;
	print "GET_PROTO $this $name\n";
	if($this->{Protos}{$name}) {return $this->{Protos}{$name}}
	if($this->{Parent}) {return $this->{Parent}->get_proto($name)}
	print "GET_PROTO_UNDEF $this $name\n";
	return undef;
}

###############################

# Must be done after copies are made..
# sub add_def{
# 	my($this,$name,$node) = @_;
# 	$this->{DEF}{$name} = $node;
# }
# 
# sub get_def {
# 	my($this,$name) = @_;
# 	return $this->{DEF}{$name};
# }

# Construct a full copy of this scene -- used for protos.
# Note: much data is shared - problems?
sub get_copy {
	my($this,$name) = @_;
	my $new = bless {
	},ref $this;
	$new->{Pars} = $this->{Pars};
	$new->{FieldTypes} = $this->{FieldTypes};
	$new->{Nodes} = [map {$_->copy} @{$this->{Nodes}}];
	$new->{EventModel} = $this->{EventModel};
	$new->{Routes} = $this->{Routes};
	return $new;
}

#
# Here come the expansions:
#  - make executable: create copies of all prototypes.
#

sub iterate_nodes {
	my($this,$sub,$parent) = @_;
	for(@{$this->{Nodes}}) {
		$_->iterate_nodes($sub,$parent);
	}
}

sub iterate_nodes_all {
	my($this,$sub) = @_;
	for(@{$this->{Nodes}}) {
		my $sub;
		$sub = sub {
			&$sub($_[0]);
			if($_[0]->{ProtoExp}) {
				$_[0]->{ProtoExp}->iterate_nodes($sub);
			}
		};
		$_->iterate_nodes($sub);
		undef $sub;
	}
}

sub set_parentnode { $_[0]{NodeParent} = $_[1] }

# XXX This routine is too static - should be split and executed
# as the scene graph grows/shrinks.
{
my %sends = map {($_=>1)} qw/
	TouchSensor TimeSensor
/;
sub make_executable {
	my($this) = @_;
	print "MAKE_EXECUTABLE $this\n";
	for(@{$this->{Nodes}}) {
		$_->make_executable($this);
	}
	# Gather all 'DEF' statements
	my %DEF;
	$this->iterate_nodes(sub {
		return unless ref $_[0] eq "VRML::DEF";
		print "FOUND DEF ($this, $_[0]) ",$_[0]->name,"\n";
		$DEF{$_[0]->name} = $_[0]->def;
	});
	# Set all USEs
	$this->iterate_nodes(sub {
		return unless ref $_[0] eq "VRML::USE";
		print "FOUND USE ($this, $_[0]) ",$_[0]->name,"\n";
		$_[0]->set_used($DEF{$_[0]->name});
	});
	$this->{DEF} = \%DEF;
	# Collect all prototyped nodes from here
	# so we can call their events
	$this->iterate_nodes(sub {
		return unless ref $_[0] eq "VRML::Node";
		push @{$this->{SubScenes}}, $_[0]
		 	if $_[0]->{ProtoExp};
		push @{$this->{Sensors}}, $_[0] 
			if $sends{$_[0]};
	});
	# Give all ISs references to my data
	print "MAKEEX $this\n";
	if($this->{NodeParent}) {
		print "MAKEEXNOD\n";
		$this->iterate_nodes(sub {
			print "MENID\n";
			return unless ref $_[0] eq "VRML::Node";
			for(keys %{$_[0]->{Fields}}) {
				print "MENIDF $_\n";
				next unless ((ref $_[0]{Fields}{$_}) eq "VRML::IS");
				print "MENIDFSET $_\n";
				$_[0]{Fields}{$_}->set_ref(
				  \$this->{NodeParent}{Fields}{
				  	$_[0]{Fields}{$_}->name});
			}
		});
	}
}
}

sub make_backend {
	my($this,$be,$parentbe) = @_;
	if($this->{BackNode}) {return $this->{BackNode}}
	my $bn;
	if($this->{Parent}) {
		# I am a proto -- only my first node renders anything...
		$bn = $this->{Nodes}[0]->make_backend($be,$parentbe);
	} else {
		# I am *the* root node.
		my $n = $be->new_node(Group);
		$be->set_fields($n, {children => [
			map { $_->make_backend($be,$n) } @{$this->{Nodes}}
			]
		});
		$be->set_root($n);
		print "MBESVP VIEWPOINT $this->{Bindable}{Viewpoint} $this->{Bindable}{Viewpoint}{BackNode}\n";
		$be->set_viewpoint($this->{Bindable}{Viewpoint}{BackNode});
		$bn = $n;
	}
	$this->{BackNode} = $bn;
	return $bn;
}

# Events are generally in the format
#  [$scene, $node, $name, $value]

# XXX This routine is too static - should be split and executed
# But also: we can simply redo this every time the scenegraph
# or routes change. Of course, that's a bit overkill.
sub setup_routing {
	my($this,$eventmodel,$be) = @_;
	print "SETUP_ROUTING $this $eventmodel $be\n";
	my $firstev = [];
	$this->iterate_nodes(sub {
		return unless "VRML::Node" eq ref $_[0];
		if($VRML::Nodes::initevents{$_[0]->{TypeName}}) {
			$eventmodel->add_first($_[0]);
		} else {
			if($_[0]{ProtoExp}) {
				 $_[0]{ProtoExp}->setup_routing(
				 	$eventmodel,$be) ;
			}
		}
		# Look at child nodes
		my $c;
		for(keys %{$_[0]{Fields}}) {
			if("VRML::IS" eq ref $_[0]{Fields}{$_}) {
				$eventmodel->add_is($this->{NodeParent},
					$_[0]{Fields}{$_}->name,
					$_[0],
					$_
				);
			}
		}
		if(($c = $VRML::Nodes::children{$_[0]->{TypeName}})) {
			for(@{$_[0]{Fields}{$c}}) {
				# XXX Removing/moving sensors?!?!
				my $n = $_->real_node();
				print "REALNODE: $n $n->{TypeName}\n";
				if($VRML::Nodes::siblingsensitive{$n->{TypeName}}) {
					print "SES: $n $n->{TypeName}\n";
					$be->set_sensitive(
						$_[0]->{BackNode},
						sub {
							$eventmodel->
							    handle_touched($n,
							    		@_);
						}
					);
				}
			}
		}
	});
	print "DEVINED NODES in $this: ",(join ',',keys %{$this->{DEF}}),"\n";
	for(@{$this->{Routes}}) {
		my($fnam, $ff, $tnam, $tf) = @$_;
		my ($fn, $tn) = map {
			print "LOOKING FOR $_ in $this\n";
			$this->{DEF}{$_} or
			 die("Routed node name '$_' not found ($fnam, $ff, $tnam, $tf)!");
		} ($fnam, $tnam);
		$eventmodel->add_route($fn,$ff,$tn,$tf);
	}
}

# Get first events for a certain timestamp.
# Because it is possible to put/take nodes from inside
# protos by giving them as eventins/outs, we need to handle
# it all in one place.
sub get_firstevents {
	my($this) = @_;
	for(@{$this->{FirstEv}}) {
	}
}

# Ok, here we go... :)
sub do_events {
	return;
	my($this,$timestamp) = @_;
	# 
	# XXX Bindable-init
	#
	print "DOEV $timestamp\n";

	# See which sensors generate events this time..
	my @evs;
	for(@{$this->{Sensors}}) {
		print "TICK $_\n";
		if($_->{Type}{Actions}{ClockTick}) {
			push @evs, &{$_->{Type}{Actions}{ClockTick}}(
					$_, $_->{Fields}, $timestamp);
		}
	}
	print "NOW @evs\n";

	while(@evs) {
		# Do event cascade. This involves:

		my @newevs;
		# Do eventsProcessed
	}

}

1;


