/*
 * control.prg — TControl: base interna de los controles
 *
 * Un control no existe sin padre: en Init() se comprueba (cláusula OF)
 * y en Place() se coloca en el contenedor de posicionamiento del padre
 * y queda registrado en él, que es como TRadio localiza a los radios
 * del mismo grupo.
 *
 * El puntero hWnd lo maneja sólo el puente C. Para saber si el widget
 * sigue vivo se pregunta con IsAlive(), que no desreferencia nada.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TControl

   VAR oWnd        INIT  NIL    // padre: TWindow, TDialog o TGroup
   VAR hWnd        INIT  NIL    // puntero al widget, sólo para el puente
   VAR nRow        INIT  0      // fila    (unidades de diálogo)
   VAR nCol        INIT  0      // columna (unidades de diálogo)
   VAR nHeight     INIT  0      // alto;  0 = lo que GTK elija
   VAR nWidth      INIT  0      // ancho; 0 = lo que GTK elija
   VAR lDestroyed  INIT  .F.

   METHOD Init( oParent, nRow, nCol, nHeight, nWidth )
   METHOD Place( pWidget )
   METHOD Value( x ) SETGET
   METHOD IsAlive()
   METHOD End()
   METHOD SetFocus()
   METHOD HasFocus()

ENDCLASS

/*
 * Init( oParent [, nRow, nCol, nHeight, nWidth ] )
 *   oParent  contenedor obligatorio (cláusula OF del comando)
 *   nRow, nCol      posición en unidades de diálogo
 *   nHeight, nWidth tamaño en unidades de diálogo; 0 = tamaño natural
 * Lo llaman los constructores de los controles, antes de crear el
 * widget. No coloca nada: eso es Place().
 */
METHOD Init( oParent, nRow, nCol, nHeight, nWidth ) CLASS TControl

   IF ValType( oParent ) != "O" .OR. ! __objHasMsg( oParent, "AddControl" )
      HgtkErrArgs( "TControl:Init", ;
                   "el control necesita un padre (cláusula OF)" )
      ::oWnd := NIL
   ELSE
      ::oWnd := oParent
   ENDIF

   ::nRow    := IIf( ValType( nRow ) == "N", nRow, HGTK_AT_FILA_DEF )
   ::nCol    := IIf( ValType( nCol ) == "N", nCol, HGTK_AT_COL_DEF )
   ::nHeight := IIf( ValType( nHeight ) == "N", nHeight, 0 )
   ::nWidth  := IIf( ValType( nWidth ) == "N", nWidth, 0 )

RETURN SELF

/*
 * Place( pWidget ) — guarda el widget, lo registra en el padre y lo
 * coloca en su contenedor de posicionamiento. Un widget nulo (no hay
 * gráficos) deja el control creado y sin representación.
 */
METHOD Place( pWidget ) CLASS TControl

   ::hWnd := pWidget

   IF ::oWnd != NIL
      ::oWnd:AddControl( SELF )
   ENDIF

   IF ::hWnd == NIL .OR. ::oWnd == NIL .OR. ::oWnd:hWnd == NIL
      RETURN NIL
   ENDIF

   HGtkSetSize( ::hWnd, HgtkColToPx( ::nWidth ), HgtkRowToPx( ::nHeight ) )
   HGtkAdd( ::oWnd:hWnd, ::hWnd, ;
            HgtkColToPx( ::nCol ), HgtkRowToPx( ::nRow ) )

RETURN NIL

/* Value() de la base: los controles con valor lo redefinen */
METHOD Value( x ) CLASS TControl

   IF PCount() > 0
      HgtkErrArgs( "TControl:Value", "ese control no tiene valor" )
   ENDIF

RETURN NIL

/* .T. si el widget todavía existe; sólo compara con la lista */
METHOD IsAlive() CLASS TControl

RETURN ::hWnd != NIL .AND. HGtkCtrlAlive( ::hWnd )

/* Destruye el control. Sobre uno ya destruido no hace nada. */
METHOD End() CLASS TControl

   IF ::hWnd != NIL
      IF HGtkCtrlAlive( ::hWnd )
         HGtkCtrlDestroy( ::hWnd )
      ENDIF
      ::hWnd       := NIL
      ::lDestroyed := .T.
   ENDIF

RETURN NIL

/* Pone el foco de teclado en el control (si existe) */
METHOD SetFocus() CLASS TControl

   IF ::IsAlive()
      HGtkFocus( ::hWnd )
   ENDIF

RETURN NIL

/* .T. si el control tiene ahora mismo el foco de teclado */
METHOD HasFocus() CLASS TControl

RETURN ::IsAlive() .AND. HGtkHasFocus( ::hWnd )
