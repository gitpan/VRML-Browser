# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.


use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => "VRML::VRMLFunc",
	DISTNAME => "VRML-Browser",
	VERSION => "0.01",
);

sub MY::postamble {
	'
VRMLFunc.pm VRMLFunc.xs: VRMLC.pm VRMLFields.pm VRMLNodes.pm
	$(PERL) VRMLC.pm
'
}
