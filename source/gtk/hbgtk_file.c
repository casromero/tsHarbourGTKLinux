/*
 * hbgtk_file.c — selector de fichero y de directorio (GTK)
 *
 * GtkFileChooserNative en vez de la ventana antigua de GTK: es el
 * diálogo nativo, no depende de un padre, y cerrarlo con la X de la
 * barra de título devuelve una respuesta de cancelación (medido en el
 * banco de pruebas de la fase 4: aparece con el título que se le
 * pase, se cierra con WM_DELETE y regresa sin avisos).
 *
 * Los botones llevan texto fijo en español con su mnemónico: la
 * librería no tiene dominio de traducción propio.
 *
 * Licencia: LGPL-3.0-or-later
 */
#include "hbgtk.h"
#include <string.h>

/* mismos valores que TFileDialog en filedialog.prg */
#define HGTK_ARCHIVO_ABRIR   1
#define HGTK_ARCHIVO_GUARDAR 2
#define HGTK_ARCHIVO_CARPETA 3

/* HGtkFileDlg( nAccion, cTitulo, cDir, cMascara, cNombre ) -> cRuta
 * Devuelve el camino elegido o la cadena vacía si el usuario la
 * canceló (o no hay gráficas). cMascara es una lista de patrones
 * separados por punto y coma, por ejemplo "*.dbf;*.txt". */
HB_FUNC( HGTKFILEDLG )
{
   GtkFileChooserNative * pDlg;
   const char * szTitulo;
   gchar * szRuta;
   gint nResp;
   int nAccion;

   nAccion = hb_parni( 1 );
   if( nAccion != HGTK_ARCHIVO_ABRIR && nAccion != HGTK_ARCHIVO_GUARDAR &&
       nAccion != HGTK_ARCHIVO_CARPETA )
   {
      hbgtk_errArgs( "HGtkFileDlg", "camino del selector no válido" );
      hb_retc( "" );
      return;
   }
   if( hb_pcount() >= 2 && ! HB_ISCHAR( 2 ) )
   {
      hbgtk_errArgs( "HGtkFileDlg", "el título debe ser una cadena" );
      hb_retc( "" );
      return;
   }
   if( ! hbgtk_initGTK() )
   {
      hb_retc( "" );
      return;
   }

   szTitulo = ( hb_pcount() >= 2 && HB_ISCHAR( 2 ) ) ? hb_parc( 2 ) : "";

   pDlg = gtk_file_chooser_native_new(
             szTitulo, NULL,
             nAccion == HGTK_ARCHIVO_CARPETA ?
                GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER :
                nAccion == HGTK_ARCHIVO_GUARDAR ?
                GTK_FILE_CHOOSER_ACTION_SAVE :
                GTK_FILE_CHOOSER_ACTION_OPEN,
             nAccion == HGTK_ARCHIVO_GUARDAR ? "_Guardar" : "_Aceptar",
             "_Cancelar" );

   if( hb_pcount() >= 3 && HB_ISCHAR( 3 ) && hb_parclen( 3 ) > 0 )
      gtk_file_chooser_set_current_folder( GTK_FILE_CHOOSER( pDlg ),
                                           hb_parc( 3 ) );

   if( nAccion == HGTK_ARCHIVO_GUARDAR &&
       hb_pcount() >= 5 && HB_ISCHAR( 5 ) && hb_parclen( 5 ) > 0 )
   {
      gtk_file_chooser_set_current_name( GTK_FILE_CHOOSER( pDlg ),
                                         hb_parc( 5 ) );
      gtk_file_chooser_set_do_overwrite_confirmation(
         GTK_FILE_CHOOSER( pDlg ), TRUE );
   }

   if( nAccion != HGTK_ARCHIVO_CARPETA &&
       hb_pcount() >= 4 && HB_ISCHAR( 4 ) && hb_parclen( 4 ) > 0 )
   {
      GtkFileFilter * pFiltro = gtk_file_filter_new();
      gchar ** aPatrones = g_strsplit( hb_parc( 4 ), ";", -1 );
      int i;

      for( i = 0; aPatrones[ i ]; i++ )
      {
         gchar * szPatron = g_strstrip( g_strdup( aPatrones[ i ] ) );

         if( *szPatron )
            gtk_file_filter_add_pattern( pFiltro, szPatron );
         g_free( szPatron );
      }
      g_strfreev( aPatrones );

      /*
       * El filtro lleva referencia flotante y set_filter se la queda:
       * un unref aquí provoca use-after-free al abrir el diálogo
       * (medido en la fase 4 con el banco f11: sin unref funciona,
       * con unref, segfault en gtk_native_dialog_run).
       */
      gtk_file_chooser_set_filter( GTK_FILE_CHOOSER( pDlg ), pFiltro );
   }

   nResp = gtk_native_dialog_run( GTK_NATIVE_DIALOG( pDlg ) );

   if( nResp == GTK_RESPONSE_ACCEPT )
   {
      szRuta = gtk_file_chooser_get_filename( GTK_FILE_CHOOSER( pDlg ) );
      hb_retc( szRuta ? szRuta : "" );
      g_free( szRuta );
   }
   else
      hb_retc( "" );

   g_object_unref( pDlg );
}
