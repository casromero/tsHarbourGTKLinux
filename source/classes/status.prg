/*
 * status.prg — TStatus: barra de estado de una línea
 *
 * Va al pie de la ventana, en su caja vertical (lFueraDelFijo), y
 * muestra un texto: Value( c ) lo pone y Value() lo lee de la etiqueta
 * que está en pantalla.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TStatus FROM TControl

   METHOD New( oParent ) CONSTRUCTOR
   METHOD Value( x ) SETGET

ENDCLASS

/* New( oParent ) — oParent es la ventana (cláusula OF) */
METHOD New( oParent ) CLASS TStatus

   ::lFueraDelFijo := .T.
   ::Init( oParent, 0, 0, 0, 0 )

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkStatusNew() )
      IF ::IsAlive()
         HGtkWndSetStatus( ::oWnd:hWnd, ::hWnd )
      ENDIF
   ELSE
      ::Place( NIL )
   ENDIF

RETURN SELF

/* Value() lee o cambia el mensaje de la barra */
METHOD Value( x ) CLASS TStatus

   IF PCount() > 0
      IF ValType( x ) != "C"
         HgtkErrArgs( "TStatus:Value", "el texto debe ser una cadena" )
      ELSEIF ::IsAlive()
         HGtkStatusPut( ::hWnd, x )
      ENDIF
   ENDIF

   IF ::IsAlive()
      RETURN HGtkStatusGet( ::hWnd )
   ENDIF

RETURN ""
