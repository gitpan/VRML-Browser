# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

# Default is exposedfield - third argument says what it is if otherwise:
# 0 = non-exposed field,
# in = eventIn
# out = eventOut
#
# The event subs:
#  Initialize($node,$fields,$time): called when node created in world
#  EventsProcessed($node,$fields,$time): called when events have been received
#					and processed by other routines 
#  field/eventname($node,$fields,$value,$time) 
#	(if field/exposedField, the name, otherwise exact eventname)
#		: called when eventIn received in that event.
#  ClockTick($node,$fields,$time): called at each clocktick if exists 
#	(only timesensor-type nodes)
#  
# default field/eventname: $t->set_field(...,...), if event received,
#  field is not set so that it can be ignored (e.g. TimeSensor)
#  set_field returns the eventout to send also...!!
#
#  all these can return lists of eventOuts to send.
#
# XXXXXXXXXXXX
#  Problem: Interpolators send an event at startup and they shouldn't...
#  TouchSensor: how to get hitpoint, normal and texcoords without 
#   		spending an ungodly amount of time at it?

package VRML::NodeType; # Same for internal and external!

sub new {
	my($type,$name,$fields,$eventsubs) = @_;
	my $this = bless {
		Name => $name,
		Fields => {},
		Defaults => {},
		Actions => $eventsubs,
	},$type;
	for(keys %$fields) {
		$this->{Defaults}{$_} = $fields->{$_}[1];
		$this->{FieldTypes}{$_} = $fields->{$_}[0];
		# $this->{Fields}{$_} = "VRML::Field::$fields->{$_}[0]";
		my $t = $fields->{$_}[2];
		if(!defined $t or $t eq "") {
			if(!defined $t) {
				$this->{EventOuts}{$_} = $_;
				$this->{EventOuts}{$_."_changed"} = $_;
				$this->{EventIns}{$_} = $_;
				$this->{EventIns}{"set_".$_} = $_;
			}
		} else {
			my $io = ucfirst $t;
			$this->{Event.$io."s"}{$_} = $_;
		}
	}
	return $this;
}


%VRML::Nodes::bindable = map {($_,1)} qw/
	Viewpoint
	Background
	Navigationinfo
	Fog
/;

%VRML::Nodes::initevents = map {($_,1)} qw/
	TimeSensor
	TouchSensor
	PlaneSensor
	CylinderSensor
	SphereSensor
	ProximitySensor
	Collision
	VisibilitySensor
/;

# What are the transformation-hierarchy child nodes?
%VRML::Nodes::children = qw(
	Transform	children
	Group		children
);

%VRML::Nodes::siblingsensitive = map {($_,1)} qw/
	TouchSensor
	PlaneSensor
	CylinderSensor
	SphereSensor
/;


%VRML::Nodes = (
# Internal structures, to store def and use in the right way
DEF => new VRML::NodeType("DEF",{node => [SFNode, NULL]}, id => [SFString,""]),
USE => new VRML::NodeType("USE",{node => [SFNode, NULL]}, id => [SFString,""]),

Shape => new VRML::NodeType ("Shape",
	{appearance => [SFNode, NULL],
	 geometry => [SFNode, NULL]}
),

# Complete
Appearance => new VRML::NodeType ("Appearance",
	{material => [SFNode,NULL],
	 texture => [SFNode,NULL],
	 texturetransform => [SFNode,NULL]}
),

# Complete 
Material => new VRML::NodeType ("Material",
	{diffuseColor => [SFColor, [0.8, 0.8, 0.8]],
	 ambientIntensity => [SFFloat, 0.2],
	 specularColor => [SFColor, [0,0,0]],
	 emissiveColor => [SFColor, [0,0,0]],
	 shininess => [SFFloat, 0.2],
	 transparency => [SFFloat, 0]}
),

Box => new VRML::NodeType("Box",
	{size => [SFVec3f, [2,2,2]]}
),

# Complete
Cylinder => new VRML::NodeType ("Cylinder",
	{radius => [SFFloat,1],
	 height => [SFFloat,1],
	 side => [SFBool,1],
	 top => [SFBool,1],
	 bottom => [SFBool,1]},
),

# Complete
Cone => new VRML::NodeType ("Cone",
	{bottomRadius => [SFFloat,1],
	 height => [SFFloat,2],
	 side => [SFBool,1],
	 bottom => [SFBool,1]},
),

# Complete
Coordinate => new VRML::NodeType("Coordinate",
	{point => [MFVec3f, []]}
),

ElevationGrid => new VRML::NodeType("ElevationGrid",
	{height => [MFFloat, []],
	 xDimension => [SFInt32, 0],
	 zDimension => [SFInt32, 0]
	}
),

# Complete
Sphere => new VRML::NodeType("Sphere",
	{radius => [SFFloat, 1]}
),

IndexedFaceSet => new VRML::NodeType("IndexedFaceSet",
	{coord => [SFNode, NULL],
	 coordIndex => [MFInt32, []],
	 solid => [SFBool, 1],
	 creaseAngle => [SFFloat, 0],
	}
),

Transform => new VRML::NodeType ("Transform",
	{translation => [SFVec3f, [0,0,0]],
	 rotation => [SFRotation, [0,0,1,0]],
	 scale => [SFVec3f, [1,1,1]],
	 children => [MFNode, []],
	},
),

# Complete 
Group => new VRML::NodeType("Group",
	{children => [MFNode, []],
	 bboxCenter => [SFVec3f, [0,0,0]],
	 bboxSize => [SFVec3f, [-1,-1,-1]],
	}
),

# Complete
WorldInfo => new VRML::NodeType("WorldInfo",
	{title => [SFString, ""],
	 info => [MFString, []]
	}
),

# Complete
# XXX "getting value if no events should give keyValue[0]!!!"
ScalarInterpolator => new VRML::NodeType("ScalarInterpolator",
	{key => [MFFloat, []],
	 keyValue => [MFFloat, []],
	 set_fraction => [SFFloat, undef, in],
	 value_changed => [SFFloat, undef, out],
	},
	{Initialize => sub {
		my($t,$f) = @_;
		$f->{value_changed} = 
		 (defined $f->{keyValue}[0] ?
		 	$f->{keyValue}[0] : 0);
		return [$t, value_changed, $f->{keyValue}[0]];
	 },
	 EventsProcessed => sub {
		my($t, $f) = @_;
		my $k = $f->{key};
		my $kv = $f->{keyValue};
		my $fr = $f->{set_fraction};
		my $v;
		if($f->{set_fraction} <= $k->[0]) {
			$v = $kv->[0]
		} elsif($f->{set_fraction} >= $k->[-1]) {
			$v = $kv->[-1]
		} else {
			my $i;
			for($i=1; $i<=$#$k; $i++) {
				if($f->{set_fraction} < $k->[$i]) {
					print "SCALARX: $i\n"
						if $VRML::verbose;
					$v = ($f->{set_fraction} - $k->[$i-1]) /
					     ($k->[$i] - $k->[$i-1]) *
					     ($kv->[$i] - $kv->[$i-1]) +
					     $kv->[$i-1];
					last
				}
			}
		}
		print "SCALAR: NEW_VALUE $v ($k $kv $f->{set_fraction}, $k->[0] $k->[1] $k->[2] $kv->[0] $kv->[1] $kv->[2])\n"
			if $VRML::verbose;
		return [$t, value_changed, $v];
	}
	}
),

# Complete
# XXX "getting value if no events should give keyValue[0]!!!"
OrientationInterpolator => new VRML::NodeType("OrientationInterpolator",
	{key => [MFFloat, []],
	 keyValue => [MFRotation, []],
	 set_fraction => [SFFloat, undef, in],
	 value_changed => [SFRotation, undef, out],
	},
	{Initialize => sub {
		my($t,$f) = @_;
		# XXX Correct?
		$f->{value_changed} = ($f->{keyValue}[0] or [0,0,1,0]);
		return ();
		# return [$t, value_changed, $f->{keyValue}[0]];
	 },
	 EventsProcessed => sub {
		my($t, $f) = @_;
		my $k = $f->{key};
		my $kv = $f->{keyValue};
		my $fr = $f->{set_fraction};
		my $v;
		if($f->{set_fraction} <= $k->[0]) {
			$v = $kv->[0]
		} elsif($f->{set_fraction} >= $k->[-1]) {
			$v = $kv->[-1]
		} else {
			my $i;
			for($i=1; $i<=$#$k; $i++) {
				if($f->{set_fraction} < $k->[$i]) {
					print "SCALARX: $i\n"
						if $VRML::verbose::events;
					my $f = ($f->{set_fraction} - $k->[$i-1]) /
					     ($k->[$i] - $k->[$i-1]) ;
					my $s = VRML::Quaternion->
						new_vrmlrot(@{$kv->[$i-1]});
					my $e = VRML::Quaternion->
						new_vrmlrot(@{$kv->[$i]});
					print "Start: ",$s->as_str,"\n" if $VRML::verbose::oint;
					print "End: ",$e->as_str,"\n" if $VRML::verbose::oint;
					my $step = $e->multiply($s->invert);
					print "Step: ",$step->as_str,"\n" if $VRML::verbose::oint;
					$step = $step->multiply_scalar($f);
					print "StepMult $f: ",$step->as_str,"\n" if $VRML::verbose::oint;
					my $tmp = $s->multiply($step);
					print "TMP: ",$tmp->as_str,"\n" if $VRML::verbose::oint;
					$v = $tmp->to_vrmlrot;
					print "V: ",(join ',  ',@$v),"\n" if $VRML::verbose::oint;
					last
				}
			}
		}
		print "SCALAR: NEW_VALUE $v ($k $kv $f->{set_fraction}, $k->[0] $k->[1] $k->[2] $kv->[0] $kv->[1] $kv->[2])\n"
			if $VRML::verbose;
		return [$t, value_changed, $v];
	}
	}
),

# Complete
# XXX "getting value if no events should give keyValue[0]!!!"
ColorInterpolator => new VRML::NodeType("ColorInterpolator",
	{key => [MFFloat, []],
	 keyValue => [MFColor, []],
	 set_fraction => [SFFloat, undef, in],
	 value_changed => [SFColor, undef, out],
	},
    @x = 
	{Initialize => sub {
		my($t,$f) = @_;
		$f->{value_changed} = ($f->{keyValue}[0] or [0,0,0]);
		return ();
		# XXX DON'T DO THIS!
		# return [$t, value_changed, $f->{keyValue}[0]];
	 },
	 EventsProcessed => sub {
		my($t, $f) = @_;
		my $k = $f->{key};
		my $kv = $f->{keyValue};
		# print "K,KV: $k, $kv->[0][0], $kv->[0][1], $kv->[0][2],
		# 	$kv->[1][0], $kv->[1][1], $kv->[1][2]\n";
		my $fr = $f->{set_fraction};
		my $v;
		if($f->{set_fraction} <= $k->[0]) {
			$v = $kv->[0]
		} elsif($f->{set_fraction} >= $k->[-1]) {
			$v = $kv->[-1]
		} else {
			my $i;
			for($i=1; $i<=$#$k; $i++) {
				if($f->{set_fraction} < $k->[$i]) {
					print "COLORX: $i\n"
						if $VRML::verbose or
						   $VRML::sverbose =~ /\binterp\b/;
					for(0..2) {
						$v->[$_] = ($f->{set_fraction} - $k->[$i-1]) /
						     ($k->[$i] - $k->[$i-1]) *
						     ($kv->[$i][$_] - $kv->[$i-1][$_]) +
						     $kv->[$i-1][$_];
					}
					last
				}
			}
		}
		print "SCALAR: NEW_VALUE $v ($k $kv $f->{set_fraction}, $k->[0] $k->[1] $k->[2] $kv->[0] $kv->[1] $kv->[2])\n"
			if $VRML::verbose or
			   $VRML::sverbose =~ /\binterp\b/;
		return [$t, value_changed, $v];
	}
	}
),

PositionInterpolator => new VRML::NodeType("PositionInterpolator",
	{key => [MFFloat, []],
	 keyValue => [MFVec3f, []],
	 set_fraction => [SFFloat, undef, in],
	 value_changed => [SFVec3f, undef, out],
	},
	@x
),
	

TimeSensor => new VRML::NodeType("TimeSensor",
	{cycleInterval => [SFTime, 1],
	 enabled => [SFBool, 1],
	 loop => [SFBool, 0],
	 startTime => [SFTime, 0],
	 stopTime => [SFTime, 0],
	 isActive => [SFBool, undef, out],
	 cycleTime => [SFTime, undef, out],
	 fraction_changed => [SFFloat, undef, out],
	 time => [SFTime, undef, out]
	}, 
	{
	 Initialize => sub {
	 	my($t,$f) = @_;
	 	return ();
	 },
	 EventsProcessed => sub {
	 	return ();
	 },
	 # 
	 #  Ignore startTime and cycleInterval when active..
	 #
	 startTime => sub {
	 	my($t,$f,$val) = @_;
		if($t->{Priv}{active}) {
		} else {
			# $f->{startTime} = $val;
		}
	 },
	 cycleInterval => sub {
	 	my($t,$f,$val) = @_;
		if($t->{Priv}{active}) {
		} else {
			# $f->{cycleInterval} = $val;
		}
	 },
	 # Ignore if less than startTime
	 stopTime => sub {
	 	my($t,$f,$val) = @_;
		if($t->{Priv}{active} and $val < $f->{startTime}) {
		} else {
			# return $t->set_field(stopTime,$val);
		}
	 },

	 ClockTick => sub {
		my($t,$f,$tick) = @_;
		my @e;
		my $act = 0; 
		# Are we active?
		if($tick > $f->{startTime}) {
			if($f->{startTime} >= $f->{stopTime}) {
				if($f->{loop}) {
					$act = 1;
				} else {
					if($f->{startTime} + $f->{cycleInterval} >=
						$tick) {
						$act = 1;
					}
				}
			} else {
				if($tick < $f->{stopTime}) {
					if($f->{loop}) {
						$act = 1;
					} else {
						if($f->{startTime} + $f->{cycleInterval} >=
							$tick) {
							$act = 1;
						}
					}
				}
			}
		}
		my $ct = 0, $frac = 0;
		my $time = ($tick - $f->{startTime}) / $f->{cycleInterval};
		print "TIMESENS: $time '$act'\n" if $VRML::verbose::timesens;
		if($act) {
			if($f->{loop}) {
				$frac = $time - int $time;
			} else {
				$frac = ($time > 1 ? 1 : $time);
			}
		} else {$frac = 1}
		$ct = int $time;
		if($act || $f->{isActive}) {
			push @e, [$t, "time", $tick];
			push @e, [$t, fraction_changed, $frac];
			print "TIME: FRAC: $frac ($time $act $ct $tick $f->{startTime} $f->{cycleInterval} $f->{stopTime})\n"
				if $VRML::verbose;
			if($ct != $f->{cycleTime}) {
				push @e, [$t, cycleTime, $ct];
			}
		} 
		if($act) {
			if(!$f->{isActive}) {
				push @e, [$t, isActive, 1];
			}
		} else {
			if($f->{isActive}) {
				push @e, [$t, isActive, 0];
			}
		}
		$this->{Priv}{active} = $act;
		return @e;
	 },
	}
),

TouchSensor => new VRML::NodeType("TouchSensor",
	{enabled => [SFBool, 1],
	 isOver => [SFBool, undef, out],
	 isActive => [SFBool, undef, out],
	 hitPoint_changed => [SFVec3f, undef, out],
	 hitNormal_changed => [SFVec3f, undef, out],
	 hitTexCoord_changed => [SFVec2f, undef, out],
	 touchTime => [SFTime, undef, out],
	},
	{
	__mouse__ => sub {
		my($t,$f,$time,$moved,$button,$over,$pos,$norm,$texc) = @_; 
		print "MOUSE: over $over but $button moved $moved\n";
		# 1. isover
		if($moved and $t->{MouseOver} != $over) {
			print "OVCH\n";
			$f->{isOver} = $over;
			$t->{MouseOver} = $over;
		}
		# 2. hitpoint
		# XXX
		# 3. button
		if($t->{MouseOver} and $button) {
			if($button eq "PRESS") {
				print "ISACT\n";
				$f->{isActive} = 1;
				$t->{MouseActive} = 1;
			} else {
				if($t->{MouseActive}) {
					print "TOUCHTIM\n";
					$f->{touchTime} = $time;
				}
				print "ISACT 0\n";
				$f->{isActive} = 0;
				$t->{MouseActive} = 0;
			}
		}
	}
	}
),

NavigationInfo => new VRML::NodeType("NavigationInfo",
	{type => [SFString, ""],
	 headlight => [SFBool, 1]} # Unimpl
),

Viewpoint => new VRML::NodeType("Viewpoint",
	{position => [SFVec3f,[0,0,10]],
	 orientation => [SFRotation, [0,0,1,0]],
	 fieldOfView => [SFFloat, 0.785398],
	 description => [SFString, ""],
	 jump => [SFBool, 1],
	 set_bind => [SFBool, undef, in],
	 bindTime => [SFTime, undef, out],
	 isBound => [SFBool, undef, out],
	},
	{
	Initialize => sub {
		my($t,$f) = @_;
		if($t->{Priv}{initbound}) {
			print "SEND_INITBOUND!!!\n"
				if $VRML::verbose;
			return [$t, isBound, 1];
		}
		return ();
	}
	}
),

# Complete
#  - fields, eventins and outs parsed in Parse.pm by special switch :(
Script => new VRML::NodeType("Script",
	{url => [MFString, []],
	 directOutput => [SFBool, 0, ""], # not exposedfields
	 mustEvaluate => [SFBool, 0, ""]
	},
	{
		Initialize => sub {
			my($t,$f) = @_;
			print "ScriptInit $_[0] $_[1]!!\n";
			print "Parsing script\n";
			my $h;
			for(@{$f->{url}}) {
				my $str = $_;
				print "TRY $str\n";
				if(s/^perl_tjl_xxx://) {
					$h = eval "({$_})";
					if($@) {
						die "Inv script '$@'"
					}
					last;
				} elsif(s/^perl_tjl_xxx1://) {
					{
					print "XXX1 script\n";
					my $t = $t->{RFields};
					$h = eval "({$_})";
					print "Evaled: $h\n";
					if($@) {
						die "Inv script '$@'"
					}
					}
					last;
				}
			}
			if(!defined $h) {
				die "Didn't found a valid perl_tjl_xxx(1) script";
			}
			print "GOT EVS: ",(join ',',keys %$h),"\n";
			$t->{ScriptScript} = $h;
			return ();
		},
		url => sub {
			print "ScriptURL $_[0] $_[1]!!\n";
			die "URL setting not enabled";
		},
		__any__ => sub {
			my($t,$f,$v,$time,$ev) = @_;
			print "ScriptANY $_[0] $_[1] $_[2] $_[3] $_[4]!!\n"
				if $VRML::verbose::script;
			my $s;
			if(($s = $t->{ScriptScript}{$ev})) {
				print "CALL $s\n"
				 if $VRML::verbose::script;
				return &{$s}();
			}
			return ();
		},
		EventsProcessed => sub {
			print "ScriptEP $_[0] $_[1]!!\n"
				if $VRML::verbose::script;
			return ();
		},
	}
),

# XXX
Collision => new VRML::NodeType("Collision",
	{collide => [SFBool, 1],
	 children => [MFNode, []],
	}
),


);



