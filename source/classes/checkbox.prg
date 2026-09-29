/*
 * checkbox.prg — TCheckBox: casilla de verificación
 *
 * El valor (lógico) vive en la variable Harbour, igual que en TGet:
 * se sincroniza en cada cambio de la casilla.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TCheckBox FROM TControl

   VAR bSetGet     INIT  NIL    // bloque de enlace con la variable

   METHOD New( oParent, bSetGet, cPrompt, nRow, nCol, nHeight, nWidth ) ;
      CONSTRUCTOR
   METHOD Value( x ) SETGET
   METHOD Escribir()            // de la casilla a la variable

ENDCLASS

/*
 * New( oParent, bSetGet, cPrompt [, nRow, nCol, nHeight, nWidth ] )
 *   bSetGet  {|x| iif( PCount() > 0, lVar := x, lVar ) }
 *   cPrompt  texto de la casilla
 */
METHOD New( oParent, bSetGet, cPrompt, nRow, nCol, nHeight, nWidth ) ;
      CLASS TCheckBox

   LOCAL xValor

   IF ValType( bSetGet ) != "B"
      HgtkErrArgs( "TCheckBox:New", "se esperaba un bloque de enlace (VAR)" )
      bSetGet := NIL
   ENDIF
   IF PCount() < 3 .OR. ValType( cPrompt ) != "C"
      cPrompt := ""
   ENDIF

   ::Init( oParent, nRow, nCol, nHeight, nWidth )
   ::bSetGet := bSetGet

   xValor := IIf( bSetGet == NIL, .F., Eval( bSetGet ) )

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkCheckNew( cPrompt ) )
      IF ::IsAlive()
         HGtkSetActive( ::hWnd, ValType( xValor ) == "L" .AND. xValor )
         HGtkSetSignal( ::hWnd, "toggled", {|| ::Escribir() } )
      ENDIF
   ELSE
      ::Place( NIL )
   ENDIF

RETURN SELF

/* Value() lee o cambia el estado de la casilla */
METHOD Value( x ) CLASS TCheckBox

   IF PCount() > 0
      IF ValType( x ) != "L"
         HgtkErrArgs( "TCheckBox:Value", "se esperaba un lógico" )
      ELSEIF ::IsAlive()
         HGtkSetActive( ::hWnd, x )     // "toggled" sincroniza la variable
      ELSE
         Eval( ::bSetGet, x )
      ENDIF
   ENDIF

   IF ::IsAlive()
      RETURN HGtkGetActive( ::hWnd )
   ENDIF

RETURN IIf( ::bSetGet != NIL .AND. ValType( Eval( ::bSetGet ) ) == "L", ;
            Eval( ::bSetGet ), .F. )

/* Escribe en la variable el estado actual de la casilla */
METHOD Escribir() CLASS TCheckBox

   IF ::bSetGet == NIL .OR. ! ::IsAlive()
      RETURN NIL
   ENDIF

   Eval( ::bSetGet, HGtkGetActive( ::hWnd ) )

RETURN NIL
