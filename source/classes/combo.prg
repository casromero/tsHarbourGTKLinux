/*
 * combo.prg — TComboBox: desplegable de una sola línea
 *
 * La variable guarda el número de entrada (1 por la primera), que es
 * lo que se sincroniza en cada cambio.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TComboBox FROM TControl

   VAR bSetGet     INIT  NIL    // bloque de enlace con la variable

   METHOD New( oParent, bSetGet, aItems, nRow, nCol, nHeight, nWidth ) ;
      CONSTRUCTOR
   METHOD Value( x ) SETGET
   METHOD AddItem( cTexto )
   METHOD Escribir()            // de la selección a la variable

ENDCLASS

/*
 * New( oParent, bSetGet, aItems [, nRow, nCol, nHeight, nWidth ] )
 *   bSetGet  {|x| iif( PCount() > 0, nVar := x, nVar ) }
 *   aItems   array de textos; se pueden añadir después con AddItem()
 */
METHOD New( oParent, bSetGet, aItems, nRow, nCol, nHeight, nWidth ) ;
      CLASS TComboBox

   LOCAL xValor, cItem

   IF ValType( bSetGet ) != "B"
      HgtkErrArgs( "TComboBox:New", "se esperaba un bloque de enlace (VAR)" )
      bSetGet := NIL
   ENDIF
   IF PCount() < 3 .OR. ! HB_IsArray( aItems )
      aItems := {}
   ENDIF

   ::Init( oParent, nRow, nCol, nHeight, nWidth )
   IF ::nWidth == 0
      ::nWidth := HGTK_GET_COLS_DEF
   ENDIF
   ::bSetGet := bSetGet

   xValor := IIf( bSetGet == NIL, 0, Eval( bSetGet ) )

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkComboNew() )
      IF ::IsAlive()
         FOR EACH cItem IN aItems
            HGtkComboAdd( ::hWnd, cItem )
         NEXT
         IF ValType( xValor ) == "N" .AND. xValor >= 1 .AND. ;
            xValor <= Len( aItems )
            HGtkComboSelect( ::hWnd, xValor )
         ENDIF
         HGtkSetSignal( ::hWnd, "changed", {|| ::Escribir() } )
      ENDIF
   ELSE
      ::Place( NIL )
   ENDIF

RETURN SELF

/* Value() lee o cambia la entrada seleccionada (1-based; 0 = ninguna) */
METHOD Value( x ) CLASS TComboBox

   IF PCount() > 0
      IF ValType( x ) != "N"
         HgtkErrArgs( "TComboBox:Value", "se esperaba un número" )
      ELSEIF ::IsAlive()
         HGtkComboSelect( ::hWnd, x )   // "changed" sincroniza la variable
      ELSEIF ::bSetGet != NIL
         Eval( ::bSetGet, x )
      ENDIF
   ENDIF

   IF ::IsAlive()
      RETURN HGtkComboIndex( ::hWnd )
   ENDIF

RETURN IIf( ::bSetGet != NIL .AND. ValType( Eval( ::bSetGet ) ) == "N", ;
            Eval( ::bSetGet ), 0 )

/* Añade una entrada al final; devuelve el número que le toca */
METHOD AddItem( cTexto ) CLASS TComboBox

   IF ValType( cTexto ) != "C"
      HgtkErrArgs( "TComboBox:AddItem", "la entrada debe ser una cadena" )
      RETURN 0
   ENDIF
   IF ! ::IsAlive()
      RETURN 0
   ENDIF

   HGtkComboAdd( ::hWnd, cTexto )

RETURN HGtkComboIndex( ::hWnd )

/* Escribe en la variable la entrada seleccionada */
METHOD Escribir() CLASS TComboBox

   LOCAL nEntrada

   IF ::bSetGet == NIL .OR. ! ::IsAlive()
      RETURN NIL
   ENDIF

   nEntrada := HGtkComboIndex( ::hWnd )
   IF nEntrada > 0
      Eval( ::bSetGet, nEntrada )
   ENDIF

RETURN NIL
