/*
 * image.prg — TImage: una imagen en pantalla
 *
 * El widget es un GtkImage con el pixbuf del fichero y se coloca como
 * cualquier otro control. Value() es la ruta de la imagen; Size()
 * devuelve su tamaño en píxeles (el de la imagen, no el del control),
 * que se lee con GdkPixbuf y no necesita pantalla: sirve en una prueba
 * de consola.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TImage FROM TControl

   VAR cFile       INIT  ""     // ruta de la imagen que se enseña

   METHOD New( oParent, cFile, nRow, nCol, nHeight, nWidth ) ;
      CONSTRUCTOR
   METHOD Value( x ) SETGET
   METHOD Size()

ENDCLASS

/*
 * New( oParent, cFile [, nRow, nCol, nHeight, nWidth ] )
 *   cFile  ruta de la imagen (cláusula FILE); se lee con GdkPixbuf
 */
METHOD New( oParent, cFile, nRow, nCol, nHeight, nWidth ) CLASS TImage

   IF ValType( cFile ) != "C"
      cFile := ""
   ENDIF

   ::Init( oParent, nRow, nCol, nHeight, nWidth )
   ::cFile := cFile

   IF ::oWnd == NIL .OR. ::oWnd:hWnd == NIL
      ::Place( NIL )
      RETURN SELF
   ENDIF

   IF Empty( ::cFile )
      HgtkErrArgs( "TImage:New", "hace falta la imagen (cláusula FILE)" )
      ::Place( NIL )
      RETURN SELF
   ENDIF

   ::Place( HGtkImageNew( ::cFile ) )

RETURN SELF

/* Value() lee o cambia la imagen: la ruta del fichero enseñado */
METHOD Value( x ) CLASS TImage

   IF PCount() > 0
      IF ValType( x ) != "C"
         HgtkErrArgs( "TImage:Value", "la imagen debe ser una cadena" )
      ELSEIF ! File( x )
         HgtkErrArgs( "TImage:Value", "no existe el fichero " + x )
      ELSEIF ::IsAlive()
         HGtkImageSet( ::hWnd, x )
         ::cFile := x
      ENDIF
   ENDIF

RETURN ::cFile

/* Size() -> { ancho, alto } en píxeles de la imagen, {0,0} si no se
 * lee el fichero. */
METHOD Size() CLASS TImage

   LOCAL aTam := HGtkImageTam( ::cFile )

RETURN IIf( HB_IsArray( aTam ) .AND. Len( aTam ) == 2, aTam, { 0, 0 } )
