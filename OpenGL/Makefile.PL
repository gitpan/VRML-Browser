BEGIN {
  $skip = 0;
  if ($^O =~ /win32/i) {
    warn "Win32 systems not yet supported. Buzz off.";
    open(OUT,">Makefile");
    print OUT "fred:\n";
    print OUT "\t\@echo \n";
    print OUT "\t\@echo $msg\n";
    print OUT "\t\@echo \n";
    print OUT "\nall: fred\n";
    print OUT "\ntest: fred\n";
    close(OUT);
    $skip=1;
  }
}

# Makefile.PL for VRML::OpenGL module.

# Use this as a template for the Makefile.PL for
# any external PDL module.

goto SKIP if $skip;
use ExtUtils::MakeMaker;

# Add several possible places for -L. 

WriteMakefile(
	NAME => 'VRML::OpenGL',
	VERSION => '0.5',
#
# You have to explain here how to find your opengl libs.
#
    LIBS      => 
     '-L/home/l/u/lukka/lib -L/usr/X11R6/lib -L/usr/lib/mesa -lMesaGL -lMesaGLU -lXext -lX11',

    DEFINE => '',
    INC => '',
);

#
#      ['-L/usr/X11R6/lib -L/usr/lib/mesa/ -lGL -lGLU -lMesaGL -lMesaGLU -lXext -lX11 '],
#

SKIP: return;

