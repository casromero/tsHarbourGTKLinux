/*
 * popup.prg — TPopup: ítem de menú con submenú
 *
 * Es un ítem de la barra de menú o de otro popup que, al elegirlo,
 * despliega lo que se declare con "OF oPopup". Su texto admite la
 * marca de mnemónico "&x" de FiveWin.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TPopup FROM TControl

   VAR aControles   INIT  {}     // TMenuItem declarados dentro

   METHOD New( oParent, cPrompt ) CONSTRUCTOR
   METHOD AddControl( oCtrl )

ENDCLASS

/* New( oParent, cPrompt ) — oParent es TMenu o TPopup (cláusula OF) */
METHOD New( oParent, cPrompt ) CLASS TPopup

   IF PCount() < 2 .OR. ValType( cPrompt ) != "C"
      cPrompt := ""
   ENDIF

   ::lFueraDelFijo := .T.
   ::Init( oParent, 0, 0, 0, 0 )

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkMenuPopupNew( cPrompt ) )
      IF ::IsAlive()
         HGtkMenuAdd( ::oWnd:hWnd, ::hWnd )
      ENDIF
   ELSE
      ::Place( NIL )
   ENDIF

RETURN SELF

/* Registra una orden dentro del submenú (lo llama TMenuItem) */
METHOD AddControl( oCtrl ) CLASS TPopup

   IF ValType( oCtrl ) == "O"
      AAdd( ::aControles, oCtrl )
   ENDIF

RETURN NIL
