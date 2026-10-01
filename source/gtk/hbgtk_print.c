/*
 * hbgtk_print.c — listado de texto por GtkPrintOperation
 *
 * Una sola función del puente: HGtkPrintRun coge el título, la
 * fuente, el camino (con diálogo o exportando a fichero) y las líneas
 * del listado, y hace lo demás GTK:
 *
 *   - "begin-print" mide la fuente en la página y decide cuántas
 *     caben y cuántas páginas hay;
 *   - "draw-page" dibuja, con Pango sobre el Cairo del contexto, las
 *     líneas que le tocan a cada página (si una no cabe en el ancho
 *     imprimible, se corta con puntos suspensivos);
 *   - con camino de exportación no se muestra ningún diálogo y sale
 *     un PDF (o PS) por el backend "file" de impresión de GTK: es el
 *     camino que se comprueba solo, sin impresora ni ventana.
 *
 * Medido en el banco de pruebas de la fase 4: 120 líneas salen en 2
 * páginas, con cabecera %PDF y cierre %%EOF.
 *
 * Licencia: LGPL-3.0-or-later
 */
#include "hbgtk.h"
#include <string.h>

/* mismos valores que HGTK_PRINT_DIALOGO y HGTK_PRINT_EXPORTA */
#define HGTK_PRINT_DIALOGO 0
#define HGTK_PRINT_EXPORTA 1

/* el listado mientras corre la operación */
typedef struct
{
   gchar ** aLineas;      /* NULL-terminado */
   int      nLineas;
   int      nPorPagina;
   gchar *  szFuente;
} HGTK_LISTADO;

/* begin-print: medir y decir cuántas páginas */
static void hbgtk_print_comienza( GtkPrintOperation * pOp,
                                  GtkPrintContext * pCtx, gpointer pData )
{
   HGTK_LISTADO * pListado = (HGTK_LISTADO *) pData;
   PangoLayout * pLayout = gtk_print_context_create_pango_layout( pCtx );
   PangoFontDescription * pDesc =
      pango_font_description_from_string( pListado->szFuente );
   int nAlto = 16;
   double dUtil;

   pango_layout_set_font_description( pLayout, pDesc );
   pango_layout_set_text( pLayout, "Mg", -1 );
   pango_layout_get_pixel_size( pLayout, NULL, &nAlto );
   if( nAlto < 1 )
      nAlto = 16;

   /* el alto del contexto es ya el área imprimible, sin márgenes */
   dUtil = gtk_print_context_get_height( pCtx );
   pListado->nPorPagina = (int) ( dUtil / nAlto );
   if( pListado->nPorPagina < 1 )
      pListado->nPorPagina = 1;

   gtk_print_operation_set_n_pages(
      pOp, ( pListado->nLineas + pListado->nPorPagina - 1 ) /
           pListado->nPorPagina );

   g_object_unref( pLayout );
   pango_font_description_free( pDesc );
}

/* draw-page: las líneas que le tocan a esta página */
static void hbgtk_print_pagina( GtkPrintOperation * pOp,
                                GtkPrintContext * pCtx, gint nPagina,
                                gpointer pData )
{
   HGTK_LISTADO * pListado = (HGTK_LISTADO *) pData;
   cairo_t * pCairo = gtk_print_context_get_cairo_context( pCtx );
   PangoLayout * pLayout = gtk_print_context_create_pango_layout( pCtx );
   PangoFontDescription * pDesc =
      pango_font_description_from_string( pListado->szFuente );
   GtkPageSetup * pSetup = gtk_print_context_get_page_setup( pCtx );
   double dY;
   int i, nPrimero;

   (void) pOp;

   pango_layout_set_font_description( pLayout, pDesc );
   pango_layout_set_width( pLayout,
                           (int) ( gtk_print_context_get_width( pCtx ) *
                                   PANGO_SCALE ) );
   pango_layout_set_ellipsize( pLayout, PANGO_ELLIPSIZE_END );

   nPrimero = nPagina * pListado->nPorPagina;
   dY = gtk_page_setup_get_top_margin( pSetup, GTK_UNIT_POINTS );

   for( i = nPrimero;
        i < nPrimero + pListado->nPorPagina && i < pListado->nLineas;
        i++ )
   {
      int nAlto = 16;

      pango_layout_set_text( pLayout, pListado->aLineas[ i ], -1 );
      pango_layout_get_pixel_size( pLayout, NULL, &nAlto );
      cairo_move_to( pCairo,
                     gtk_page_setup_get_left_margin( pSetup,
                                                     GTK_UNIT_POINTS ),
                     dY );
      pango_cairo_show_layout( pCairo, pLayout );
      dY += nAlto;
   }

   g_object_unref( pLayout );
   pango_font_description_free( pDesc );
}

/* el resultado real de la operación (imprimió, canceló o falló) */
static void hbgtk_print_hecho( GtkPrintOperation * pOp,
                               GtkPrintOperationResult nResultado,
                               gpointer pData )
{
   (void) pOp;
   *(int *) pData = (int) nResultado;
}

/*
 * HGtkPrintRun( cTitulo, cFuente, nAccion, cFichero, aLineas ) -> .T.
 *   nAccion 0 = con el diálogo de impresión de GTK
 *           1 = exportar a cFichero (según la extensión: .pdf...)
 * Devuelve .T. si se imprimió o se exportó; .F. si el usuario
 * canceló o si GTK encontró un error (que queda en el ErrorBlock).
 */
HB_FUNC( HGTKPRINTRUN )
{
   HGTK_LISTADO Listado;
   GtkPrintOperation * pOp;
   GError * pError = NULL;
   PHB_ITEM pLineas;
   gboolean fOk;
   int nAccion, nResultado = (int) GTK_PRINT_OPERATION_RESULT_ERROR;
   int i, nTotal;

   if( hb_pcount() < 5 || ! HB_ISCHAR( 1 ) || ! HB_ISCHAR( 2 ) ||
       ! HB_ISNUM( 3 ) || ! HB_ISCHAR( 4 ) )
   {
      hbgtk_errArgs( "HGtkPrintRun",
                     "se esperaba (cTitulo, cFuente, nAccion,"
                     " cFichero, aLineas)" );
      hb_retl( FALSE );
      return;
   }

   nAccion = hb_parni( 3 );
   if( nAccion != HGTK_PRINT_DIALOGO && nAccion != HGTK_PRINT_EXPORTA )
   {
      hbgtk_errArgs( "HGtkPrintRun", "camino de impresión no válido" );
      hb_retl( FALSE );
      return;
   }
   if( nAccion == HGTK_PRINT_EXPORTA && hb_parclen( 4 ) < 1 )
   {
      hbgtk_errArgs( "HGtkPrintRun",
                     "hace falta el fichero de destino" );
      hb_retl( FALSE );
      return;
   }
   pLineas = hb_param( 5, HB_IT_ARRAY );
   if( ! pLineas )
   {
      hbgtk_errArgs( "HGtkPrintRun", "el listado debe ser un array" );
      hb_retl( FALSE );
      return;
   }
   if( ! hbgtk_initGTK() )
   {
      hbgtk_errGui( "HGtkPrintRun",
                    "GTK no está inicializado: no se puede imprimir" );
      hb_retl( FALSE );
      return;
   }

   nTotal = (int) hb_arrayLen( pLineas );
   Listado.aLineas   = g_new0( gchar *, nTotal + 1 );
   Listado.nLineas   = nTotal;
   Listado.nPorPagina = 1;
   Listado.szFuente  = g_strdup( hb_parc( 2 ) );
   for( i = 1; i <= nTotal; i++ )
   {
      PHB_ITEM pLinea = hb_itemArrayGet( pLineas, i );

      Listado.aLineas[ i - 1 ] = g_strdup(
         ( pLinea && HB_IS_STRING( pLinea ) ) ?
            hb_itemGetCPtr( pLinea ) : "" );
      if( pLinea )
         hb_itemRelease( pLinea );
   }

   pOp = gtk_print_operation_new();
   gtk_print_operation_set_job_name( pOp, hb_parc( 1 ) );
   gtk_print_operation_set_unit( pOp, GTK_UNIT_POINTS );
   gtk_print_operation_set_show_progress( pOp, FALSE );
   if( nAccion == HGTK_PRINT_EXPORTA )
      gtk_print_operation_set_export_filename( pOp, hb_parc( 4 ) );

   g_signal_connect( pOp, "begin-print",
                     G_CALLBACK( hbgtk_print_comienza ), &Listado );
   g_signal_connect( pOp, "draw-page", G_CALLBACK( hbgtk_print_pagina ),
                     &Listado );
   g_signal_connect( pOp, "done", G_CALLBACK( hbgtk_print_hecho ),
                     &nResultado );

   fOk = gtk_print_operation_run(
            pOp, nAccion == HGTK_PRINT_EXPORTA ?
                    GTK_PRINT_OPERATION_ACTION_EXPORT :
                    GTK_PRINT_OPERATION_ACTION_PRINT_DIALOG,
            NULL, &pError );

   if( ! fOk )
   {
      hbgtk_errGui( "HGtkPrintRun",
                    pError ? pError->message :
                             "GTK no pudo completar la impresión" );
      if( pError )
         g_error_free( pError );
   }

   /* sólo cuenta como impreso lo que se llegó a aplicar: el diálogo
    * también devuelve sin error cuando el usuario cancela */
   hb_retl( fOk && nResultado == (int) GTK_PRINT_OPERATION_RESULT_APPLY );

   g_object_unref( pOp );
   g_free( Listado.szFuente );
   g_strfreev( Listado.aLineas );
}
