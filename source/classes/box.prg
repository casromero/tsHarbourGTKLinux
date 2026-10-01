/*
 * box.prg — TBox: caja de empaquetado (modo de cajas, fase 4)
 *
 * El control va donde va siempre, en el GtkFixed de su ventana, con
 * AT y SIZE; lo que cambia es lo que ocurre dentro: los controles
 * declarados "OF oCaja" no se colocan a pulso, se empaquetan en orden
 * (primero declarado, primero puesto) por GTK. Si la caja es
 * HORIZONTAL van en fila, si no, apilados en vertical; el tamaño es
 * el natural de cada uno, con 6 píxeles de separación.
 *
 * Elegir un modo o el otro es de la aplicación: el de coordenadas es
 * el de siempre (y sigue siendo el que usan la ventana, los grupos y
 * las páginas de un panel).
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TBox FROM TControl

   VAR aControles  INIT  {}     // controles declarados dentro

   METHOD New( oParent, lHorizontal, nRow, nCol, nHeight, nWidth ) ;
          CONSTRUCTOR
   METHOD AddControl( oCtrl )

ENDCLASS

/* New( oParent, lHorizontal [, nRow, nCol, nHeight, nWidth ] ) */
METHOD New( oParent, lHorizontal, nRow, nCol, nHeight, nWidth ) CLASS TBox

   IF PCount() < 2 .OR. ValType( lHorizontal ) != "L"
      lHorizontal := .F.
   ENDIF

   ::Init( oParent, nRow, nCol, nHeight, nWidth )

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkBoxNew( lHorizontal ) )
   ELSE
      ::Place( NIL )
   ENDIF

RETURN SELF

/* Registra un control dentro de la caja (lo llama TControl:Place) */
METHOD AddControl( oCtrl ) CLASS TBox

   IF ValType( oCtrl ) == "O"
      AAdd( ::aControles, oCtrl )
   ENDIF

RETURN NIL
