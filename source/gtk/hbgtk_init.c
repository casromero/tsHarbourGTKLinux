/*
 * hbgtk_init.c — arranque de GTK
 *
 * gtk_init se ejecuta una sola vez para todo el proceso, desde
 * TApplication (o desde la creación de la primera ventana).
 * Si no hay display, se lanza un error de Harbour y se devuelve .F.
 *
 * Licencia: LGPL-3.0-or-later
 */
#include "hbgtk.h"
#include "hbapierr.h"

gboolean hbgtk_fInited = FALSE;

HB_BOOL hbgtk_initGTK( void )
{
   if( hbgtk_fInited )
      return TRUE;

   if( ! gtk_init_check( NULL, NULL ) )
   {
      hbgtk_errGui( "HGtkInit",
                    "GTK no puede abrir un display (comprueba $DISPLAY y WSLg)" );
      return FALSE;
   }

   hbgtk_fInited = TRUE;
   return TRUE;
}

/* HGtkInit() -> .T. si GTK ya está listo, .F. si no hay display */
HB_FUNC( HGTKINIT )
{
   hb_retl( hbgtk_initGTK() );
}

/* HGtkInit() ya se ha ejecutado con éxito */
HB_FUNC( HGTKISINIT )
{
   hb_retl( hbgtk_fInited );
}

/* HGtkVersion() -> "3.24.41" */
HB_FUNC( HGTKVERSION )
{
   char szVersion[ 32 ];

   snprintf( szVersion, sizeof( szVersion ), "%u.%u.%u",
             (unsigned) gtk_get_major_version(),
             (unsigned) gtk_get_minor_version(),
             (unsigned) gtk_get_micro_version() );
   hb_retc( szVersion );
}
