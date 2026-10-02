/*
 * centrado — la cláusula CENTER de DEFINE DIALOG
 * (ampliación posterior a la hoja de ruta)
 *
 * Tres diálogos seguidos y cada uno se cierra solo con su
 * temporizador en dos disparos: en el primero se mira su posición y
 * en el segundo se cierra con End(), que es lo que hace regresar
 * ACTIVATE DIALOG. Son los tres casos del centrado:
 *
 *   - con SIZE y sin cláusula: el diálogo pide centro por defecto y
 *     tiene que salir centrado;
 *   - con FROM..TO y CENTER: manda el centro sobre la posición
 *     escrita en la línea;
 *   - con FROM..TO y sin CENTER: se queda justo donde se pidió (el
 *     control: si centrara siempre, el CENTER no valdría nada).
 *
 * La posición se lee con HGtkWndPos() y HGtkPantalla(), dos
 * funciones de pruebas: la primera devuelve la ventana —posición y
 * tamaño— y la segunda el área de trabajo del monitor en que GTK
 * centraría (el del puntero, con el mismo criterio que gtkwindow.c).
 * La comparación es con 4 píxeles de holgura: bajo Xvfb no hay gestor
 * de ventanas, así que GTK coloca la ventana él mismo y la medida es
 * directa.
 *
 * Ojo con Wayland: el protocolo no admite que un cliente coloque un
 * toplevel —en GTK 3.24 la posición se tira en
 * gdk_window_wayland_move_resize, que sólo acepta move de
 * subsuperficies—, así que allí HGtkWndPos devuelve el origen y esta
 * prueba sólo tiene sentido en X11, que es lo que fija el smoke.
 *
 * Compilar:  make smoke      (o make con la regla tests/centrado)
 * Ejecutar:  xvfb-run -a tests/centrado
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

FUNCTION Main()

   LOCAL cFallo := ""
   LOCAL cErr

   ? "HarbGtkLin " + LTrim( Str( HGTK_FASE ) ) + ;
     " - prueba de centrar diálogos"

   /* el de SIZE sin cláusula: por defecto pide centro */
   cErr := DlgSinClausula()
   IF ! ( cErr == "" )
      cFallo := "sin cláusula: " + cErr
   ENDIF

   /* FROM..TO con CENTER: el centro gana a la posición escrita */
   IF cFallo == ""
      cErr := DlgConCenter()
      IF ! ( cErr == "" )
         cFallo := "con CENTER: " + cErr
      ENDIF
   ENDIF

   /* y el mismo FROM..TO sin CENTER: tiene que respetarse el sitio
    * pedido, que es el control de que el centrado no es automático */
   IF cFallo == ""
      cErr := DlgPedida()
      IF ! ( cErr == "" )
         cFallo := "sin CENTER (control): " + cErr
      ENDIF
   ENDIF

   ? ""

   IF cFallo == ""
      ? "centrado_test: OK"
   ELSE
      ? "centrado_test: FALLO -", cFallo
      ErrorLevel( 1 )
   ENDIF
   ? ""

RETURN NIL

/* ------------------------------------------------------------------ */
/* los tres diálogos                                                   */
/* ------------------------------------------------------------------ */

/* DlgSinClausula() — SIZE sólo: HGtkDlgNew pide centro al crearse,
 * así que al mostrarse tiene que salir en el centro del monitor */
STATIC FUNCTION DlgSinClausula()

   LOCAL cFallo := ""
   LOCAL nEtapa := 0
   LOCAL oDlg, oTick

   DEFINE DIALOG oDlg TITLE "centrado sin cláusula" SIZE 26, 76
   DEFINE TIMER oTick OF oDlg INTERVAL 500 ;
      ACTION {|| nEtapa += 1, cFallo := Etapa( nEtapa, oDlg, cFallo, ;
                                               .T., 0, 0 ) }

   ACTIVATE TIMER oTick
   ACTIVATE DIALOG oDlg

RETURN cFallo

/* DlgConCenter() — FROM..TO con CENTER: la cláusula se pide después
 * de Move(), así que el centro tiene que ganar sobre la posición */
STATIC FUNCTION DlgConCenter()

   LOCAL cFallo := ""
   LOCAL nEtapa := 0
   LOCAL oDlg, oTick

   DEFINE DIALOG oDlg TITLE "centrado con CENTER" ;
      FROM 2, 3 TO 28, 79 CENTER
   DEFINE TIMER oTick OF oDlg INTERVAL 500 ;
      ACTION {|| nEtapa += 1, cFallo := Etapa( nEtapa, oDlg, cFallo, ;
                                               .T., 0, 0 ) }

   ACTIVATE TIMER oTick
   ACTIVATE DIALOG oDlg

RETURN cFallo

/* DlgPedida() — el mismo FROM..TO sin CENTER: control, tiene que
 * quedarse en la columna 3 y la fila 2 (24, 32 píxeles) */
STATIC FUNCTION DlgPedida()

   LOCAL cFallo := ""
   LOCAL nEtapa := 0
   LOCAL oDlg, oTick

   DEFINE DIALOG oDlg TITLE "centrado posición pedida" ;
      FROM 2, 3 TO 28, 79
   DEFINE TIMER oTick OF oDlg INTERVAL 500 ;
      ACTION {|| nEtapa += 1, cFallo := Etapa( nEtapa, oDlg, cFallo, ;
                                               .F., 3, 2 ) }

   ACTIVATE TIMER oTick
   ACTIVATE DIALOG oDlg

RETURN cFallo

/* ------------------------------------------------------------------ */
/* los dos disparos                                                    */
/* ------------------------------------------------------------------ */

/*
 * Etapa( n, oDlg, cFallo, lCentro, nCol, nFila ) — un disparo del
 * temporizador, cada 500 ms. El primero mira la posición: con
 * lCentro hay que estar en el centro del monitor, sin él en la
 * posición pedida con FROM..TO (nCol, nFila en unidades de diálogo).
 * El segundo cierra con End(). El fallo de la primera comprobación
 * no se guarda para saltarse la segunda: el diálogo tiene que cerrarse
 * venga mal o bien, o ACTIVATE DIALOG no regresaría nunca.
 */
STATIC FUNCTION Etapa( n, oDlg, cFallo, lCentro, nCol, nFila )

   DO CASE
   CASE n == 1
      /* el "!=" de Harbour es flojo (SET EXACT OFF): un fallo ya
       * guardado daría .F. y no se vería, por eso con "==": */
      IF cFallo == ""
         cFallo := MiraPos( oDlg, lCentro, nCol, nFila )
      ENDIF

   CASE n == 2
      IF ! oDlg:IsAlive()
         IF cFallo == ""
            cFallo := "el diálogo se perdió antes de poder cerrarlo"
         ENDIF
      ELSE
         oDlg:End()
      ENDIF
   ENDCASE

RETURN cFallo

/* ------------------------------------------------------------------ */
/* comprobación de la posición                                         */
/* ------------------------------------------------------------------ */

/*
 * MiraPos( oDlg, lCentro, nCol, nFila ) — compara la posición real
 * con la esperada: el centro del área de trabajo del monitor (la
 * misma fórmula que gtkwindow.c, con 4 px de holgura) o la posición
 * pedida, convertida con los mismos factores que usa TWindow:Move.
 * Si HGtkWndPos devuelve cero —el caso de Wayland, sin posición de
 * toplevel— la comparación falla y el mensaje lo dice.
 */
STATIC FUNCTION MiraPos( oDlg, lCentro, nCol, nFila )

   LOCAL aPos  := HGtkWndPos( oDlg:hWnd )
   LOCAL aArea := HGtkPantalla()
   LOCAL nEspX, nEspY, cDonde

   IF lCentro
      nEspX := aArea[ 1 ] + Int( ( aArea[ 3 ] - aPos[ 3 ] ) / 2 )
      nEspY := aArea[ 2 ] + Int( ( aArea[ 4 ] - aPos[ 4 ] ) / 2 )
      cDonde := "el centro"
   ELSE
      nEspX := HgtkColToPx( nCol )
      nEspY := HgtkRowToPx( nFila )
      cDonde := "la posición pedida"
   ENDIF

   IF Abs( aPos[ 1 ] - nEspX ) > 4 .OR. Abs( aPos[ 2 ] - nEspY ) > 4
      RETURN "se esperaba " + cDonde + " " + ;
             LTrim( Str( nEspX ) ) + "," + LTrim( Str( nEspY ) ) + ;
             " y el diálogo está en " + LTrim( Str( aPos[ 1 ] ) ) + ;
             "," + LTrim( Str( aPos[ 2 ] ) ) + ;
             " (" + LTrim( Str( aPos[ 3 ] ) ) + "x" + ;
             LTrim( Str( aPos[ 4 ] ) ) + ")"
   ENDIF

RETURN ""
