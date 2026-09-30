/*
 * window.prg — TWindow: ventana de nivel superior no modal
 *
 * El puntero hWnd lo maneja solo el puente C; la clase lo guarda y
 * comprueba, nunca lo interpreta. InitVentana() comparte el arranque
 * con TDialog, que crea un diálogo modal en lugar de una ventana.
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
   VAR nColIni       INIT  0        // columna inicial (unidades de diálogo)
   VAR nFilaIni      INIT  0        // fila inicial
   VAR lActive       INIT  .F.      // dentro de ACTIVATE
   VAR lDestroyed    INIT  .F.
   VAR bClose        INIT  NIL      // codeblock: .F. cancela el cierre
   VAR aControles    INIT  {}       // controles declarados dentro

   METHOD New( cTitle, nCols, nRows ) CONSTRUCTOR
   METHOD InitVentana( cTitle, nCols, nRows, lModal )
   METHOD Activate()
   METHOD End()
   METHOD Title( cTitle ) SETGET
   METHOD Move( nCol, nFila )
   METHOD AddControl( oCtrl )
   METHOD IsActive()
   METHOD IsAlive()
   METHOD FocusName()

ENDCLASS

/*
 * New( cTitle [, nCols [, nRows ]] )
 *   cTitle  título en UTF-8
 *   nCols   ancho  en unidades de diálogo (columnas)
 *   nRows   alto   en unidades de diálogo (filas)
 * El widget se crea aquí; Activate() lo muestra y espera.
 */
METHOD New( cTitle, nCols, nRows ) CLASS TWindow

   ::InitVentana( cTitle, nCols, nRows, .F. )

RETURN SELF

/*
 * Arranque común de ventana y diálogo. lModal crea un TDialog (GTK
 * dialog) en lugar de una ventana normal.
 */
METHOD InitVentana( cTitle, nCols, nRows, lModal ) CLASS TWindow

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
      IF lModal
         ::hWnd := HGtkDlgNew( ::cTitle, ::nWidth, ::nHeight )
      ELSE
         ::hWnd := HGtkWndNew( ::cTitle, ::nWidth, ::nHeight )
      ENDIF
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

/* Move( nCol, nFila ) — posición en unidades de diálogo */
METHOD Move( nCol, nFila ) CLASS TWindow

   IF ValType( nCol ) != "N" .OR. ValType( nFila ) != "N"
      HgtkErrArgs( "TWindow:Move", "se esperaban columna y fila" )
      RETURN NIL
   ENDIF

   ::nColIni  := nCol
   ::nFilaIni := nFila

   IF ::hWnd != NIL .AND. HGtkWndAlive( ::hWnd )
      HGtkWndMove( ::hWnd, HgtkColToPx( nCol ), HgtkRowToPx( nFila ) )
   ENDIF

RETURN NIL

/* Registra un control declarado dentro de la ventana (o del diálogo) */
METHOD AddControl( oCtrl ) CLASS TWindow

   IF ValType( oCtrl ) == "O"
      AAdd( ::aControles, oCtrl )
   ENDIF

RETURN NIL

/* .T. mientras se está dentro de Activate() */
METHOD IsActive() CLASS TWindow

RETURN ::lActive

/* .T. si el widget sigue vivo (aunque se haya cerrado desde fuera) */
METHOD IsAlive() CLASS TWindow

RETURN ::hWnd != NIL .AND. HGtkWndAlive( ::hWnd )

/*
 * FocusName() — tipo del widget con el foco ("GtkListBox",
 * "GtkToolButton", ...), vacío si no lo tiene ninguno. Comprueba por
 * dónde van a ir las teclas sin tener que mirar la pantalla.
 */
METHOD FocusName() CLASS TWindow

   IF ::hWnd == NIL .OR. ! ::IsAlive()
      RETURN ""
   ENDIF

RETURN HGtkWndFocus( ::hWnd )
