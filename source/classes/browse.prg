/*
 * browse.prg — TBrowse: tabla de solo lectura sobre un array
 *
 * GtkTreeView con una columna por cabecera. Los datos son un array de
 * arrays (una fila por entrada) y la variable guarda el número de la
 * fila elegida (1 por la primera). Al cambiar de fila con el teclado o
 * con el ratón se escribe en la variable y se evalúa ACTION, que es
 * donde, por ejemplo, la lista de al lado se pone en la misma fila.
 *
 * No se puede escribir en una celda: la edición llega en la fase 3.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TBrowse FROM TControl

   VAR bSetGet     INIT  NIL    // bloque de enlace con la variable
   VAR bAction     INIT  NIL    // se evalúa al cambiar de fila
   VAR aCabeceras  INIT  {}     // títulos de las columnas
   VAR aDatos      INIT  {}     // filas: array de arrays

   METHOD New( oParent, bSetGet, aCabeceras, aDatos, nRow, nCol, ;
               nHeight, nWidth, bAction ) CONSTRUCTOR
   METHOD Value( x ) SETGET
   METHOD Row( n )
   METHOD SetData( a )
   METHOD Escribir()            // de la fila a la variable y ACTION

ENDCLASS

/*
 * New( oParent, bSetGet, aCabeceras, aDatos
 *      [, nRow, nCol, nHeight, nWidth [, bAction ]] )
 *   aCabeceras  títulos de las columnas (cláusula FIELDS)
 *   aDatos      array de arrays con los datos (cláusula DATA)
 */
METHOD New( oParent, bSetGet, aCabeceras, aDatos, nRow, nCol, ;
            nHeight, nWidth, bAction ) CLASS TBrowse

   LOCAL nValor, aFila

   IF ValType( bSetGet ) != "B"
      HgtkErrArgs( "TBrowse:New", "se esperaba un bloque de enlace (VAR)" )
      bSetGet := NIL
   ENDIF
   IF PCount() < 3 .OR. ! HB_IsArray( aCabeceras )
      aCabeceras := {}
   ENDIF
   IF PCount() < 4 .OR. ! HB_IsArray( aDatos )
      aDatos := {}
   ENDIF

   ::Init( oParent, nRow, nCol, nHeight, nWidth )
   ::bSetGet    := bSetGet
   ::bAction    := IIf( ValType( bAction ) == "B", bAction, NIL )
   ::aCabeceras := aCabeceras
   ::aDatos     := aDatos

   nValor := IIf( bSetGet == NIL, 0, Eval( bSetGet ) )

   IF ::oWnd == NIL .OR. ::oWnd:hWnd == NIL
      ::Place( NIL )
      RETURN SELF
   ENDIF

   IF Len( ::aCabeceras ) == 0
      HgtkErrArgs( "TBrowse:New", ;
                   "hace falta al menos una cabecera (cláusula FIELDS)" )
      ::Place( NIL )
      RETURN SELF
   ENDIF

   ::Place( HGtkTreeViewNew( ::aCabeceras ) )

   IF ::IsAlive()
      FOR EACH aFila IN ::aDatos
         HGtkTreeViewAdd( ::hWnd, HgtkTextos( ;
            IIf( HB_IsArray( aFila ), aFila, {} ) ) )
      NEXT

      /* fila inicial, tomada de la variable y colocada antes de
       * conectar la señal: la primera no dispara ACTION */
      IF ValType( nValor ) == "N" .AND. nValor >= 1 .AND. ;
         nValor <= Len( ::aDatos )
         HGtkTreeViewSelect( ::hWnd, nValor )
      ENDIF

      HGtkSetSignal( ::hWnd, "cursor-changed", {|| ::Escribir() } )
   ENDIF

RETURN SELF

/* Value() lee o cambia la fila seleccionada (1-based; 0 = ninguna) */
METHOD Value( x ) CLASS TBrowse

   IF PCount() > 0
      IF ValType( x ) != "N"
         HgtkErrArgs( "TBrowse:Value", "se esperaba un número" )
      ELSEIF ::IsAlive()
         HGtkTreeViewSelect( ::hWnd, Int( x ) )   // la señal sincroniza
      ELSEIF ::bSetGet != NIL
         Eval( ::bSetGet, x )
      ENDIF
   ENDIF

   IF ::IsAlive()
      RETURN HGtkTreeViewValue( ::hWnd )
   ENDIF

RETURN IIf( ::bSetGet != NIL .AND. ValType( Eval( ::bSetGet ) ) == "N", ;
            Eval( ::bSetGet ), 0 )

/* Row( [ n ] ) — la fila n, o la elegida si no se indica */
METHOD Row( n ) CLASS TBrowse

   IF ValType( n ) != "N"
      n := ::Value()
   ENDIF

   IF ValType( n ) == "N" .AND. n >= 1 .AND. n <= Len( ::aDatos )
      RETURN ::aDatos[ Int( n ) ]
   ENDIF

RETURN NIL

/*
 * SetData( a ) — cambia todos los datos. Se conserva la fila elegida
 * si sigue existiendo; si no, la selección queda en 0.
 */
METHOD SetData( a ) CLASS TBrowse

   LOCAL nAntes, aFila

   IF ! HB_IsArray( a )
      a := {}
   ENDIF

   nAntes  := ::Value()
   ::aDatos := a

   IF ! ::IsAlive()
      RETURN NIL
   ENDIF

   HGtkTreeViewClear( ::hWnd )
   FOR EACH aFila IN a
      HGtkTreeViewAdd( ::hWnd, HgtkTextos( ;
         IIf( HB_IsArray( aFila ), aFila, {} ) ) )
   NEXT

   IF nAntes >= 1 .AND. nAntes <= Len( a )
      HGtkTreeViewSelect( ::hWnd, nAntes )
   ENDIF

RETURN NIL

/* De la fila elegida a la variable, y ACTION si la hay */
METHOD Escribir() CLASS TBrowse

   LOCAL nFila

   IF ! ::IsAlive()
      RETURN NIL
   ENDIF

   nFila := HGtkTreeViewValue( ::hWnd )
   IF nFila > 0
      IF ::bSetGet != NIL
         Eval( ::bSetGet, nFila )
      ENDIF
      IF ::bAction != NIL
         Eval( ::bAction )
      ENDIF
   ENDIF

RETURN NIL
