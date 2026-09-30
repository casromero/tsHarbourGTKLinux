/*
 * hbgtk_list.c — lista de una columna (GtkListBox) y browse de solo
 * lectura (GtkTreeView con un GtkListStore de cadenas)
 *
 * La lista son filas con una etiqueta; la selección es única y se
 * señala con "selected-rows-changed" (señal sin argumentos, que es lo
 * que conecta HGtkSetSignal). El browse muestra los datos en columnas
 * con título y se selecciona con "cursor-changed", que tampoco lleva
 * argumentos. Ninguno de los dos admite escribir en la celda: la
 * edición llega en la fase 3.
 *
 * Licencia: LGPL-3.0-or-later
 */
#include "hbgtk.h"

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
/* browse de solo lectura (TBrowse)                                    */
/* ------------------------------------------------------------------ */

/* HGtkTreeViewNew( aCabeceras ) -> browse con una columna por título */
HB_FUNC( HGTKTREEVIEWNEW )
{
   PHB_ITEM pCabeceras = hb_param( 1, HB_IT_ARRAY );
   GtkListStore * pModelo;
   GtkWidget * pVista;
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
      gtk_tree_view_append_column( GTK_TREE_VIEW( pVista ), pCol );
   }

   gtk_tree_view_set_headers_visible( GTK_TREE_VIEW( pVista ), TRUE );
   hbgtk_ctrl_init( pVista );
   hb_retptr( pVista );
}

/* HGtkTreeViewAdd( pVista, aCampos ) -> número de fila (base 1) */
HB_FUNC( HGTKTREEVIEWADD )
{
   GtkWidget * pVista = hbgtk_cpar( 1, "HGtkTreeViewAdd" );
   PHB_ITEM pCampos = hb_param( 2, HB_IT_ARRAY );
   GtkListStore * pModelo;
   GtkTreeIter iter;
   int nCols, i;

   if( ! pVista || ! GTK_IS_TREE_VIEW( pVista ) || ! pCampos )
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
   GtkWidget * pVista = hbgtk_cpar( 1, "HGtkTreeViewClear" );

   if( ! pVista || ! GTK_IS_TREE_VIEW( pVista ) )
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
   GtkWidget * pVista = hbgtk_cpar( 1, "HGtkTreeViewSelect" );
   GtkTreePath * pRuta;
   int nFila;

   if( ! pVista || ! GTK_IS_TREE_VIEW( pVista ) )
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
   GtkWidget * pVista = hbgtk_cpar( 1, "HGtkTreeViewValue" );
   GtkTreeSelection * pSel;
   GtkTreeModel * pModelo;
   GtkTreeIter iter;
   GtkTreePath * pRuta;
   int nFila = 0;

   if( ! pVista || ! GTK_IS_TREE_VIEW( pVista ) )
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
