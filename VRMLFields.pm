# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

# Field types, parsing and printing

# SFNode is in Parse.pm

# XXX Decide what's the forward assertion..

@VRML::Fields = qw/
	SFFloat
	MFFloat
	SFRotation
	SFVec3f
	MFVec3f
	SFBool
	SFInt32
	MFInt32
	SFNode
	MFNode
	SFColor
	MFColor
	SFTime
	SFString
/;

package VRML::Field;
VRML::Error->import();

sub es {
	$p = (pos $_[1]) - 20;
	return substr $_[1],$p,40;
	
}

# The C type interface for the field type, encapsulated
# By encapsulating things well enough, we'll be able to completely
# change the interface later, e.g. to fit together with javascript etc.
sub ctype ($) {die "VRML::Field::ctype - abstract function called"}
sub calloc ($$) {return ""}
sub cassign ($$) {return "$_[1] = $_[2];"}
sub cfree ($) {if($_[0]->calloc) {return "free($_[1]);"} return ""}
sub cget {if(!defined $_[2]) {return "$_[1]"}
	else {die "If CGet with indices, abstract must be overridden"} }
sub cstruct () {return ""}
sub cfunc {die("Must overload cfunc")}

package VRML::Field::SFFloat;
@ISA=VRML::Field;

sub parse {
	my($type,$p,$s,$n) = @_;
	$_[2] =~ /\G\s*([\d\.+-eE]+)\b/gs or die "$s at $p didn't match number";
	return $1;
}

sub print {print $_[1]}

sub ctype {return "float $_[1]"}
sub cfunc {return "$_[1] = SvNV($_[2]);\n"}

package VRML::Field::SFTime;
@ISA=VRML::Field::SFFloat;

package VRML::Field::SFInt32;
@ISA=VRML::Field;

sub parse {
	my($type,$p,$s,$n) = @_;
	$_[2] =~ /\G\s*(-?[\deE]+)\b/gsc 
		or die "$s at $p didn't match SFInt32: '",$type->es($_[2]),"'\n'";
	return $1;
}

sub print {print " $_[1] "}

sub ctype {return "int $_[1]"}
sub cfunc {return "$_[1] = SvIV($_[2]);\n"}

package VRML::Field::SFColor;
@ISA=VRML::Field;

sub parse {
	my($type,$p) = @_;
	$_[2] =~ /\G\s*([\d\.+-eE]+)\s+([\d\.+-eE]+)\s+([\d\.+-eE]+)\b/gsc 
		or die "$_[2] at $p didn't match color: '",$type->es($_[2]),"'\n'";
	return [$1,$2,$3];
}

sub print {print join ' ',@{$_[1]}}

sub cstruct {return "struct SFColor {
	float c[3]; };"}
sub ctype {return "struct SFColor $_[1]"}
sub cget {return "($_[1].c[$_[2]])"}

sub cfunc {
#	return ("a,b,c","float a;\nfloat b;\nfloat c;\n",
#		"$_[1].c[0] = a; $_[1].c[1] = b; $_[1].c[2] = c;");
	return "{
		AV *a;
		SV **b;
		int i;
		if(!SvROK($_[2])) {
			die(\"Help! SFColor without being ref\");
		}
		if(SvTYPE(SvRV($_[2])) != SVt_PVAV) {
			die(\"Help! SFColor without being arrayref\");
		}
		a = (AV *) SvRV($_[2]);
		for(i=0; i<3; i++) {
			b = av_fetch(a, i, 1); /* LVal for easiness */
			if(!b) {
				die(\"Help: SFColor b == 0\");
			}
			$_[1].c[i] = SvNV(*b);
		}
	}
	"
}

package VRML::Field::SFVec3f;
@ISA=VRML::Field::SFColor;
sub cstruct {return ""}


package VRML::Field::SFRotation;
@ISA=VRML::Field;

sub parse {
	my($type,$p) = @_;
	$_[2] =~ /\G\s*([\d\.+-]+)\s+([\d\.+-]+)\s+([\d\.+-]+)\s+([\d\.+-]+)\b/gsc 
		or VRML::Error::parsefail($_[2],"not proper rotation");
	return [$1,$2,$3,$4];
}

sub print {print join ' ',@{$_[1]}}

sub cstruct {return "struct SFRotation {
 	float r[4]; };"}
sub ctype {return "struct SFRotation $_[1]"}
sub cget {return "($_[1].r[$_[2]])"}

sub cfunc {
#	return ("a,b,c,d","float a;\nfloat b;\nfloat c;\nfloat d;\n",
#		"$_[1].r[0] = a; $_[1].r[1] = b; $_[1].r[2] = c; $_[1].r[3] = d;");
	return "{
		AV *a;
		SV **b;
		int i;
		if(!SvROK($_[2])) {
			die(\"Help! SFRotation without being ref\");
		}
		if(SvTYPE(SvRV($_[2])) != SVt_PVAV) {
			die(\"Help! SFRotation without being arrayref\");
		}
		a = (AV *) SvRV($_[2]);
		for(i=0; i<4; i++) {
			b = av_fetch(a, i, 1); /* LVal for easiness */
			if(!b) {
				die(\"Help: SFColor b == 0\");
			}
			$_[1].r[i] = SvNV(*b);
		}
	}
	"
}

package VRML::Field::SFBool;
@ISA=VRML::Field;

sub parse {
	my($type,$p,$s,$n) = @_;
	$_[2] =~ /\G\s*(TRUE|FALSE)\b/gs or die "Invalid value for BOOL\n";
	return ($1 eq "TRUE");
}

sub ctype {return "int $_[1]"}
sub cget {return "($_[1])"}
sub cfunc {return "$_[1] = SvIV($_[2]);\n"}

sub print {print ($_[1] ? TRUE : FALSE)}

package VRML::Field::SFString;
@ISA=VRML::Field;

# XXX Handle backslashes in string properly
sub parse {
	my($type,$p,$s,$n) = @_;
	$_[2] =~ /\G\s*"([^"]*)"\s*/gs or die "Invalid SFString";
	print "GOT STRING '$1'\n";
	return $1;
}

sub ctype {return "SV *$_[1]"}
sub calloc {"$_[1] = newSVpv(\"\",0);"}
sub cassign {"sv_setsv($_[1],$_[2]);"}
sub cfree {"SvREFCNT_dec($_[1]);"}
sub cfunc {"sv_setsv($_[1],$_[2]);"}

sub print {print "\"$_[1]\""}

package VRML::Field::MFString;
@ISA=VRML::Field::Multi;

# XXX Should be optimized heavily! Other MFs are ok.
package VRML::Field::MFFloat;
@ISA=VRML::Field::Multi;

package VRML::Field::MFNode;
@ISA=VRML::Field::Multi;

package VRML::Field::MFColor;
@ISA=VRML::Field::Multi;

package VRML::Field::MFVec3f;
@ISA=VRML::Field::Multi;

package VRML::Field::MFInt32;
@ISA=VRML::Field::Multi;

package VRML::Field::MFRotation;
@ISA=VRML::Field::Multi;

package VRML::Field::Multi;

sub ctype {
	my $r = (ref $_[0] or $_[0]);
	$r =~ s/VRML::Field::MF//;
	return "struct Multi_$r $_[1]";
}
sub cstruct {
	my $r = (ref $_[0] or $_[0]);
	my $t = $r;
	$r =~ s/VRML::Field::MF//;
	$t =~ s/::MF/::SF/;
	my $ct = $t->ctype;
	return "struct Multi_$r { int n; $ct *p; };"
}
sub calloc {
	return "$_[1].n = 0; $_[1].p = 0;";
}
sub cassign {
	my $t = (ref $_[0] or $_[0]);
	$t =~ s/::MF/::SF/;
	my $cm = $t->calloc("$_[1].n");
	my $ca = $t->cassign("$_[1].p[__i]", "$_[2].p[__i]");
	"if($_[1].p) {free($_[1].p)};
	 $_[1].n = $_[2].n; $_[1].p = malloc(sizeof(*($_[1].p))*$_[1].n);
	 {int __i;
	  for(__i=0; __i<$_[1].n; __i++) {
	  	$cm
		$ca
	  }
	 }
	"
}
sub cfree {
	"if($_[1].p) {free($_[1].p);$_[1].p=0;} $_[1].n = 0;"
}
sub cgetn { "($_[1].n)" }
sub cget { if($#_ == 1) {"($_[1].p)"} else {
	my $r = (ref $_[0] or $_[0]);
	$r =~ s/::MF/::SF/;
	if($#_ == 2) {
		return "($_[1].p[$_[2]])";
	}
	return $r->cget("($_[1].p[$_[2]])", @$_[3..$#_])
	} }

sub cfunc {
	my $r = (ref $_[0] or $_[0]);
	$r =~ s/::MF/::SF/;
	my $su = $r->cfunc("($_[1].p[iM])","(*bM)");
	return "{
		AV *aM;
		SV **bM;
		int iM;
		int lM;
		if(!SvROK($_[2])) {
			die(\"Help! Multi without being ref\");
		}
		if(SvTYPE(SvRV($_[2])) != SVt_PVAV) {
			die(\"Help! Multi without being arrayref\");
		}
		aM = (AV *) SvRV($_[2]);
		lM = av_len(aM)+1;
		/* XXX Free previous p */
		$_[1].n = lM;
		$_[1].p = malloc(lM * sizeof(*($_[1].p)));
		/* XXX ALLOC */
		for(iM=0; iM<lM; iM++) {
			bM = av_fetch(aM, iM, 1); /* LVal for easiness */
			if(!bM) {
				die(\"Help: Multi $r bM == 0\");
			}
			$su
		}
	}
	"
}


sub parse {
	my($type,$p) = @_;
	my $stype = $type;
	$stype =~ s/::MF/::SF/;
	if($_[2] =~ /\G\s*\[\s*/gsc) {
		my @a;
		while($_[2] !~ /\G\s*,?\s*\]\s*/gsc) {
			$_[2] =~ /\G\s*,\s*/gsc; # Eat comma if it is there...
			my $v =  $stype->parse($p,$_[2],$_[3]);
			push @a, $v if defined $v; 
		}
		return \@a;
	} else {
		return [$stype->parse($p,$_[2],$_[3])];
	}
}

sub print {
	my($type) = @_;
	print " [ ";
	my $r = $type;
	$r =~ s/::MF/::SF/;
	for(@{$_[1]}) {
		$r->print($_);
	}
	print " ]\n";
}

package VRML::Field::SFNode;

sub ctype {"void *$_[1]"}      # XXX ???
sub calloc {"$_[1] = 0;"}
sub cfree {"$_[1] = 0;"}
sub cstruct {""}
sub cfunc {
	"$_[1] = (void *)SvIV($_[2]);"
}
sub cget {if(!defined $_[2]) {return "$_[1]"}
	else {die "SFNode index!??!"} }

