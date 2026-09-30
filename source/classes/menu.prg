/*
 * menu.prg — TMenu: barra de menú de una ventana
 *
 * La barra no va en el contenedor de posicionamiento sino arriba del
 * todo en la caja vertical de la ventana, por eso lleva lFueraDelFijo
 * y por eso no se cuelga al crearla sino con ACTIVATE MENU, que llama
 * a Activate().
 *
 * Dentro del menú hay TPopup (ítems con submenú) y TMenuItem (las
 * órdenes); cada uno se declara con su cláusula OF y queda aquí
 * apuntado en aControles, igual que los controles de una ventana.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TMenu FROM TControl

   VAR aControles   INIT  {}     // TPopup y TMenuItem declarados dentro
   VAR lActivada    INIT  .F.    // .T. tras ACTIVATE MENU

   METHOD New( oParent ) CONSTRUCTOR
   METHOD AddControl( oCtrl )
   METHOD Activate()

ENDCLASS

/* New( oParent ) — oParent es la ventana (cláusula OF) */
METHOD New( oParent ) CLASS TMenu

   ::lFueraDelFijo := .T.
   ::Init( oParent, 0, 0, 0, 0 )

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkMenuBarNew() )
   ELSE
      ::Place( NIL )
   ENDIF

RETURN SELF

/* Registra un ítem del menú (lo llaman TPopup y TMenuItem) */
METHOD AddControl( oCtrl ) CLASS TMenu

   IF ValType( oCtrl ) == "O"
      AAdd( ::aControles, oCtrl )
   ENDIF

RETURN NIL

/* ACTIVATE MENU — cuelga la barra en la ventana y la muestra */
METHOD Activate() CLASS TMenu

   IF ::oWnd == NIL .OR. ::oWnd:hWnd == NIL .OR. ! ::IsAlive()
      HgtkErrArgs( "TMenu:Activate", ;
                   "el menú no está creado o su ventana ya no existe" )
      RETURN NIL
   ENDIF

   HGtkWndSetMenu( ::oWnd:hWnd, ::hWnd )
   ::lActivada := .T.

RETURN NIL
