/*
 * tabs.prg — TTabs: panel con pestañas (GtkNotebook)
 *
 * El panel es un control más de la ventana, con AT y SIZE. Cada
 * pestaña se declara con DEFINE PAGE y es un contenedor con su propio
 * sistema de coordenadas, como un grupo.
 *
 * La variable de VAR guarda el número de pestaña visible (1 por la
 * primera); se escribe sola al cambiar de pestaña, con el teclado o
 * con Value( n ), y ahí mismo se evalúa ACTION, si lo hay.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TTabs FROM TControl

   VAR aPaginas    INIT  {}     // páginas declaradas dentro
   VAR bSetGet     INIT  NIL    // bloque de enlace con la variable
   VAR bAction     INIT  NIL    // se evalúa al cambiar de pestaña

   METHOD New( oParent, bSetGet, nRow, nCol, nHeight, nWidth, bAction ) ;
          CONSTRUCTOR
   METHOD Value( x ) SETGET
   METHOD AddControl( oCtrl )
   METHOD Escribir( nSenal )   // de la pestaña a la variable y ACTION

ENDCLASS

/*
 * New( oParent, bSetGet [, nRow, nCol, nHeight, nWidth [, bAction ]] )
 * La pestaña visible inicial es la 1: si la variable arranca en otro
 * número se aplica con Value() cuando ya están las páginas.
 */
METHOD New( oParent, bSetGet, nRow, nCol, nHeight, nWidth, bAction ) ;
   CLASS TTabs

   IF PCount() < 2 .OR. ValType( bSetGet ) != "B"
      bSetGet := NIL
   ENDIF
   IF PCount() < 7 .OR. ValType( bAction ) != "B"
      bAction := NIL
   ENDIF

   ::bSetGet := bSetGet
   ::bAction := bAction

   ::Init( oParent, nRow, nCol, nHeight, nWidth )

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkTabsNew() )
   ELSE
      ::Place( NIL )
   ENDIF

   IF ::IsAlive()
      /* la clase se suscribe siempre: la variable se sincroniza aunque
       * la cláusula ACTION no esté. La pestaña nueva llega por la
       * señal: "switch-page" se emite ANTES de cambiar el panel, y
       * leyendo el panel se tendría la página anterior (medido en la
       * fase 4) */
      HGtkTabsAction( ::hWnd, {|n| ::Escribir( n ) } )
   ENDIF

RETURN SELF

/*
 * Value() lee o cambia la pestaña visible (base 1). Cambiarla dispara
 * "switch-page" y con él la sincronización con la variable.
 */
METHOD Value( x ) CLASS TTabs

   IF PCount() > 0
      IF ValType( x ) != "N"
         HgtkErrArgs( "TTabs:Value", "el número de pestaña debe ser" ;
                      + " un número" )
      ELSEIF ::IsAlive()
         HGtkTabsSelect( ::hWnd, x )
      ENDIF
   ENDIF

   IF ::IsAlive()
      RETURN HGtkTabsPage( ::hWnd )
   ENDIF

RETURN 0

/* Registra una página dentro del panel (lo llama TControl:Place) */
METHOD AddControl( oCtrl ) CLASS TTabs

   IF ValType( oCtrl ) == "O"
      AAdd( ::aPaginas, oCtrl )
   ENDIF

RETURN NIL

/*
 * Escribir( [ nSenal ] ) — de la pestaña visible a la variable y,
 * si la hay, ACTION. Si trae el número que manda la señal se usa
 * ése (ver arriba); sin número, se lee el panel.
 */
METHOD Escribir( nSenal ) CLASS TTabs

   LOCAL nPag

   IF ! ::IsAlive()
      RETURN NIL
   ENDIF

   IF PCount() > 0 .AND. ValType( nSenal ) == "N" .AND. nSenal >= 1
      nPag := nSenal
   ELSE
      nPag := HGtkTabsPage( ::hWnd )
   ENDIF

   IF nPag > 0 .AND. ::bSetGet != NIL
      Eval( ::bSetGet, nPag )
   ENDIF
   IF ::bAction != NIL
      Eval( ::bAction )
   ENDIF

RETURN NIL
