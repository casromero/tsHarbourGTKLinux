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
#include <string.h>   /* strstr, strchr */

gboolean hbgtk_fInited = FALSE;

/*
 * hbgtk_decoraciones() — los botones de maximizar y minimizar de la
 * barra.
 *
 * Cuando el compositor no ofrece decoración de servidor (el Weston de
 * WSLg no anuncia zxdg_decoration), la barra la dibuja el propio GTK y
 * los botones salen del ajuste "gtk-decoration-layout". Ese valor
 * llega desde GSettings, y en esta imagen el default del schema de
 * GNOME es 'appmenu:close': sólo la X, sin forma de maximizar ni de
 * minimizar con el ratón. Si faltan minimize o maximize se piden
 * añadiéndolos al lado de la X y dejando el lado izquierdo como está;
 * si la sesión ya los trae (X11, que además no pasa por GSettings y
 * usa settings.ini, con el layout completo), no se toca nada.
 *
 * Se mira una sola vez al arrancar, antes de crear la primera ventana.
 */
static void hbgtk_decoraciones( void )
{
   GtkSettings * pSettings = gtk_settings_get_default();
   gchar * szLayout = NULL;
   gchar * szPunto;
   gchar * szNuevo;

   if( ! pSettings )
      return;

   g_object_get( pSettings, "gtk-decoration-layout", &szLayout, NULL );
   if( ! szLayout )
      return;

   /* los dos botones presentes: la sesión ya los gestiona */
   if( strstr( szLayout, "minimize" ) && strstr( szLayout, "maximize" ) )
   {
      g_free( szLayout );
      return;
   }

   szPunto = strchr( szLayout, ':' );
   if( szPunto )
      szNuevo = g_strdup_printf( "%.*s:minimize,maximize,close",
                                 (int)( szPunto - szLayout ), szLayout );
   else
      szNuevo = g_strdup( "menu:minimize,maximize,close" );

   g_object_set( pSettings, "gtk-decoration-layout", szNuevo, NULL );
   g_free( szNuevo );
   g_free( szLayout );
}

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

   /* los botones de la barra, si la sesión no los trae */
   hbgtk_decoraciones();

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

/* HGtkDecoracion() -> "menu:minimize,maximize,close" — sólo pruebas:
 * el layout de decoración que resuelve GTK para este proceso, con el
 * complemento de hbgtk_decoraciones(). Vacío si no hay display. */
HB_FUNC( HGTKDECORACION )
{
   gchar * szLayout = NULL;

   if( hbgtk_initGTK() )
      g_object_get( gtk_settings_get_default(), "gtk-decoration-layout",
                    &szLayout, NULL );

   hb_retc( szLayout ? szLayout : "" );
   g_free( szLayout );
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
