# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.


# Implement OpenGL backend using the C structs.

package VRML::GLBackEnd;
use VRML::OpenGL;
use blib;
use VRML::VRMLFunc;
require 'VRMLCU.pm';
require 'Viewer.pm';
use strict vars;
# ISA?

if(0) {
VRML::VRMLFunc::render_verbose(1);
$VRML::verbose = 1;
}

sub new {
	my($type) = @_;
	my $this = bless {}, $type;
	my($w,$h) = (300,300);
	$this->{W} = $w; $this->{H} = $h;
        my $x = 0; 
        my @db = &GLX_DOUBLEBUFFER;
#       my @db = ();
        if($VRML::offline) {$x = -1; @db=()}
        
        print "STARTING OPENGL\n" if $VRML::verbose;
        glpOpenWindow(attributes=>[&GLX_RGBA, @db,
                                &GLX_RED_SIZE,1,
                                &GLX_GREEN_SIZE,1,
                                &GLX_BLUE_SIZE,1,
                                &GLX_DEPTH_SIZE,1,
# Alpha size?
                        ],
                mask => (KeyPressMask | ButtonPressMask |
                        ButtonMotionMask | ButtonReleaseMask |
                        ExposureMask | StructureNotifyMask |
                        PointerMotionMask),
                width => $w,height => $h,
                "x" => $x);

        glClearColor(0,0,0,1);
        my $lb = VRML::OpenGL::glpRasterFont("5x8",0,256);
        $VRML::OpenGL::fontbase = $lb;
#       glDisable(&GL_DITHER);
        glShadeModel (&GL_SMOOTH);
        glEnable(&GL_DEPTH_TEST);
        glEnable(&GL_NORMALIZE);
        glEnable(&GL_LIGHTING);
        glEnable(&GL_LIGHT0);
        glLightModeli(&GL_LIGHT_MODEL_TWO_SIDE, &GL_TRUE);

	glEnable(&GL_POLYGON_OFFSET_EXT);
	glPolygonOffsetEXT(0.0000000001,0.00002);

        # $this->reshape();

# Try to interface with Tk event loop?
        if(defined &Tk::DoOneEvent) {
                my $gld = VRML::OpenGL::glpXConnectionNumber();
                # Create new mainwindow just for us.
                my $mw = MainWindow->new();
                $mw->iconify();
                my $fh = new FileHandle("<&=$gld\n") 
                        or die("Couldn't reopen GL filehandle");
                $mw->fileevent($fh,'readable',
                   sub {# print "GLEV\n"; 
                        $this->twiddle(1)});
                $this->{FileHandle} = $fh;
                $this->{MW} = $mw;
        }

        $this->{Interactive} = 1;
        print "STARTED OPENGL\n" if $VRML::verbose;

        if($VRML::offline) {
                $this->doconfig($w,$h);
        }
	$this->{Viewer} = VRML::Viewer::Examine->new;

	return $this;
}

sub update_scene {
	my($this) = @_;

	while(XPending()) {
		my @e = &glpXNextEvent();
		# print "EVENT $e[0] $e[1] $e[2] !!!\n";
		if($e[0] == &ConfigureNotify) {
			$this->resize($e[1],$e[2]);
		} 
		$this->event(@e);
	}
	$this->finish_event();

	$this->render();

}

sub set_root { $_[0]{Root} = $_[1] }
sub set_viewpoint { $_[0]{Viewpoint} = $_[1] }

sub event {
	my $w;
	my($this,$type,@args) = @_;
	my $code;
	my $but;
	# print "EVENT $this $type $args[0] $args[1] $args[2]\n";
	if($type == &MotionNotify) {
		my $but;
		# print "MOT!\n";
		if($args[0] & (&Button1Mask)) {
			$but = 1;
		} elsif ($args[0] & (&Button2Mask)) {
			$but = 2;
		} elsif ($args[0] & (&Button3Mask)) {
			$but = 3;
		}
		# print "BUT: $but\n";
		$this->{MX} = $args[1]; $this->{MY} = $args[2];
		$this->{BUT} = $but;
		$this->{SENSMOVE} = 1;
		undef $this->{EDone} if ($but > 0);
	} elsif($type == &ButtonPress) {
		# print "BP!\n";
		if($args[0] == (&Button1)) {
			$but = 1;
		} elsif($args[0] == (&Button2)) {
			$but = 2;
		} elsif ($args[0] == (&Button3)) {
			$but = 3;
		}
		$this->{MX} = $args[1]; $this->{MY} = $args[2];
		my $x = $args[1]/$this->{W}; my $y = $args[2]/$this->{H};
		if($but == 1 or $but == 3) {
			# print "BPRESS $but $x $y\n";
			$this->{Viewer}->handle("PRESS",$but,$x,$y);
		}
		$this->{BUT} = $but;
		$this->{SENSBUT} = $but;
		undef $this->{EDone};
	} elsif($type == &ButtonRelease) {
		if($args[0] == (&Button1)) {
			$but = 1;
		} elsif($args[0] == (&Button2)) {
			$but = 2;
		} elsif ($args[0] == (&Button3)) {
			$but = 3;
		}
		$this->finish_event;
		$this->{SENSBUTREL} = $but;
		undef $this->{BUT};
	} elsif($type == &KeyPress) {
		print "KEY: $args[0] $args[1] $args[2] $args[3]\n";
		if((lc $args[0]) eq "k") {
			$this->{Viewer}->handle("PRESS", 1, 0.5, 0.5);
			$this->{Viewer}->handle("DRAG", 1, 0.5, 0.4);
		} elsif((lc $args[0]) eq "j") {
			$this->{Viewer}->handle("PRESS", 1, 0.5, 0.5);
			$this->{Viewer}->handle("DRAG", 1, 0.5, 0.6);
		} elsif((lc $args[0]) eq "l") {
			$this->{Viewer}->handle("PRESS", 1, 0.5, 0.5);
			$this->{Viewer}->handle("DRAG", 1, 0.6, 0.5);
		} elsif((lc $args[0]) eq "h") {
			$this->{Viewer}->handle("PRESS", 1, 0.5, 0.5);
			$this->{Viewer}->handle("DRAG", 1, 0.4, 0.5);
		} elsif((lc $args[0]) eq "e") {
			$this->{Viewer} = VRML::Viewer::Examine->new;
		} elsif((lc $args[0]) eq "w") {
			$this->{Viewer} = VRML::Viewer::Walk->new;
		} elsif((lc $args[0]) eq "q") {
			exit
		}
	}
}
	
sub finish_event {
	my($this) = @_;
	return if $this->{EDone};
	my $x = $this->{MX} / $this->{W}; my $y = $this->{MY} / $this->{H};
	my $but = $this->{BUT};
	if($but == 1 or $but == 3) {
		$this->{Viewer}->handle("DRAG", $but, $x, $y);
		# print "FE: $but $x $y\n";
	} elsif($but == 2) {
		$this->{MCLICK} = 1;
		$this->{MCLICKO} = 1;
		$this->{MOX} = $this->{MX}; $this->{MOY} = $this->{MY}
	}
	$this->{EDone} = 1;
}

sub resize { # Called by resizehandler.
	my($t,$w,$h) = @_;
	print "RESIZE: $w $h\n";
	$t->{W} = $w;
	$t->{H} = $h;
}

sub new_node {
	my($this,$type,$fields) = @_;
	print "NEW_NODE $type\n";
	my $node = {
		Type => $type,
		CNode => VRML::CU::alloc_struct_be($type),
	}; 
	$this->set_fields($node,$fields);
	return $node;
}

sub set_fields {
	my($this,$node,$fields) = @_;
	for(keys %$fields) {
		my $value = $fields->{$_};
		# if("HASH" eq ref $value) { # Field
		# 	$value = $value->{CNode};
		# } elsif("ARRAY" eq ref $value and "HASH" eq ref $value->[0]) {
		# 	$value = [map {$_->{CNode}} @$value];
		# }
		VRML::CU::set_field_be($node->{CNode}, 
			$node->{Type}, $_, $fields->{$_});
	}
}

sub set_sensitive {
	my($this,$node,$sub) = @_;
	push @{$this->{Sens}}, [$node, $sub];
}

sub delete_node {
	my($this,$node) = @_;
	VRML::CU::free_struct_be($node->{CNode}, $node->{Type});
}

sub setup_projection {
	my($this,$pick) = @_;
		glMatrixMode(&GL_PROJECTION);
		glViewport(0,0,$this->{W},$this->{H});
		glLoadIdentity();
		if($pick) { # We are picking for mouse events ..
			my $vp = pack("i4",0,0,0,0);
			glGetIntegerv(&GL_VIEWPORT, $vp);
			# print "VPORT: ",(join ",",unpack"i*",$vp),"\n";
			# print "PM: $this->{MX} $this->{MY} 3 3\n";
			my @vp = unpack("i*",$vp);
			print "Pick",
			 (join ', ',$this->{MX}, $vp[3]-$this->{MY}, 3, 3, @vp),
			 "\n"
			  if $VRML::verbose::glsens;
			glupPickMatrix($this->{MX}, $vp[3]-$this->{MY}, 3, 3, @vp);
		}
		gluPerspective(40.0, $this->{W}/$this->{H},	
			0.1, 200000);
		glMatrixMode(&GL_MODELVIEW);
		glLoadIdentity();
		glShadeModel(GL_SMOOTH);
}

sub setup_viewpoint {
	my($this,$node) = @_;
	my $viewpoint = $this->{Viewpoint}{CNode};
		$this->{Viewer}->togl(); # Make viewpoint
	     # Store stack depth
		my $i = pack ("i",0);
		glGetIntegerv(&GL_MODELVIEW_STACK_DEPTH,$i);
		my $dep = unpack("i",$i);
	     # Go through the scene, rendering all transforms
	     # in reverse until we hit the viewpoint
	     # die "NOVP" if !$viewpoint;
	         VRML::VRMLFunc::render_hier($node,
		 		1, 1, 0, 0, 0, $viewpoint);
}

# Given root node of scene, render it all
sub render {
	my($this) = @_;
	my($node,$viewpoint) = @{$this}{Root, Viewpoint};
	glClear(&GL_COLOR_BUFFER_BIT | &GL_DEPTH_BUFFER_BIT);
	$node = $node->{CNode};
	$viewpoint = $viewpoint->{CNode};
	my $pick;
	# 1. Set up projection
		$this->setup_projection();
	# 2. Lights
	     # Headlight - make conditional
		glEnable(&GL_LIGHT0);
		my $pos = pack ("f*",0,0,1,1);
		glLightfv(&GL_LIGHT0,&GL_POSITION, $pos);
		my $s = pack ("f*", 1,1,1,1);
		glLightfv(&GL_LIGHT0,&GL_AMBIENT, $s);
		glLightfv(&GL_LIGHT0,&GL_DIFFUSE, $s);
		glLightfv(&GL_LIGHT0,&GL_SPECULAR, $s);
	     # Other lights
	     # render_hier
	# 3. Viewpoint
		$this->setup_viewpoint($node);
	# 4. Nodes
		VRML::VRMLFunc::render_hier($node,
				0, 0, 1, 0, 0, 0);
	glFlush();
	glXSwapBuffers();

	# Do selection
	if(@{$this->{Sens}}) {
		print "SENSING\n"
			if $VRML::verbose::glsens;
		for(@{$this->{Sens}}) {
			VRML::VRMLFunc::zero_hits($_->[0]{CNode});
			VRML::VRMLFunc::set_sensitive($_->[0]{CNode},1);
		}
		my $nints = 100;
		my $s = pack("i$nints");
		glRenderMode(&GL_SELECT);
		$this->setup_projection();
		glSelectBuffer($nints, $s);
		$this->setup_projection(1);
		$this->setup_viewpoint($node);
		VRML::VRMLFunc::render_hier($node,
				0, 0, 0, 0, 1, 0);
		my $b = delete $this->{SENSBUT};
		my $sb = delete $this->{SENSBUTREL};
		my $m = delete $this->{SENSMOVE};
		print "SENS_BR: $b\n" if $VRML::verbose::glsens;
		for(@{$this->{Sens}}) {
			print "SENS $_\n" if $VRML::verbose::glsens;
			if(VRML::VRMLFunc::get_hits($_->[0]{CNode})) {
				print "HIT! $_->[0]\n"
				 if $VRML::verbose::glsens;
				if($m) {
					$_->[1]->("",1);
				}
				if($b) {
					$_->[1]->("PRESS",0);
				}
				if($sb) {
					$_->[1]->("RELEASE",0);
				}
			}
		}
		glRenderMode(&GL_RENDER);
	}
}




1;
