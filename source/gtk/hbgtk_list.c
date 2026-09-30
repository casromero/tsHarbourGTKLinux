/*
 * hbgtk_list.c — lista de una columna (GtkListBox) y browse
 * (GtkTreeView dentro de un marco de desplazamiento)
 *
 * La lista son filas con una etiqueta; la selección es única y se
 * señala con "selected-rows-changed" (señal sin argumentos, que es lo
 * que conecta HGtkSetSignal). El browse muestra los datos en columnas
 * con título y se selecciona con "cursor-changed". Desde la fase 3 el
 * browse también se ordena pulsando la cabecera y admite editar la
 * celda: la columna "clicked" lleva el número de columna y el editor
 * "edited" trae fila, columna y texto nuevo.
 *
 * Licencia: LGPL-3.0-or-later
 */
#include "hbgtk.h"
#include <stdlib.h>   /* atoi: la fila viene como ruta "3" */

/* ------------------------------------------------------------------ */
/* lista (TListBox)                                                    */
/* ------------------------------------------------------------------ */

/* fila n (base 1) de la lista, o NULL */
static GtkWidget * hbgtk_fila( GtkWidget * pLista, int nIndice )
{
   GtkWidget * pFila = NULL;

   if( nIndice > 0 )
   {
      GList * pFilas;

      pFilas = gtk_container_get_children( GTK_CONTAINER( pLista ) );
      pFila = (GtkWidget *) g_list_nth_data( pFilas, nIndice - 1 );
      g_list_free( pFilas );
   }

   return pFila;
}

/* HGtkListNew() -> lista de una columna */
HB_FUNC( HGTKLISTNEW )
{
   GtkWidget * pLista;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   pLista = gtk_list_box_new();
   gtk_list_box_set_selection_mode( GTK_LIST_BOX( pLista ),
                                    GTK_SELECTION_SINGLE );
   hbgtk_ctrl_init( pLista );
   hb_retptr( pLista );
}

/* HGtkListAdd( pLista, cTexto ) -> posición (base 1) de la fila nueva */
HB_FUNC( HGTKLISTADD )
{
   GtkWidget * pLista = hbgtk_cpar( 1, "HGtkListAdd" );
   GtkWidget * pFila, * pTexto;
   GList * pFilas;
   int nPos;

   if( ! pLista || ! GTK_IS_LIST_BOX( pLista ) )
   {
      hb_retni( 0 );
      return;
   }

   pFilas = gtk_container_get_children( GTK_CONTAINER( pLista ) );
   nPos = (int) g_list_length( pFilas );
   g_list_free( pFilas );

   pFila  = gtk_list_box_row_new();
   pTexto = gtk_label_new( HB_ISCHAR( 2 ) ? hb_parc( 2 ) : "" );
   gtk_label_set_xalign( GTK_LABEL( pTexto ), 0.0f );
   gtk_container_add( GTK_CONTAINER( pFila ), pTexto );
   gtk_widget_show( pTexto );

   gtk_list_box_insert( GTK_LIST_BOX( pLista ), pFila, -1 );
   gtk_widget_show( pFila );

   hb_retni( nPos + 1 );
}

/* HGtkListClear( pLista ) — deja la lista vacía */
HB_FUNC( HGTKLISTCLEAR )
{
   GtkWidget * pLista = hbgtk_cpar( 1, "HGtkListClear" );
   GList * pFilas;

   if( ! pLista || ! GTK_IS_LIST_BOX( pLista ) )
   {
      hb_ret();
      return;
   }

   pFilas = gtk_container_get_children( GTK_CONTAINER( pLista ) );
   g_list_free_full( pFilas, (GDestroyNotify) gtk_widget_destroy );
   hb_ret();
}

/* HGtkListSelect( pLista, nFila ) — selecciona (0: ninguna) */
HB_FUNC( HGTKLISTSELECT )
{
   GtkWidget * pLista = hbgtk_cpar( 1, "HGtkListSelect" );
   GtkWidget * pFila;

   if( ! pLista || ! GTK_IS_LIST_BOX( pLista ) )
   {
      hb_ret();
      return;
   }

   pFila = hbgtk_fila( pLista, hb_parni( 2 ) );
   if( pFila )
      gtk_list_box_select_row( GTK_LIST_BOX( pLista ),
                               GTK_LIST_BOX_ROW( pFila ) );
   else
      gtk_list_box_unselect_all( GTK_LIST_BOX( pLista ) );
   hb_ret();
}

/* HGtkListValue( pLista ) -> fila seleccionada (base 1), 0 si ninguna */
HB_FUNC( HGTKLISTVALUE )
{
   GtkWidget * pLista = hbgtk_cpar( 1, "HGtkListValue" );
   GtkListBoxRow * pFila;

   if( ! pLista || ! GTK_IS_LIST_BOX( pLista ) )
   {
      hb_retni( 0 );
      return;
   }

   pFila = gtk_list_box_get_selected_row( GTK_LIST_BOX( pLista ) );
   hb_retni( pFila ? gtk_list_box_row_get_index( pFila ) + 1 : 0 );
}

/* ------------------------------------------------------------------ */
/* browse (TBrowse): GtkTreeView dentro de un marco de desplazamiento  */
/* ------------------------------------------------------------------ */
/*
 * El widget que devuelve HGtkTreeViewNew —y que la clase lleva en su
 * hWnd— es un GtkScrolledWindow con el GtkTreeView dentro: sin el
 * marco, las filas que no caben no se ven ni se desplazan. Las
 * funciones desenvuelven el marco para trabajar con la vista, y el
 * foco se pone igual (hbgtk_desenvuelve, en hbgtk_ctrl.c).
 *
 * El orden por columna lo decide Harbour, no el modelo de GTK: así el
 * array de DATA y los números de registro siguen mandando y una
 * edición sigue cayendo en su registro. La flecha de orden la pone
 * HGtkTreeViewOrdenMarca.
 *
 * La edición es la de GTK: celda con "editable" y señal "edited", que
 * trae la fila (como ruta, que se pasa en base 1), la columna y el
 * texto nuevo. El modelo no se actualiza solo: lo hace la clase con
 * HGtkTreeViewPoner.
 */

/* claves de los codeblocks sujetos a una columna o a un editor */
#define HGTK_ORDEN_KEY  "harbgtklin-orden"
#define HGTK_ORDEN_N    "harbgtklin-orden-n"
#define HGTK_ORDEN_ON   "harbgtklin-orden-on"
#define HGTK_EDIT_KEY   "harbgtklin-editar"
#define HGTK_EDIT_N     "harbgtklin-editar-n"
#define HGTK_EDIT_ON    "harbgtklin-editar-on"

/* se suelta el bloque al acabarse la columna o el editor: no son
 * widgets y no pasan por hbgtk_on_ctrl_destroy */
static void hbgtk_bloque_final( gpointer pData )
{
   if( pData )
      hb_gcGripDrop( (PHB_ITEM) pData );
}

/* guarda el codeblock del parámetro iPar en la clave del objeto; al
 * sustituirlo GObject avisa y se suelta el anterior */
static void hbgtk_bloque_gobj( GObject * pObj, const char * szClave, int iPar )
{
   if( hb_pcount() >= iPar && HB_ISBLOCK( iPar ) )
   {
      PHB_ITEM pBloque = hb_itemNew( hb_param( iPar, HB_IT_BLOCK ) );

      hb_gcGripGet( pBloque );
      g_object_set_data_full( pObj, szClave, pBloque, hbgtk_bloque_final );
   }
   else
      g_object_set_data_full( pObj, szClave, NULL, hbgtk_bloque_final );
}

/* se pulsó la cabecera: su bloque recibe el número de columna */
static void hbgtk_on_orden( GtkTreeViewColumn * pCol, gpointer pData )
{
   PHB_ITEM pBloque = (PHB_ITEM) g_object_get_data( G_OBJECT( pCol ),
                                                    HGTK_ORDEN_KEY );
   PHB_ITEM pArg;

   (void) pData;
   if( ! pBloque || ! HB_IS_BLOCK( pBloque ) )
      return;

   pArg = hb_itemNew( NULL );
   hb_itemPutNI( pArg, GPOINTER_TO_INT( g_object_get_data( G_OBJECT( pCol ),
                                                           HGTK_ORDEN_N ) ) );
   hb_vmEvalBlockV( pBloque, 1, pArg );
   hb_itemRelease( pArg );
}

/* se terminó de editar una celda: su bloque recibe fila, columna y
 * el texto nuevo */
static void hbgtk_on_editado( GtkCellRenderer * pRend, const gchar * szRuta,
                              const gchar * szTexto, gpointer pData )
{
   PHB_ITEM pBloque = (PHB_ITEM) g_object_get_data( G_OBJECT( pRend ),
                                                    HGTK_EDIT_KEY );
   PHB_ITEM pFila, pCol, pTxt;

   (void) pData;
   if( ! pBloque || ! HB_IS_BLOCK( pBloque ) || ! szRuta )
      return;

   pFila = hb_itemNew( NULL );
   pCol  = hb_itemNew( NULL );
   pTxt  = hb_itemNew( NULL );
   hb_itemPutNI( pFila, atoi( szRuta ) + 1 );
   hb_itemPutNI( pCol, GPOINTER_TO_INT( g_object_get_data( G_OBJECT( pRend ),
                                                           HGTK_EDIT_N ) ) );
   hb_itemPutC( pTxt, szTexto ? szTexto : "" );
   hb_vmEvalBlockV( pBloque, 3, pFila, pCol, pTxt );
   hb_itemRelease( pFila );
   hb_itemRelease( pCol );
   hb_itemRelease( pTxt );
}

/* parámetro 1 desenvuelto y comprobado: la vista, o NULL */
static GtkWidget * hbgtk_vista_par( const char * szProc )
{
   GtkWidget * pWidget = hbgtk_cpar( 1, szProc );
   GtkWidget * pVista;

   if( ! pWidget )
      return NULL;        /* hbgtk_cpar ya ha avisado */

   pVista = hbgtk_desenvuelve( pWidget );
   if( ! pVista || ! GTK_IS_TREE_VIEW( pVista ) )
   {
      hbgtk_errArgs( szProc, "no es un browse" );
      return NULL;
   }
   return pVista;
}

/* HGtkTreeViewNew( aCabeceras ) -> browse (GtkScrolledWindow con el
 * GtkTreeView dentro) */
HB_FUNC( HGTKTREEVIEWNEW )
{
   PHB_ITEM pCabeceras = hb_param( 1, HB_IT_ARRAY );
   GtkListStore * pModelo;
   GtkWidget * pVista, * pMarco;
   GType * aTipos;
   int nCols, i;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }
   nCols = pCabeceras ? (int) hb_arrayLen( pCabeceras ) : 0;
   if( nCols < 1 )
   {
      hbgtk_errArgs( "HGtkTreeViewNew",
                     "hace falta al menos una cabecera" );
      hb_retptr( NULL );
      return;
   }

   aTipos = g_new( GType, nCols );
   for( i = 0; i < nCols; i++ )
      aTipos[ i ] = G_TYPE_STRING;

   pModelo = gtk_list_store_newv( nCols, aTipos );
   g_free( aTipos );

   pVista = gtk_tree_view_new_with_model( GTK_TREE_MODEL( pModelo ) );
   g_object_unref( pModelo );   /* la vista se queda con la suya */

   for( i = 0; i < nCols; i++ )
   {
      PHB_ITEM pDato = hb_itemArrayGet( pCabeceras, i + 1 );
      GtkCellRenderer * pRend = gtk_cell_renderer_text_new();
      GtkTreeViewColumn * pCol = gtk_tree_view_column_new();

      gtk_tree_view_column_set_title(
         pCol, ( pDato && HB_IS_STRING( pDato ) ) ?
                  hb_itemGetCPtr( pDato ) : "" );
      if( pDato )
         hb_itemRelease( pDato );

      gtk_tree_view_column_pack_start( pCol, pRend, TRUE );
      gtk_tree_view_column_set_attributes( pCol, pRend, "text", i, NULL );
      gtk_tree_view_column_set_resizable( pCol, TRUE );
      /* la cabecera se puede pulsar: el orden lo pone la clase */
      gtk_tree_view_column_set_clickable( pCol, TRUE );
      gtk_tree_view_append_column( GTK_TREE_VIEW( pVista ), pCol );
   }

   gtk_tree_view_set_headers_visible( GTK_TREE_VIEW( pVista ), TRUE );

   /* el marco de desplazamiento: sin él no se ven las filas que
    * no caben y no hay barra */
   pMarco = gtk_scrolled_window_new( NULL, NULL );
   gtk_scrolled_window_set_policy( GTK_SCROLLED_WINDOW( pMarco ),
                                   GTK_POLICY_AUTOMATIC,
                                   GTK_POLICY_AUTOMATIC );
   gtk_scrolled_window_set_shadow_type( GTK_SCROLLED_WINDOW( pMarco ),
                                        GTK_SHADOW_IN );
   gtk_container_add( GTK_CONTAINER( pMarco ), pVista );
   gtk_widget_show( pVista );
   gtk_widget_show( pMarco );

   hbgtk_ctrl_init( pMarco );
   hb_retptr( pMarco );
}

/* HGtkTreeViewAdd( pVista, aCampos ) -> número de fila (base 1) */
HB_FUNC( HGTKTREEVIEWADD )
{
   GtkWidget * pVista = hbgtk_vista_par( "HGtkTreeViewAdd" );
   PHB_ITEM pCampos = hb_param( 2, HB_IT_ARRAY );
   GtkListStore * pModelo;
   GtkTreeIter iter;
   int nCols, i;

   if( ! pVista || ! pCampos )
   {
      hb_retni( 0 );
      return;
   }

   pModelo = GTK_LIST_STORE( gtk_tree_view_get_model(
                                GTK_TREE_VIEW( pVista ) ) );
   nCols = (int) hb_arrayLen( pCampos );
   if( nCols > (int) gtk_tree_view_get_n_columns( GTK_TREE_VIEW( pVista ) ) )
      nCols = gtk_tree_view_get_n_columns( GTK_TREE_VIEW( pVista ) );

   gtk_list_store_append( pModelo, &iter );
   for( i = 1; i <= nCols; i++ )
   {
      PHB_ITEM pDato = hb_itemArrayGet( pCampos, i );
      const char * szTexto = "";

      if( pDato )
      {
         if( HB_IS_STRING( pDato ) )
            szTexto = hb_itemGetCPtr( pDato );
         hb_itemRelease( pDato );
      }
      gtk_list_store_set( pModelo, &iter, i - 1, szTexto, -1 );
   }

   hb_retni( (int) gtk_tree_model_iter_n_children(
                GTK_TREE_MODEL( pModelo ), NULL ) );
}

/* HGtkTreeViewClear( pVista ) — borra todas las filas */
HB_FUNC( HGTKTREEVIEWCLEAR )
{
   GtkWidget * pVista = hbgtk_vista_par( "HGtkTreeViewClear" );

   if( ! pVista )
   {
      hb_ret();
      return;
   }

   gtk_list_store_clear( GTK_LIST_STORE( gtk_tree_view_get_model(
                            GTK_TREE_VIEW( pVista ) ) ) );
   hb_ret();
}

/* HGtkTreeViewSelect( pVista, nFila ) — lleva el cursor a la fila */
HB_FUNC( HGTKTREEVIEWSELECT )
{
   GtkWidget * pVista = hbgtk_vista_par( "HGtkTreeViewSelect" );
   GtkTreePath * pRuta;
   int nFila;

   if( ! pVista )
   {
      hb_ret();
      return;
   }

   nFila = hb_parni( 2 );
   if( nFila < 1 )
   {
      gtk_tree_selection_unselect_all( gtk_tree_view_get_selection(
                                          GTK_TREE_VIEW( pVista ) ) );
      hb_ret();
      return;
   }

   pRuta = gtk_tree_path_new_from_indices( nFila - 1, -1 );
   gtk_tree_view_set_cursor( GTK_TREE_VIEW( pVista ), pRuta, NULL, FALSE );
   gtk_tree_view_scroll_to_cell( GTK_TREE_VIEW( pVista ), pRuta, NULL,
                                 FALSE, 0.0f, 0.0f );
   gtk_tree_path_free( pRuta );
   hb_ret();
}

/* HGtkTreeViewValue( pVista ) -> fila seleccionada (base 1), 0 si ninguna */
HB_FUNC( HGTKTREEVIEWVALUE )
{
   GtkWidget * pVista = hbgtk_vista_par( "HGtkTreeViewValue" );
   GtkTreeSelection * pSel;
   GtkTreeModel * pModelo;
   GtkTreeIter iter;
   GtkTreePath * pRuta;
   int nFila = 0;

   if( ! pVista )
   {
      hb_retni( 0 );
      return;
   }

   pSel = gtk_tree_view_get_selection( GTK_TREE_VIEW( pVista ) );
   if( gtk_tree_selection_get_selected( pSel, &pModelo, &iter ) )
   {
      pRuta = gtk_tree_model_get_path( pModelo, &iter );
      if( pRuta )
      {
         gint * aIndices = gtk_tree_path_get_indices( pRuta );
         if( aIndices )
            nFila = aIndices[ 0 ] + 1;
         gtk_tree_path_free( pRuta );
      }
   }

   hb_retni( nFila );
}

/* HGtkTreeViewPoner( pVista, nFila, nCol, cTexto ) — pone el texto de
 * una celda del modelo. La clase lo usa al rellenar y, sobre todo, al
 * editar: la señal "edited" no cambia el modelo por sí sola. */
HB_FUNC( HGTKTREEVIEWPONER )
{
   GtkWidget * pVista = hbgtk_vista_par( "HGtkTreeViewPoner" );
   GtkListStore * pModelo;
   GtkTreeIter iter;
   GtkTreePath * pRuta;
   int nFila, nCol;

   if( ! pVista )
   {
      hb_ret();
      return;
   }

   nFila = hb_parni( 2 );
   nCol  = hb_parni( 3 );
   if( nFila < 1 || nCol < 1 ||
       nCol > gtk_tree_view_get_n_columns( GTK_TREE_VIEW( pVista ) ) )
   {
      hb_ret();
      return;
   }

   pModelo = GTK_LIST_STORE( gtk_tree_view_get_model(
                                GTK_TREE_VIEW( pVista ) ) );
   pRuta = gtk_tree_path_new_from_indices( nFila - 1, -1 );
   if( gtk_tree_model_get_iter( GTK_TREE_MODEL( pModelo ), &iter, pRuta ) )
      gtk_list_store_set( pModelo, &iter, nCol - 1,
                          HB_ISCHAR( 4 ) ? hb_parc( 4 ) : "", -1 );
   gtk_tree_path_free( pRuta );
   hb_ret();
}

/* HGtkTreeViewOrden( pVista, nCol, bBloque ) — la cabecera de la
 * columna queda conectada: al pulsarla se evalúa bBloque con su número
 * de columna. Varias llamadas con el mismo bloque sólo conectan una
 * vez. */
HB_FUNC( HGTKTREEVIEWORDEN )
{
   GtkWidget * pVista = hbgtk_vista_par( "HGtkTreeViewOrden" );
   GtkTreeViewColumn * pCol;
   int nCol;

   if( ! pVista )
   {
      hb_ret();
      return;
   }

   nCol = hb_parni( 2 );
   pCol = gtk_tree_view_get_column( GTK_TREE_VIEW( pVista ), nCol - 1 );
   if( ! pCol )
   {
      hb_ret();
      return;
   }

   gtk_tree_view_column_set_clickable( pCol, TRUE );
   g_object_set_data( G_OBJECT( pCol ), HGTK_ORDEN_N,
                      GINT_TO_POINTER( nCol ) );
   hbgtk_bloque_gobj( G_OBJECT( pCol ), HGTK_ORDEN_KEY, 3 );

   if( ! g_object_get_data( G_OBJECT( pCol ), HGTK_ORDEN_ON ) )
   {
      g_object_set_data( G_OBJECT( pCol ), HGTK_ORDEN_ON,
                         GINT_TO_POINTER( 1 ) );
      g_signal_connect( pCol, "clicked", G_CALLBACK( hbgtk_on_orden ), NULL );
   }
   hb_ret();
}

/* HGtkTreeViewOrdenMarca( pVista, nCol [, lAsc ] ) — flecha de orden
 * en la columna nCol y ninguna en las demás (nCol 0: ninguna). */
HB_FUNC( HGTKTREEVIEWORDENMARCA )
{
   GtkWidget * pVista = hbgtk_vista_par( "HGtkTreeViewOrdenMarca" );
   GtkTreeViewColumn * pCol;
   int nCols, i, nCol;

   if( ! pVista )
   {
      hb_ret();
      return;
   }

   nCol  = hb_parni( 2 );
   nCols = gtk_tree_view_get_n_columns( GTK_TREE_VIEW( pVista ) );
   for( i = 0; i < nCols; i++ )
   {
      pCol = gtk_tree_view_get_column( GTK_TREE_VIEW( pVista ), i );
      if( pCol && i + 1 == nCol )
      {
         gtk_tree_view_column_set_sort_order( pCol, hb_parl( 3 ) ?
                                              GTK_SORT_ASCENDING :
                                              GTK_SORT_DESCENDING );
         gtk_tree_view_column_set_sort_indicator( pCol, TRUE );
      }
      else if( pCol )
         gtk_tree_view_column_set_sort_indicator( pCol, FALSE );
   }
   hb_ret();
}

/* HGtkTreeViewEditar( pVista [, bBloque ] ) — las celdas de texto
 * quedan editables (F2 o doble clic) y, al terminar, se evalúa
 * bBloque con fila, columna y texto nuevo. */
HB_FUNC( HGTKTREEVIEWEDITAR )
{
   GtkWidget * pVista = hbgtk_vista_par( "HGtkTreeViewEditar" );
   int nCols, i;

   if( ! pVista )
   {
      hb_ret();
      return;
   }

   nCols = gtk_tree_view_get_n_columns( GTK_TREE_VIEW( pVista ) );
   for( i = 0; i < nCols; i++ )
   {
      GtkTreeViewColumn * pCol = gtk_tree_view_get_column(
                                    GTK_TREE_VIEW( pVista ), i );
      GList * pCeldas, * p;

      if( ! pCol )
         continue;

      pCeldas = gtk_cell_layout_get_cells( GTK_CELL_LAYOUT( pCol ) );
      for( p = pCeldas; p; p = p->next )
      {
         GtkCellRenderer * pRend = GTK_CELL_RENDERER( p->data );

         if( ! GTK_IS_CELL_RENDERER_TEXT( pRend ) )
            continue;

         g_object_set( pRend, "editable", TRUE, NULL );
         g_object_set_data( G_OBJECT( pRend ), HGTK_EDIT_N,
                            GINT_TO_POINTER( i + 1 ) );
         hbgtk_bloque_gobj( G_OBJECT( pRend ), HGTK_EDIT_KEY, 2 );

         if( ! g_object_get_data( G_OBJECT( pRend ), HGTK_EDIT_ON ) )
         {
            g_object_set_data( G_OBJECT( pRend ), HGTK_EDIT_ON,
                               GINT_TO_POINTER( 1 ) );
            g_signal_connect( pRend, "edited",
                              G_CALLBACK( hbgtk_on_editado ), NULL );
         }
      }
      g_list_free( pCeldas );
   }
   hb_ret();
}
