
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
struct Multi_Float { int n; float  *p; };struct SFRotation {
 	float r[4]; };struct Multi_Vec3f { int n; struct SFColor  *p; };struct Multi_Int32 { int n; int  *p; };struct Multi_Node { int n; void * *p; };struct SFColor {
	float c[3]; };struct Multi_Color { int n; struct SFColor  *p; };struct VRML_Appearance {struct VRML_Virt *v;int _sens;int _hit; 
	void *texture;
	void *texturetransform;
	void *material;
};
struct VRML_Shape {struct VRML_Virt *v;int _sens;int _hit; 
	void *appearance;
	void *geometry;
};
struct VRML_Viewpoint {struct VRML_Virt *v;int _sens;int _hit; 
	float fieldOfView;
	SV *description;
	int isBound;
	struct SFColor position;
	int set_bind;
	float bindTime;
	int jump;
	struct SFRotation orientation;
};
struct VRML_Cone {struct VRML_Virt *v;int _sens;int _hit; 
	float height;
	float bottomRadius;
	int side;
	int bottom;
};
struct VRML_Sphere {struct VRML_Virt *v;int _sens;int _hit; 
	float radius;
};
struct VRML_Coordinate {struct VRML_Virt *v;int _sens;int _hit; 
	struct Multi_Vec3f point;
};
struct VRML_Box {struct VRML_Virt *v;int _sens;int _hit; 
	struct SFColor size;
};
struct VRML_Cylinder {struct VRML_Virt *v;int _sens;int _hit; 
	float radius;
	float height;
	int top;
	int side;
	int bottom;
};
struct VRML_IndexedFaceSet {struct VRML_Virt *v;int _sens;int _hit; 
	float creaseAngle;
	int solid;
	void *coord;
	struct Multi_Int32 coordIndex;
};
struct VRML_Transform {struct VRML_Virt *v;int _sens;int _hit; 
	struct SFRotation rotation;
	struct SFColor scale;
	struct Multi_Node children;
	struct SFColor translation;
};
struct VRML_Group {struct VRML_Virt *v;int _sens;int _hit; 
	struct Multi_Node children;
	struct SFColor bboxCenter;
	struct SFColor bboxSize;
};
struct VRML_ElevationGrid {struct VRML_Virt *v;int _sens;int _hit; 
	int zDimension;
	struct Multi_Float height;
	int xDimension;
};
struct VRML_Material {struct VRML_Virt *v;int _sens;int _hit; 
	float transparency;
	struct SFColor emissiveColor;
	float shininess;
	struct SFColor diffuseColor;
	struct SFColor specularColor;
	float ambientIntensity;
};


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

	void Appearance_Child(void *nod_){
			struct VRML_Appearance *this_ = (struct VRML_Appearance *)nod_;
			{
		render_node((this_->material));
	}}void Shape_Child(void *nod_){
			struct VRML_Shape *this_ = (struct VRML_Shape *)nod_;
			{
		if(!(this_->appearance) || !(this_->geometry)) {
			return;
		}
		glPushAttrib(GL_LIGHTING_BIT);
		glLightModeli(GL_LIGHT_MODEL_TWO_SIDE,GL_TRUE);
		render_node((this_->appearance));
		render_node((this_->geometry));
		glPopAttrib();
	}}void Viewpoint_Prep(void *nod_){
			struct VRML_Viewpoint *this_ = (struct VRML_Viewpoint *)nod_;
			{
	if(render_vp) {
		if(verbose) printf("RENDVIEWP: %d %d\n",this_,what_vp); 
		if(this_ == what_vp) {
		render_anything = 0; /* Stop rendering any more */
		glTranslatef(-(((this_->position).c[0])),-(((this_->position).c[1])),-(((this_->position).c[2]))
		);
		glRotatef(-(((this_->orientation).r[3]))/3.1415926536*180,((this_->orientation).r[0]),((this_->orientation).r[1]),((this_->orientation).r[2])
		);
	/*
#		glMatrixMode(&GL_PROJECTION);
#		glLoadIdentity();
#		gluPerspective($f->{fieldOfView}/3.1415926536*180,1,0.1,10000);
#		glMatrixMode(&GL_MODELVIEW);
	 */
	 	}
	}
}}void Cone_Rend(void *nod_){
			struct VRML_Cone *this_ = (struct VRML_Cone *)nod_;
			{
		int div = 14;
		float h = (this_->height)/2;
		float r = (this_->bottomRadius); 
		float a,a1,a2;
		int i;
		if(h <= 0 && r <= 0) {return;}
		/* XXX
		glPushAttrib(GL_LIGHTING);
		glShadeModel(GL_FLAT);
		*/
		if(((this_->bottom))) {
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
		if(((this_->side))) {
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
		
}}void Sphere_Rend(void *nod_){
			struct VRML_Sphere *this_ = (struct VRML_Sphere *)nod_;
			{int vdiv = 5;
		int hdiv = 9;
		int v; int h;
		float va1,va2,van,ha1,ha2,han;
		glPushMatrix();
			/* if(!nomode) {
				glPushAttrib(&GL_LIGHTING);
				# glShadeModel(&GL_SMOOTH);
			} */
		glScalef((this_->radius), (this_->radius), (this_->radius));
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
}}struct SFColor *Coordinate_Get3(void *nod_,int *n){
			struct VRML_Coordinate *this_ = (struct VRML_Coordinate *)nod_;
			{
	*n = ((this_->point).n);
	return ((this_->point).p);
}}void Box_Rend(void *nod_){
			struct VRML_Box *this_ = (struct VRML_Box *)nod_;
			{float x = ((this_->size).c[0])/2;
	 float y = ((this_->size).c[1])/2;
	 float z = ((this_->size).c[2])/2;
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
	}}void Cylinder_Rend(void *nod_){
			struct VRML_Cylinder *this_ = (struct VRML_Cylinder *)nod_;
			{
		int div = 14;
		float h = (this_->height)/2;
		float r = (this_->radius);
		float a,a1,a2;
		int i;
		if(((this_->bottom))) {
			glBegin(GL_POLYGON);
			glNormal3f(0,1,0);
			for(i=0; i<div; i++) {
				a = i * 6.29 / div;
				glVertex3f(r*sin(a),-h,r*cos(a));
			}
			glEnd();
		} 
		if(((this_->top))) {
			glBegin(GL_POLYGON);
			glNormal3f(0,-1,0);
			for(i=div-1; i>=0; i--) {
				a = i * 6.29 / div;
				glVertex3f(r*sin(a),h,r*cos(a));
			}
			glEnd();
		}
		if(((this_->side))) {
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
}}void IndexedFaceSet_Rend(void *nod_){
			struct VRML_IndexedFaceSet *this_ = (struct VRML_IndexedFaceSet *)nod_;
			{/* # Normal / face always  */
		int i;
		int ind;
		int ind2;
		int ind3;
		int cin = ((this_->coordIndex).n);
		int npoints;
		struct SFColor *c1,*c2,*c3;
		float a[3]; float b[3];
		struct SFColor *points;
		if(this_->coord) {
		  if(!(*(struct VRML_Virt **)(this_->coord))->get3) {
		  	die("NULL METHOD IndexedFaceSet coord get3");
		  }
		  points =  ((*(struct VRML_Virt **)(this_->coord))->get3(this_->coord,
		    &npoints)) ;}
 	  else { (die("NULL FIELD IndexedFaceSet coord "));};
		for (i=0; i < cin; i++) {
			ind = ((this_->coordIndex).p[i]);
			if(ind == -1) {
				continue;
			} else {
				ind2 = ((this_->coordIndex).p[i+1]);
				if(ind2 == -1) continue;
				ind3 = ((this_->coordIndex).p[i+2]);
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
					(ind2 = ((this_->coordIndex).p[i])) >=0) {
					c1 = &(points[ind2]);
					glVertex3f(c1->c[0],c1->c[1],c1->c[2]);
					i++;
				}
				glEnd();
			}
		}
		glEnd();
		
}}void Transform_Prep(void *nod_){
			struct VRML_Transform *this_ = (struct VRML_Transform *)nod_;
			{
	glPushMatrix();
	if(!reverse_trans) {
		glTranslatef(((this_->translation).c[0]),((this_->translation).c[1]),((this_->translation).c[2])
		);
		glRotatef(((this_->rotation).r[3])/3.1415926536*180,((this_->rotation).r[0]),((this_->rotation).r[1]),((this_->rotation).r[2])
		);
		glScalef(((this_->scale).c[0]),((this_->scale).c[1]),((this_->scale).c[2])
		);
	} else {
		glScalef(1.0/(((this_->scale).c[0])),1.0/(((this_->scale).c[1])),1.0/(((this_->scale).c[2]))
		);
		glRotatef(-(((this_->rotation).r[3]))/3.1415926536*180,((this_->rotation).r[0]),((this_->rotation).r[1]),((this_->rotation).r[2])
		);
		glTranslatef(-(((this_->translation).c[0])),-(((this_->translation).c[1])),-(((this_->translation).c[2]))
		);
	}
}}void Transform_Child(void *nod_){
			struct VRML_Transform *this_ = (struct VRML_Transform *)nod_;
			{
		int nc = ((this_->children).n); 
		int i;
		for(i=0; i<nc; i++) {
			void *p = ((this_->children).p[i]);
			render_node(p);
		}
	}}void Transform_Fin(void *nod_){
			struct VRML_Transform *this_ = (struct VRML_Transform *)nod_;
			{
	glPopMatrix();
}}void Group_Child(void *nod_){
			struct VRML_Group *this_ = (struct VRML_Group *)nod_;
			{
		int nc = ((this_->children).n); 
		int i;
		for(i=0; i<nc; i++) {
			void *p = ((this_->children).p[i]);
			render_node(p);
		}
	}}void ElevationGrid_Rend(void *nod_){
			struct VRML_ElevationGrid *this_ = (struct VRML_ElevationGrid *)nod_;
			{
		int x,z;
		int nx = (this_->xDimension);
		int nz = (this_->zDimension);
		float *f = ((this_->height).p);
		glBegin(GL_QUADS);
		for(x=0; x<nx-1; x++) {
		 for(z=0; z<nz-1; z++) {
		   die("Sorry, elevationgrids not finished");
		 }
		}
}}void Material_Rend(void *nod_){
			struct VRML_Material *this_ = (struct VRML_Material *)nod_;
			{	float m[4]; int i;
		m[0] = ((this_->diffuseColor).c[0]);m[1] = ((this_->diffuseColor).c[1]);m[2] = ((this_->diffuseColor).c[2]);m[3] = 1;;
		glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, m);
		for(i=0; i<3; i++) {
			m[i] *= (this_->ambientIntensity);
		}
		glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, m);
		m[0] = ((this_->specularColor).c[0]);m[1] = ((this_->specularColor).c[1]);m[2] = ((this_->specularColor).c[2]);m[3] = 1;;
		glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, m);

		m[0] = ((this_->emissiveColor).c[0]);m[1] = ((this_->emissiveColor).c[1]);m[2] = ((this_->emissiveColor).c[2]);m[3] = 1;;
		glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, m);

		glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, 
			1.0/(((this_->shininess)+1)/128.0));
		
		
}}
static struct VRML_Virt virt_Appearance = { "Appearance", NULL,NULL,Appearance_Child,NULL,NULL};
static struct VRML_Virt virt_Shape = { "Shape", NULL,NULL,Shape_Child,NULL,NULL};
static struct VRML_Virt virt_Viewpoint = { "Viewpoint", Viewpoint_Prep,NULL,NULL,NULL,NULL};
static struct VRML_Virt virt_Cone = { "Cone", NULL,Cone_Rend,NULL,NULL,NULL};
static struct VRML_Virt virt_Sphere = { "Sphere", NULL,Sphere_Rend,NULL,NULL,NULL};
static struct VRML_Virt virt_Coordinate = { "Coordinate", NULL,NULL,NULL,NULL,Coordinate_Get3};
static struct VRML_Virt virt_Box = { "Box", NULL,Box_Rend,NULL,NULL,NULL};
static struct VRML_Virt virt_Cylinder = { "Cylinder", NULL,Cylinder_Rend,NULL,NULL,NULL};
static struct VRML_Virt virt_IndexedFaceSet = { "IndexedFaceSet", NULL,IndexedFaceSet_Rend,NULL,NULL,NULL};
static struct VRML_Virt virt_Transform = { "Transform", Transform_Prep,NULL,Transform_Child,Transform_Fin,NULL};
static struct VRML_Virt virt_Group = { "Group", NULL,NULL,Group_Child,NULL,NULL};
static struct VRML_Virt virt_ElevationGrid = { "ElevationGrid", NULL,ElevationGrid_Rend,NULL,NULL,NULL};
static struct VRML_Virt virt_Material = { "Material", NULL,Material_Rend,NULL,NULL,NULL};
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



void 
set_offs_SFFloat(ptr,offs,sv_)
	void *ptr
	int offs
	SV *sv_
CODE:
	float *ptr_ = (float *)(((char *)ptr)+offs);
	(*ptr_) = SvNV(sv_);



void 
alloc_offs_SFFloat(ptr,offs)
	void *ptr
	int offs
CODE:
	float *ptr_ = (float *)(((char *)ptr)+offs);
	

void
free_offs_SFFloat(ptr,offs)
	void *ptr
	int offs
CODE:
	float *ptr_ = (float *)(((char *)ptr)+offs);
	



void 
set_offs_MFFloat(ptr,offs,sv_)
	void *ptr
	int offs
	SV *sv_
CODE:
	struct Multi_Float *ptr_ = (struct Multi_Float *)(((char *)ptr)+offs);
	{
		AV *aM;
		SV **bM;
		int iM;
		int lM;
		if(!SvROK(sv_)) {
			die("Help! Multi without being ref");
		}
		if(SvTYPE(SvRV(sv_)) != SVt_PVAV) {
			die("Help! Multi without being arrayref");
		}
		aM = (AV *) SvRV(sv_);
		lM = av_len(aM)+1;
		/* XXX Free previous p */
		(*ptr_).n = lM;
		(*ptr_).p = malloc(lM * sizeof(*((*ptr_).p)));
		/* XXX ALLOC */
		for(iM=0; iM<lM; iM++) {
			bM = av_fetch(aM, iM, 1); /* LVal for easiness */
			if(!bM) {
				die("Help: Multi VRML::Field::SFFloat bM == 0");
			}
			((*ptr_).p[iM]) = SvNV((*bM));

		}
	}
	


void 
alloc_offs_MFFloat(ptr,offs)
	void *ptr
	int offs
CODE:
	struct Multi_Float *ptr_ = (struct Multi_Float *)(((char *)ptr)+offs);
	(*ptr_).n = 0; (*ptr_).p = 0;

void
free_offs_MFFloat(ptr,offs)
	void *ptr
	int offs
CODE:
	struct Multi_Float *ptr_ = (struct Multi_Float *)(((char *)ptr)+offs);
	if((*ptr_).p) {free((*ptr_).p);(*ptr_).p=0;} (*ptr_).n = 0;



void 
set_offs_SFRotation(ptr,offs,sv_)
	void *ptr
	int offs
	SV *sv_
CODE:
	struct SFRotation *ptr_ = (struct SFRotation *)(((char *)ptr)+offs);
	{
		AV *a;
		SV **b;
		int i;
		if(!SvROK(sv_)) {
			die("Help! SFRotation without being ref");
		}
		if(SvTYPE(SvRV(sv_)) != SVt_PVAV) {
			die("Help! SFRotation without being arrayref");
		}
		a = (AV *) SvRV(sv_);
		for(i=0; i<4; i++) {
			b = av_fetch(a, i, 1); /* LVal for easiness */
			if(!b) {
				die("Help: SFColor b == 0");
			}
			(*ptr_).r[i] = SvNV(*b);
		}
	}
	


void 
alloc_offs_SFRotation(ptr,offs)
	void *ptr
	int offs
CODE:
	struct SFRotation *ptr_ = (struct SFRotation *)(((char *)ptr)+offs);
	

void
free_offs_SFRotation(ptr,offs)
	void *ptr
	int offs
CODE:
	struct SFRotation *ptr_ = (struct SFRotation *)(((char *)ptr)+offs);
	



void 
set_offs_SFVec3f(ptr,offs,sv_)
	void *ptr
	int offs
	SV *sv_
CODE:
	struct SFColor *ptr_ = (struct SFColor *)(((char *)ptr)+offs);
	{
		AV *a;
		SV **b;
		int i;
		if(!SvROK(sv_)) {
			die("Help! SFColor without being ref");
		}
		if(SvTYPE(SvRV(sv_)) != SVt_PVAV) {
			die("Help! SFColor without being arrayref");
		}
		a = (AV *) SvRV(sv_);
		for(i=0; i<3; i++) {
			b = av_fetch(a, i, 1); /* LVal for easiness */
			if(!b) {
				die("Help: SFColor b == 0");
			}
			(*ptr_).c[i] = SvNV(*b);
		}
	}
	


void 
alloc_offs_SFVec3f(ptr,offs)
	void *ptr
	int offs
CODE:
	struct SFColor *ptr_ = (struct SFColor *)(((char *)ptr)+offs);
	

void
free_offs_SFVec3f(ptr,offs)
	void *ptr
	int offs
CODE:
	struct SFColor *ptr_ = (struct SFColor *)(((char *)ptr)+offs);
	



void 
set_offs_MFVec3f(ptr,offs,sv_)
	void *ptr
	int offs
	SV *sv_
CODE:
	struct Multi_Vec3f *ptr_ = (struct Multi_Vec3f *)(((char *)ptr)+offs);
	{
		AV *aM;
		SV **bM;
		int iM;
		int lM;
		if(!SvROK(sv_)) {
			die("Help! Multi without being ref");
		}
		if(SvTYPE(SvRV(sv_)) != SVt_PVAV) {
			die("Help! Multi without being arrayref");
		}
		aM = (AV *) SvRV(sv_);
		lM = av_len(aM)+1;
		/* XXX Free previous p */
		(*ptr_).n = lM;
		(*ptr_).p = malloc(lM * sizeof(*((*ptr_).p)));
		/* XXX ALLOC */
		for(iM=0; iM<lM; iM++) {
			bM = av_fetch(aM, iM, 1); /* LVal for easiness */
			if(!bM) {
				die("Help: Multi VRML::Field::SFVec3f bM == 0");
			}
			{
		AV *a;
		SV **b;
		int i;
		if(!SvROK((*bM))) {
			die("Help! SFColor without being ref");
		}
		if(SvTYPE(SvRV((*bM))) != SVt_PVAV) {
			die("Help! SFColor without being arrayref");
		}
		a = (AV *) SvRV((*bM));
		for(i=0; i<3; i++) {
			b = av_fetch(a, i, 1); /* LVal for easiness */
			if(!b) {
				die("Help: SFColor b == 0");
			}
			((*ptr_).p[iM]).c[i] = SvNV(*b);
		}
	}
	
		}
	}
	


void 
alloc_offs_MFVec3f(ptr,offs)
	void *ptr
	int offs
CODE:
	struct Multi_Vec3f *ptr_ = (struct Multi_Vec3f *)(((char *)ptr)+offs);
	(*ptr_).n = 0; (*ptr_).p = 0;

void
free_offs_MFVec3f(ptr,offs)
	void *ptr
	int offs
CODE:
	struct Multi_Vec3f *ptr_ = (struct Multi_Vec3f *)(((char *)ptr)+offs);
	if((*ptr_).p) {free((*ptr_).p);(*ptr_).p=0;} (*ptr_).n = 0;



void 
set_offs_SFBool(ptr,offs,sv_)
	void *ptr
	int offs
	SV *sv_
CODE:
	int *ptr_ = (int *)(((char *)ptr)+offs);
	(*ptr_) = SvIV(sv_);



void 
alloc_offs_SFBool(ptr,offs)
	void *ptr
	int offs
CODE:
	int *ptr_ = (int *)(((char *)ptr)+offs);
	

void
free_offs_SFBool(ptr,offs)
	void *ptr
	int offs
CODE:
	int *ptr_ = (int *)(((char *)ptr)+offs);
	



void 
set_offs_SFInt32(ptr,offs,sv_)
	void *ptr
	int offs
	SV *sv_
CODE:
	int *ptr_ = (int *)(((char *)ptr)+offs);
	(*ptr_) = SvIV(sv_);



void 
alloc_offs_SFInt32(ptr,offs)
	void *ptr
	int offs
CODE:
	int *ptr_ = (int *)(((char *)ptr)+offs);
	

void
free_offs_SFInt32(ptr,offs)
	void *ptr
	int offs
CODE:
	int *ptr_ = (int *)(((char *)ptr)+offs);
	



void 
set_offs_MFInt32(ptr,offs,sv_)
	void *ptr
	int offs
	SV *sv_
CODE:
	struct Multi_Int32 *ptr_ = (struct Multi_Int32 *)(((char *)ptr)+offs);
	{
		AV *aM;
		SV **bM;
		int iM;
		int lM;
		if(!SvROK(sv_)) {
			die("Help! Multi without being ref");
		}
		if(SvTYPE(SvRV(sv_)) != SVt_PVAV) {
			die("Help! Multi without being arrayref");
		}
		aM = (AV *) SvRV(sv_);
		lM = av_len(aM)+1;
		/* XXX Free previous p */
		(*ptr_).n = lM;
		(*ptr_).p = malloc(lM * sizeof(*((*ptr_).p)));
		/* XXX ALLOC */
		for(iM=0; iM<lM; iM++) {
			bM = av_fetch(aM, iM, 1); /* LVal for easiness */
			if(!bM) {
				die("Help: Multi VRML::Field::SFInt32 bM == 0");
			}
			((*ptr_).p[iM]) = SvIV((*bM));

		}
	}
	


void 
alloc_offs_MFInt32(ptr,offs)
	void *ptr
	int offs
CODE:
	struct Multi_Int32 *ptr_ = (struct Multi_Int32 *)(((char *)ptr)+offs);
	(*ptr_).n = 0; (*ptr_).p = 0;

void
free_offs_MFInt32(ptr,offs)
	void *ptr
	int offs
CODE:
	struct Multi_Int32 *ptr_ = (struct Multi_Int32 *)(((char *)ptr)+offs);
	if((*ptr_).p) {free((*ptr_).p);(*ptr_).p=0;} (*ptr_).n = 0;



void 
set_offs_SFNode(ptr,offs,sv_)
	void *ptr
	int offs
	SV *sv_
CODE:
	void **ptr_ = (void **)(((char *)ptr)+offs);
	(*ptr_) = (void *)SvIV(sv_);


void 
alloc_offs_SFNode(ptr,offs)
	void *ptr
	int offs
CODE:
	void **ptr_ = (void **)(((char *)ptr)+offs);
	(*ptr_) = 0;

void
free_offs_SFNode(ptr,offs)
	void *ptr
	int offs
CODE:
	void **ptr_ = (void **)(((char *)ptr)+offs);
	(*ptr_) = 0;



void 
set_offs_MFNode(ptr,offs,sv_)
	void *ptr
	int offs
	SV *sv_
CODE:
	struct Multi_Node *ptr_ = (struct Multi_Node *)(((char *)ptr)+offs);
	{
		AV *aM;
		SV **bM;
		int iM;
		int lM;
		if(!SvROK(sv_)) {
			die("Help! Multi without being ref");
		}
		if(SvTYPE(SvRV(sv_)) != SVt_PVAV) {
			die("Help! Multi without being arrayref");
		}
		aM = (AV *) SvRV(sv_);
		lM = av_len(aM)+1;
		/* XXX Free previous p */
		(*ptr_).n = lM;
		(*ptr_).p = malloc(lM * sizeof(*((*ptr_).p)));
		/* XXX ALLOC */
		for(iM=0; iM<lM; iM++) {
			bM = av_fetch(aM, iM, 1); /* LVal for easiness */
			if(!bM) {
				die("Help: Multi VRML::Field::SFNode bM == 0");
			}
			((*ptr_).p[iM]) = (void *)SvIV((*bM));
		}
	}
	


void 
alloc_offs_MFNode(ptr,offs)
	void *ptr
	int offs
CODE:
	struct Multi_Node *ptr_ = (struct Multi_Node *)(((char *)ptr)+offs);
	(*ptr_).n = 0; (*ptr_).p = 0;

void
free_offs_MFNode(ptr,offs)
	void *ptr
	int offs
CODE:
	struct Multi_Node *ptr_ = (struct Multi_Node *)(((char *)ptr)+offs);
	if((*ptr_).p) {free((*ptr_).p);(*ptr_).p=0;} (*ptr_).n = 0;



void 
set_offs_SFColor(ptr,offs,sv_)
	void *ptr
	int offs
	SV *sv_
CODE:
	struct SFColor *ptr_ = (struct SFColor *)(((char *)ptr)+offs);
	{
		AV *a;
		SV **b;
		int i;
		if(!SvROK(sv_)) {
			die("Help! SFColor without being ref");
		}
		if(SvTYPE(SvRV(sv_)) != SVt_PVAV) {
			die("Help! SFColor without being arrayref");
		}
		a = (AV *) SvRV(sv_);
		for(i=0; i<3; i++) {
			b = av_fetch(a, i, 1); /* LVal for easiness */
			if(!b) {
				die("Help: SFColor b == 0");
			}
			(*ptr_).c[i] = SvNV(*b);
		}
	}
	


void 
alloc_offs_SFColor(ptr,offs)
	void *ptr
	int offs
CODE:
	struct SFColor *ptr_ = (struct SFColor *)(((char *)ptr)+offs);
	

void
free_offs_SFColor(ptr,offs)
	void *ptr
	int offs
CODE:
	struct SFColor *ptr_ = (struct SFColor *)(((char *)ptr)+offs);
	



void 
set_offs_MFColor(ptr,offs,sv_)
	void *ptr
	int offs
	SV *sv_
CODE:
	struct Multi_Color *ptr_ = (struct Multi_Color *)(((char *)ptr)+offs);
	{
		AV *aM;
		SV **bM;
		int iM;
		int lM;
		if(!SvROK(sv_)) {
			die("Help! Multi without being ref");
		}
		if(SvTYPE(SvRV(sv_)) != SVt_PVAV) {
			die("Help! Multi without being arrayref");
		}
		aM = (AV *) SvRV(sv_);
		lM = av_len(aM)+1;
		/* XXX Free previous p */
		(*ptr_).n = lM;
		(*ptr_).p = malloc(lM * sizeof(*((*ptr_).p)));
		/* XXX ALLOC */
		for(iM=0; iM<lM; iM++) {
			bM = av_fetch(aM, iM, 1); /* LVal for easiness */
			if(!bM) {
				die("Help: Multi VRML::Field::SFColor bM == 0");
			}
			{
		AV *a;
		SV **b;
		int i;
		if(!SvROK((*bM))) {
			die("Help! SFColor without being ref");
		}
		if(SvTYPE(SvRV((*bM))) != SVt_PVAV) {
			die("Help! SFColor without being arrayref");
		}
		a = (AV *) SvRV((*bM));
		for(i=0; i<3; i++) {
			b = av_fetch(a, i, 1); /* LVal for easiness */
			if(!b) {
				die("Help: SFColor b == 0");
			}
			((*ptr_).p[iM]).c[i] = SvNV(*b);
		}
	}
	
		}
	}
	


void 
alloc_offs_MFColor(ptr,offs)
	void *ptr
	int offs
CODE:
	struct Multi_Color *ptr_ = (struct Multi_Color *)(((char *)ptr)+offs);
	(*ptr_).n = 0; (*ptr_).p = 0;

void
free_offs_MFColor(ptr,offs)
	void *ptr
	int offs
CODE:
	struct Multi_Color *ptr_ = (struct Multi_Color *)(((char *)ptr)+offs);
	if((*ptr_).p) {free((*ptr_).p);(*ptr_).p=0;} (*ptr_).n = 0;



void 
set_offs_SFTime(ptr,offs,sv_)
	void *ptr
	int offs
	SV *sv_
CODE:
	float *ptr_ = (float *)(((char *)ptr)+offs);
	(*ptr_) = SvNV(sv_);



void 
alloc_offs_SFTime(ptr,offs)
	void *ptr
	int offs
CODE:
	float *ptr_ = (float *)(((char *)ptr)+offs);
	

void
free_offs_SFTime(ptr,offs)
	void *ptr
	int offs
CODE:
	float *ptr_ = (float *)(((char *)ptr)+offs);
	



void 
set_offs_SFString(ptr,offs,sv_)
	void *ptr
	int offs
	SV *sv_
CODE:
	SV **ptr_ = (SV **)(((char *)ptr)+offs);
	sv_setsv((*ptr_),sv_);


void 
alloc_offs_SFString(ptr,offs)
	void *ptr
	int offs
CODE:
	SV **ptr_ = (SV **)(((char *)ptr)+offs);
	(*ptr_) = newSVpv("",0);

void
free_offs_SFString(ptr,offs)
	void *ptr
	int offs
CODE:
	SV **ptr_ = (SV **)(((char *)ptr)+offs);
	SvREFCNT_dec((*ptr_));


void *
get_Appearance_offsets(p)
	SV *p;
CODE:
	int *ptr_;
	SvGROW(p,(3+1)*sizeof(int));
	SvCUR_set(p,(3+1)*sizeof(int));
	ptr_ = (int *)SvPV(p,na);
	*ptr_++ = offsetof(struct VRML_Appearance, texture);
	*ptr_++ = offsetof(struct VRML_Appearance, texturetransform);
	*ptr_++ = offsetof(struct VRML_Appearance, material);
	*ptr_++ = sizeof(struct VRML_Appearance);
RETVAL=&(virt_Appearance);
	printf("Appearance virtual: %d\n", RETVAL);
OUTPUT:
	RETVAL

void *
get_Shape_offsets(p)
	SV *p;
CODE:
	int *ptr_;
	SvGROW(p,(2+1)*sizeof(int));
	SvCUR_set(p,(2+1)*sizeof(int));
	ptr_ = (int *)SvPV(p,na);
	*ptr_++ = offsetof(struct VRML_Shape, appearance);
	*ptr_++ = offsetof(struct VRML_Shape, geometry);
	*ptr_++ = sizeof(struct VRML_Shape);
RETVAL=&(virt_Shape);
	printf("Shape virtual: %d\n", RETVAL);
OUTPUT:
	RETVAL

void *
get_Viewpoint_offsets(p)
	SV *p;
CODE:
	int *ptr_;
	SvGROW(p,(8+1)*sizeof(int));
	SvCUR_set(p,(8+1)*sizeof(int));
	ptr_ = (int *)SvPV(p,na);
	*ptr_++ = offsetof(struct VRML_Viewpoint, fieldOfView);
	*ptr_++ = offsetof(struct VRML_Viewpoint, description);
	*ptr_++ = offsetof(struct VRML_Viewpoint, isBound);
	*ptr_++ = offsetof(struct VRML_Viewpoint, position);
	*ptr_++ = offsetof(struct VRML_Viewpoint, set_bind);
	*ptr_++ = offsetof(struct VRML_Viewpoint, bindTime);
	*ptr_++ = offsetof(struct VRML_Viewpoint, jump);
	*ptr_++ = offsetof(struct VRML_Viewpoint, orientation);
	*ptr_++ = sizeof(struct VRML_Viewpoint);
RETVAL=&(virt_Viewpoint);
	printf("Viewpoint virtual: %d\n", RETVAL);
OUTPUT:
	RETVAL

void *
get_Cone_offsets(p)
	SV *p;
CODE:
	int *ptr_;
	SvGROW(p,(4+1)*sizeof(int));
	SvCUR_set(p,(4+1)*sizeof(int));
	ptr_ = (int *)SvPV(p,na);
	*ptr_++ = offsetof(struct VRML_Cone, height);
	*ptr_++ = offsetof(struct VRML_Cone, bottomRadius);
	*ptr_++ = offsetof(struct VRML_Cone, side);
	*ptr_++ = offsetof(struct VRML_Cone, bottom);
	*ptr_++ = sizeof(struct VRML_Cone);
RETVAL=&(virt_Cone);
	printf("Cone virtual: %d\n", RETVAL);
OUTPUT:
	RETVAL

void *
get_Sphere_offsets(p)
	SV *p;
CODE:
	int *ptr_;
	SvGROW(p,(1+1)*sizeof(int));
	SvCUR_set(p,(1+1)*sizeof(int));
	ptr_ = (int *)SvPV(p,na);
	*ptr_++ = offsetof(struct VRML_Sphere, radius);
	*ptr_++ = sizeof(struct VRML_Sphere);
RETVAL=&(virt_Sphere);
	printf("Sphere virtual: %d\n", RETVAL);
OUTPUT:
	RETVAL

void *
get_Coordinate_offsets(p)
	SV *p;
CODE:
	int *ptr_;
	SvGROW(p,(1+1)*sizeof(int));
	SvCUR_set(p,(1+1)*sizeof(int));
	ptr_ = (int *)SvPV(p,na);
	*ptr_++ = offsetof(struct VRML_Coordinate, point);
	*ptr_++ = sizeof(struct VRML_Coordinate);
RETVAL=&(virt_Coordinate);
	printf("Coordinate virtual: %d\n", RETVAL);
OUTPUT:
	RETVAL

void *
get_Box_offsets(p)
	SV *p;
CODE:
	int *ptr_;
	SvGROW(p,(1+1)*sizeof(int));
	SvCUR_set(p,(1+1)*sizeof(int));
	ptr_ = (int *)SvPV(p,na);
	*ptr_++ = offsetof(struct VRML_Box, size);
	*ptr_++ = sizeof(struct VRML_Box);
RETVAL=&(virt_Box);
	printf("Box virtual: %d\n", RETVAL);
OUTPUT:
	RETVAL

void *
get_Cylinder_offsets(p)
	SV *p;
CODE:
	int *ptr_;
	SvGROW(p,(5+1)*sizeof(int));
	SvCUR_set(p,(5+1)*sizeof(int));
	ptr_ = (int *)SvPV(p,na);
	*ptr_++ = offsetof(struct VRML_Cylinder, radius);
	*ptr_++ = offsetof(struct VRML_Cylinder, height);
	*ptr_++ = offsetof(struct VRML_Cylinder, top);
	*ptr_++ = offsetof(struct VRML_Cylinder, side);
	*ptr_++ = offsetof(struct VRML_Cylinder, bottom);
	*ptr_++ = sizeof(struct VRML_Cylinder);
RETVAL=&(virt_Cylinder);
	printf("Cylinder virtual: %d\n", RETVAL);
OUTPUT:
	RETVAL

void *
get_IndexedFaceSet_offsets(p)
	SV *p;
CODE:
	int *ptr_;
	SvGROW(p,(4+1)*sizeof(int));
	SvCUR_set(p,(4+1)*sizeof(int));
	ptr_ = (int *)SvPV(p,na);
	*ptr_++ = offsetof(struct VRML_IndexedFaceSet, creaseAngle);
	*ptr_++ = offsetof(struct VRML_IndexedFaceSet, solid);
	*ptr_++ = offsetof(struct VRML_IndexedFaceSet, coord);
	*ptr_++ = offsetof(struct VRML_IndexedFaceSet, coordIndex);
	*ptr_++ = sizeof(struct VRML_IndexedFaceSet);
RETVAL=&(virt_IndexedFaceSet);
	printf("IndexedFaceSet virtual: %d\n", RETVAL);
OUTPUT:
	RETVAL

void *
get_Transform_offsets(p)
	SV *p;
CODE:
	int *ptr_;
	SvGROW(p,(4+1)*sizeof(int));
	SvCUR_set(p,(4+1)*sizeof(int));
	ptr_ = (int *)SvPV(p,na);
	*ptr_++ = offsetof(struct VRML_Transform, rotation);
	*ptr_++ = offsetof(struct VRML_Transform, scale);
	*ptr_++ = offsetof(struct VRML_Transform, children);
	*ptr_++ = offsetof(struct VRML_Transform, translation);
	*ptr_++ = sizeof(struct VRML_Transform);
RETVAL=&(virt_Transform);
	printf("Transform virtual: %d\n", RETVAL);
OUTPUT:
	RETVAL

void *
get_Group_offsets(p)
	SV *p;
CODE:
	int *ptr_;
	SvGROW(p,(3+1)*sizeof(int));
	SvCUR_set(p,(3+1)*sizeof(int));
	ptr_ = (int *)SvPV(p,na);
	*ptr_++ = offsetof(struct VRML_Group, children);
	*ptr_++ = offsetof(struct VRML_Group, bboxCenter);
	*ptr_++ = offsetof(struct VRML_Group, bboxSize);
	*ptr_++ = sizeof(struct VRML_Group);
RETVAL=&(virt_Group);
	printf("Group virtual: %d\n", RETVAL);
OUTPUT:
	RETVAL

void *
get_ElevationGrid_offsets(p)
	SV *p;
CODE:
	int *ptr_;
	SvGROW(p,(3+1)*sizeof(int));
	SvCUR_set(p,(3+1)*sizeof(int));
	ptr_ = (int *)SvPV(p,na);
	*ptr_++ = offsetof(struct VRML_ElevationGrid, zDimension);
	*ptr_++ = offsetof(struct VRML_ElevationGrid, height);
	*ptr_++ = offsetof(struct VRML_ElevationGrid, xDimension);
	*ptr_++ = sizeof(struct VRML_ElevationGrid);
RETVAL=&(virt_ElevationGrid);
	printf("ElevationGrid virtual: %d\n", RETVAL);
OUTPUT:
	RETVAL

void *
get_Material_offsets(p)
	SV *p;
CODE:
	int *ptr_;
	SvGROW(p,(6+1)*sizeof(int));
	SvCUR_set(p,(6+1)*sizeof(int));
	ptr_ = (int *)SvPV(p,na);
	*ptr_++ = offsetof(struct VRML_Material, transparency);
	*ptr_++ = offsetof(struct VRML_Material, emissiveColor);
	*ptr_++ = offsetof(struct VRML_Material, shininess);
	*ptr_++ = offsetof(struct VRML_Material, diffuseColor);
	*ptr_++ = offsetof(struct VRML_Material, specularColor);
	*ptr_++ = offsetof(struct VRML_Material, ambientIntensity);
	*ptr_++ = sizeof(struct VRML_Material);
RETVAL=&(virt_Material);
	printf("Material virtual: %d\n", RETVAL);
OUTPUT:
	RETVAL


BOOT:
	I_OPENGL;

