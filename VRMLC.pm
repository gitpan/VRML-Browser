# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

# The C routines to render various nodes quickly
#
# Field values by subs so that generalization possible..
#
# getf(Node,"fieldname",[index,...]) returns c string to get field name.
# getaf(Node,"fieldname",n) returns comma-separated list of all the field values.
# getfn(Node,"fieldname"
# children("fieldname") returns code to render children in the fieldname
#
# Render modes: 
#  Render
#  VP
#  L
#  M
#
# Of these, VP is taken into account by Transform
#
# retmode returns from this call if the mode is one of the or'ed
# list of modes (VP, L, M, C): VP - render only viewpoint / child nodes,
# reverse transformations. L: render only lights. 
# C: waiting for the right child
# 
# ret_geom(code) = this renders a geometry.
#
# Why so elaborate code generation?
#  - makes it easy to change structs later
#  - makes it very easy to add fast implementations for new proto'ed 
#    node types

require 'VRMLFields.pm';
require 'VRMLNodes.pm';

# Rend = real rendering
%RendC = (
Box => (join '',
	'float x = $f(size,0)/2;
	 float y = $f(size,1)/2;
	 float z = $f(size,2)/2;
	glPushAttrib(GL_LIGHTING);
	glShadeModel(GL_FLAT);
		glBegin(GL_QUADS);
		glNormal3f(0,0,1);
		glVertex3f(x,y,z);
		glVertex3f(-x,y,z);
		glVertex3f(-x,-y,z);
		glVertex3f(x,-y,z);
		glNormal3f(0,0,-1);
		glVertex3f(x,-y,-z);
		glVertex3f(-x,-y,-z);
		glVertex3f(-x,y,-z);
		glVertex3f(x,y,-z);
		glNormal3f(0,1,0);
		glVertex3f(x,y,z);
		glVertex3f(x,y,-z);
		glVertex3f(-x,y,-z);
		glVertex3f(-x,y,z);
		glNormal3f(0,-1,0);
		glVertex3f(-x,-y,z);
		glVertex3f(-x,-y,-z);
		glVertex3f(x,-y,-z);
		glVertex3f(x,-y,z);
		glNormal3f(1,0,0);
		glVertex3f(x,y,z);
		glVertex3f(x,-y,z);
		glVertex3f(x,-y,-z);
		glVertex3f(x,y,-z);
		glNormal3f(-1,0,0);
		glVertex3f(-x,y,-z);
		glVertex3f(-x,-y,-z);
		glVertex3f(-x,-y,z);
		glVertex3f(-x,y,z);
		glEnd();
	glPopAttrib();
	',
),

Cylinder => '
		int div = 14;
		float h = $f(height)/2;
		float r = $f(radius);
		float a,a1,a2;
		int i;
		if($f(bottom)) {
			glBegin(GL_POLYGON);
			glNormal3f(0,1,0);
			for(i=0; i<div; i++) {
				a = i * 6.29 / div;
				glVertex3f(r*sin(a),-h,r*cos(a));
			}
			glEnd();
		} 
		if($f(top)) {
			glBegin(GL_POLYGON);
			glNormal3f(0,-1,0);
			for(i=div-1; i>=0; i--) {
				a = i * 6.29 / div;
				glVertex3f(r*sin(a),h,r*cos(a));
			}
			glEnd();
		}
		if($f(side)) {
				/* if(!nomode) {
				glPushAttrib(GL_LIGHTING);
				# glShadeModel(GL_SMOOTH);
				} */
			glBegin(GL_QUADS);
			for(i=0; i<div; i++) {
				a = i * 6.29 / div;
				a1 = (i+1) * 6.29 / div;
				a2 = (a+a1)/2;
				glNormal3f(sin(a),0,cos(a));
				glVertex3f(r*sin(a),-h,r*cos(a));
				glNormal3f(sin(a1),0,cos(a1));
				glVertex3f(r*sin(a1),-h,r*cos(a1));
				/* glNormal3f(sin(a1),0,cos(a1));  (same) */
				glVertex3f(r*sin(a1),h,r*cos(a1));
				glNormal3f(sin(a),0,cos(a));
				glVertex3f(r*sin(a),h,r*cos(a));
			}
			glEnd();
				/*
				if(!nomode) {
				glPopAttrib();
				}
				*/
		}
',

Cone => '
		int div = 14;
		float h = $f(height)/2;
		float r = $f(bottomRadius); 
		float a,a1,a2;
		int i;
		if(h <= 0 && r <= 0) {return;}
		/* XXX
		glPushAttrib(GL_LIGHTING);
		glShadeModel(GL_FLAT);
		*/
		if($f(bottom)) {
			glBegin(GL_POLYGON);
			glNormal3f(0,-1,0);
			for(i=div-1; i>=0; i--) {
				a = i * 6.29 / div;
				glVertex3f(r*sin(a),-h,r*cos(a));
			}
			glEnd();
		}
		/*
		glShadeModel(GL_SMOOTH);
		*/
		if($f(side)) {
			double ml = sqrt(h*h + r * r);
			double mlh = h / ml;
			double mlr = r / ml;
				/* if(!nomode) {
				glPushAttrib(GL_LIGHTING);
				# glShadeModel(GL_SMOOTH);
				} */
			for(i=0; i<div; i++) {
				a = i * 6.29 / div;
				a1 = (i+1) * 6.29 / div;
				a2 = (a+a1)/2;
				glBegin(GL_POLYGON);
				glNormal3f(mlh*sin(a),mlr,mlh*cos(a));
				glVertex3f(0,h,0);
				glVertex3f(r*sin(a),-h,r*cos(a));
				glNormal3f(mlh*sin(a1),mlr,mlh*cos(a1));
				glVertex3f(r*sin(a1),-h,r*cos(a1));
				glVertex3f(0,h,0);
				glEnd();
				#ifdef FOOBAR
				glBegin(GL_POLYGON);
				glNormal3f(mlh*sin(a),mlr,mlh*cos(a));
				glVertex3f(0,h,0);
				glVertex3f(0.5*r*sin(a),0,0.5*r*cos(a));
				glNormal3f(mlh*sin(a1),mlr,mlh*cos(a1));
				glVertex3f(0.5*r*sin(a1),0,0.5*r*cos(a1));
				glVertex3f(0,h,0);
				glEnd();
				glBegin(GL_POLYGON);
				glNormal3f(mlh*sin(a),mlr,mlh*cos(a));
				glVertex3f(0.5*r*sin(a),0,0.5*r*cos(a));
				glVertex3f(r*sin(a),-h,r*cos(a));
				glNormal3f(mlh*sin(a1),mlr,mlh*cos(a1));
				glVertex3f(r*sin(a1),-h,r*cos(a1));
				glVertex3f(0.5*r*sin(a1),0,0.5*r*cos(a1));
				glEnd();
				#endif
			}
				/*
				if(!nomode) {
				glPopAttrib();
				}
				*/
		}
		/*
		glPopAttrib();
		*/
		
',

Sphere => 'int vdiv = 5;
		int hdiv = 9;
		int v; int h;
		float va1,va2,van,ha1,ha2,han;
		glPushMatrix();
			/* if(!nomode) {
				glPushAttrib(&GL_LIGHTING);
				# glShadeModel(&GL_SMOOTH);
			} */
		glScalef($f(radius), $f(radius), $f(radius));
		glBegin(GL_QUADS);
		for(v=0; v<vdiv; v++) {
			va1 = v * 3.15 / vdiv;
			va2 = (v+1) * 3.15 / vdiv;
			van = (v+0.5) * 3.15 / vdiv;
			for(h=0; h<hdiv; h++) {
				ha1 = h * 6.29 / hdiv;
				ha2 = (h+1) * 6.29 / hdiv;
				han = (h+0.5) * 6.29 / hdiv;
				/* glNormal3f(sin(van) * cos(han), sin(van) * sin(han), cos(van)); */
				glNormal3f(sin(va2) * cos(ha1), sin(va2) * sin(ha1), cos(va2));
				glVertex3f(sin(va2) * cos(ha1), sin(va2) * sin(ha1), cos(va2));
				glNormal3f(sin(va2) * cos(ha2), sin(va2) * sin(ha2), cos(va2));
				glVertex3f(sin(va2) * cos(ha2), sin(va2) * sin(ha2), cos(va2));
				glNormal3f(sin(va1) * cos(ha2), sin(va1) * sin(ha2), cos(va1));
				glVertex3f(sin(va1) * cos(ha2), sin(va1) * sin(ha2), cos(va1));
				glNormal3f(sin(va1) * cos(ha1), sin(va1) * sin(ha1), cos(va1));
				glVertex3f(sin(va1) * cos(ha1), sin(va1) * sin(ha1), cos(va1));
			}
		}
		glEnd();
		glPopMatrix();
					/* if(!$nomode) {
						glPopAttrib();
					} */
',

IndexedFaceSet =>  ( join '',
		"/* # Normal / face always  */
		int i;
		int ind;
		int ind2;
		int ind3;
		int cin = ".getfn(IndexedFaceSet, coordIndex).";
		int npoints;
		struct SFColor *c1,*c2,*c3;
		float a[3]; float b[3];
		struct SFColor *points;
		",fvirt("IndexedFaceSet", "coord", "points", "get3", "&npoints"),';
		for (i=0; i < cin; i++) {
			ind = $f(coordIndex,i);
			if(ind == -1) {
				continue;
			} else {
				ind2 = $f(coordIndex,i+1);
				if(ind2 == -1) continue;
				ind3 = $f(coordIndex,i+2);
				if(ind3 == -1) continue;
				c1 = &(points[ind]);
				c2 = &(points[ind2]); /* XXX Potential dump */
				c3 = &(points[ind3]);
				a[0] = c2->c[0] - c1->c[0];
				a[1] = c2->c[1] - c1->c[1];
				a[2] = c2->c[2] - c1->c[2];
				b[0] = c3->c[0] - c1->c[0];
				b[1] = c3->c[1] - c1->c[1];
				b[2] = c3->c[2] - c1->c[2];
			        glNormal3f(
					a[1]*b[2] - b[1]*a[2],
					-(a[0]*b[2] - b[0]*a[2]),
					a[0]*b[1] - b[0]*a[1]
				);
				glBegin(GL_POLYGON);
				while(i < cin &&
					(ind2 = $f(coordIndex,i)) >=0) {
					c1 = &(points[ind2]);
					glVertex3f(c1->c[0],c1->c[1],c1->c[2]);
					i++;
				}
				glEnd();
			}
		}
		glEnd();
		
'),

ElevationGrid => ( '
		int x,z;
		int nx = $f(xDimension);
		int nz = $f(zDimension);
		float *f = $f(height);
		glBegin(GL_QUADS);
		for(x=0; x<nx-1; x++) {
		 for(z=0; z<nz-1; z++) {
		   die("Sorry, elevationgrids not finished");
		 }
		}
'),

# How to disable material when doing just select-rendering?
# XXX Optimize..
Material => ( join '',
	"	float m[4]; int i;
		",assgn_m(diffuseColor,1),";
		glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, m);
		for(i=0; i<3; i++) {
			m[i] *= ", getf(Material, ambientIntensity),";
		}
		glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, m);
		",assgn_m(specularColor,1),";
		glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, m);

		",assgn_m(emissiveColor,1),";
		glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, m);

		glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, 
			1.0/((",getf(Material,shininess),"+1)/128.0));
		
		
"),

);

# Prep = prepare for rendering children - if searching for nodes,
# unnecessary
%PrepC = (
Transform => (join '','
	glPushMatrix();
	if(!reverse_trans) {
		glTranslatef(',(join ',',map {getf(Transform,translation,$_)} 0..2),'
		);
		glRotatef(',getf(Transform,rotation,3),'/3.1415926536*180,',
			(join ',',map {getf(Transform,rotation,$_)} 0..2),'
		);
		glScalef(',(join ',',map {getf(Transform,scale,$_)} 0..2),'
		);
	} else {
		glScalef(',(join ',',map {"1.0/(".getf(Transform,scale,$_).")"} 0..2),'
		);
		glRotatef(-(',getf(Transform,rotation,3),')/3.1415926536*180,',
			(join ',',map {getf(Transform,rotation,$_)} 0..2),'
		);
		glTranslatef(',(join ',',map {"-(".getf(Transform,translation,$_).")"} 
			0..2),'
		);
	}
'),

Viewpoint => (join '','
	if(render_vp) {
		if(verbose) printf("RENDVIEWP: %d %d\n",this_,what_vp); 
		if(this_ == what_vp) {
		render_anything = 0; /* Stop rendering any more */
		glTranslatef(',(join ',',map {"-(".getf(Viewpoint,position,$_).")"} 
			0..2),'
		);
		glRotatef(-(',getf(Viewpoint,orientation,3),')/3.1415926536*180,',
			(join ',',map {getf(Viewpoint,orientation,$_)} 0..2),'
		);
	/*
#		glMatrixMode(&GL_PROJECTION);
#		glLoadIdentity();
#		gluPerspective($f->{fieldOfView}/3.1415926536*180,1,0.1,10000);
#		glMatrixMode(&GL_MODELVIEW);
	 */
	 	}
	}
'),

);

# Finish rendering
%FinC = (
Transform => (join '','
	glPopMatrix();
'),
);

# Render children (real child nodes, not e.g. appearance/geometry)
%ChildC = (
	Group => '
		int nc = $f_n(children); 
		int i;
		for(i=0; i<nc; i++) {
			void *p = $f(children,i);
			render_node(p);
		}
	',
	Appearance => '
		render_node($f(material));
	',
	Shape => '
		if(!$f(appearance) || !$f(geometry)) {
			return;
		}
		glPushAttrib(GL_LIGHTING_BIT);
		glLightModeli(GL_LIGHT_MODEL_TWO_SIDE,GL_TRUE);
		render_node($f(appearance));
		render_node($f(geometry));
		glPopAttrib();
	',
);

$ChildC{Transform} = $ChildC{Group};

%Get3C = (
Coordinate => "
	*n = ".getfn("Coordinate","point").";
	return ".getf("Coordinate","point").";
"
);

{
	my %AllNodes = (%RendC, %PrepC, %FinC, %ChildC, %Get3C);
	@NodeTypes = keys %AllNodes;
}

sub assgn_m {
	my($f, $l) = @_;
	return ((join '',map {"m[$_] = ".getf(Material, $f, $_).";"} 0..2).
		"m[3] = $l;");
}

# XXX Might we need separate fields for separate structs?
sub getf {
	my ($t, $f, @l) = @_;
	my $type = $VRML::Nodes{$t}{FieldTypes}{$f};
	return "VRML::Field::$type"->cget("(this_->$f)",@l);
}

sub getfn {
	my($t, $f) = @_;
	my $type = $VRML::Nodes{$t}{FieldTypes}{$f};
	return "VRML::Field::$type"->cgetn("(this_->$f)");
}

sub fvirt {
	my($t, $f, $ret, $v, @a) = @_;
	# Die if not exists
	my $type = $VRML::Nodes{$t}{FieldTypes}{$f};
	if($type ne "SFNode") {
		die("Fvirt must have SFNode");
	}
	if($ret) {$ret = "$ret = ";}
	return "if(this_->$f) {
		  if(!(*(struct VRML_Virt **)(this_->$f))->$v) {
		  	die(\"NULL METHOD $t $f $v\");
		  }
		  $ret ((*(struct VRML_Virt **)(this_->$f))->$v(this_->$f,
		    ".(join ',',@a).")) ;}
 	  else { (die(\"NULL FIELD $t $f $a\"));}";
}

sub fvirt_n {
	my($n, $ret, $v, @a) = @_;
	if($ret) {$ret = "$ret = ";}
	return "if($n) {
	         if(!(*(struct VRML_Virt **)n)->$v) {
		  	die(\"NULL METHOD $n $ret $v\");
		 }
		 $ret ((*(struct VRML_Virt **)($n))->$v($n,
		    ".(join ',',@a).")) ;}
	"
}

sub rend_geom {
	return $_[0];
}

sub gen_struct {
	my($name,$node) = @_;
	my @f = keys %{$node->{FieldTypes}};
	my $nf = scalar @f;
	# /* Store actual point etc. later */
	my $s = "struct VRML_$name {struct VRML_Virt *v;int _sens;int _hit; \n";
	my $o = "
void *
get_${name}_offsets(p)
	SV *p;
CODE:
	int *ptr_;
	SvGROW(p,($nf+1)*sizeof(int));
	SvCUR_set(p,($nf+1)*sizeof(int));
	ptr_ = (int *)SvPV(p,na);
";
	my $p = " {
		my \$s = '';
		my \$v = get_${name}_offsets(\$s);
		\@{\$n->{$name}{Offs}}{".(join ',',map {"\"$_\""} @f,'_end_')."} =
			unpack(\"i*\",\$s);
		\$n->{$name}{Virt} = \$v;
 }
	";
	for(@f) {
		my $cty = "VRML::Field::$node->{FieldTypes}{$_}"->ctype($_);
		$s .= "\t$cty;\n";
		$o .= "\t*ptr_++ = offsetof(struct VRML_$name, $_);\n";
	}
	$o .= "\t*ptr_++ = sizeof(struct VRML_$name);\n";
	$o .= "RETVAL=&(virt_${name});
	printf(\"$name virtual: %d\\n\", RETVAL);
OUTPUT:
	RETVAL
";
	$s .= "};\n";
	return ($s,$o,$p);
}

sub get_offsf {
	my($f) = @_;
	my ($ct) = ("VRML::Field::$_")->ctype("*ptr_");
	my ($ctp) = ("VRML::Field::$_")->ctype("*");
	my ($c) = ("VRML::Field::$_")->cfunc("(*ptr_)", "sv_");
	my ($ca) = ("VRML::Field::$_")->calloc("(*ptr_)");
	my ($cf) = ("VRML::Field::$_")->cfree("(*ptr_)");
	return "

void 
set_offs_$f(ptr,offs,sv_)
	void *ptr
	int offs
	SV *sv_
CODE:
	$ct = ($ctp)(((char *)ptr)+offs);
	$c


void 
alloc_offs_$f(ptr,offs)
	void *ptr
	int offs
CODE:
	$ct = ($ctp)(((char *)ptr)+offs);
	$ca

void
free_offs_$f(ptr,offs)
	void *ptr
	int offs
CODE:
	$ct = ($ctp)(((char *)ptr)+offs);
	$cf

"
}

sub get_rendfunc {
	my($n) = @_;
	print "RENDF $n\n";
	# XXX
	my @f = qw/Prep Rend Child Fin Get3/;
	my $f;
	my $v = "
static struct VRML_Virt virt_${n} = { \"$n\", ".
	(join ',',map {${$_."C"}{$n} ? "${n}_$_" : "NULL"} @f).
"};";
	for(@f) {
		my $c =${$_."C"}{$n};
		next if !defined $c;
		# Substitute field gets
		$c =~ s/\$f\(([^)]*)\)/getf($n,split ',',$1)/ge;
		$c =~ s/\$f_n\(([^)]*)\)/getfn($n,split ',',$1)/ge;
		if($_ eq "Get3") {
			$f .= "struct SFColor *${n}_$_(void *nod_,int *n)";
		} else {
			$f .= "void ${n}_$_(void *nod_)";
		}
		$f .= "{
			struct VRML_$n *this_ = (struct VRML_$n *)nod_;
			{$c}}";
	}
	return ($f,$v);
}

sub gen {
	for(@VRML::Fields) {
		push @str, ("VRML::Field::$_")->cstruct;
		push @xsfn, get_offsf($_);
	}
	for(@NodeTypes) {
		my $no = $VRML::Nodes{$_}; 
		my($str, $offs, $perl) = gen_struct($_, $no);
		push @str, $str;
		push @xsfn, $offs;
		push @poffsfn, $perl;
		my($f, $vstru) = get_rendfunc($_);
		push @func, $f;
		push @vstruc, $vstru;
	}
	open XS, ">VRMLFunc.xs";
	print XS '
/* VRMLFunc.c generated by VRMLC.pm. DO NOT MODIFY, MODIFY VRMLC.pm INSTEAD */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glx.h>

#include "OpenGL/OpenGL.m"

#define offset_of(p_type,field) ((unsigned int)(&(((p_type)NULL)->field)-NULL))

D_OPENGL;

struct VRML_Virt {
	char *name;
	void (*prep)(void *);
	void (*rend)(void *); 
	void (*children)(void *);
	void (*fin)(void *);
	/* And get float coordinates : Coordinate, Color */
	/* XXX Relies on MFColor repr.. */
	struct SFColor *(*get3)(void *, int *); /* Number in int */
};
';
	print XS join '',@str;
	print XS '

int verbose;

int reverse_trans;
int render_vp; 
int render_geom;
int render_light;
int render_sensitive;

int cur_hits=0;

void *what_vp;
int render_anything; /* Turned off when we hit the viewpoint */
void render_node(void *node) {
	struct VRML_Virt *v;
	struct VRML_Box *p;
	int srg;
	int sch;
	if(verbose) printf("Render_node %d\n",node);
	if(!node) {return;}
	v = *(struct VRML_Virt **)node;
	p = node;
	if(verbose) printf("Render_node_v %d\n",v);
	if(verbose) printf("Render_node_v_d \"%s\"\n",v->name);
	if(verbose) printf("Render_node_v_prep %d\n",v->prep);
	if(verbose) printf("Render_node_v_rend %d\n",v->rend);
	if(verbose) printf("Render_node_v_children %d\n",v->children);
	if(verbose) printf("Render_node_v_fin %d\n",v->fin);
	if(render_anything && v->prep) {v->prep(node);}
	if(render_anything && render_geom && v->rend) {v->rend(node);}
	/* Future optimization: when doing VP/Lights, do only 
	 * that child... further in future: could just calculate
	 * transforms myself..
	 */
	if(render_anything &&
	   render_sensitive &&
	   p->_sens) {
	   	srg = render_geom;
		render_geom = 1;
		cur_hits += glRenderMode(GL_SELECT);
		if(verbose) printf("CH1 %d: %d\n",node, cur_hits, p->_hit);
		glInitNames();
		glPushName(1);
		sch = cur_hits;
		cur_hits = 0;
	}
	if(render_anything && v->children) {v->children(node);}
	if(render_anything &&
	   render_sensitive &&
	   p->_sens) {
	   	cur_hits += glRenderMode(GL_SELECT);
		if(verbose) printf("CH2 %d: %d\n",node, cur_hits);
		glInitNames();
		glPushName(1);
		p->_hit += cur_hits;
		render_geom = srg;
		cur_hits = sch;
		if(verbose) printf("CH3: %d %d\n",cur_hits, p->_hit);
	}
	if(render_anything && v->fin) {v->fin(node);}
}

	';
	print XS join '',@func;
	print XS join '',@vstruc;
	print XS <<'ENDHERE'

MODULE = VRML::VRMLFunc PACKAGE = VRML::VRMLFunc

void *
alloc_struct(siz,virt)
	int siz
	void *virt
CODE:
	void *ptr = malloc(siz);
	struct VRML_Box *p = ptr;
	printf("Alloc: %d %d -> %d\n", siz, virt, ptr);
	*(struct VRML_Virt **)ptr = (struct VRML_Virt *)virt;
	p->_sens = p->_hit = 0;
	RETVAL=ptr;
OUTPUT:
	RETVAL

void
release_struct(ptr)
	void *ptr
CODE:
	free(ptr); /* COULD BE MEMLEAK IF STUFF LEFT INSIDE */

void
set_sensitive(ptr,sens)
	void *ptr
	int sens
CODE:
	/* Choose box randomly */
	struct VRML_Box *p = ptr;
	p->_sens = sens;

int
get_hits(ptr)
	void *ptr
CODE:
	struct VRML_Box *p = ptr;
	RETVAL = p->_hit;
	p->_hit = 0;
OUTPUT:
	RETVAL

void
zero_hits(ptr)
	void *ptr
CODE:
	struct VRML_Box *p = ptr;
	p->_hit = 0;

void 
render_verbose(i)
	int i;
CODE:
	verbose=i;

void
render_geom(p)
	void *p
CODE:
	struct VRML_Virt *v;
	if(!p) {
		die("Render_geom null!??");
	}
	v = *(struct VRML_Virt **)p;
	v->rend(p);

void 
render_hier(p,revt,rvp,rgeom,rlight,rsens,wvp)
	void *p
	int revt
	int rvp
	int rgeom
	int rlight
	int rsens
	void *wvp
CODE:
	reverse_trans = revt;
	render_vp = rvp;
	render_geom =  rgeom;
	render_light = rlight;
	render_sensitive = rsens;
	what_vp = wvp;
	render_anything = 1;
	if(!p) {
		die("Render_hier null!??");
	}
	if(verbose) printf("Render_hier %d %d %d %d %d %d\n", p, revt, rvp, rgeom, rlight, wvp);
	render_node(p);

ENDHERE
;
	print XS join '',@xsfn;
	print XS '

BOOT:
	I_OPENGL;

';

	open PM, ">VRMLFunc.pm";
	print PM "
# VRMLFunc.pm, generated by VRMLC.pm. DO NOT MODIFY, MODIFY VRMLC.pm INSTEAD
package VRML::VRMLFunc;
require DynaLoader;
\@ISA=DynaLoader;
bootstrap VRML::VRMLFunc;
sub load_data {
	my \$n = \\\%VRML::CNodes;
";
	print PM join '',@poffsfn;
	print PM "
}
";
}


gen();


