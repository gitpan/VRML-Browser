# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.


# 
# The different viewers for VRML::Browser.
#
# All viewers are given the current viewpoint node
# and their own internal coordinate system (position+rotation)
# from that.
#
# XXX Examine doesn't handle animated viewpoints at all!


package VRML::Viewer;
require 'Quaternion.pm';

# Default gaze: -z, pos: z
sub new {
	my($type) = @_;
	return bless {
		Pos => [0,0,10],
		Dist => 10,
		Quat => new VRML::Quaternion(1,0,0,0),
	}, $type;
}

package VRML::Viewer::Walk;
@ISA=VRML::Viewer;

sub handle {
	my($this, $mev, $but, $mx, $my) = @_;
	# print "VEIEVENT\n";
	if($mev eq "PRESS" and $but == 1) {
		$this->{SY} = $my;
		$this->{SX} = $mx;
	} elsif($mev eq "DRAG" and $but == 1) {
		my $yd = ($my - $this->{SY});
		my $xd = ($mx - $this->{SX});
		my $nv = $this->{Quat}->invert->rotate([0,0,0.15*$yd]);
		for(0..2) {$this->{Pos}[$_] += $nv->[$_]}
		my $nq = new VRML::Quaternion(1-0.2*$xd,0,0.2*$xd,0);
		$nq->normalize_this;
		$this->{Quat} = $nq->multiply($this->{Quat});
		print "WVIEW: (",(join ',',@{$this->{Quat}}),") (",
				(join ',',@{$this->{Pos}}),") (",
				(join ',',@{$nv}),") \n";
	}
}

sub ignore_vpcoords {
	return 0;
}

{my $ind = 0;
sub togl {
	my($this) = @_;
	$this->{Quat}->togl();
	VRML::OpenGL::glTranslatef(map {-$_} @{$this->{Pos}});
	$ind ++;
}
}

package VRML::Viewer::Examine;
@ISA=VRML::Viewer;

# Mev: PRESS, DRAG
sub handle {
	my($this, $mev, $but, $mx, $my) = @_;
	 # print "HANDLE $mev $but $mx $my\n";
	if($mev eq "PRESS" and $but == 1) {
		# print 'PRESS\n';
		$this->{SQuat} = $this->xy2qua($mx,$my);
		$this->{OQuat} = $this->{Quat};
	} elsif($mev eq "DRAG" and $but == 1) {
		my $q = $this->xy2qua($mx,$my);
		my $arc = $q->multiply($this->{SQuat}->invert());
		# print "Arc: ",(join '   ',@$arc),"\n";
		$this->{Quat} = $arc->multiply($this->{OQuat});
		# print "Quat:\t\t\t\t ",(join '   ',@{$this->{Quat}}),"\n";
		# $this->{Quat} = $this->{OQuat}->multiply($arc);
#		print "DRAG1: (",
#			(join ',',@{$this->{SQuat}}), ") (",
#			(join ',',@{$this->{OQuat}}), ")\n (",
#			(join ',',@$q), ")\n (",
#			(join ',',@$arc), ") (",
#			(join ',',@{$this->{Quat}}), ")\n",
	} elsif($mev eq "PRESS" and $but == 3) {
		$this->{SY} = $my;
		$this->{ODist} = $this->{Dist};
	} elsif($mev eq "DRAG" and $but == 3) {
		$this->{Dist} = $this->{ODist} * exp($this->{SY} - $my);
	}
	$this->{Pos} = $this->{Quat}->invert->rotate([0,0,$this->{Dist}]);
	# print "POS:     ",(join '    ',@{$this->{Pos}}),"\n";
	# print "QUASQ: ",$this->{Quat}->abssq,"\n";
	# print "VIEW: (",(join ',',@{$this->{Quat}}),") (",
	# 	 	(join ',',@{$this->{Pos}}),")\n";
}

sub change_viewpoint {
	my($this, $jump, $push, $ovp, $nvp) = @_;
	if($push == 1) { # Pushing the ovp under - must store stuff...
		$ovp->{Priv}{viewercoords} = [
			$this->{Dist}, $this->{Quat}
		];
	} elsif($push == -1 && $jump && $nvp->{Priv}{viewercoords}) {
		($this->{Dist}, $this->{Quat}) = 
			@{$nvp->{Priv}{viewercoords}};
	}
	if($push == -1) {
		delete $ovp->{Priv}{viewercoords};
	}
	if(!$jump) {return}
	my $f = $nvp->getfields();
	my $p = $f->{position};
	my $o = $f->{orientation};
	my $os = sin($o->[3]); my $oc = cos($o->[3]);
	$this->{Dist} = sqrt($p->[0]**2 + $p->[1]**2 + $p->[2]**2);
	$this->{Quat} = new VRML::Quaternion(
		$oc, map {$os * $_} @{$o}[0..2]);
}

{my $ind = 0;
sub togl {
	my($this) = @_;
#	print "VP: [",(join ', ',@{$this->{Pos}}),"] [",(join ', ',@{$this->{Quat}}),"]\n";
	if($ind % 3 == -1) { # XXX Why doesn't this work?
		$this->{Quat}->togl();
		VRML::OpenGL::glTranslatef(map {-$_} @{$this->{Pos}});
	} else {
		VRML::OpenGL::glTranslatef(0,0,-$this->{Dist});
		$this->{Quat}->togl();
	}
	$ind ++;
}
}

# Whether to ignore the internal VP coords aside from jumps?
sub ignore_vpcoords {
	return 1;
}

# ArcCone from TriD
sub xy2qua {
	my($this, $x, $y) = @_;
#	print "XY2QUA: $x $y\n";
	$x -= 0.5; $y -= 0.5; $x *= 2; $y *= 2;
	$y = -$y;
	my $dist = sqrt($x**2 + $y**2);
#	print "DXY: $x $y $dist\n";
	if($dist > 1.0) {$x /= $dist; $y /= $dist; $dist = 1.0}
	my $z = 1-$dist;
	# print "Z: $z\n";
	my $qua = VRML::Quaternion->new(0,$x,$y,$z);
#	print "XY2QUA: $x $y ",(join ',',@$qua),"\n";
	$qua->normalize_this();
#	print "XY2QUA: $x $y ",(join ',',@$qua),"\n";
	return $qua;

}

1;
