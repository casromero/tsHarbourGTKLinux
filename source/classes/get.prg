/*
 * get.prg — TGet: campo de entrada de una línea
 *
 * El valor vive en la variable Harbour: el comando DEFINE GET arma un
 * codeblock de enlace (bSetGet) que lee y escribe esa variable. El
 * control sincroniza el texto del campo con la variable en cada
 * cambio, de modo que al cerrar el diálogo la variable ya tiene lo
 * que se escribió, aunque el cierre venga de la barra de título.
 *
 * bValid se evalúa al perder el foco; si devuelve .F. el foco se
 * devuelve al campo, es decir, no se puede salir de él.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TGet FROM TControl

   VAR bSetGet     INIT  NIL    // bloque de enlace con la variable
   VAR bValid      INIT  NIL    // validación al perder el foco
   VAR cTexto      INIT  ""     // último texto conocido

   METHOD New( oParent, bSetGet, nRow, nCol, nHeight, nWidth, bValid ) ;
      CONSTRUCTOR
   METHOD Value( x ) SETGET
   METHOD Validar()
   METHOD Escribir()            // del campo a la variable

ENDCLASS

/* Convierte el valor de la variable en texto para el campo */
STATIC FUNCTION ATexto( xValor )

   DO CASE
   CASE ValType( xValor ) == "C"
      RETURN xValor
   CASE ValType( xValor ) == "N"
      RETURN LTrim( Str( xValor ) )
   CASE ValType( xValor ) == "D"
      RETURN DToC( xValor )
   CASE ValType( xValor ) == "L"
      RETURN iif( xValor, ".T.", ".F." )
   ENDCASE

RETURN ""

/* Convierte el texto del campo al tipo que tiene la variable */
STATIC FUNCTION DeTexto( cTexto, xActual )

   DO CASE
   CASE ValType( xActual ) == "N"
      RETURN Val( cTexto )
   CASE ValType( xActual ) == "D"
      RETURN CTod( cTexto )
   CASE ValType( xActual ) == "L"
      RETURN Left( Upper( AllTrim( cTexto ) ), 1 ) $ "TSY1"
   ENDCASE

RETURN cTexto

/*
 * New( oParent, bSetGet [, nRow, nCol, nHeight, nWidth [, bValid ]] )
 *   bSetGet  {|x| iif( PCount() > 0, xVar := x, xVar ) }
 *   bValid   bloque sin argumentos; .F. impide salir del campo
 */
METHOD New( oParent, bSetGet, nRow, nCol, nHeight, nWidth, bValid ) ;
      CLASS TGet

   IF ValType( bSetGet ) != "B"
      HgtkErrArgs( "TGet:New", "se esperaba un bloque de enlace (VAR)" )
      bSetGet := NIL
   ENDIF
   IF PCount() < 7
      bValid := NIL
   ENDIF
   IF bValid != NIL .AND. ValType( bValid ) != "B"
      HgtkErrArgs( "TGet:New", "VALID debe ser un codeblock" )
      bValid := NIL
   ENDIF

   ::Init( oParent, nRow, nCol, nHeight, nWidth )
   IF ::nWidth == 0
      ::nWidth := HGTK_GET_COLS_DEF
   ENDIF

   ::bSetGet := bSetGet
   ::bValid  := bValid
   ::cTexto  := IIf( bSetGet == NIL, "", ATexto( Eval( bSetGet ) ) )

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkEntryNew( ::cTexto ) )
      IF ::IsAlive()
         HGtkSetSignal( ::hWnd, "changed", {|| ::Escribir() } )
         HGtkSetValid( ::hWnd, {|| ::Validar() } )
      ENDIF
   ELSE
      ::Place( NIL )
   ENDIF

RETURN SELF

/* Value() lee el texto del campo o lo cambia (y actualiza la variable) */
METHOD Value( x ) CLASS TGet

   IF PCount() > 0
      IF ValType( x ) != "C"
         x := ATexto( x )
      ENDIF
      ::cTexto := x
      IF ::IsAlive()
         HGtkSetText( ::hWnd, x )     // "changed" sincroniza la variable
      ELSE
         ::Escribir()
      ENDIF
   ELSEIF ::IsAlive()
      ::cTexto := HGtkGetText( ::hWnd )
   ENDIF

RETURN ::cTexto

/* Validación: .T. salvo que bValid devuelva .F. de forma expresa */
METHOD Validar() CLASS TGet

   LOCAL xResultado

   IF ::bValid == NIL
      RETURN .T.
   ENDIF
   IF ValType( ::bValid ) != "B"
      HgtkErrArgs( "TGet:Validar", "bValid debe ser un codeblock" )
      RETURN .T.
   ENDIF

   xResultado := Eval( ::bValid )
   IF ValType( xResultado ) == "L" .AND. ! xResultado
      RETURN .F.
   ENDIF

RETURN .T.

/* Escribe en la variable lo que haya en el campo (si la hay) */
METHOD Escribir() CLASS TGet

   IF ::bSetGet == NIL
      RETURN NIL
   ENDIF

   IF ::IsAlive()
      ::cTexto := HGtkGetText( ::hWnd )
   ENDIF

   Eval( ::bSetGet, DeTexto( ::cTexto, Eval( ::bSetGet ) ) )

RETURN NIL
