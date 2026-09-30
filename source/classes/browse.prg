/*
 * browse.prg — TBrowse: tabla editable sobre un array o sobre un DBF
 *
 * GtkTreeView con una columna por cabecera, dentro de un marco de
 * desplazamiento: eso devuelve HGtkTreeViewNew y eso es lo que la
 * clase lleva en hWnd, que es lo que permite ver y desplazar las
 * filas que no caben. Los datos son un array de arrays y la variable
 * guarda el número de la fila elegida (1 por la primera).
 *
 * La fase 3 añade:
 *
 *   - orden por columna: se pulsa la cabecera o se llama a Ordenar().
 *     El orden lo hace Harbour sobre aDatos; aReg, que lleva el
 *     número de registro de cada fila, se reordena a la par y por eso
 *     una edición sigue cayendo en su registro después de ordenar.
 *   - edición de celda con EDIT (F2 o doble clic): la celda se escribe
 *     con Poner(), que la cambia en aDatos y, si hay fichero, en él.
 *   - el origen de DATA puede ser un TDataBase además de un array.
 *
 * Al cambiar de fila con el teclado o con el ratón se escribe en la
 * variable y se evalúa ACTION, que también se evalúa al terminar de
 * editar una celda.
 *
 * Todas las comparaciones de texto de este fichero son exactas
 * (ComparaTexto): con SET EXACT OFF, que es la omisión de Harbour,
 * "x != texto" sólo mira los primeros caracteres y contra "" da
 * siempre .F. (ver docs/api-fase0.md §12).
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TBrowse FROM TControl

   VAR bSetGet     INIT  NIL    // bloque de enlace con la variable
   VAR bAction     INIT  NIL    // fila cambiada o celda editada
   VAR aCabeceras  INIT  {}     // títulos de las columnas
   VAR aDatos      INIT  {}     // filas: array de arrays
   VAR aReg        INIT  {}     // nº de registro de cada fila, en par
   VAR oOrigen     INIT  NIL    // TDataBase de donde salen los datos
   VAR lEditar     INIT  .F.    // .T.: se escribe en la celda (EDIT)
   VAR nOrdenCol   INIT  0      // columna por la que está ordenado
   VAR lOrdenAsc   INIT  .T.    // sentido del orden vigente

   METHOD New( oParent, bSetGet, aCabeceras, aDatos, nRow, nCol, ;
               nHeight, nWidth, bAction, lEditar ) CONSTRUCTOR
   METHOD Value( x ) SETGET
   METHOD Row( n )
   METHOD FijarDatos( xDatos )
   METHOD SetData( a )
   METHOD Refrescar( nFila )
   METHOD Reordenar()
   METHOD Ordenar( nCol, lDesc )
   METHOD Anadir( aFila )
   METHOD Poner( nFila, nCol, xValor )
   METHOD Editada( nFila, nCol, cTexto )
   METHOD ClicColumna( nCol )
   METHOD Escribir()            // de la fila a la variable y ACTION

ENDCLASS

/*
 * New( oParent, bSetGet, aCabeceras, aDatos
 *      [, nRow, nCol, nHeight, nWidth [, bAction [, lEditar ]]] )
 *   aCabeceras  títulos de las columnas (cláusula FIELDS)
 *   aDatos      array de arrays o TDataBase (cláusula DATA)
 *   lEditar     .T. con la cláusula EDIT
 */
METHOD New( oParent, bSetGet, aCabeceras, aDatos, nRow, nCol, ;
            nHeight, nWidth, bAction, lEditar ) CLASS TBrowse

   LOCAL nValor, nColCab

   IF ValType( bSetGet ) != "B"
      HgtkErrArgs( "TBrowse:New", "se esperaba un bloque de enlace (VAR)" )
      bSetGet := NIL
   ENDIF
   IF PCount() < 3 .OR. ! HB_IsArray( aCabeceras )
      aCabeceras := {}
   ENDIF

   ::Init( oParent, nRow, nCol, nHeight, nWidth )
   ::bSetGet    := bSetGet
   ::bAction    := IIf( ValType( bAction ) == "B", bAction, NIL )
   ::aCabeceras := aCabeceras
   ::lEditar    := IIf( PCount() >= 10 .AND. ValType( lEditar ) == "L", ;
                        lEditar, .F. )

   ::FijarDatos( IIf( PCount() >= 4, aDatos, {} ) )

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
      /* la fila inicial, tomada de la variable, antes de conectar la
       * señal: la primera no dispara ACTION */
      ::Refrescar( IIf( ValType( nValor ) == "N" .AND. nValor >= 1 .AND. ;
                        nValor <= Len( ::aDatos ), Int( nValor ), 0 ) )

      /* cabeceras ordenables (con el número de columna) y, con EDIT,
       * celdas editables (fila, columna y texto nuevo) */
      FOR nColCab := 1 TO Len( ::aCabeceras )
         HGtkTreeViewOrden( ::hWnd, nColCab, ;
                            { | nCol| ::ClicColumna( nCol ) } )
      NEXT
      IF ::lEditar
         HGtkTreeViewEditar( ::hWnd, ;
            { | nFila, nCol, cTexto| ::Editada( nFila, nCol, cTexto ) } )
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
 * FijarDatos( xDatos ) — de dónde salen las filas: un array de arrays
 * o un TDataBase (Cargar + Registros). aReg lleva el número de
 * registro de cada fila en el mismo orden que aDatos: sin fichero es
 * la posición y con fichero es lo que devuelve Registros(), y así
 * ordenar por una columna no descuadra nada.
 */
METHOD FijarDatos( xDatos ) CLASS TBrowse

   LOCAL aFilas := {}, aRegs := {}, nFila

   IF ValType( xDatos ) == "O" .AND. ;
      __objHasMsg( xDatos, "Cargar" ) .AND. ;
      __objHasMsg( xDatos, "Registros" )

      ::oOrigen := xDatos
      aFilas := ::oOrigen:Cargar()
      aRegs  := ::oOrigen:Registros()
      IF ! HB_IsArray( aFilas )
         aFilas := {}
      ENDIF
      IF ! HB_IsArray( aRegs )
         aRegs := {}
      ENDIF
   ELSE
      ::oOrigen := NIL
      IF HB_IsArray( xDatos )
         aFilas := xDatos
      ENDIF
   ENDIF

   /* aReg y aDatos van siempre a la par; si algo no cuadra, con la
    * posición basta para seguir sin romper el enlace */
   IF Len( aRegs ) != Len( aFilas )
      aRegs := {}
      FOR nFila := 1 TO Len( aFilas )
         AAdd( aRegs, nFila )
      NEXT
   ENDIF

   ::aDatos := aFilas
   ::aReg   := aRegs

RETURN NIL

/*
 * SetData( a ) — cambia el origen de los datos (array o TDataBase) y
 * vuelve a montar la vista. Se conserva la fila elegida si sigue
 * existiendo; si no, la selección queda en 0.
 */
METHOD SetData( a ) CLASS TBrowse

   LOCAL nAntes := ::Value()

   ::FijarDatos( a )

   IF nAntes < 1 .OR. nAntes > Len( ::aDatos )
      nAntes := 0
   ENDIF
   ::Refrescar( nAntes )

RETURN NIL

/*
 * Refrescar( [ nFila ] ) — vuelve a montar la vista con aDatos, que
 * es lo que toca tras ordenar, dar de alta o cambiar el origen. Sin
 * nFila se queda en la fila que estaba, leída antes de vaciarla. La
 * flecha de orden se pone según nOrdenCol y lOrdenAsc.
 */
METHOD Refrescar( nFila ) CLASS TBrowse

   LOCAL nInd, aFila

   IF ! ::IsAlive()
      RETURN NIL
   ENDIF

   IF ValType( nFila ) != "N"
      nFila := ::Value()
   ENDIF

   HGtkTreeViewClear( ::hWnd )
   FOR nInd := 1 TO Len( ::aDatos )
      aFila := ::aDatos[ nInd ]
      HGtkTreeViewAdd( ::hWnd, HgtkTextos( ;
         IIf( HB_IsArray( aFila ), aFila, {} ) ) )
   NEXT

   HGtkTreeViewOrdenMarca( ::hWnd, ::nOrdenCol, ::lOrdenAsc )

   IF nFila >= 1 .AND. nFila <= Len( ::aDatos )
      HGtkTreeViewSelect( ::hWnd, Int( nFila ) )   // la señal sincroniza
   ENDIF

RETURN NIL

/*
 * Reordenar() — deja aDatos y aReg en el orden de nOrdenCol con el
 * sentido de lOrdenAsc. No toca la vista: eso es Refrescar.
 */
METHOD Reordenar() CLASS TBrowse

   LOCAL aIdx, aFilas, aRegs, n, nCol

   nCol := ::nOrdenCol
   IF nCol < 1 .OR. Len( ::aDatos ) < 2
      RETURN NIL
   ENDIF

   aIdx := Array( Len( ::aDatos ) )
   FOR n := 1 TO Len( aIdx )
      aIdx[ n ] := n
   NEXT

   /* el bloque ordena los índices; aReg se mueve con ellos */
   ASort( aIdx, 1, Len( aIdx ), ;
      { | nA, nB | ;
         IIf( ::lOrdenAsc, ;
              Compara( ValorCol( ::aDatos[ nA ], nCol ), ;
                       ValorCol( ::aDatos[ nB ], nCol ) ) < 0, ;
              Compara( ValorCol( ::aDatos[ nA ], nCol ), ;
                       ValorCol( ::aDatos[ nB ], nCol ) ) > 0 ) } )

   aFilas := Array( Len( aIdx ) )
   aRegs  := Array( Len( aIdx ) )
   FOR n := 1 TO Len( aIdx )
      aFilas[ n ] := ::aDatos[ aIdx[ n ] ]
      aRegs[ n ]  := RegDe( ::aReg, aIdx[ n ] )
   NEXT

   ::aDatos := aFilas
   ::aReg   := aRegs

RETURN NIL

/*
 * Ordenar( nCol [, lDesc ] ) — reordena por la columna nCol (1-based)
 * y vuelve a montar la vista. La fila elegida se conserva por su
 * número de registro. lDesc .T. es de mayor a menor; por omisión, de
 * menor a mayor. Pulsando la cabecera se llama desde ClicColumna.
 */
METHOD Ordenar( nCol, lDesc ) CLASS TBrowse

   LOCAL nFila, nReg, nNueva

   IF ValType( nCol ) != "N" .OR. nCol < 1 .OR. nCol > Len( ::aCabeceras )
      HgtkErrArgs( "TBrowse:Ordenar", "columna fuera de rango" )
      RETURN NIL
   ENDIF
   IF ValType( lDesc ) != "L"
      lDesc := .F.
   ENDIF

   nFila := ::Value()
   nReg  := RegDe( ::aReg, nFila )

   ::nOrdenCol := Int( nCol )
   ::lOrdenAsc := ! lDesc
   ::Reordenar()

   nNueva := IIf( nFila >= 1, AScan( ::aReg, { | n| n == nReg } ), 0 )
   IF nNueva == 0 .AND. nFila >= 1 .AND. nFila <= Len( ::aDatos )
      nNueva := nFila
   ENDIF

   ::Refrescar( nNueva )

RETURN NIL

/*
 * Anadir( [ aFila ] ) -> número de registro de la fila nueva, 0 si no
 * se pudo dar de alta. Con origen en fichero se da de alta en él y se
 * guarda el número que devuelve; la fila nueva queda seleccionada.
 */
METHOD Anadir( aFila ) CLASS TBrowse

   LOCAL nReg, nNueva

   IF ! HB_IsArray( aFila )
      aFila := {}
   ENDIF

   IF ::oOrigen != NIL
      nReg := ::oOrigen:Anadir( aFila )
   ELSE
      nReg := Len( ::aDatos ) + 1
   ENDIF

   IF ValType( nReg ) != "N" .OR. nReg < 1
      HgtkErrArgs( "TBrowse:Anadir", "no se pudo dar de alta la fila" )
      RETURN 0
   ENDIF

   AAdd( ::aDatos, aFila )
   AAdd( ::aReg, nReg )

   IF ::nOrdenCol >= 1
      ::Reordenar()
   ENDIF

   nNueva := AScan( ::aReg, { | n| n == nReg } )
   ::Refrescar( nNueva )

RETURN nReg

/*
 * Poner( nFila, nCol, xValor ) -> lo que quedó escrito.
 * Cambia la celda de aDatos y, si hay origen, la escribe en el
 * fichero; lo que devuelve el fichero es lo que se enseña y lo que
 * devuelve este método, que no siempre es lo que se dio: un texto sin
 * número en un campo numérico se guarda como 0.
 */
METHOD Poner( nFila, nCol, xValor ) CLASS TBrowse

   IF ValType( nFila ) != "N" .OR. nFila < 1 .OR. nFila > Len( ::aDatos )
      HgtkErrArgs( "TBrowse:Poner", "fila fuera de rango" )
      RETURN NIL
   ENDIF
   IF ValType( nCol ) != "N" .OR. nCol < 1 .OR. nCol > Len( ::aCabeceras )
      HgtkErrArgs( "TBrowse:Poner", "columna fuera de rango" )
      RETURN NIL
   ENDIF

   IF ! HB_IsArray( ::aDatos[ nFila ] )
      ::aDatos[ nFila ] := {}
   ENDIF
   DO WHILE Len( ::aDatos[ nFila ] ) < nCol
      AAdd( ::aDatos[ nFila ], NIL )
   ENDDO
   ::aDatos[ nFila, nCol ] := xValor

   IF ::oOrigen != NIL
      xValor := ::oOrigen:Guardar( RegDe( ::aReg, nFila ), nCol, xValor )
      ::aDatos[ nFila, nCol ] := xValor
   ENDIF

   IF ::IsAlive()
      HGtkTreeViewPoner( ::hWnd, nFila, nCol, HgtkTexto( xValor ) )
   ENDIF

RETURN xValor

/*
 * Editada( nFila, nCol, cTexto ) — la señal "edited" del navegador:
 * el usuario terminó de escribir en la celda. Con EDIT se guarda y se
 * evalúa ACTION, que es también el aviso de que la tabla ha cambiado.
 * Fuera de tabla se ignora: esto viene de GTK y no debe romper nada.
 */
METHOD Editada( nFila, nCol, cTexto ) CLASS TBrowse

   IF ! ::lEditar
      RETURN NIL
   ENDIF
   IF ValType( nFila ) != "N" .OR. ValType( nCol ) != "N"
      RETURN NIL
   ENDIF
   IF nFila < 1 .OR. nFila > Len( ::aDatos ) .OR. ;
      nCol < 1 .OR. nCol > Len( ::aCabeceras )
      RETURN NIL
   ENDIF

   ::Poner( nFila, nCol, cTexto )
   ::Escribir()

RETURN NIL

/*
 * ClicColumna( nCol ) — se pulsó la cabecera: ordena por esa columna
 * y, si ya estaba ordenada por ella, cambia de sentido. Al final se
 * vuelve a poner el foco en la vista: el ratón se lo puede haber
 * llevado al título y la faena sigue con el teclado.
 */
METHOD ClicColumna( nCol ) CLASS TBrowse

   IF ValType( nCol ) != "N" .OR. nCol < 1 .OR. nCol > Len( ::aCabeceras )
      RETURN NIL
   ENDIF

   ::Ordenar( nCol, IIf( nCol == ::nOrdenCol, ! ::lOrdenAsc, .F. ) )
   ::SetFocus()

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

/* ------------------------------------------------------------------ */
/* orden: comparaciones exactas                                        */
/* ------------------------------------------------------------------ */

/* valor de la columna nCol de una fila, o NIL si la fila no la tiene */
STATIC FUNCTION ValorCol( aFila, nCol )

   IF HB_IsArray( aFila ) .AND. nCol >= 1 .AND. nCol <= Len( aFila )
      RETURN aFila[ nCol ]
   ENDIF

RETURN NIL

/* número de registro de la fila n; sin aReg a la par, la posición */
STATIC FUNCTION RegDe( aReg, n )

   IF HB_IsArray( aReg ) .AND. n >= 1 .AND. n <= Len( aReg )
      RETURN aReg[ n ]
   ENDIF

RETURN n

/* Compara( x, y ) -> -1, 0 o 1: números como números, fechas como
 * fechas y todo lo demás como texto exacto */
STATIC FUNCTION Compara( x, y )

   IF ValType( x ) == "N" .AND. ValType( y ) == "N"
      RETURN IIf( x < y, -1, IIf( x == y, 0, 1 ) )
   ELSEIF ValType( x ) == "D" .AND. ValType( y ) == "D"
      RETURN IIf( x < y, -1, IIf( x == y, 0, 1 ) )
   ENDIF

RETURN ComparaTexto( HgtkTexto( x ), HgtkTexto( y ) )

/*
 * ComparaTexto( cA, cB ) -> -1, 0 o 1 — orden de texto exacto.
 *
 * El "<" de Harbour con SET EXACT OFF (la omisión) sólo mira los
 * primeros caracteres del texto de la derecha, y con eso "abc" y "ab"
 * serían iguales y el orden dejaría de ser un orden. Por eso se
 * prueba primero "<": cuando dice que sí, es cierto; lo que sobre lo
 * resuelve "==", que sí es exacto. Queda cubierto el caso en que un
 * texto es prefijo del otro (entra el más corto).
 */
STATIC FUNCTION ComparaTexto( cA, cB )

   IF cA < cB
      RETURN -1
   ENDIF
   IF cA == cB
      RETURN 0
   ENDIF

RETURN 1
