/*
 * hbgtk_image.c — imágenes (TImage)
 *
 * El pixbuf se lee con GdkPixbuf, que no necesita pantalla ni
 * gtk_init(): con eso se mide una imagen en una prueba de consola y
 * con el mismo código se enseña en pantalla, que es un GtkImage como
 * cualquier otro control y se coloca con HGtkAdd.
 *
 * Licencia: LGPL-3.0-or-later
 */
#include "hbgtk.h"

/* hbgtk_pixbuf( cFichero ) -> pixbuf nuevo, que suelta quien lo use,
 * o NULL si el fichero no está o no es una imagen legible */
GdkPixbuf * hbgtk_pixbuf( const char * szFichero )
{
   GError * pError = NULL;
   GdkPixbuf * pPix;

   if( ! szFichero || ! *szFichero )
      return NULL;

   pPix = gdk_pixbuf_new_from_file( szFichero, &pError );
   if( pError )
   {
      g_error_free( pError );
      return NULL;
   }
   return pPix;
}

/* HGtkImageNew( cFichero ) -> imagen (TImage) */
HB_FUNC( HGTKIMAGENEW )
{
   GtkWidget * pCtrl;
   GdkPixbuf * pPix;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   pPix = hbgtk_pixbuf( HB_ISCHAR( 1 ) ? hb_parc( 1 ) : "" );
   if( ! pPix )
   {
      hbgtk_errGui( "HGtkImageNew", "no se pudo leer la imagen" );
      hb_retptr( NULL );
      return;
   }

   pCtrl = gtk_image_new_from_pixbuf( pPix );
   g_object_unref( pPix );   /* la imagen ya tiene la suya */
   hbgtk_ctrl_init( pCtrl );
   hb_retptr( pCtrl );
}

/* HGtkImageSet( pImagen, cFichero ) — cambia la imagen enseñada */
HB_FUNC( HGTKIMAGESET )
{
   GtkWidget * pCtrl = hbgtk_cpar( 1, "HGtkImageSet" );
   GdkPixbuf * pPix;

   if( ! pCtrl )
   {
      hb_ret();
      return;
   }
   if( ! GTK_IS_IMAGE( pCtrl ) )
   {
      hbgtk_errArgs( "HGtkImageSet", "no es una imagen" );
      hb_ret();
      return;
   }

   pPix = hbgtk_pixbuf( HB_ISCHAR( 2 ) ? hb_parc( 2 ) : "" );
   if( ! pPix )
   {
      hbgtk_errGui( "HGtkImageSet", "no se pudo leer la imagen" );
      hb_ret();
      return;
   }

   gtk_image_set_from_pixbuf( GTK_IMAGE( pCtrl ), pPix );
   g_object_unref( pPix );
   hb_ret();
}

/* HGtkImageTam( cFichero ) -> { ancho, alto } en píxeles, {0,0} si no
 * se lee. No hace falta pantalla: sólo se abre el fichero. */
HB_FUNC( HGTKIMAGETAM )
{
   GdkPixbuf * pPix = hbgtk_pixbuf( HB_ISCHAR( 1 ) ? hb_parc( 1 ) : "" );
   PHB_ITEM pRes = hb_itemArrayNew( 2 );

   if( pPix )
   {
      hb_arraySetNI( pRes, 1, gdk_pixbuf_get_width( pPix ) );
      hb_arraySetNI( pRes, 2, gdk_pixbuf_get_height( pPix ) );
      g_object_unref( pPix );
   }
   else
   {
      /* sin imagen no hay medida: {0,0}, que es lo que se espera de
       * un fichero que no se puede leer (un array nuevo viene vacío) */
      hb_arraySetNI( pRes, 1, 0 );
      hb_arraySetNI( pRes, 2, 0 );
   }
   hb_itemReturnRelease( pRes );
}
