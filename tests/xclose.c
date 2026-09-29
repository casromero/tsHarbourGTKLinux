/*
 * xclose.c — envía WM_DELETE_WINDOW a una ventana de nivel superior
 *
 * Es lo mismo que manda el gestor de ventanas cuando el usuario
 * pulsa el aspa de la barra de título. Permite cerrar las ventanas de
 * las pruebas sin tocar el código de la librería y sin un entorno de
 * escritorio: bajo Xvfb, cualquier ventana está en pantalla.
 *
 *   xclose -t <título> [-n envíos] [-w segundos] [-d ms]
 *
 * Sale con 0 si encontró la ventana y envió, 1 si no la encontró,
 * 2 si no hay display.
 *
 * Compilar:  make tests/xclose
 *
 * Licencia: LGPL-3.0-or-later
 */

#include <X11/Xlib.h>
#include <X11/Xatom.h>
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

int main( int argc, char ** argv )
{
   const char * szTitulo = NULL;
   int nEnvios = 1, nEspera = 20, nDelayMs = 700, i;
   int fVerbose = 0;
   Display * dpy;
   Window raiz, objetivo = None;
   Atom wmProtocols, wmDelete;
   char * szArgs[ 32 ];
   int nArgs = 0;

   for( i = 1; i < argc && nArgs < 30; i++ )
      szArgs[ nArgs++ ] = argv[ i ];

   for( i = 0; i + 1 < nArgs; i++ )
   {
      if( strcmp( szArgs[ i ], "-t" ) == 0 )
         szTitulo = szArgs[ ++i ];
      else if( strcmp( szArgs[ i ], "-n" ) == 0 )
         nEnvios = atoi( szArgs[ ++i ] );
      else if( strcmp( szArgs[ i ], "-w" ) == 0 )
         nEspera = atoi( szArgs[ ++i ] );
      else if( strcmp( szArgs[ i ], "-d" ) == 0 )
         nDelayMs = atoi( szArgs[ ++i ] );
      else if( strcmp( szArgs[ i ], "-v" ) == 0 )
         fVerbose = 1;
   }

   if( fVerbose )
      fprintf( stderr, "xclose: display=%s título=%s envíos=%d\n",
               getenv( "DISPLAY" ) ? getenv( "DISPLAY" ) : "(ninguno)",
               szTitulo ? szTitulo : "(cualquiera)", nEnvios );

   if( nEnvios < 1 )
      nEnvios = 1;

   dpy = XOpenDisplay( NULL );
   if( ! dpy )
   {
      fprintf( stderr, "xclose: no hay display X\n" );
      return 2;
   }

   raiz = DefaultRootWindow( dpy );

   for( i = 0; ! objetivo && i < nEspera * 10; i++ )
   {
      Window raiz_ret, padre, * hijos = NULL;
      unsigned int nHijos = 0, j;

      if( XQueryTree( dpy, raiz, &raiz_ret, &padre, &hijos, &nHijos ) )
      {
         if( fVerbose && i < 3 )
            fprintf( stderr, "  intento %d: %u ventanas en la raíz\n", i, nHijos );

         for( j = 0; j < nHijos; j++ )
         {
            XWindowAttributes attr;
            char * szTitulo2 = ventana_titulo( dpy, hijos[ j ] );
            int fMapa = XGetWindowAttributes( dpy, hijos[ j ], &attr ) &&
                        attr.map_state == IsViewable;

            if( fVerbose && i < 3 )
               fprintf( stderr, "  ventana[%u] %s título=%s\n", j,
                        fMapa ? "en pantalla" : "sin mapear",
                        szTitulo2 ? szTitulo2 : "(ninguno)" );

            if( szTitulo2 && fMapa &&
                ( szTitulo == NULL || strcmp( szTitulo2, szTitulo ) == 0 ) )
            {
               objetivo = hijos[ j ];
               printf( "xclose: ventana encontrada «%s»\n", szTitulo2 );
            }
            if( szTitulo2 )
               XFree( szTitulo2 );
         }
         if( hijos )
            XFree( hijos );
      }
      if( ! objetivo )
         usleep( 100000 );
   }

   if( ! objetivo )
   {
      fprintf( stderr, "xclose: no se encontró ninguna ventana%s%s\n",
               szTitulo ? " con título " : "", szTitulo ? szTitulo : "" );
      XCloseDisplay( dpy );
      return 1;
   }

   wmProtocols = XInternAtom( dpy, "WM_PROTOCOLS", False );
   wmDelete = XInternAtom( dpy, "WM_DELETE_WINDOW", False );

   for( i = 0; i < nEnvios; i++ )
   {
      XEvent ev;

      memset( &ev, 0, sizeof( ev ) );
      ev.xclient.type = ClientMessage;
      ev.xclient.window = objetivo;
      ev.xclient.message_type = wmProtocols;
      ev.xclient.format = 32;
      ev.xclient.data.l[ 0 ] = (long) wmDelete;
      ev.xclient.data.l[ 1 ] = CurrentTime;

      XSendEvent( dpy, objetivo, False, NoEventMask, &ev );
      XFlush( dpy );
      printf( "xclose: WM_DELETE_WINDOW %d/%d\n", i + 1, nEnvios );

      if( i + 1 < nEnvios )
         usleep( (useconds_t) nDelayMs * 1000 );
   }

   XCloseDisplay( dpy );
   return 0;
}
