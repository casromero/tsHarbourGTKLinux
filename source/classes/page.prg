/*
 * page.prg — TPage: una pestaña de un panel con pestañas
 *
 * La página es un contenedor como un grupo: lo que se declara con
 * "OF oPagina" lleva coordenadas relativas a ella. La añade al panel
 * el propio constructor (append_page), por eso va fuera del fijo de
 * la ventana (lFueraDelFijo): HGtkAdd no debe tocarla, y su tamaño
 * también lo reparte el panel.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TPage FROM TControl

   VAR aControles  INIT  {}     // controles declarados dentro

   METHOD New( oParent, cPrompt ) CONSTRUCTOR
   METHOD AddControl( oCtrl )

ENDCLASS

/* New( oParent, cPrompt ) — oParent es el panel (TTabs) */
METHOD New( oParent, cPrompt ) CLASS TPage

   IF PCount() < 2 .OR. ValType( cPrompt ) != "C"
      cPrompt := ""
   ENDIF

   ::Init( oParent, NIL, NIL, NIL, NIL )

   /* ni AT ni SIZE: el panel decide dónde y cuánto ocupa la página */
   ::lFueraDelFijo := .T.

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkPageNew( ::oWnd:hWnd, cPrompt ) )
   ELSE
      ::Place( NIL )
   ENDIF

RETURN SELF

/* Registra un control dentro de la página (lo llama TControl:Place) */
METHOD AddControl( oCtrl ) CLASS TPage

   IF ValType( oCtrl ) == "O"
      AAdd( ::aControles, oCtrl )
   ENDIF

RETURN NIL
