/*
 * listbox.prg — TListBox: lista vertical de una columna
 *
 * La variable guarda el número de fila (1 por la primera), igual que
 * en el desplegable; 0 si no hay nada seleccionado. Al cambiar la
 * selección se escribe en la variable y, si hay ACTION, se evalúa el
 * bloque, que es donde se sincroniza con el resto de la ventana.
 *
 * Las filas son de solo lectura: cambiar el contenido entero es
 * SetItems( a ).
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TListBox FROM TControl

   VAR bSetGet     INIT  NIL    // bloque de enlace con la variable
   VAR bAction     INIT  NIL    // se evalúa al cambiar la selección
   VAR aItems      INIT  {}     // textos de las filas

   METHOD New( oParent, bSetGet, aItems, nRow, nCol, nHeight, nWidth, ;
               bAction ) CONSTRUCTOR
   METHOD Value( x ) SETGET
   METHOD SetItems( a )
   METHOD Escribir()            // de la selección a la variable y ACTION

ENDCLASS

/*
 * New( oParent, bSetGet, aItems [, nRow, nCol, nHeight, nWidth [, bAction ]] )
 *   bSetGet  {|x| iif( PCount() > 0, nVar := x, nVar ) }
 *   aItems   array de textos; se pueden reemplazar con SetItems()
 *   bAction  bloque sin argumentos, al cambiar la selección
 */
METHOD New( oParent, bSetGet, aItems, nRow, nCol, nHeight, nWidth, ;
            bAction ) CLASS TListBox

   LOCAL nValor

   IF ValType( bSetGet ) != "B"
      HgtkErrArgs( "TListBox:New", "se esperaba un bloque de enlace (VAR)" )
      bSetGet := NIL
   ENDIF
   IF PCount() < 3 .OR. ! HB_IsArray( aItems )
      aItems := {}
   ENDIF

   ::Init( oParent, nRow, nCol, nHeight, nWidth )
   ::bSetGet := bSetGet
   ::bAction := IIf( ValType( bAction ) == "B", bAction, NIL )

   nValor := IIf( bSetGet == NIL, 0, Eval( bSetGet ) )

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkListNew() )
      IF ::IsAlive()
         ::SetItems( aItems )

         /* selección inicial, tomada de la variable y colocada antes
          * de conectar la señal: la primera no dispara ACTION */
         IF ValType( nValor ) == "N" .AND. nValor >= 1 .AND. ;
            nValor <= Len( ::aItems )
            HGtkListSelect( ::hWnd, nValor )
         ENDIF

         HGtkSetSignal( ::hWnd, "selected-rows-changed", ;
                        {|| ::Escribir() } )
      ENDIF
   ELSE
      ::Place( NIL )
   ENDIF

RETURN SELF

/* Value() lee o cambia la fila seleccionada (1-based; 0 = ninguna) */
METHOD Value( x ) CLASS TListBox

   IF PCount() > 0
      IF ValType( x ) != "N"
         HgtkErrArgs( "TListBox:Value", "se esperaba un número" )
      ELSEIF ::IsAlive()
         HGtkListSelect( ::hWnd, Int( x ) )   // la señal sincroniza
      ELSEIF ::bSetGet != NIL
         Eval( ::bSetGet, x )
      ENDIF
   ENDIF

   IF ::IsAlive()
      RETURN HGtkListValue( ::hWnd )
   ENDIF

RETURN IIf( ::bSetGet != NIL .AND. ValType( Eval( ::bSetGet ) ) == "N", ;
            Eval( ::bSetGet ), 0 )

/*
 * SetItems( a ) — cambia el contenido entero de la lista. Se vacía y
 * se vuelve a llenar, así que la selección se pierde (queda 0): si la
 * variable enlazada tenía una fila, se le queda el valor viejo, que es
 * lo que hace también el desplegable al vaciarse.
 */
METHOD SetItems( a ) CLASS TListBox

   LOCAL cItem

   IF ! HB_IsArray( a )
      a := {}
   ENDIF

   ::aItems := a

   IF ! ::IsAlive()
      RETURN NIL
   ENDIF

   HGtkListClear( ::hWnd )
   FOR EACH cItem IN a
      HGtkListAdd( ::hWnd, HgtkTexto( cItem ) )
   NEXT

RETURN NIL
/* De la selección a la variable, y ACTION si la hay */
METHOD Escribir() CLASS TListBox

   LOCAL nFila

   IF ! ::IsAlive()
      RETURN NIL
   ENDIF

   nFila := HGtkListValue( ::hWnd )
   IF nFila > 0
      IF ::bSetGet != NIL
         Eval( ::bSetGet, nFila )
      ENDIF
      IF ::bAction != NIL
         Eval( ::bAction )
      ENDIF
   ENDIF

RETURN NIL
