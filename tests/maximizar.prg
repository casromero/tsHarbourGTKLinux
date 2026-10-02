/*
 * maximizar — Maximize(), Minimize(), Restore(), IsMaximized() y los
 * botones de la barra (ampliación posterior a la hoja de ruta)
 *
 * Tres ventanas seguidas, cada una se cierra sola con su temporizador
 * en cuatro disparos: con la ventana recién mostrada se mira
 * IsMaximized() y se llama a Minimize(); después Restore(); después
 * Maximize(); y al cuarto se cierra con End(). Son las tres formas de
 * escribir la cláusula MAXIMIZED: con SIZE, sin cláusula ninguna y
 * con FROM..TO.
 *
 * Lo que se comprueba:
 *
 *   - la cláusula MAXIMIZED deja la ventana por maximizada en cuanto
 *     se muestra (IsMaximized() .T. en el primer disparo), y una
 *     ventana escrita sin ella sale en .F.;
 *   - antes de ACTIVATE ninguna está maximizada: GTK reconoce el
 *     estado al mapearla (medido con el banco f17);
 *   - los cuatro métodos se pueden llamar en los cuatro disparos y
 *     también sobre la ventana ya destruida, sin avisos de GTK —los
 *     vigila el smoke— y sin romper nada;
 *   - el layout de decoración de GTK acaba con los botones de
 *     maximizar y minimizar: donde GTK dibuja la barra ella misma
 *     (el Weston de WSLg no ofrece decoración de servidor), la
 *     sesión sólo trae la X y el arranque del puente la completa;
 *     bajo Xvfb el layout ya viene completo y ésta es la
 *     comprobación de que no se estropea nada;
 *   - las cuentas del puente vuelven a {0,0,0,0} tras cada ventana.
 *
 * Bajo Xvfb no hay gestor de ventanas: el efecto visual de maximizar
 * una ventana ya mostrada ni el de restaurarla no se pueden comprobar
 * aquí (GTK pide el cambio al gestor y nadie lo confirma; medido con
 * los bancos f17*, el indicador no se mueve en ese caso), así que la
 * prueba sólo pide esas llamadas y comprueba que no rompen nada.
 *
 * Esta prueba abre ventanas, así que necesita display: va en el smoke
 * bajo Xvfb, no en make test.
 *
 * Compilar:  make smoke      (o make con la regla tests/maximizar)
 * Ejecutar:  xvfb-run -a tests/maximizar
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

FUNCTION Main()

   LOCAL cFallo := ""
   LOCAL aBase
   LOCAL cErr
   LOCAL cDeco

   ? "HarbGtkLin " + LTrim( Str( HGTK_FASE ) ) + ;
     " - prueba de maximizar, minimizar y restaurar"

   aBase := HGtkCuentas()

   IF ! CuentasIguales( aBase, { 0, 0, 0, 0 } )
      ? "maximizar_test: FALLO - se empieza con las cuentas " + ;
        Cuenta( aBase )
      ErrorLevel( 1 )
      ? ""
      RETURN NIL
   ENDIF

   /* los botones de la barra: el arranque del puente completa el
    * layout cuando faltan minimize o maximize (en WSLg la sesión
    * sólo trae la X). At() devuelve número, así que el "==" es
    * exacto sin el apuro del "!=" flojo con cadenas. */
   cDeco := HGtkDecoracion()
   IF At( "minimize", cDeco ) == 0 .OR. At( "maximize", cDeco ) == 0
      ? "maximizar_test: FALLO - la decoración se quedó en [" + ;
        cDeco + "]"
      ErrorLevel( 1 )
      ? ""
      RETURN NIL
   ENDIF

   /* la ventana con la cláusula MAXIMIZED: al mostrarse, maximizada.
    * Ojo con el "!=" de Harbour: es flojo (SET EXACT OFF) y cualquier
    * cadena != "" da .F., así que el fallo se mira con "==". */
   cErr := VentConMaximized( aBase )
   IF ! ( cErr == "" )
      cFallo := "con MAXIMIZED: " + cErr
   ENDIF

   /* la misma sin cláusula: al mostrarse, no maximizada */
   IF cFallo == ""
      cErr := VentNormal( aBase )
      IF ! ( cErr == "" )
         cFallo := "sin MAXIMIZED: " + cErr
      ENDIF
   ENDIF

   /* y la otra variante del comando, FROM..TO con MAXIMIZED */
   IF cFallo == ""
      cErr := VentDesde( aBase )
      IF ! ( cErr == "" )
         cFallo := "FROM..TO con MAXIMIZED: " + cErr
      ENDIF
   ENDIF

   ? ""

   IF cFallo == ""
      ? "maximizar_test: OK"
   ELSE
      ? "maximizar_test: FALLO -", cFallo
      ErrorLevel( 1 )
   ENDIF
   ? ""

RETURN NIL

/* ------------------------------------------------------------------ */
/* las tres ventanas                                                   */
/* ------------------------------------------------------------------ */

/*
 * VentConMaximized( aBase ) — SIZE 20, 60 MAXIMIZED: al mostrarse, la
 * cláusula la deja por maximizada. Antes de ACTIVATE, en cambio, no:
 * GTK reconoce el estado al mapearla (medido: banco f17).
 */
STATIC FUNCTION VentConMaximized( aBase )

   LOCAL cFallo := ""
   LOCAL nEtapa := 0
   LOCAL oWnd, oTick

   DEFINE WINDOW oWnd TITLE "maximizar con cláusula" SIZE 20, 60 ;
      MAXIMIZED
   DEFINE TIMER oTick OF oWnd INTERVAL 400 ;
      ACTION {|| nEtapa += 1, cFallo := Etapa( nEtapa, oWnd, cFallo, ;
                                               .T. ) }

   IF oWnd:IsMaximized()
      cFallo := "antes de ACTIVATE no debe estar maximizada"
   ENDIF

   IF cFallo == ""
      cFallo := Creada( HGtkCuentas(), aBase )
   ENDIF

   IF cFallo == ""
      ACTIVATE TIMER oTick
      ACTIVATE WINDOW oWnd
   ELSE
      oWnd:End()
   ENDIF

   IF cFallo == ""
      cFallo := Destruida( oWnd, aBase )
   ENDIF

RETURN cFallo

/* VentNormal( aBase ) — sin cláusula: la diferencia está en el
 * primer disparo, que espera IsMaximized() en .F. */
STATIC FUNCTION VentNormal( aBase )

   LOCAL cFallo := ""
   LOCAL nEtapa := 0
   LOCAL oWnd, oTick

   DEFINE WINDOW oWnd TITLE "maximizar normal" SIZE 20, 60
   DEFINE TIMER oTick OF oWnd INTERVAL 400 ;
      ACTION {|| nEtapa += 1, cFallo := Etapa( nEtapa, oWnd, cFallo, ;
                                               .F. ) }

   IF oWnd:IsMaximized()
      cFallo := "una ventana sin MAXIMIZED no debe nacer maximizada"
   ENDIF

   IF cFallo == ""
      cFallo := Creada( HGtkCuentas(), aBase )
   ENDIF

   IF cFallo == ""
      ACTIVATE TIMER oTick
      ACTIVATE WINDOW oWnd
   ELSE
      oWnd:End()
   ENDIF

   IF cFallo == ""
      cFallo := Destruida( oWnd, aBase )
   ENDIF

RETURN cFallo

/* VentDesde( aBase ) — la otra variante del comando: FROM..TO con
 * MAXIMIZED, que además pide la posición con Move() */
STATIC FUNCTION VentDesde( aBase )

   LOCAL cFallo := ""
   LOCAL nEtapa := 0
   LOCAL oWnd, oTick

   DEFINE WINDOW oWnd TITLE "maximizar desde posición" ;
      FROM 3, 4 TO 24, 70 MAXIMIZED
   DEFINE TIMER oTick OF oWnd INTERVAL 400 ;
      ACTION {|| nEtapa += 1, cFallo := Etapa( nEtapa, oWnd, cFallo, ;
                                               .T. ) }

   IF oWnd:IsMaximized()
      cFallo := "antes de ACTIVATE no debe estar maximizada"
   ENDIF

   IF cFallo == ""
      cFallo := Creada( HGtkCuentas(), aBase )
   ENDIF

   IF cFallo == ""
      ACTIVATE TIMER oTick
      ACTIVATE WINDOW oWnd
   ELSE
      oWnd:End()
   ENDIF

   IF cFallo == ""
      cFallo := Destruida( oWnd, aBase )
   ENDIF

RETURN cFallo

/* ------------------------------------------------------------------ */
/* los cuatro disparos                                                 */
/* ------------------------------------------------------------------ */

/*
 * Etapa( n, oWnd, cFallo, lMax ) — un disparo del temporizador, cada
 * 400 ms. El primero mira el estado recién mostrada (lMax es lo que
 * debe decir) y llama a Minimize(); el segundo, Restore(); el
 * tercero, Maximize(); el cuarto cierra con End(), que es lo que
 * hace regresar ACTIVATE. Si ya hay fallo se devuelve tal cual sin
 * tocar la ventana.
 */
STATIC FUNCTION Etapa( n, oWnd, cFallo, lMax )

   LOCAL lAhora

   /* el "!=" de Harbour es flojo (SET EXACT OFF): cualquier cadena
    * != "" da .F., con lo que un fallo guardado aquí no se vería */
   IF ! ( cFallo == "" )
      RETURN cFallo
   ENDIF

   DO CASE
   CASE n == 1
      lAhora := oWnd:IsMaximized()
      IF lAhora != lMax
         RETURN "al mostrarse IsMaximized() debía ser " + ;
                iif( lMax, ".T.", ".F." ) + " y es " + ;
                iif( lAhora, ".T.", ".F." )
      ENDIF
      oWnd:Minimize()

   CASE n == 2
      IF ! oWnd:IsAlive()
         RETURN "la ventana se perdió tras Minimize()"
      ENDIF
      oWnd:Restore()

   CASE n == 3
      IF ! oWnd:IsAlive()
         RETURN "la ventana se perdió tras Restore()"
      ENDIF
      oWnd:Maximize()

   CASE n == 4
      IF ! oWnd:IsAlive()
         RETURN "la ventana se perdió tras Maximize()"
      ENDIF
      oWnd:End()
   ENDCASE

RETURN ""

/* ------------------------------------------------------------------ */
/* comprobaciones de las cuentas                                       */
/* ------------------------------------------------------------------ */

/*
 * Creada( aAbi, aBase ) — con la ventana creada y todavía sin
 * mostrar: hay una ventana más y un reloj más (el temporizador se
 * crea en su DEFINE, parado), y los grips suben porque el puente
 * sujeta el propietario de la ventana y el bloque del temporizador.
 * Los controles NO cambian: ésta ventana sólo lleva un temporizador
 * y una ventana desnuda no registra ninguno (los cuenta aparte
 * s_pCtrls, y ni el GtkFixed ni la caja pasan por ahí).
 */
STATIC FUNCTION Creada( aAbi, aBase )

   IF aAbi[ 1 ] != aBase[ 1 ] + 1
      RETURN "había que ver una ventana más y las cuentas son " + ;
             Cuenta( aAbi )
   ENDIF
   IF aAbi[ 2 ] != aBase[ 2 ]
      RETURN "una ventana con sólo temporizador no cuelga controles: " + ;
             Cuenta( aAbi )
   ENDIF
   IF aAbi[ 3 ] != aBase[ 3 ] + 1
      RETURN "había que ver un reloj más y las cuentas son " + ;
             Cuenta( aAbi )
   ENDIF
   IF ! ( aAbi[ 4 ] > aBase[ 4 ] )
      RETURN "los bloques sujetos deben subir: " + Cuenta( aAbi )
   ENDIF

RETURN ""

/*
 * Destruida( oWnd, aBase ) — con la ventana ya destruida: los cuatro
 * métodos siguen siendo llamables (la clase comprueba IsAlive antes
 * de tocar GTK), IsMaximized() devuelve .F. y las cuentas vuelven
 * exactamente a las de partida.
 */
STATIC FUNCTION Destruida( oWnd, aBase )

   LOCAL aFin

   oWnd:Maximize()
   oWnd:Minimize()
   oWnd:Restore()

   IF oWnd:IsMaximized()
      RETURN "destruida, IsMaximized() debe devolver .F."
   ENDIF
   IF oWnd:IsAlive()
      RETURN "destruida, IsAlive() debe seguir en .F."
   ENDIF

   aFin := HGtkCuentas()

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
