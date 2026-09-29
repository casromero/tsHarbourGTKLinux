/*
 * radio.prg — TRadio: botón de radio, agrupado por variable
 *
 * Dos radios del mismo padre y con la misma variable (cláusula VAR
 * del comando) forman un grupo: el segundo nace ligado al primero y
 * GTK se encarga de que sólo uno esté marcado. La variable guarda el
 * número de opción (1, 2, 3...) de la opción marcada.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TRadio FROM TControl

   VAR bSetGet     INIT  NIL    // bloque de enlace con la variable
   VAR cVar        INIT  ""     // nombre de la variable (para agrupar)
   VAR nOpcion     INIT  0      // número de esta opción

   METHOD New( oParent, cVar, nOpcion, bSetGet, cPrompt, ;
               nRow, nCol, nHeight, nWidth ) CONSTRUCTOR
   METHOD Value( x ) SETGET
   METHOD Escribir()            // de la casilla a la variable

ENDCLASS

/* Último radio del padre que usa la misma variable, si ya existe */
STATIC FUNCTION RadioDeGrupo( oPadre, cVar )

   LOCAL oCtrl

   IF ValType( oPadre ) != "O" .OR. ! __objHasMsg( oPadre, "aControles" )
      RETURN NIL
   ENDIF

   FOR EACH oCtrl IN oPadre:aControles
      /* ClassName() devuelve el nombre en mayúsculas */
      IF ValType( oCtrl ) == "O" ;
         .AND. Upper( oCtrl:ClassName() ) == "TRADIO" ;
         .AND. oCtrl:cVar == cVar .AND. oCtrl:hWnd != NIL
         RETURN oCtrl
      ENDIF
   NEXT

RETURN NIL

/*
 * New( oParent, cVar, nOpcion, bSetGet, cPrompt [, nRow, nCol, nHeight, nWidth ] )
 *   cVar     nombre de la variable (texto; lo pone el comando)
 *   nOpcion  número de opción de este botón
 *   bSetGet  bloque de enlace con la variable numérica
 */
METHOD New( oParent, cVar, nOpcion, bSetGet, cPrompt, ;
            nRow, nCol, nHeight, nWidth ) CLASS TRadio

   LOCAL oAnterior := NIL
   LOCAL xValor

   IF ValType( bSetGet ) != "B"
      HgtkErrArgs( "TRadio:New", "se esperaba un bloque de enlace (VAR)" )
      bSetGet := NIL
   ENDIF
   IF ValType( cVar ) != "C"
      cVar := ""
   ENDIF
   IF ValType( nOpcion ) != "N"
      nOpcion := 0
   ENDIF
   IF PCount() < 8 .OR. ValType( cPrompt ) != "C"
      cPrompt := ""
   ENDIF

   ::Init( oParent, nRow, nCol, nHeight, nWidth )
   ::bSetGet := bSetGet
   ::cVar    := cVar
   ::nOpcion := nOpcion

   /* el anterior radio del mismo padre y variable es el ancla del grupo */
   IF ::oWnd != NIL
      oAnterior := RadioDeGrupo( ::oWnd, ::cVar )
   ENDIF

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkRadioNew( cPrompt, ;
                             IIf( oAnterior == NIL, NIL, oAnterior:hWnd ) ) )
   ELSE
      ::Place( NIL )
   ENDIF

   IF ::IsAlive()
      xValor := IIf( ::bSetGet == NIL, 0, Eval( ::bSetGet ) )
      HGtkSetActive( ::hWnd, ValType( xValor ) == "N" .AND. ;
                             xValor == ::nOpcion )
      HGtkSetSignal( ::hWnd, "toggled", {|| ::Escribir() } )
   ENDIF

RETURN SELF

/* Value() devuelve el número de opción si está marcado, 0 si no lo está.
 * Es de lectura: para cambiar la opción se marca otro radio. */
METHOD Value( x ) CLASS TRadio

   IF PCount() > 0
      HgtkErrArgs( "TRadio:Value", "es sólo de lectura" )
      RETURN 0
   ENDIF

   IF ! ::IsAlive()
      RETURN 0
   ENDIF

RETURN iif( HGtkGetActive( ::hWnd ), ::nOpcion, 0 )

/* Si este radio está marcado, escribe su número en la variable */
METHOD Escribir() CLASS TRadio

   IF ::bSetGet == NIL .OR. ! ::IsAlive()
      RETURN NIL
   ENDIF

   IF HGtkGetActive( ::hWnd )
      Eval( ::bSetGet, ::nOpcion )
   ENDIF

RETURN NIL
