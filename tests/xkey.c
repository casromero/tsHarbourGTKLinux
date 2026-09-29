/*
 * xkey.c — envía una tecla a la ventana de una aplicación (XTEST)
 *
 * Es lo que haría un usuario pulsando el teclado. Permite probar sin
 * mirar la pantalla comportamientos que sólo se ven con foco: la
 * validación al perder el foco (Tab) y las teclas de diálogo.
 *
 *   xkey -k <tecla> [-t <título>] [-w segundos] [-v]
 *
 * <tecla> es un nombre de keysym: Tab, Return, Escape, space, a...
 * <título> (opcional) es la ventana a la que va la tecla; se compara
 * como subcadena y, si no se indica, se usa la primera ventana con
 * título que esté en pantalla.
 *
 * Bajo Xvfb no hay gestor de ventanas que conceda el foco de entrada,
 * así que xkey hace de gestor: si la ventana no lo tiene, se lo da con
 * XSetInputFocus antes de enviar la tecla.
 *
 * Sale con 0 si envió, 1 si no hay ventana, tecla desconocida o el
 * servidor no admite XTEST, 2 si no hay display.
 *
 * Compilar:  make tests/xkey
 *
 * Licencia: LGPL-3.0-or-later
 */

#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/keysym.h>
#include <X11/extensions/XTest.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* título en UTF-8: _NET_WM_NAME y, si no, WM_NAME. Caller hace XFree. */
static char * ventana_titulo( Display * dpy, Window w )
{
   Atom neta = XInternAtom( dpy, "_NET_WM_NAME", False );
   Atom utf8 = XInternAtom( dpy, "UTF8_STRING", False );
   Atom tipo;
   int formato;
   unsigned long nitems, bytes_tras;
   unsigned char * datos = NULL;
   char * nombre = NULL;

   if( XGetWindowProperty( dpy, w, neta, 0, 1024, False, utf8,
                           &tipo, &formato, &nitems, &bytes_tras,
                           &datos ) == Success && datos && nitems > 0 )
      return (char *) datos;

   if( datos )
      XFree( datos );

   if( XFetchName( dpy, w, &nombre ) )
      return nombre;

   return NULL;
}

/* sube hasta la ventana de nivel superior que contiene a w */
static Window toplevel_de( Display * dpy, Window w )
{
   Window raiz, padre, actual = w, * hijos = NULL;
   unsigned int nHijos = 0;

   while( actual != None && actual != DefaultRootWindow( dpy ) )
   {
      if( ! XQueryTree( dpy, actual, &raiz, &padre, &hijos, &nHijos ) )
         return w;
      if( hijos )
         XFree( hijos );
      if( padre == raiz || padre == None )
         return actual;
      actual = padre;
   }
   return w;
}

/* primera ventana de nivel superior visible cuyo título contiene
 * szTitulo (o con cualquier título, si szTitulo es NULL) */
static Window ventana_objetivo( Display * dpy, const char * szTitulo )
{
   Window raiz = DefaultRootWindow( dpy ), raiz_ret, padre, * hijos = NULL;
   unsigned int nHijos = 0, j;
   Window elegida = None;

   if( ! XQueryTree( dpy, raiz, &raiz_ret, &padre, &hijos, &nHijos ) )
      return None;

   for( j = 0; j < nHijos && elegida == None; j++ )
   {
      XWindowAttributes attr;
      char * szTitulo2;

      if( ! XGetWindowAttributes( dpy, hijos[ j ], &attr ) ||
          attr.map_state != IsViewable )
         continue;

      szTitulo2 = ventana_titulo( dpy, hijos[ j ] );
      if( szTitulo2 )
      {
         if( szTitulo == NULL || strstr( szTitulo2, szTitulo ) != NULL )
            elegida = hijos[ j ];
         XFree( szTitulo2 );
      }
   }

   if( hijos )
      XFree( hijos );
   return elegida;
}

int main( int argc, char ** argv )
{
   const char * szTecla = NULL, * szTitulo = NULL;
   int nEspera = 10, fVerbose = 0, i;
   Display * dpy;
   Window objetivo = None, foco = None;
   KeySym tecla = NoSymbol;
   KeyCode codigo = 0;
   int evBase, errorBase, major = 2, minor = 0;

   for( i = 1; i < argc; i++ )
   {
      if( strcmp( argv[ i ], "-k" ) == 0 && i + 1 < argc )
         szTecla = argv[ ++i ];
      else if( strcmp( argv[ i ], "-t" ) == 0 && i + 1 < argc )
         szTitulo = argv[ ++i ];
      else if( strcmp( argv[ i ], "-w" ) == 0 && i + 1 < argc )
         nEspera = atoi( argv[ ++i ] );
      else if( strcmp( argv[ i ], "-v" ) == 0 )
         fVerbose = 1;
   }

   if( ! szTecla && ! szTitulo )
   {
      fprintf( stderr,
               "uso: xkey [-k <tecla>] [-t <título>] [-w segundos] [-v]\n"
               "      sin -k sólo se da el foco a la ventana\n" );
      return 1;
   }

   dpy = XOpenDisplay( NULL );
   if( ! dpy )
   {
      fprintf( stderr, "xkey: no hay display X\n" );
      return 2;
   }

   if( ! XTestQueryExtension( dpy, &evBase, &errorBase, &major, &minor ) )
   {
      fprintf( stderr, "xkey: el servidor no admite XTEST\n" );
      XCloseDisplay( dpy );
      return 1;
   }

   if( szTecla )
   {
      tecla = XStringToKeysym( szTecla );
      if( tecla == NoSymbol )
      {
         fprintf( stderr, "xkey: tecla desconocida «%s»\n", szTecla );
         XCloseDisplay( dpy );
         return 1;
      }
      codigo = XKeysymToKeycode( dpy, tecla );
      if( codigo == 0 )
      {
         fprintf( stderr, "xkey: el servidor no tiene código para «%s»\n",
                  szTecla );
         XCloseDisplay( dpy );
         return 1;
      }
   }

   /* espera a que aparezca la ventana objetivo */
   for( i = 0; i < nEspera * 10 && objetivo == None; i++ )
   {
      objetivo = ventana_objetivo( dpy, szTitulo );
      if( objetivo == None )
         usleep( 100000 );
   }
   if( objetivo == None )
   {
      fprintf( stderr, "xkey: no hay ninguna ventana%s%s\n",
               szTitulo ? " con título " : "", szTitulo ? szTitulo : "" );
      XCloseDisplay( dpy );
      return 1;
   }

   /* el foco de entrada: si nadie lo ha dado (no hay gestor de
    * ventanas), xkey se lo concede a la ventana, como haría él */
   for( i = 0; i < 20; i++ )
   {
      XGetInputFocus( dpy, &foco, &errorBase );
      if( foco != None && foco != PointerRoot &&
          toplevel_de( dpy, foco ) == objetivo )
         break;
      if( i == 0 &&
          ( foco == None || foco == PointerRoot ||
            toplevel_de( dpy, foco ) != objetivo ) )
      {
         if( fVerbose )
            fprintf( stderr, "xkey: el foco está en otra ventana, "
                             "se lo doy a la ventana objetivo\n" );
         XSetInputFocus( dpy, objetivo, RevertToParent, CurrentTime );
         XFlush( dpy );
      }
      usleep( 100000 );
   }

   if( foco == None || foco == PointerRoot ||
       toplevel_de( dpy, foco ) != objetivo )
   {
      fprintf( stderr, "xkey: no se pudo dar el foco a la ventana\n" );
      XCloseDisplay( dpy );
      return 1;
   }

   {
      char * szT = ventana_titulo( dpy, objetivo );

      if( szTecla )
         printf( "xkey: foco en «%s»; envío %s\n",
                 szT ? szT : "(sin título)", szTecla );
      else
         printf( "xkey: foco en «%s» (sólo foco)\n",
                 szT ? szT : "(sin título)" );
      if( szT )
         XFree( szT );
   }

   if( szTecla )
   {
      /* Un instante para que la aplicación procese el FocusIn: si la
       * tecla llega pegada al cambio de foco, GTK se la guarda y no
       * llega a activar el widget. */
      usleep( 300000 );

      XTestFakeKeyEvent( dpy, codigo, True, CurrentTime );
      XTestFakeKeyEvent( dpy, codigo, False, CurrentTime + 1 );
      XFlush( dpy );
   }

   XCloseDisplay( dpy );
   return 0;
}
