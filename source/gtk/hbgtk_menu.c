/*
 * hbgtk_menu.c — barra de menú, barra de botones y barra de estado
 *
 * Menús: una barra (GtkMenuBar) contiene ítems con submenú (un
 * GtkMenuItem cuyo hijo es un GtkMenu), y éstos contienen los ítems
 * de la orden (GtkMenuItem). Se cuelgan de la ventana con
 * HGtkWndSetMenu, que los mete en la caja vertical (hbgtk_ctrl.c).
 *
 * La barra de botones es un GtkToolbar con botones de texto; los
 * botones son los mismos TButton de siempre, creados como tool item
 * cuando el padre es una TBar.
 *
 * Licencia: LGPL-3.0-or-later
 */
#include "hbgtk.h"

/* ------------------------------------------------------------------ */
/* menú                                                               */
/* ------------------------------------------------------------------ */

/* HGtkMenuBarNew() -> barra de menú (TMenu) */
HB_FUNC( HGTKMENUBARNEW )
{
   GtkWidget * pBar;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   pBar = gtk_menu_bar_new();
   hbgtk_ctrl_init( pBar );
   hb_retptr( pBar );
}

/* HGtkMenuPopupNew( cTexto ) -> ítem con submenú (TPopup) */
HB_FUNC( HGTKMENUPOPUPNEW )
{
   GtkWidget * pItem, * pSub;
   char * szTexto;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   szTexto = hbgtk_mnemonico( HB_ISCHAR( 1 ) ? hb_parc( 1 ) : "" );
   pItem = gtk_menu_item_new_with_mnemonic( szTexto );
   g_free( szTexto );

   pSub = gtk_menu_new();
   gtk_menu_item_set_submenu( GTK_MENU_ITEM( pItem ), pSub );

   hbgtk_ctrl_init( pItem );
   hb_retptr( pItem );
}

/* HGtkMenuItemNew( cTexto ) -> ítem de orden (TMenuItem) */
HB_FUNC( HGTKMENUITEMNEW )
{
   GtkWidget * pItem;
   char * szTexto;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   szTexto = hbgtk_mnemonico( HB_ISCHAR( 1 ) ? hb_parc( 1 ) : "" );
   pItem = gtk_menu_item_new_with_mnemonic( szTexto );
   g_free( szTexto );

   hbgtk_ctrl_init( pItem );
   hb_retptr( pItem );
}

/* adónde se añade un ítem: una barra, o el submenú de un ítem */
static GtkWidget * hbgtk_menu_destino( GtkWidget * pDonde )
{
   GtkWidget * pSub;

   if( GTK_IS_MENU_BAR( pDonde ) )
      return pDonde;

   if( GTK_IS_MENU_ITEM( pDonde ) )
   {
      pSub = gtk_menu_item_get_submenu( GTK_MENU_ITEM( pDonde ) );
      if( pSub && GTK_IS_MENU_SHELL( pSub ) )
         return pSub;
   }

   return NULL;
}

/* HGtkMenuAdd( pDonde, pÍtem ) — añade el ítem al final */
HB_FUNC( HGTKMENUADD )
{
   GtkWidget * pDonde = hbgtk_cpar( 1, "HGtkMenuAdd" );
   GtkWidget * pItem  = hbgtk_cpar( 2, "HGtkMenuAdd" );
   GtkWidget * pDestino;

   if( ! pDonde || ! pItem )
   {
      hb_ret();
      return;
   }

   pDestino = hbgtk_menu_destino( pDonde );
   if( ! pDestino )
   {
      hbgtk_errArgs( "HGtkMenuAdd",
                     "ese widget no admite menús dentro (¿ es un ítem "
                     "sin submenú ?)" );
      hb_ret();
      return;
    }

   gtk_menu_shell_append( GTK_MENU_SHELL( pDestino ), pItem );
   hb_ret();
}

/* ------------------------------------------------------------------ */
/* barra de botones                                                    */
/* ------------------------------------------------------------------ */

/* HGtkToolBarNew() -> barra de botones (TBar) */
HB_FUNC( HGTKTOOLBARNEW )
{
   GtkWidget * pBar;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   pBar = gtk_toolbar_new();
   gtk_toolbar_set_style( GTK_TOOLBAR( pBar ), GTK_TOOLBAR_TEXT );
   hbgtk_ctrl_init( pBar );
   hb_retptr( pBar );
}

/* HGtkToolButtonNew( cTexto ) -> botón de la barra (TButton) */
HB_FUNC( HGTKTOOLBUTTONNEW )
{
   GtkWidget * pBtn;
   char * szTexto;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   szTexto = hbgtk_mnemonico( HB_ISCHAR( 1 ) ? hb_parc( 1 ) : "" );
   pBtn = GTK_WIDGET( gtk_tool_button_new( NULL, szTexto ) );
   g_free( szTexto );

   gtk_tool_button_set_use_underline( GTK_TOOL_BUTTON( pBtn ), TRUE );
   hbgtk_ctrl_init( pBtn );
   hb_retptr( pBtn );
}

/* HGtkToolAdd( pBarra, pBotón ) — mete el botón al final de la barra */
HB_FUNC( HGTKTOOLADD )
{
   GtkWidget * pBarra = hbgtk_cpar( 1, "HGtkToolAdd" );
   GtkWidget * pBoton = hbgtk_cpar( 2, "HGtkToolAdd" );

   if( ! pBarra || ! pBoton )
   {
      hb_ret();
      return;
   }
   if( ! GTK_IS_TOOLBAR( pBarra ) )
   {
      hbgtk_errArgs( "HGtkToolAdd", "el padre no es una barra de botones" );
      hb_ret();
      return;
   }

   gtk_toolbar_insert( GTK_TOOLBAR( pBarra ),
                       GTK_TOOL_ITEM( pBoton ), -1 );
   hb_ret();
}

/* ------------------------------------------------------------------ */
/* barra de estado                                                     */
/* ------------------------------------------------------------------ */

/* HGtkStatusNew() -> barra de estado (TStatus) */
HB_FUNC( HGTKSTATUSNEW )
{
   GtkWidget * pBar;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   pBar = gtk_statusbar_new();
   hbgtk_ctrl_init( pBar );
   hb_retptr( pBar );
}

/* HGtkStatusPut( pBarra, cTexto ) — pone el mensaje (borra el anterior) */
HB_FUNC( HGTKSTATUSPUT )
{
   GtkWidget * pBar = hbgtk_cpar( 1, "HGtkStatusPut" );
   guint nCtx;

   if( ! pBar )
   {
      hb_ret();
      return;
   }
   if( ! GTK_IS_STATUSBAR( pBar ) )
   {
      hbgtk_errArgs( "HGtkStatusPut", "el widget no es una barra de estado" );
      hb_ret();
      return;
   }

   nCtx = gtk_statusbar_get_context_id( GTK_STATUSBAR( pBar ),
                                         "harbgtklin" );
   gtk_statusbar_remove_all( GTK_STATUSBAR( pBar ), nCtx );
   gtk_statusbar_push( GTK_STATUSBAR( pBar ), nCtx,
                       HB_ISCHAR( 2 ) ? hb_parc( 2 ) : "" );
   hb_ret();
}

/* HGtkStatusGet( pBarra ) -> mensaje actual.
 * GTK no ofrece leer el texto apilado: se lee la etiqueta del área de
 * mensajes, que es la que está en pantalla, así que lo devuelto es lo
 * que se ve. */
HB_FUNC( HGTKSTATUSGET )
{
   GtkWidget * pBar = hbgtk_cpar( 1, "HGtkStatusGet" );
   GtkWidget * pArea, * pEtiqueta = NULL;
   const gchar * szTexto = "";
   GList * pHijos;

   if( ! pBar || ! GTK_IS_STATUSBAR( pBar ) )
   {
      hb_retc( "" );
      return;
   }

   pArea = gtk_statusbar_get_message_area( GTK_STATUSBAR( pBar ) );
   if( pArea && GTK_IS_BOX( pArea ) )
   {
      pHijos = gtk_container_get_children( GTK_CONTAINER( pArea ) );
      if( pHijos )
         pEtiqueta = GTK_WIDGET( pHijos->data );
      g_list_free( pHijos );
   }

   if( pEtiqueta && GTK_IS_LABEL( pEtiqueta ) )
      szTexto = gtk_label_get_text( GTK_LABEL( pEtiqueta ) );

   hb_retc( szTexto );
}
