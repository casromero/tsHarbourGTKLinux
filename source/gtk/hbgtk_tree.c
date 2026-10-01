/*
 * hbgtk_tree.c — árbol de categorías (GtkTreeView sobre GtkTreeStore)
 *
 * El widget que se devuelve y el que guarda la clase es, como el
 * browse, un GtkScrolledWindow con la vista dentro (sin el marco no
 * hay barra ni se ven las ramas que no caben): las señales y el foco
 * van a la vista de dentro (hbgtk_desenvuelve).
 *
 * Los datos entran como array de arrays { texto, hijos }, donde hijos
 * es opcional y un texto suelto vale como hoja. La selección se lee o
 * escribe como la RUTA DE ETIQUETAS unida con "/" — "Clientes/Zona
 * norte" — que es lo que guarda la variable de VAR.
 *
 * Medidas de la fase 4 (banco de pruebas f6):
 *   - elegir un nodo sólo funciona si sus padres están expandidos, y
 *     colapsar la rama deselecciona lo que había dentro: por eso
 *     HGtkTreeSelect expande antes de elegir;
 *   - la selección no se puede poner antes de que la vista se muestre:
 *     GTK elige la primera fila al mapear. Lo que se pida antes se
 *     guarda como pendiente y se aplica en un giro posterior del bucle
 *     después del "map", que es cuando ya vale.
 *
 * Licencia: LGPL-3.0-or-later
 */
#include "hbgtk.h"
#include <string.h>

#define HGTK_ARBOL_INI "harbgtklin-arbol-ini"
#define HGTK_ARBOL_ON  "harbgtklin-arbol-on"

/* parámetro 1 validado: la vista del árbol, o NULL */
static GtkWidget * hbgtk_arbol_vista( const char * szProc )
{
   GtkWidget * pWidget = hbgtk_cpar( 1, szProc );
   GtkWidget * pVista;

   if( ! pWidget )
      return NULL;          /* hbgtk_cpar ya ha avisado */

   pVista = hbgtk_desenvuelve( pWidget );
   if( ! pVista || ! GTK_IS_TREE_VIEW( pVista ) )
   {
      hbgtk_errArgs( szProc, "no es un árbol" );
      return NULL;
   }
   return pVista;
}

/* ------------------------------------------------------------------ */
/* llenado                                                             */
/* ------------------------------------------------------------------ */

/*
 * hbgtk_arbol_llena( pStore, pItems, pPadre ) — añade los elementos
 * bajo pPadre (NULL = raíces). Un elemento es un texto (hoja) o un
 * array { texto [, hijos] }. Devuelve .F. si algún elemento no es de
 * esa forma.
 */
static HB_BOOL hbgtk_arbol_llena( GtkTreeStore * pStore, PHB_ITEM pItems,
                                  GtkTreeIter * pPadre )
{
   int i, n = (int) hb_arrayLen( pItems );
   HB_BOOL fBien = TRUE;

   for( i = 1; i <= n && fBien; i++ )
   {
      PHB_ITEM pElem = hb_itemArrayGet( pItems, i );

      if( ! pElem )
         return FALSE;

      if( HB_IS_STRING( pElem ) )
      {
         GtkTreeIter iter;

         gtk_tree_store_append( pStore, &iter, pPadre );
         gtk_tree_store_set( pStore, &iter, 0, hb_itemGetCPtr( pElem ), -1 );
         hb_itemRelease( pElem );
      }
      else if( HB_IS_ARRAY( pElem ) )
      {
         PHB_ITEM pTexto = hb_itemArrayGet( pElem, 1 );
         PHB_ITEM pHijos = hb_itemArrayGet( pElem, 2 );
         GtkTreeIter iter;

         if( ! pTexto || ! HB_IS_STRING( pTexto ) ||
             hb_itemGetCLen( pTexto ) < 1 )
            fBien = FALSE;
         else
         {
            gtk_tree_store_append( pStore, &iter, pPadre );
            gtk_tree_store_set( pStore, &iter, 0,
                                hb_itemGetCPtr( pTexto ), -1 );
            if( pHijos && HB_IS_ARRAY( pHijos ) &&
                hb_arrayLen( pHijos ) > 0 &&
                ! hbgtk_arbol_llena( pStore, pHijos, &iter ) )
               fBien = FALSE;
         }

         if( pTexto )
            hb_itemRelease( pTexto );
         if( pHijos )
            hb_itemRelease( pHijos );
         hb_itemRelease( pElem );
      }
      else
      {
         hb_itemRelease( pElem );
         fBien = FALSE;
      }
   }

   return fBien;
}

/* ------------------------------------------------------------------ */
/* valor: la ruta de etiquetas                                         */
/* ------------------------------------------------------------------ */

/* etiqueta del iter, ya liberada (NULL si no hay columna de texto) */
static gchar * hbgtk_arbol_texto( GtkTreeModel * pModelo,
                                  GtkTreeIter * pIter )
{
   gchar * szTexto = NULL;

   gtk_tree_model_get( pModelo, pIter, 0, &szTexto, -1 );
   return szTexto;
}

/* "Clientes/Zona sur" del nodo seleccionado; cadena vacía si no */
static gchar * hbgtk_arbol_valor( GtkTreeModel * pModelo,
                                  GtkTreeIter * pIter )
{
   GtkTreeIter iter = *pIter;
   GtkTreeIter iterPadre;
   gchar * szHojas[ 32 ];
   int nHojas = 0;
   gchar * szParte;
   GString * pRes;

   /*
    * Se sube de nivel guardando cada etiqueta; la última (la raíz)
    * queda guardada ANTES de salir, y sólo la que no cabe se suelta
    * aquí. Ojo: liberar szParte tras el bucle libero dos veces la raíz
    * (también está en szHojas), que era el doble free al mostrar.
    */
   szParte = hbgtk_arbol_texto( pModelo, &iter );
   while( szParte )
   {
      if( nHojas >= 32 )
      {
         g_free( szParte );        /* no cabe en 32: se pierde el resto */
         break;
      }

      szHojas[ nHojas++ ] = szParte;
      if( ! gtk_tree_model_iter_parent( pModelo, &iterPadre, &iter ) )
         break;                    /* ya en la raíz: szParte guardada */
      iter = iterPadre;
      szParte = hbgtk_arbol_texto( pModelo, &iter );
   }

   pRes = g_string_new( NULL );
   while( nHojas > 0 )
   {
      nHojas--;
      g_string_append( pRes, szHojas[ nHojas ] );
      if( nHojas > 0 )
         g_string_append_c( pRes, '/' );
      g_free( szHojas[ nHojas ] );
   }

   return g_string_free( pRes, FALSE );
}

/* ------------------------------------------------------------------ */
/* selección                                                           */
/* ------------------------------------------------------------------ */

/*
 * hbgtk_arbol_ruta( pModelo, szRuta ) — camino GTK de "Clientes/Zona
 * sur": va bajando de nivel buscando cada etiqueta entre los hermanos
 * del nivel. NULL si algún nivel no existe.
 */
static GtkTreePath * hbgtk_arbol_ruta( GtkTreeModel * pModelo,
                                       const char * szRuta )
{
   gchar ** aPartes;
   GtkTreePath * pPath = NULL;
   GtkTreeIter iter, iterPadre;
   gboolean fExiste, fEnPadre = FALSE;
   int i;

   if( ! szRuta || ! *szRuta )
      return NULL;

   aPartes = g_strsplit( szRuta, "/", -1 );

   for( i = 0; aPartes[ i ]; i++ )
   {
      fExiste = fEnPadre ?
                gtk_tree_model_iter_children( pModelo, &iter,
                                              &iterPadre ) :
                gtk_tree_model_get_iter_first( pModelo, &iter );

      while( fExiste )
      {
         gchar * szTexto = hbgtk_arbol_texto( pModelo, &iter );

         if( szTexto && strcmp( szTexto, aPartes[ i ] ) == 0 )
         {
            g_free( szTexto );
            break;
         }
         g_free( szTexto );
         fExiste = gtk_tree_model_iter_next( pModelo, &iter );
      }

      if( ! fExiste )
      {
         if( pPath )
            gtk_tree_path_free( pPath );
         pPath = NULL;
         break;
      }

      if( pPath )
         gtk_tree_path_free( pPath );
      pPath = gtk_tree_model_get_path( pModelo, &iter );
      iterPadre = iter;
      fEnPadre = TRUE;
   }

   g_strfreev( aPartes );
   return pPath;
}

/* expande la rama y lleva el cursor (y la selección) al nodo.
 * Devuelve .F. si la ruta no existe. */
static HB_BOOL hbgtk_arbol_elige( GtkWidget * pVista, const char * szRuta )
{
   GtkTreeModel * pModelo = gtk_tree_view_get_model(
                               GTK_TREE_VIEW( pVista ) );
   GtkTreePath * pPath = hbgtk_arbol_ruta( pModelo, szRuta );

   if( ! pPath )
      return FALSE;

   gtk_tree_view_expand_to_path( GTK_TREE_VIEW( pVista ), pPath );
   gtk_tree_view_set_cursor( GTK_TREE_VIEW( pVista ), pPath, NULL,
                             FALSE );
   gtk_tree_path_free( pPath );
   return TRUE;
}

/* la selección pendiente se aplica en un giro posterior del bucle,
 * que es cuando la vista ya se ha mostrado y la elección vale */
static gboolean hbgtk_arbol_aplica( gpointer pData )
{
   GtkWidget * pVista = (GtkWidget *) pData;
   const char * szRuta;
   gchar * szCopia;

   if( ! hbgtk_ctrl_alive( pVista ) )
      return G_SOURCE_REMOVE;

   szRuta = (const char *) g_object_get_data( G_OBJECT( pVista ),
                                              HGTK_ARBOL_INI );
   if( ! szRuta || ! *szRuta || ! gtk_widget_get_mapped( pVista ) )
      return G_SOURCE_REMOVE;

   szCopia = g_strdup( szRuta );
   g_object_set_data( G_OBJECT( pVista ), HGTK_ARBOL_INI, NULL );
   (void) hbgtk_arbol_elige( pVista, szCopia );
   g_free( szCopia );

   return G_SOURCE_REMOVE;
}

static void hbgtk_arbol_map( GtkWidget * pVista, gpointer pData )
{
   (void) pData;

   if( g_object_get_data( G_OBJECT( pVista ), HGTK_ARBOL_INI ) )
      g_idle_add( hbgtk_arbol_aplica, pVista );
}

/* ------------------------------------------------------------------ */
/* funciones del puente                                                */
/* ------------------------------------------------------------------ */

/* HGtkTreeNew() -> árbol (GtkScrolledWindow con GtkTreeView dentro) */
HB_FUNC( HGTKTREENEW )
{
   GtkTreeStore * pStore;
   GtkWidget * pVista, * pMarco;
   GtkCellRenderer * pRend;
   GtkTreeViewColumn * pCol;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   pStore  = gtk_tree_store_new( 1, G_TYPE_STRING );
   pVista  = gtk_tree_view_new_with_model( GTK_TREE_MODEL( pStore ) );
   g_object_unref( pStore );      /* la vista se queda con la suya */

   pRend = gtk_cell_renderer_text_new();
   pCol  = gtk_tree_view_column_new();
   gtk_tree_view_column_pack_start( pCol, pRend, TRUE );
   gtk_tree_view_column_set_attributes( pCol, pRend, "text", 0, NULL );
   gtk_tree_view_append_column( GTK_TREE_VIEW( pVista ), pCol );
   gtk_tree_view_set_headers_visible( GTK_TREE_VIEW( pVista ), FALSE );

   pMarco = gtk_scrolled_window_new( NULL, NULL );
   gtk_scrolled_window_set_policy( GTK_SCROLLED_WINDOW( pMarco ),
                                   GTK_POLICY_AUTOMATIC,
                                   GTK_POLICY_AUTOMATIC );
   gtk_container_add( GTK_CONTAINER( pMarco ), pVista );
   gtk_widget_show( pVista );
   gtk_widget_show( pMarco );

   if( ! g_object_get_data( G_OBJECT( pVista ), HGTK_ARBOL_ON ) )
   {
      g_signal_connect( pVista, "map", G_CALLBACK( hbgtk_arbol_map ),
                        NULL );
      g_object_set_data( G_OBJECT( pVista ), HGTK_ARBOL_ON,
                         GINT_TO_POINTER( 1 ) );
   }

   hbgtk_ctrl_init( pMarco );
   hb_retptr( pMarco );
}

/* HGtkTreeItems( pArbol, aItems ) — llena el árbol con los datos */
HB_FUNC( HGTKTREEITEMS )
{
   GtkWidget * pVista = hbgtk_arbol_vista( "HGtkTreeItems" );
   PHB_ITEM pItems = hb_param( 2, HB_IT_ARRAY );

   if( ! pVista || ! pItems )
   {
      if( pVista && ! pItems )
         hbgtk_errArgs( "HGtkTreeItems",
                        "los datos deben ser un array" );
      hb_ret();
      return;
   }

   gtk_tree_store_clear( GTK_TREE_STORE( gtk_tree_view_get_model(
                            GTK_TREE_VIEW( pVista ) ) ) );

   if( ! hbgtk_arbol_llena( GTK_TREE_STORE( gtk_tree_view_get_model(
                               GTK_TREE_VIEW( pVista ) ) ),
                            pItems, NULL ) )
      hbgtk_errArgs( "HGtkTreeItems",
                     "cada elemento debe ser un texto o { texto, hijos }" );
   hb_ret();
}

/* HGtkTreeValue( pArbol ) -> "Clientes/Zona sur", "" si no hay nada */
HB_FUNC( HGTKTREEVALUE )
{
   GtkWidget * pVista = hbgtk_arbol_vista( "HGtkTreeValue" );
   GtkTreeSelection * pSel;
   GtkTreeIter iter;
   gchar * szValor;

   if( ! pVista )
   {
      hb_retc( "" );
      return;
   }

   pSel = gtk_tree_view_get_selection( GTK_TREE_VIEW( pVista ) );
   if( ! gtk_tree_selection_get_selected( pSel, NULL, &iter ) )
   {
      hb_retc( "" );
      return;
   }

   szValor = hbgtk_arbol_valor(
                gtk_tree_view_get_model( GTK_TREE_VIEW( pVista ) ),
                &iter );
   hb_retc( szValor );
   g_free( szValor );
}

/*
 * HGtkTreeSelect( pArbol, cRuta ) -> .T. si el nodo se puso (o quedó
 * en espera, si la ventana todavía no se ha mostrado) y .F. si esa
 * ruta no existe en el árbol.
 */
HB_FUNC( HGTKTREESELECT )
{
   GtkWidget * pVista = hbgtk_arbol_vista( "HGtkTreeSelect" );
   const char * szRuta;

   if( ! pVista )
   {
      hb_retl( FALSE );
      return;
   }
   if( hb_pcount() < 2 || ! HB_ISCHAR( 2 ) )
   {
      hbgtk_errArgs( "HGtkTreeSelect", "la ruta debe ser una cadena" );
      hb_retl( FALSE );
      return;
   }

   szRuta = hb_parc( 2 );

   if( ! *szRuta )
   {
      g_object_set_data( G_OBJECT( pVista ), HGTK_ARBOL_INI, NULL );
      if( gtk_widget_get_mapped( pVista ) )
         gtk_tree_selection_unselect_all(
            gtk_tree_view_get_selection( GTK_TREE_VIEW( pVista ) ) );
      hb_retl( TRUE );
   }
   else if( gtk_widget_get_mapped( pVista ) )
      hb_retl( hbgtk_arbol_elige( pVista, szRuta ) );
   else
   {
      /* aún sin mostrar: se guarda y vale en cuanto se muestre */
      g_object_set_data_full( G_OBJECT( pVista ), HGTK_ARBOL_INI,
                              g_strdup( szRuta ), g_free );
      hb_retl( TRUE );
   }
}
