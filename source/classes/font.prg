/*
 * font.prg — TFont: descripción de una fuente
 *
 * Se usa con SetFont/Font de las ventanas y los controles:
 *
 *   oWnd:Font( TFont():New( "Sans", 9 ) )
 *   oCtrl:Font( TFont():New( "DejaVu Sans Mono", 10, .T., .T. ) )
 *
 * El tamaño va en puntos; GTK lo convierte a los píxeles del CSS. La
 * familia si no se da es "Sans" (la que trae el tema), y negrita y
 * cursiva, por omisión, apagadas. El sistema de las fuentes es CSS
 * (ver HGtkCss): la del widget y de sus hijos, y para toda la
 * pantalla, la hoja global.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TFont

   VAR cFace       INIT  "Sans"  // familia
   VAR nSize       INIT  10      // puntos
   VAR lBold       INIT  .F.     // negrita
   VAR lItalic     INIT  .F.     // cursiva

   METHOD New( cFace, nSize, lBold, lItalic ) CONSTRUCTOR
   METHOD Descripcion()

ENDCLASS

/* New( [ cFace [, nSize [, lBold [, lItalic ]]] ] ) — lo que no
 * cumpla se rechaza con error de uso y se queda el valor por omisión */
METHOD New( cFace, nSize, lBold, lItalic ) CLASS TFont

   IF PCount() >= 1
      IF ValType( cFace ) != "C" .OR. Empty( cFace )
         HgtkErrArgs( "TFont:New", "la familia debe ser una cadena" )
      ELSE
         ::cFace := cFace
      ENDIF
   ENDIF
   IF PCount() >= 2
      IF ValType( nSize ) != "N" .OR. nSize < 1
         HgtkErrArgs( "TFont:New", "el tamaño debe ser 1 o más puntos" )
      ELSE
         ::nSize := Int( nSize )
      ENDIF
   ENDIF
   IF PCount() >= 3 .AND. ValType( lBold ) == "L"
      ::lBold := lBold
   ENDIF
   IF PCount() >= 4 .AND. ValType( lItalic ) == "L"
      ::lItalic := lItalic
   ENDIF

RETURN SELF

/* Descripcion() -> "Sans 10", "DejaVu Sans Mono 12 +negrita +cursiva" */
METHOD Descripcion() CLASS TFont

   LOCAL cRes := ::cFace + " " + LTrim( Str( ::nSize ) )

   IF ::lBold
      cRes += " +negrita"
   ENDIF
   IF ::lItalic
      cRes += " +cursiva"
   ENDIF

RETURN cRes
