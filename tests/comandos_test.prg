/*
 * comandos_test — pruebas de consola de los comandos (fase 5)
 *
 * Un comando DEFINE no hace más que llamar al constructor de su
 * clase, así que lo que aquí se prueba es el camino de frío: con un
 * padre de mentira (sin hWnd) ningún constructor toca GTK, y eso es
 * lo que hace falta para una prueba que no necesite pantalla.
 *
 *   - cada comando DEFINE de las fases 1 a 4 crea su objeto y guarda
 *     lo que se le dio; los enlaces VAR se escriben sin ventana y el
 *     ACTION de un botón se evalúa con oBt:Click();
 *   - los usos incorrectos (VAR sin bloque, ACTION sin codeblock, OF
 *     sin ventana...) saltan como error recuperable y dejan el
 *     programa en pie: el error se instala a mano como Break(), que
 *     es como se recupera en Harbour (el fallo salta al RECOVER);
 *   - el temporizador nace parado y ni él ni el menú se pueden
 *     activar sin ventana creada;
 *   - HGtkCuentas devuelve {0,0,0,0}: sin ventanas no hay nada
 *     sujeto. Ésas mismas cuentas comprueba tests/fugas_test.prg
 *     tras abrir y cerrar ventanas en bucle.
 *
 * Compilar:  make test       (desde la raíz del proyecto)
 * Ejecutar:  tests/comandos_test
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

FUNCTION Main()

   LOCAL cFallo := ""
   LOCAL bAntes, lRecup, oError
   LOCAL oPadre, aC, aObj, oObj, oTmp, nObj
   LOCAL cTexto := "hola", lMarcar := .T., nOpt := 1
   LOCAL nCmb := 2, nLst := 1, nSel := 1, nPag := 1
   LOCAL cRuta := "Norte/0001 Aceros"
   LOCAL aItems := { "Uno", "Dos" }
   LOCAL aCab  := { "Código", "Nombre" }
   LOCAL aDat  := { { 1, "Ana" }, { 2, "Luis" } }
   LOCAL aArb  := { { "Norte", { "0001 Aceros" } }, ;
                    { "Sur", { "0003 Vientos" } } }
   LOCAL nClicks := 0
   LOCAL oSay, oBt, oGet, oChk, oRad, oCmb, oGrp, oLst, oBrw, oImg
   LOCAL oTick, oMenu, oPop, oIt, oBar, oBtBar, oSta, oCaja, oBtCaja
   LOCAL oTabs, oPag1, oPag2, oArb

   ? "HarbGtkLin " + LTrim( Str( HGTK_FASE ) ) + ;
     " - prueba de consola de comandos"

   /* ---------------------------------------------------------------
    * un padre de mentira: ninguno de los constructores de abajo
    * toca GTK con él, y por eso esta prueba no necesita pantalla
    * --------------------------------------------------------------- */
   oPadre := PadreFalso():New()

   /* ---------------------------------------------------------------
    * los comandos, uno por uno, en el orden fijo OF, VAR/PROMPT, AT,
    * SIZE y ACTION
    * --------------------------------------------------------------- */

   DEFINE SAY oSay OF oPadre PROMPT "Etiqueta" AT 1, 1 SIZE 1, 20
   DEFINE BUTTON oBt OF oPadre PROMPT "&Aceptar" AT 2, 1 SIZE 1, 12 ;
      ACTION {|| nClicks++ }
   DEFINE GET oGet OF oPadre VAR cTexto AT 3, 1 SIZE 1, 20
   DEFINE CHECKBOX oChk OF oPadre VAR lMarcar PROMPT "&Marcar" ;
      AT 4, 1 SIZE 1, 12
   DEFINE RADIO oRad OF oPadre VAR nOpt OPTION 2 PROMPT "&Norte" ;
      AT 5, 1 SIZE 1, 12
   DEFINE COMBOBOX oCmb OF oPadre VAR nCmb ITEMS aItems ;
      AT 6, 1 SIZE 3, 20
   DEFINE GROUP oGrp OF oPadre PROMPT "&Zona" AT 1, 25 SIZE 8, 30
   DEFINE LISTBOX oLst OF oPadre VAR nLst ITEMS aItems ;
      AT 7, 1 SIZE 3, 20 ACTION {|| nClicks += 10 }
   DEFINE BROWSE oBrw OF oPadre VAR nSel FIELDS aCab DATA aDat ;
      AT 8, 1 SIZE 5, 30
   DEFINE IMAGE oImg OF oPadre FILE "no-existe.png" AT 9, 1 SIZE 2, 2
   DEFINE TIMER oTick OF oPadre INTERVAL 600000 ;
      ACTION {|| nClicks += 100 }
   DEFINE MENU oMenu OF oPadre
   DEFINE POPUP oPop OF oMenu PROMPT "&Archivo"
   DEFINE MENUITEM oIt OF oPop PROMPT "&Salir" ;
      ACTION {|| nClicks += 1000 }
   DEFINE BAR oBar OF oPadre
   DEFINE BUTTON oBtBar OF oBar PROMPT "&Nuevo" ACTION {|| NIL }
   DEFINE STATUS oSta OF oPadre
   DEFINE BOX oCaja OF oPadre HORIZONTAL AT 10, 1 SIZE 2, 30
   DEFINE BUTTON oBtCaja OF oCaja PROMPT "En caja" AT 1, 1 SIZE 1, 10 ;
      ACTION {|| NIL }
   DEFINE TABS oTabs OF oPadre VAR nPag AT 11, 1 SIZE 6, 30 ;
      ACTION {|| NIL }
   DEFINE PAGE oPag1 OF oTabs PROMPT "&Uno"
   DEFINE PAGE oPag2 OF oTabs PROMPT "&Dos"
   DEFINE TREE oArb OF oPadre VAR cRuta ITEMS aArb ;
      AT 12, 1 SIZE 5, 24 ACTION {|| NIL }

   /* --- cada comando creó su objeto -------------------------------- */
   aObj := { oSay, oBt, oGet, oChk, oRad, oCmb, oGrp, oLst, oBrw, ;
             oImg, oTick, oMenu, oPop, oIt, oBar, oBtBar, oSta, ;
             oCaja, oBtCaja, oTabs, oPag1, oPag2, oArb }

   nObj := 0
   FOR EACH oObj IN aObj
      nObj++
      IF ValType( oObj ) != "O"
         cFallo := "el comando no creó el objeto #" + LTrim( Str( nObj ) )
         EXIT
      ENDIF
   NEXT

   /* --- lo que se dio se guardó y los enlaces VAR funcionan -------- */
   IF cFallo == ""
      IF Distinto( oSay:Value(), "Etiqueta" )
         cFallo := "el SAY debe guardar su PROMPT"
      ENDIF
   ENDIF

   IF cFallo == ""
      IF Distinto( oImg:cFile, "no-existe.png" )
         cFallo := "el IMAGE debe guardar su FILE"
      ENDIF
   ENDIF

   IF cFallo == ""
      oGet:Value( "nuevo" )
      IF Distinto( cTexto, "nuevo" )
         cFallo := "el GET sin ventana debe escribir en su variable"
      ENDIF
   ENDIF

   IF cFallo == ""
      oChk:Value( .F. )
      IF Distinto( lMarcar, .F. )
         cFallo := "el CHECKBOX sin ventana debe escribir en su variable"
      ENDIF
   ENDIF

   IF cFallo == ""
      oLst:Value( 2 )
      oCmb:Value( 1 )
      oBrw:Value( 2 )
      IF Distinto( nLst, 2 ) .OR. Distinto( nCmb, 1 ) .OR. ;
         Distinto( nSel, 2 ) .OR. Distinto( oLst:Value(), 2 )
         cFallo := "LISTBOX, COMBOBOX y BROWSE deben usar sus variables"
      ENDIF
   ENDIF

   /* el ACTION de un botón es puro Harbour: sin ventana se evalúa */
   IF cFallo == ""
      oBt:Click()
      IF Distinto( nClicks, 1 )
         cFallo := "Click() debe evaluar el ACTION del botón"
      ENDIF
   ENDIF

   /* --- el temporizador nace parado -------------------------------- */
   IF cFallo == ""
      IF oTick:IsActive()
         cFallo := "el temporizador debe nacer parado"
      ELSEIF Distinto( oTick:nInterval, 600000 )
         cFallo := "el temporizador debe guardar su INTERVAL"
      ENDIF
   ENDIF

   /* --- las cuentas de fugas: sin ventana, todo a cero -------------- */
   IF cFallo == ""
      aC := HGtkCuentas()
      IF ! CuentasCero( aC )
         cFallo := "sin ventana las cuentas deben ser {0,0,0,0} y son " + ;
                   Cuenta( aC )
      ENDIF
   ENDIF

   /* ---------------------------------------------------------------
    * los usos incorrectos: error recuperable, no muerte del programa
    * --------------------------------------------------------------- */

   /* GET sin bloque de enlace */
   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oTmp := TGet():New( oPadre, "no es bloque" )
      RECOVER USING oError
         lRecup := .T.
         IF !( AT( "TGet:New", Detalles( oError ) ) > 0 )
            cFallo := "el error no dice quién lo dio: " + ;
                      Detalles( oError )
         ENDIF
      END SEQUENCE
      ErrorBlock( bAntes )

      IF cFallo == "" .AND. ! lRecup
         cFallo := "un GET sin bloque VAR debe dar error recuperable"
      ENDIF
   ENDIF

   /* TIMER sin ACTION que sea codeblock */
   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oTmp := TTimer():New( oPadre, 100, 7 )
      RECOVER USING oError
         lRecup := .T.
         IF !( AT( "TTimer:New", Detalles( oError ) ) > 0 )
            cFallo := "el error no dice quién lo dio: " + ;
                      Detalles( oError )
         ENDIF
      END SEQUENCE
      ErrorBlock( bAntes )

      IF cFallo == "" .AND. ! lRecup
         cFallo := "un TIMER con ACTION que no es bloque debe dar error"
      ENDIF
   ENDIF

   /* TIMER sin cláusula OF */
   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oTmp := TTimer():New( 7, 100, {|| NIL } )
      RECOVER
         lRecup := .T.
      END SEQUENCE
      ErrorBlock( bAntes )

      IF ! lRecup
         cFallo := "un TIMER sin ventana debe dar error recuperable"
      ENDIF
   ENDIF

   /* LISTBOX sin VAR */
   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oTmp := TListBox():New( oPadre, "no es bloque", aItems )
      RECOVER
         lRecup := .T.
      END SEQUENCE
      ErrorBlock( bAntes )

      IF ! lRecup
         cFallo := "un LISTBOX sin bloque VAR debe dar error recuperable"
      ENDIF
   ENDIF

   /* ACTIVATE TIMER sin ventana creada */
   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         ACTIVATE TIMER oTick
      RECOVER USING oError
         lRecup := .T.
         IF !( AT( "TTimer:Activate", Detalles( oError ) ) > 0 )
            cFallo := "el error no dice quién lo dio: " + ;
                      Detalles( oError )
         ENDIF
      END SEQUENCE
      ErrorBlock( bAntes )

      IF cFallo == "" .AND. ! lRecup
         cFallo := "ACTIVATE TIMER sin ventana debe dar error recuperable"
      ENDIF
   ENDIF

   /* ACTIVATE MENU sin ventana creada */
   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         ACTIVATE MENU oMenu
      RECOVER USING oError
         lRecup := .T.
         IF !( AT( "TMenu:Activate", Detalles( oError ) ) > 0 )
            cFallo := "el error no dice quién lo dio: " + ;
                      Detalles( oError )
         ENDIF
      END SEQUENCE
      ErrorBlock( bAntes )

      IF cFallo == "" .AND. ! lRecup
         cFallo := "ACTIVATE MENU sin ventana debe dar error recuperable"
      ENDIF
   ENDIF

   /* el texto de un SAY no admite números, y el valor no cambia */
   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oSay:Value( 7 )
      RECOVER USING oError
         lRecup := .T.
         IF !( AT( "TSay:Value", Detalles( oError ) ) > 0 )
            cFallo := "el error no dice quién lo dio: " + ;
                      Detalles( oError )
         ENDIF
      END SEQUENCE
      ErrorBlock( bAntes )

      IF cFallo == "" .AND. ! lRecup
         cFallo := "Value( 7 ) en un SAY debe dar error recuperable"
      ELSEIF cFallo == "" .AND. Distinto( oSay:Value(), "Etiqueta" )
         cFallo := "el SAY conserva su texto tras el error"
      ENDIF
   ENDIF

   /* el número de pestaña debe ser un número */
   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oTabs:Value( "x" )
      RECOVER USING oError
         lRecup := .T.
         IF !( AT( "TTabs:Value", Detalles( oError ) ) > 0 )
            cFallo := "el error no dice quién lo dio: " + ;
                      Detalles( oError )
         ENDIF
      END SEQUENCE
      ErrorBlock( bAntes )

      IF cFallo == "" .AND. ! lRecup
         cFallo := "Value de un TABS con un texto debe dar error recuperable"
      ENDIF
   ENDIF

   /* la ruta del árbol debe ser una cadena, y no se cambia */
   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oArb:Value( 7 )
      RECOVER USING oError
         lRecup := .T.
         IF !( AT( "TTree:Value", Detalles( oError ) ) > 0 )
            cFallo := "el error no dice quién lo dio: " + ;
                      Detalles( oError )
         ENDIF
      END SEQUENCE
      ErrorBlock( bAntes )

      IF cFallo == "" .AND. ! lRecup
         cFallo := "Value( 7 ) en un TREE debe dar error recuperable"
      ELSEIF cFallo == "" .AND. Distinto( cRuta, "Norte/0001 Aceros" )
         cFallo := "el árbol conserva su ruta tras el error"
      ENDIF
   ENDIF

   /* --- tras todos los intentos, las cuentas siguen en cero --------- */
   IF cFallo == ""
      aC := HGtkCuentas()
      IF ! CuentasCero( aC )
         cFallo := "al acabar las cuentas deben ser {0,0,0,0} y son " + ;
                   Cuenta( aC )
      ENDIF
   ENDIF

   ? ""

   IF cFallo == ""
      ? "comandos_test: OK"
   ELSE
      ? "comandos_test: FALLO -", cFallo
      ErrorLevel( 1 )
   ENDIF
   ? ""

RETURN NIL

/* ------------------------------------------------------------------ */
/* utilidades                                                          */
/* ------------------------------------------------------------------ */

/* Detalles( oError ) — todo lo que el error traiga consigo, en una
 * sola cadena: mensaje, operación y subsistema (los que existan) */
STATIC FUNCTION Detalles( oError )

   LOCAL cRes := ""

   IF ValType( oError ) != "O"
      RETURN cRes
   ENDIF

   IF __objHasMsg( oError, "DESCRIPTION" )
      cRes += oError:description + " "
   ENDIF
   IF __objHasMsg( oError, "OPERATION" )
      cRes += oError:operation + " "
   ENDIF
   IF __objHasMsg( oError, "SUBSYSTEM" )
      cRes += oError:subsystem + " "
   ENDIF

RETURN cRes

/* Cuenta( a ) — las cuatro cuentas de fugas en una sola cadena, para
 * el mensaje de fallo */
STATIC FUNCTION Cuenta( a )

   LOCAL cRes := "{"
   LOCAL n

   FOR n := 1 TO Len( a )
      cRes += iif( n > 1, ",", "" ) + LTrim( Str( a[ n ] ) )
   NEXT

RETURN cRes + "}"

/*
 * CuentasCero( a ) — .T. si las cuatro cuentas de fugas están a cero.
 * Ojo: en Harbour "==" entre arrays compara referencias y no
 * elementos (medido aquí), así que la igualdad se mira cuenta por
 * cuenta.
 */
STATIC FUNCTION CuentasCero( a )

   LOCAL n

   IF ValType( a ) != "A" .OR. Len( a ) != 4
      RETURN .F.
   ENDIF

   FOR n := 1 TO 4
      IF ValType( a[ n ] ) != "N" .OR. a[ n ] != 0
         RETURN .F.
      ENDIF
   NEXT

RETURN .T.

/*
 * Distinto( x, y ) — desigualdad EXACTA. El "!=" de Harbour es flojo
 * (SET EXACT OFF): "abc" != "ab" es .F. y cualquier cosa != "" es .F.
 * La igualdad exacta es "=="; esto sólo es su negación.
 */
STATIC FUNCTION Distinto( x, y )

RETURN ! ( x == y )

/* ------------------------------------------------------------------ */
/* padre de mentira: sólo hace falta para que Init() no se queje       */
/* ------------------------------------------------------------------ */

CREATE CLASS PadreFalso

   VAR hWnd       INIT  NIL

   METHOD New() CONSTRUCTOR
   METHOD AddControl( oCtrl )

ENDCLASS

METHOD New() CLASS PadreFalso

RETURN SELF

METHOD AddControl( oCtrl ) CLASS PadreFalso

   /* sin ventana no hay dónde colgar nada: no hay nada que hacer.
    * oCtrl no se usa (un parámetro sin usar no es error aquí). */
   RETURN NIL
