/*
 * say.prg — TSay: texto de solo lectura
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TSay FROM TControl

   VAR cTexto      INIT  ""     // última texto conocido

   METHOD New( oParent, cPrompt, nRow, nCol, nHeight, nWidth ) CONSTRUCTOR
   METHOD Value( x ) SETGET

ENDCLASS

/* New( oParent, cPrompt [, nRow, nCol, nHeight, nWidth ] ) */
METHOD New( oParent, cPrompt, nRow, nCol, nHeight, nWidth ) CLASS TSay

   IF PCount() < 2 .OR. ValType( cPrompt ) != "C"
      cPrompt := ""
   ENDIF

   ::Init( oParent, nRow, nCol, nHeight, nWidth )
   ::cTexto := cPrompt

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkLabelNew( cPrompt ) )
   ELSE
      ::Place( NIL )
   ENDIF

RETURN SELF

/* Value() lee o cambia el texto de la etiqueta */
METHOD Value( x ) CLASS TSay

   IF PCount() > 0
      IF ValType( x ) != "C"
         HgtkErrArgs( "TSay:Value", "el texto debe ser una cadena" )
      ELSE
         ::cTexto := x
         IF ::IsAlive()
            HGtkSetText( ::hWnd, x )
         ENDIF
      ENDIF
   ELSEIF ::IsAlive()
      ::cTexto := HGtkGetText( ::hWnd )
   ENDIF

RETURN ::cTexto
