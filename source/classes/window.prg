/*
 * window.prg — TWindow: ventana de nivel superior no modal
 *
 * Es la única clase de la fase 0. El puntero hWnd lo maneja solo el
 * puente C; la clase lo guarda y comprueba, nunca lo interpreta.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TWindow

   VAR oApplication  INIT  NIL      // TApplication único
   VAR hWnd          INIT  NIL      // puntero a GtkWindow, sólo para el puente
   VAR cTitle        INIT  ""
   VAR nWidth        INIT  0        // píxeles
   VAR nHeight       INIT  0        // píxeles
   VAR lActive       INIT  .F.      // dentro de ACTIVATE
   VAR lDestroyed    INIT  .F.
   VAR bClose        INIT  NIL      // codeblock: .F. cancela el cierre

   METHOD New( cTitle, nCols, nRows ) CONSTRUCTOR
   METHOD Activate()
   METHOD End()
   METHOD Title( cTitle ) SETGET
   METHOD IsActive()
   METHOD IsAlive()

ENDCLASS

/*
 * New( cTitle [, nCols [, nRows ]] )
 *   cTitle  título en UTF-8
 *   nCols   ancho  en unidades de diálogo (columnas)
 *   nRows   alto   en unidades de diálogo (filas)
 * El widget se crea aquí; Activate() lo muestra y espera.
 */
METHOD New( cTitle, nCols, nRows ) CLASS TWindow

   IF PCount() < 1 .OR. cTitle == NIL
      cTitle := ""
   ENDIF
   IF PCount() < 2 .OR. nCols == NIL
      nCols := HGTK_COLS_DEF
   ENDIF
   IF PCount() < 3 .OR. nRows == NIL
      nRows := HGTK_FILAS_DEF
   ENDIF

   IF ValType( cTitle ) != "C"
      HgtkErrArgs( "TWindow:New", "el título debe ser una cadena" )
      cTitle := ""
   ENDIF

   ::oApplication := HgtkApplication()

   ::cTitle  := cTitle
   ::nWidth  := HgtkColToPx( nCols )
   ::nHeight := HgtkRowToPx( nRows )

   IF ::oApplication:GuiReady()
      ::hWnd := HGtkWndNew( ::cTitle, ::nWidth, ::nHeight )
      IF ::hWnd != NIL
         HGtkWndSetOwner( ::hWnd, SELF )
      ENDIF
   ELSE
      HgtkErrGui( "TWindow:New", "GTK no está inicializado: no hay ventana" )
   ENDIF

RETURN SELF

/*
 * Muestra la ventana y espera hasta que la última ventana se cierre.
 * No volverá antes: sólo dentro de ACTIVATE se espera a la interfaz.
 */
METHOD Activate() CLASS TWindow

   IF ::hWnd == NIL
      RETURN SELF
   ENDIF

   IF ! ::lActive
      ::lActive := .T.
      HGtkWndShow( ::hWnd )
      HGtkMain()
      ::lActive := .F.

      /* la ventana pudo haberse cerrado desde la barra de título */
      IF ! HGtkWndAlive( ::hWnd )
         ::hWnd       := NIL
         ::lDestroyed := .T.
      ENDIF
   ENDIF

RETURN SELF

/* Destruye la ventana. Si se llama dentro de ACTIVATE, éste regresa. */
METHOD End() CLASS TWindow

   IF ::hWnd != NIL
      IF HGtkWndAlive( ::hWnd )
         HGtkWndDestroy( ::hWnd )
      ENDIF
      ::hWnd       := NIL
      ::lDestroyed := .T.
      ::lActive    := .F.
   ENDIF

RETURN NIL

/* Title() lee el título real del widget; Title( c ) lo cambia */
METHOD Title( cTitle ) CLASS TWindow

   IF PCount() > 0
      IF ValType( cTitle ) != "C"
         HgtkErrArgs( "TWindow:Title", "el título debe ser una cadena" )
      ELSE
         ::cTitle := cTitle
         IF ::hWnd != NIL .AND. HGtkWndAlive( ::hWnd )
            HGtkWndSetTitle( ::hWnd, cTitle )
         ENDIF
      ENDIF
   ELSE
      IF ::hWnd != NIL .AND. HGtkWndAlive( ::hWnd )
         ::cTitle := HGtkWndGetTitle( ::hWnd )
      ENDIF
   ENDIF

RETURN ::cTitle

/* .T. mientras se está dentro de Activate() */
METHOD IsActive() CLASS TWindow

RETURN ::lActive

/* .T. si el widget sigue vivo (aunque se haya cerrado desde fuera) */
METHOD IsAlive() CLASS TWindow

RETURN ::hWnd != NIL .AND. HGtkWndAlive( ::hWnd )
