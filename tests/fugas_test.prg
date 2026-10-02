/*
 * fugas_test — abrir y cerrar ventanas en bucle (fase 5)
 *
 * Repite dos ventanas de la familia de los ejemplos —una con menú,
 * campos, lista, browse y temporizador; otra con pestañas, árbol, caja
 * y botones, como la aplicación de la fase 4— y tras cada ciclo mira
 * con HGtkCuentas() que las cuatro cuentas del puente (ventanas,
 * controles, relojes y grips de GC) vuelven a las de partida. Si un
 * codeblock se quedara sujeto, el número de grips subiría con cada
 * vuelta y no bajaría.
 *
 * Mientras la ventana está abierta las cuentas deben ser MAYORES que
 * las de partida (ventana creada, controles colgados, relojes creados
 * y bloques sujetos): así el contador no puede dar un falso "todo a
 * cero". Después de los ciclos con ventana, se crean y destruyen tres
 * ventanas sin siquiera activarlas, que es el otro camino de cierre.
 *
 * Cada ventana se cierra sola con su temporizador, que llama a End()
 * desde el propio bloque dentro de un disparo: es un camino que el
 * puente soporta a propósito (nDentro/fCaduco en hbgtk_timer.c).
 *
 * Esta prueba abre ventanas, así que necesita display: va en el smoke
 * bajo Xvfb, no en make test.
 *
 * Compilar:  make smoke      (o make con la regla tests/fugas_test)
 * Ejecutar:  xvfb-run -a tests/fugas_test
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

FUNCTION Main()

   LOCAL cFallo := ""
   LOCAL aBase
   LOCAL nCiclo, cErr

   ? "HarbGtkLin " + LTrim( Str( HGTK_FASE ) ) + ;
     " - prueba de fugas: abrir y cerrar ventanas en bucle"

   aBase := HGtkCuentas()

   IF ! CuentasIguales( aBase, { 0, 0, 0, 0 } )
      ? "fugas_test: FALLO - se empieza con las cuentas " + ;
        Cuenta( aBase )
      ErrorLevel( 1 )
      ? ""
      RETURN NIL
   ENDIF

   /* seis ciclos alternando las dos familias de ventana */
   FOR nCiclo := 1 TO 6
      IF Mod( nCiclo, 2 ) == 1
         cErr := CicloListado( nCiclo, aBase )
      ELSE
         cErr := CicloFicha( nCiclo, aBase )
      ENDIF
      IF cErr != ""
         cFallo := "ciclo " + LTrim( Str( nCiclo ) ) + ": " + cErr
         EXIT
      ENDIF
   NEXT

   /* tres ventanas creadas y destruidas sin activarlas: el otro
    * camino de cierre, sin llegar ni a mostrarse */
   IF cFallo == ""
      FOR nCiclo := 1 TO 3
         cErr := CicloSinActivar( nCiclo, aBase )
         IF cErr != ""
            cFallo := "sin activar, ciclo " + LTrim( Str( nCiclo ) ) + ;
                      ": " + cErr
            EXIT
         ENDIF
      NEXT
   ENDIF

   ? ""

   IF cFallo == ""
      ? "fugas_test: OK"
   ELSE
      ? "fugas_test: FALLO -", cFallo
      ErrorLevel( 1 )
   ENDIF
   ? ""

RETURN NIL

/* ------------------------------------------------------------------ */
/* los ciclos                                                          */
/* ------------------------------------------------------------------ */

/*
 * CicloListado( nCiclo, aBase ) — ventana de la familia de los
 * ejemplos 02, 03 y 04: menú, barra de estado, campos, lista, browse
 * y un temporizador que la cierra a los 400 ms desde dentro de
 * ACTIVATE. Devuelve "" si todo vuelve a las cuentas de aBase.
 */
STATIC FUNCTION CicloListado( nCiclo, aBase )

   LOCAL cErr
   LOCAL cTexto := "hola", lMarcar := .T.
   LOCAL nCmb := 1, nLst := 1, nSel := 1
   LOCAL aItems := { "Uno", "Dos" }
   LOCAL aCab := { "Código", "Nombre" }
   LOCAL aDat := { { 1, "Ana" }, { 2, "Luis" } }
   LOCAL oWnd, oMenu, oPop, oIt, oSta, oSay, oGet, oChk, oCmb
   LOCAL oLst, oBrw, oTick

   DEFINE WINDOW oWnd ;
      TITLE "fugas listado " + LTrim( Str( nCiclo ) ) SIZE 20, 60
   DEFINE MENU oMenu OF oWnd
   DEFINE POPUP oPop OF oMenu PROMPT "&Archivo"
   DEFINE MENUITEM oIt OF oPop PROMPT "&Salir" ACTION {|| NIL }
   DEFINE STATUS oSta OF oWnd
   DEFINE SAY oSay OF oWnd PROMPT "Fila:" AT 1, 1 SIZE 1, 8
   DEFINE GET oGet OF oWnd VAR cTexto AT 1, 10 SIZE 1, 20
   DEFINE CHECKBOX oChk OF oWnd VAR lMarcar PROMPT "&Marcar" ;
      AT 2, 1 SIZE 1, 12
   DEFINE COMBOBOX oCmb OF oWnd VAR nCmb ITEMS aItems ;
      AT 3, 1 SIZE 3, 20
   DEFINE LISTBOX oLst OF oWnd VAR nLst ITEMS aItems ;
      AT 4, 1 SIZE 4, 25 ACTION {|| NIL }
   DEFINE BROWSE oBrw OF oWnd VAR nSel FIELDS aCab DATA aDat ;
      AT 9, 1 SIZE 5, 40
   DEFINE TIMER oTick OF oWnd INTERVAL 400 ;
      ACTION {|| oWnd:End() }

   cErr := Abierta( HGtkCuentas(), aBase )

   IF cErr == ""
      ACTIVATE MENU oMenu
      ACTIVATE TIMER oTick
      ACTIVATE WINDOW oWnd
      cErr := Cerrada( HGtkCuentas(), aBase )
   ELSE
      oWnd:End()
   ENDIF

RETURN cErr

/*
 * CicloFicha( nCiclo, aBase ) — ventana de la familia de la
 * aplicación de la fase 4: panel con pestañas (con un GET dentro de
 * la página), árbol de categorías y una caja con dos botones. La
 * cierra también su temporizador.
 */
STATIC FUNCTION CicloFicha( nCiclo, aBase )

   LOCAL cErr
   LOCAL nPag := 1, cRuta := "Norte/0001 Aceros", cTexto := "Ana"
   LOCAL aArb := { { "Norte", { "0001 Aceros" } }, ;
                   { "Sur", { "0003 Vientos" } } }
   LOCAL oWnd, oTabs, oPag1, oPag2, oGet, oSay, oArb, oCaja
   LOCAL oBt1, oBt2, oTick

   DEFINE WINDOW oWnd ;
      TITLE "fugas ficha " + LTrim( Str( nCiclo ) ) SIZE 24, 60
   DEFINE TABS oTabs OF oWnd VAR nPag AT 1, 1 SIZE 8, 40 ;
      ACTION {|| NIL }
   DEFINE PAGE oPag1 OF oTabs PROMPT "&Datos"
   DEFINE PAGE oPag2 OF oTabs PROMPT "&Notas"
   DEFINE SAY oSay OF oPag1 PROMPT "Nombre:" AT 1, 1 SIZE 1, 8
   DEFINE GET oGet OF oPag1 VAR cTexto AT 1, 10 SIZE 1, 20
   DEFINE TREE oArb OF oWnd VAR cRuta ITEMS aArb ;
      AT 10, 1 SIZE 6, 25 ACTION {|| NIL }
   DEFINE BOX oCaja OF oWnd HORIZONTAL AT 17, 1 SIZE 2, 30
   DEFINE BUTTON oBt1 OF oCaja PROMPT "Uno" SIZE 1, 10 ;
      ACTION {|| NIL }
   DEFINE BUTTON oBt2 OF oCaja PROMPT "Dos" SIZE 1, 10 ;
      ACTION {|| NIL }
   DEFINE TIMER oTick OF oWnd INTERVAL 400 ;
      ACTION {|| oWnd:End() }

   cErr := Abierta( HGtkCuentas(), aBase )

   IF cErr == ""
      ACTIVATE TIMER oTick
      ACTIVATE WINDOW oWnd
      cErr := Cerrada( HGtkCuentas(), aBase )
   ELSE
      oWnd:End()
   ENDIF

RETURN cErr

/*
 * CicloSinActivar( nCiclo, aBase ) — la ventana se crea con menú,
 * campo y temporizador arrancado, y se destruye sin llegar a
 * activarse: no se muestra, pero tira de los mismos caminos de
 * grips y de listas al destruirse.
 */
STATIC FUNCTION CicloSinActivar( nCiclo, aBase )

   LOCAL cErr
   LOCAL cTexto := "x"
   LOCAL oWnd, oMenu, oPop, oIt, oGet, oTick

   DEFINE WINDOW oWnd ;
      TITLE "fugas sin activar " + LTrim( Str( nCiclo ) ) SIZE 12, 40
   DEFINE MENU oMenu OF oWnd
   DEFINE POPUP oPop OF oMenu PROMPT "&Archivo"
   DEFINE MENUITEM oIt OF oPop PROMPT "&Salir" ACTION {|| NIL }
   ACTIVATE MENU oMenu
   DEFINE GET oGet OF oWnd VAR cTexto AT 1, 1 SIZE 1, 20
   DEFINE TIMER oTick OF oWnd INTERVAL 600000 ACTION {|| NIL }
   ACTIVATE TIMER oTick

   cErr := Abierta( HGtkCuentas(), aBase )

   oWnd:End()

   IF cErr == ""
      cErr := Cerrada( HGtkCuentas(), aBase )
   ENDIF

RETURN cErr

/* ------------------------------------------------------------------ */
/* comprobaciones de las cuentas                                       */
/* ------------------------------------------------------------------ */

/*
 * Abierta( aAbi, aBase ) — con la ventana creada debe haber una
 * ventana más, más controles colgados, más relojes y más grips (los
 * codeblocks sujetos). Si alguna cuenta no sube, el contador no
 * serviría para nada y el resto de la prueba sería un papel mojado.
 */
STATIC FUNCTION Abierta( aAbi, aBase )

   IF aAbi[ 1 ] != aBase[ 1 ] + 1
      RETURN "había que ver una ventana más y las cuentas son " + ;
             Cuenta( aAbi )
   ENDIF
   IF ! ( aAbi[ 2 ] > aBase[ 2 ] )
      RETURN "con la ventana abierta no se ven controles: " + ;
             Cuenta( aAbi )
   ENDIF
   IF ! ( aAbi[ 3 ] > aBase[ 3 ] )
      RETURN "con la ventana abierta no se ven relojes: " + ;
             Cuenta( aAbi )
   ENDIF
   IF ! ( aAbi[ 4 ] > aBase[ 4 ] )
      RETURN "con la ventana abierta no se ven grips: " + Cuenta( aAbi )
   ENDIF

RETURN ""

/* Cerrada( aFin, aBase ) — al destruir la ventana, las cuatro
 * cuentas tienen que volver exactamente a las de partida */
STATIC FUNCTION Cerrada( aFin, aBase )

   IF ! CuentasIguales( aFin, aBase )
      RETURN "al volver deben quedar " + Cuenta( aBase ) + ;
             " y quedan " + Cuenta( aFin )
   ENDIF

RETURN ""

/* ------------------------------------------------------------------ */
/* utilidades                                                          */
/* ------------------------------------------------------------------ */

/* Cuenta( a ) — las cuatro cuentas en una sola cadena, para los
 * mensajes de fallo */
STATIC FUNCTION Cuenta( a )

   LOCAL cRes := "{"
   LOCAL n

   FOR n := 1 TO Len( a )
      cRes += iif( n > 1, ",", "" ) + LTrim( Str( a[ n ] ) )
   NEXT

RETURN cRes + "}"

/*
 * CuentasIguales( a, b ) — igualdad cuenta por cuenta. Ojo: en
 * Harbour "==" entre arrays compara referencias y no elementos
 * (medido en la fase 5), así que no sirve para esto.
 */
STATIC FUNCTION CuentasIguales( a, b )

   LOCAL n

   IF ValType( a ) != "A" .OR. ValType( b ) != "A" .OR. ;
      Len( a ) != Len( b )
      RETURN .F.
   ENDIF

   FOR n := 1 TO Len( a )
      IF ValType( a[ n ] ) != "N" .OR. ValType( b[ n ] ) != "N" .OR. ;
         a[ n ] != b[ n ]
         RETURN .F.
      ENDIF
   NEXT

RETURN .T.
