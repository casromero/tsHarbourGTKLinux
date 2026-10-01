/*
 * hbgtk_tabs.c — panel con pestañas (GtkNotebook) y sus páginas
 *
 * Un panel (TTabs) es un widget como cualquier otro: se coloca en el
 * fijo de su ventana con AT y SIZE. Cada página (TPage) es una caja
 * con un GtkFixed dentro, con la clave de posicionamiento del padre
 * apuntando a ese fijo, de modo que los controles declarados "OF la
 * página" se colocan con coordenadas relativas a ella, igual que en un
 * grupo. El fijo va con expand y fill: sin eso se quedaría con su
 * tamaño natural y todo lo que estuviera por debajo quedaría
 * recortado (medido en el banco de pruebas de la fase 4).
 *
 * Al cambiar de pestaña se evalúa el bloque guardado con
 * HGtkTabsAction, que es el que escribe la variable de VAR. La señal
 * "switch-page" trae argumentos (página y número), así que no sirve
 * el conector genérico de HGtkSetSignal: éste recibe la señal como
 * (widget, dato) y tomaría la página por el dato.
 *
 * Licencia: LGPL-3.0-or-later
 */
#include "hbgtk.h"

#define HGTK_PESTANA_KEY "harbgtklin-pestana"
#define HGTK_PESTANA_ON  "harbgtklin-pestana-on"

/* se suelta el bloque al destruir el panel */
static void hbgtk_pestana_final( gpointer pData )
{
   if( pData )
      hb_gcGripDrop( (PHB_ITEM) pData );
}

/* cambió de pestaña: le toca al bloque de la clase.
 *
 * IMPORTANTE (medido en la fase 4): "switch-page" se emite ANTES de
 * que get_current_page() devuelva la página nueva, así que el número
 * hay que tomarlo del argumento de la señal (page_num, base 0) y no
 * leyendo el panel: con el panel se leería la página anterior. */
static void hbgtk_on_pestana( GtkNotebook * pNota, GtkWidget * pPag,
                              guint nPag, gpointer pData )
{
   PHB_ITEM pBloque;

   (void) pPag;
   (void) pData;

   pBloque = (PHB_ITEM) g_object_get_data( G_OBJECT( pNota ),
                                           HGTK_PESTANA_KEY );
   if( pBloque && HB_IS_BLOCK( pBloque ) )
   {
      PHB_ITEM pArg = hb_itemPutNI( NULL, (HB_LONG) ( nPag + 1 ) );

      hb_vmEvalBlockV( pBloque, 1, pArg );
      hb_itemRelease( pArg );
   }
}

/* parámetro 1 validado: el panel de pestañas, o NULL */
static GtkWidget * hbgtk_pestana_par( const char * szProc )
{
   GtkWidget * pNota = hbgtk_cpar( 1, szProc );

   if( ! pNota || ! GTK_IS_NOTEBOOK( pNota ) )
   {
      if( pNota )
         hbgtk_errArgs( szProc, "ese widget no es un panel de pestañas" );
      return NULL;
   }
   return pNota;
}

/* HGtkTabsNew() -> panel con pestañas (TTabs) */
HB_FUNC( HGTKTABSNEW )
{
   GtkWidget * pNota;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   pNota = gtk_notebook_new();
   hbgtk_ctrl_init( pNota );
   hb_retptr( pNota );
}

/* HGtkPageNew( pNota, cTitulo ) -> widget de la página (TPage) */
HB_FUNC( HGTKPAGENEW )
{
   GtkWidget * pNota = hbgtk_pestana_par( "HGtkPageNew" );
   GtkWidget * pPagina, * pFijo;

   if( ! pNota )
   {
      hb_retptr( NULL );
      return;
   }

   pPagina = gtk_box_new( GTK_ORIENTATION_VERTICAL, 0 );
   pFijo   = gtk_fixed_new();
   gtk_box_pack_start( GTK_BOX( pPagina ), pFijo, TRUE, TRUE, 0 );
   gtk_notebook_append_page( GTK_NOTEBOOK( pNota ), pPagina,
                             gtk_label_new( hb_pcount() >= 2 &&
                                            HB_ISCHAR( 2 ) ?
                                            hb_parc( 2 ) : "" ) );
   hbgtk_contenedor_pon( pPagina, pFijo );
   gtk_widget_show( pPagina );
   gtk_widget_show( pFijo );

   hbgtk_ctrl_init( pPagina );
   hb_retptr( pPagina );
}

/* HGtkTabsPage( pNota ) -> pestaña visible (base 1), 0 si no hay */
HB_FUNC( HGTKTABSPAGE )
{
   GtkWidget * pNota = hbgtk_pestana_par( "HGtkTabsPage" );
   int nPag;

   if( ! pNota )
   {
      hb_retni( 0 );
      return;
   }

   nPag = gtk_notebook_get_current_page( GTK_NOTEBOOK( pNota ) );
   hb_retni( nPag < 0 ? 0 : nPag + 1 );
}

/* HGtkTabsSelect( pNota, nPag ) — lleva el panel a la pestaña n (base
 * 1; fuera de rango no hace nada, como en GTK). Dispara "switch-page",
 * que es lo que sincroniza la variable de VAR. */
HB_FUNC( HGTKTABSSELECT )
{
   GtkWidget * pNota = hbgtk_pestana_par( "HGtkTabsSelect" );
   int nPag;

   if( ! pNota )
   {
      hb_ret();
      return;
   }

   nPag = hb_parni( 2 );
   if( nPag >= 1 && nPag <= gtk_notebook_get_n_pages(
                         GTK_NOTEBOOK( pNota ) ) )
      gtk_notebook_set_current_page( GTK_NOTEBOOK( pNota ), nPag - 1 );
   hb_ret();
}

/* HGtkTabsAction( pNota, bBloque ) — bloque que se evalúa al cambiar
 * de pestaña con la pestaña nueva (base 1) como argumento; sin bloque
 * no hace nada. */
HB_FUNC( HGTKTABSACTION )
{
   GtkWidget * pNota = hbgtk_pestana_par( "HGtkTabsAction" );

   if( ! pNota )
   {
      hb_ret();
      return;
   }

   hbgtk_pestana_final( g_object_get_data( G_OBJECT( pNota ),
                                           HGTK_PESTANA_KEY ) );
   g_object_set_data( G_OBJECT( pNota ), HGTK_PESTANA_KEY, NULL );

   if( hb_pcount() >= 2 && HB_ISBLOCK( 2 ) )
   {
      PHB_ITEM pBloque = hb_itemNew( hb_param( 2, HB_IT_BLOCK ) );

      hb_gcGripGet( pBloque );
      g_object_set_data_full( G_OBJECT( pNota ), HGTK_PESTANA_KEY,
                              pBloque, hbgtk_pestana_final );
   }

   if( ! g_object_get_data( G_OBJECT( pNota ), HGTK_PESTANA_ON ) )
   {
      g_signal_connect( pNota, "switch-page",
                        G_CALLBACK( hbgtk_on_pestana ), NULL );
      g_object_set_data( G_OBJECT( pNota ), HGTK_PESTANA_ON,
                         GINT_TO_POINTER( 1 ) );
   }
   hb_ret();
}
