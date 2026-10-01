/*
 * tree.prg — TTree: árbol de categorías (GtkTreeView)
 *
 * Los datos entran con la cláusula ITEMS, un array de textos o de
 * arrays { texto, hijos }, anidado cuanto haga falta. La variable de
 * VAR guarda la RUTA DE ETIQUETAS del nodo elegido, unidas con "/"
 * ("Clientes/Zona norte"), que es también lo que devuelve Value().
 *
 * IMPORTANTE — cómo manda GTK la selección (medido en la fase 4):
 *   - un nodo sólo se puede elegir si sus padres están expandidos, y
 *     al colapsar la rama se deselecciona lo que había dentro; por
 *     eso al elegir se expande antes la rama;
 *   - antes de que la ventana se muestre la selección no se puede
 *     poner (GTK elige sola la primera fila al mapear): lo que se
 *     pida mientras tanto se guarda y se aplica nada más mostrar, de
 *     modo que Value() inicial y ACTION llegan a valer. Eso sí, al
 *     mostrarse la ventana se evalúa ACTION con el nodo inicial: la
 *     ventana puede refrescarse en ese momento.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TTree FROM TControl

   VAR aItems      INIT  {}     // datos declarados con ITEMS
   VAR bSetGet     INIT  NIL    // bloque de enlace con la variable
   VAR bAction     INIT  NIL    // se evalúa al elegir nodo

   METHOD New( oParent, bSetGet, aItems, nRow, nCol, nHeight, nWidth, ;
               bAction ) CONSTRUCTOR
   METHOD Value( x ) SETGET
   METHOD Escribir()            // del nodo a la variable y ACTION

ENDCLASS

/*
 * New( oParent, bSetGet, aItems [, nRow, nCol, nHeight, nWidth
 *      [, bAction ]] )
 */
METHOD New( oParent, bSetGet, aItems, nRow, nCol, nHeight, nWidth, ;
            bAction ) CLASS TTree

   LOCAL cValor := ""

   IF PCount() < 2 .OR. ValType( bSetGet ) != "B"
      bSetGet := NIL
   ENDIF
   IF PCount() < 3 .OR. ValType( aItems ) != "A"
      aItems := {}
   ENDIF
   IF PCount() < 8 .OR. ValType( bAction ) != "B"
      bAction := NIL
   ENDIF

   ::bSetGet := bSetGet
   ::bAction := bAction
   ::aItems  := aItems

   ::Init( oParent, nRow, nCol, nHeight, nWidth )

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkTreeNew() )
      IF ::IsAlive()
         IF Len( ::aItems ) > 0
            HGtkTreeItems( ::hWnd, ::aItems )
         ENDIF

         /* selección inicial, tomada de la variable: se guarda como
          * pendiente y GTK la aplica al mostrar la ventana */
         IF ::bSetGet != NIL
            cValor := Eval( ::bSetGet )
            IF ValType( cValor ) == "C" .AND. ! Empty( cValor )
               HGtkTreeSelect( ::hWnd, cValor )
            ENDIF
         ENDIF

         HGtkSetSignal( ::hWnd, "cursor-changed", {|| ::Escribir() } )
      ENDIF
   ELSE
      ::Place( NIL )
   ENDIF

RETURN SELF

/*
 * Value() lee o cambia el nodo elegido, como ruta de etiquetas
 * ("Clientes/Zona norte"). Leer devuelve lo que marca el árbol ahora
 * mismo, que si aún no se ha mostrado es la variable enlazada.
 */
METHOD Value( x ) CLASS TTree

   IF PCount() > 0
      IF ValType( x ) != "C"
         HgtkErrArgs( "TTree:Value", "la ruta debe ser una cadena" )
      ELSEIF ::IsAlive()
         IF HGtkTreeSelect( ::hWnd, x )
            IF ::bSetGet != NIL
               Eval( ::bSetGet, x )
            ENDIF
         ELSE
            HgtkErrArgs( "TTree:Value", "no existe ese nodo en el árbol" )
         ENDIF
      ELSEIF ::bSetGet != NIL
         Eval( ::bSetGet, x )
      ENDIF
   ENDIF

   IF ::IsAlive()
      RETURN HGtkTreeValue( ::hWnd )
   ENDIF

RETURN IIf( ::bSetGet != NIL .AND. ValType( Eval( ::bSetGet ) ) == "C", ;
            Eval( ::bSetGet ), "" )

/* Del nodo elegido a la variable y, si la hay, ACTION */
METHOD Escribir() CLASS TTree

   LOCAL cRuta

   IF ! ::IsAlive()
      RETURN NIL
   ENDIF

   cRuta := HGtkTreeValue( ::hWnd )

   /* sin selección (por ejemplo, al colapsar una rama) no se toca la
    * variable: se queda en el último nodo elegido, como la lista */
   IF ! Empty( cRuta )
      IF ::bSetGet != NIL
         Eval( ::bSetGet, cRuta )
      ENDIF
      IF ::bAction != NIL
         Eval( ::bAction )
      ENDIF
   ENDIF

RETURN NIL
