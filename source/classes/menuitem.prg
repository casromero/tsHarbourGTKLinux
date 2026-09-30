/*
 * menuitem.prg — TMenuItem: orden de un menú
 *
 * La acción se evalúa sin argumentos al elegir la orden, igual que la
 * de un botón: la señal "activate" del ítem llama a Click(), que lee
 * el bloque de la clase en ese instante. De paso, Click() permite
 * disparar la orden desde el propio programa, que es como se comprueba
 * en las pruebas.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TMenuItem FROM TControl

   VAR bAction     INIT  NIL    // codeblock a evaluar al elegir la orden

   METHOD New( oParent, cPrompt, bAction ) CONSTRUCTOR
   METHOD Click()

ENDCLASS

/* New( oParent, cPrompt [, bAction ] ) — oParent es TMenu o TPopup */
METHOD New( oParent, cPrompt, bAction ) CLASS TMenuItem

   IF PCount() < 2 .OR. ValType( cPrompt ) != "C"
      cPrompt := ""
   ENDIF

   ::lFueraDelFijo := .T.
   ::Init( oParent, 0, 0, 0, 0 )
   ::bAction := IIf( ValType( bAction ) == "B", bAction, NIL )

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkMenuItemNew( cPrompt ) )
      IF ::IsAlive()
         HGtkMenuAdd( ::oWnd:hWnd, ::hWnd )
         HGtkSetSignal( ::hWnd, "activate", {|| ::Click() } )
      ENDIF
   ELSE
      ::Place( NIL )
   ENDIF

RETURN SELF

/* Dispara la orden: evalúa la acción si la hay */
METHOD Click() CLASS TMenuItem

   IF ::bAction != NIL
      Eval( ::bAction )
   ENDIF

RETURN NIL
