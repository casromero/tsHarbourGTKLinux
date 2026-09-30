/*
 * bar.prg — TBar: barra de botones de una ventana
 *
 * Los botones de la barra son TButton corrientes: se declaran con
 * "OF oBar" y, como el padre es una barra, TButton crea un botón de
 * barra en vez de un botón de formulario y se inserta solo. No llevan
 * filas ni columnas: el orden es el de declaración.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TBar FROM TControl

   VAR aControles   INIT  {}     // TButton declarados en la barra

   METHOD New( oParent ) CONSTRUCTOR
   METHOD AddControl( oCtrl )
   METHOD EsBarra()              // lo pregunta TButton en su New
   METHOD Insertar( oBoton )

ENDCLASS

/* New( oParent ) — oParent es la ventana (cláusula OF) */
METHOD New( oParent ) CLASS TBar

   ::lFueraDelFijo := .T.
   ::Init( oParent, 0, 0, 0, 0 )

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkToolBarNew() )
      IF ::IsAlive()
         HGtkWndSetBar( ::oWnd:hWnd, ::hWnd )
      ENDIF
   ELSE
      ::Place( NIL )
   ENDIF

RETURN SELF

/* Registra un botón de la barra (lo llama TButton al crearse) */
METHOD AddControl( oCtrl ) CLASS TBar

   IF ValType( oCtrl ) == "O"
      AAdd( ::aControles, oCtrl )
   ENDIF

RETURN NIL

/* .T.: el padre es una barra de botones y no un contenedor con
 * coordenadas. Es una señal para TButton: no hay que decir más. */
METHOD EsBarra() CLASS TBar

RETURN .T.

/* Insertar( oBoton ) — pone un TButton al final de la barra */
METHOD Insertar( oBoton ) CLASS TBar

   IF ValType( oBoton ) != "O"
      HgtkErrArgs( "TBar:Insertar", "se esperaba un botón" )
      RETURN NIL
   ENDIF

   IF ::IsAlive() .AND. oBoton:IsAlive()
      HGtkToolAdd( ::hWnd, oBoton:hWnd )
   ENDIF

RETURN NIL
