/*
 * hbgtk_style.c — hoja de estilo CSS y fuentes por widget
 *
 * Dos cosas distintas y complementarias de la fase 4:
 *
 *   - HGtkCss aplica una hoja de estilo a toda la pantalla, para el
 *     aspecto general de la aplicación (la hoja mínima de la muestra);
 *   - HGtkFontSet/HGtkFontGet ponen y leen la fuente de un widget.
 *     No se usa la API de fuentes obsoleta de GTK: se añade un
 *     proveedor CSS al contexto de estilo del propio widget, y como
 *     "font" es una propiedad heredable, los hijos se llevan la misma
 *     fuente salvo que la tengan puesta ellos también (medido en el
 *     banco de pruebas de la fase 4).
 *
 * Licencia: LGPL-3.0-or-later
 */
#include "hbgtk.h"

/* puntos de Pango a píxeles de CSS (96 px por pulgada) */
#define HGTK_PX_PUNTO( nPuntos ) ( ( (nPuntos) * 96 + 36 ) / 72 )

/* HGtkCss( cCss ) -> .T. si la hoja se interpretó. Un error de
 * sintaxis no se calla: llega al ErrorBlock como cualquier otro error
 * de uso, y lo que ya estuviera aplicado se queda aplicado. */
HB_FUNC( HGTKCSS )
{
   GtkCssProvider * pProv;
   GError * pError = NULL;
   const char * szCss;

   if( hb_pcount() < 1 || ! HB_ISCHAR( 1 ) )
   {
      hbgtk_errArgs( "HGtkCss", "la hoja de estilo debe ser una cadena" );
      hb_retl( FALSE );
      return;
   }
   if( ! hbgtk_initGTK() )
   {
      hbgtk_errGui( "HGtkCss", "GTK no está inicializado: no hay estilo" );
      hb_retl( FALSE );
      return;
   }

   szCss = hb_parc( 1 );
   pProv = gtk_css_provider_new();

   if( ! gtk_css_provider_load_from_data( pProv, szCss, -1, &pError ) )
   {
      hbgtk_errArgs( "HGtkCss",
                     pError ? pError->message :
                              "la hoja de estilo no es válida" );
      if( pError )
         g_error_free( pError );
      g_object_unref( pProv );
      hb_retl( FALSE );
      return;
   }

   gtk_style_context_add_provider_for_screen(
      gdk_screen_get_default(), GTK_STYLE_PROVIDER( pProv ),
      GTK_STYLE_PROVIDER_PRIORITY_APPLICATION );
   g_object_unref( pProv );
   hb_retl( TRUE );
}

/* caras de fuente dentro de comillas: la comilla y la barra
 * invertida se escapan para que el CSS no se rompa */
static gchar * hbgtk_fuente_escapa( const char * szCara )
{
   GString * pRes = g_string_new( NULL );
   const char * p = szCara ? szCara : "";

   while( *p )
   {
      if( *p == '"' || *p == '\\' )
         g_string_append_c( pRes, '\\' );
      g_string_append_c( pRes, *p );
      p++;
   }

   return g_string_free( pRes, FALSE );
}

/*
 * Widget validado para las fuentes: control o ventana (Font() sirve
 * para las dos y cada uno vive en su lista). Si el puntero no está,
 * error de Harbour sin desreferenciar nada.
 */
static GtkWidget * hbgtk_fuente_par( const char * szProc )
{
   GtkWidget * pCtrl = (GtkWidget *) hb_parptr( 1 );

   if( ! pCtrl || ( ! hbgtk_ctrl_alive( pCtrl ) &&
                    ! hbgtk_wnd_alive( pCtrl ) ) )
   {
      hbgtk_errArgs( szProc, "puntero de widget no válido" );
      return NULL;
   }
   return pCtrl;
}

/*
 * HGtkFontSet( pWidget, cCara, nPuntos, lNegrita, lCursiva ) -> .T.
 * La fuente del widget y de sus hijos; la hoja global (HGtkCss) sigue
 * mandando para el resto de la pantalla.
 */
HB_FUNC( HGTKFONTSET )
{
   GtkWidget * pCtrl = hbgtk_fuente_par( "HGtkFontSet" );
   GtkCssProvider * pProv;
   GError * pError = NULL;
   GString * pCss;
   gchar * szCara;
   int nPuntos;

   if( ! pCtrl )
   {
      hb_retl( FALSE );
      return;
   }
   if( hb_pcount() < 4 || ! HB_ISCHAR( 2 ) || ! HB_ISNUM( 3 ) )
   {
      hbgtk_errArgs( "HGtkFontSet",
                     "se esperaba (pWidget, cCara, nPuntos, lNegrita,"
                     " lCursiva)" );
      hb_retl( FALSE );
      return;
   }

   nPuntos = hb_parni( 3 );
   if( nPuntos < 1 )
   {
      hbgtk_errArgs( "HGtkFontSet", "el tamaño debe ser 1 o más puntos" );
      hb_retl( FALSE );
      return;
   }

   szCara = hbgtk_fuente_escapa( hb_parc( 2 ) );
   pCss = g_string_new( "* { font-family: \"" );
   g_string_append( pCss, szCara );
   g_string_append_printf( pCss,
                           "\"; font-size: %dpx",
                           HGTK_PX_PUNTO( nPuntos ) );
   if( hb_pcount() >= 4 && HB_ISLOG( 4 ) && hb_parl( 4 ) )
      g_string_append( pCss, "; font-weight: bold" );
   if( hb_pcount() >= 5 && HB_ISLOG( 5 ) && hb_parl( 5 ) )
      g_string_append( pCss, "; font-style: italic" );
   g_string_append( pCss, " }" );
   g_free( szCara );

   pProv = gtk_css_provider_new();
   if( ! gtk_css_provider_load_from_data( pProv, pCss->str, -1,
                                          &pError ) )
   {
      hbgtk_errArgs( "HGtkFontSet",
                     pError ? pError->message : "fuente no válida" );
      if( pError )
         g_error_free( pError );
      g_object_unref( pProv );
      g_string_free( pCss, TRUE );
      hb_retl( FALSE );
      return;
   }

   gtk_style_context_add_provider(
      gtk_widget_get_style_context( pCtrl ),
      GTK_STYLE_PROVIDER( pProv ),
      GTK_STYLE_PROVIDER_PRIORITY_APPLICATION );
   g_object_unref( pProv );
   g_string_free( pCss, TRUE );
   hb_retl( TRUE );
}

/* HGtkFontGet( pWidget ) -> "Sans 10", la fuente que tiene ahora
 * (la heredada, si no lleva una propia). Cadena vacía si no hay. */
HB_FUNC( HGTKFONTGET )
{
   GtkWidget * pCtrl = hbgtk_fuente_par( "HGtkFontGet" );
   GValue valor = G_VALUE_INIT;
   PangoFontDescription * pFont;
   gchar * szFuente;

   if( ! pCtrl )
   {
      hb_retc( "" );
      return;
   }

   gtk_style_context_get_property( gtk_widget_get_style_context( pCtrl ),
                                   "font", GTK_STATE_FLAG_NORMAL,
                                   &valor );
   if( ! G_VALUE_HOLDS( &valor, PANGO_TYPE_FONT_DESCRIPTION ) )
   {
      g_value_unset( &valor );
      hb_retc( "" );
      return;
   }

   pFont = (PangoFontDescription *) g_value_get_boxed( &valor );
   szFuente = pFont ? pango_font_description_to_string( pFont ) :
                      g_strdup( "" );
   g_value_unset( &valor );

   hb_retc( szFuente );
   g_free( szFuente );
}
