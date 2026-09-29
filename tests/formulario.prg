/*
 * formulario.prg — prueba gráfica de la fase 1
 *
 * Comprueba en una sola ejecución bajo Xvfb el criterio de hecho de la
 * fase 1 (alta de cliente):
 *
 *   - sincronización de los controles con variables Harbour, antes de
 *     activar el diálogo (GET, COMBOBOX, CHECKBOX, RADIO y un botón
 *     con ACTION);
 *   - validación de un campo vacío: con Tab (tests/xkey) el foco no
 *     sale del campo y se cuentan dos validaciones rechazadas; el
 *     título del diálogo registra cada intento ([v1], [v2]), que es
 *     lo que observa el smoke desde fuera;
 *   - un sí/no al salir: cerrar con el aspa pregunta (MsgYesNo), la
 *     primera respuesta se cancela y la segunda acepta;
 *   - los valores siguen en las variables Harbour al cerrar el
 *     diálogo, con el diálogo ya destruido.
 *
 * Sale con ErrorLevel( 1 ) si algo falla.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

STATIC nValidaciones := 0
STATIC nCierres      := 0
STATIC nAccion       := 0

FUNCTION Main()

   LOCAL oDlg, oGrp, oSayN, oGet, oSayP, oCbo, oChk, oRad1, oRad2
   LOCAL oMarcar
   LOCAL cNombre  := Space( 20 )
   LOCAL nProv    := 1
   LOCAL lActivo  := .F.
   LOCAL nPago    := 2
   LOCAL nPrevias := 0
   LOCAL cFallo   := ""

   DEFINE DIALOG oDlg TITLE "Formulario de prueba" SIZE 26, 72

   DEFINE GROUP oGrp OF oDlg PROMPT "Alta de cliente" ;
      AT 1, 1 SIZE 14, 70

      DEFINE SAY oSayN OF oGrp PROMPT "Nombre"    AT 2, 2
      DEFINE GET oGet OF oGrp VAR cNombre         AT 2, 14 ;
         SIZE 1, 44 VALID {|| Valida( cNombre, oDlg ) }

      DEFINE SAY oSayP OF oGrp PROMPT "Provincia"  AT 4, 2
      DEFINE COMBOBOX oCbo OF oGrp VAR nProv       AT 4, 14 ;
         SIZE 1, 30 ITEMS { "Madrid", "Sevilla", "Cádiz" }

      DEFINE CHECKBOX oChk OF oGrp VAR lActivo ;
         PROMPT "Cliente activo" AT 6, 14

      DEFINE RADIO oRad1 OF oGrp VAR nPago OPTION 1 ;
         PROMPT "Efectivo" AT 8, 14
      DEFINE RADIO oRad2 OF oGrp VAR nPago OPTION 2 ;
         PROMPT "Crédito"  AT 10, 14

   DEFINE BUTTON oMarcar OF oDlg PROMPT "Marcar" AT 17, 44 ;
      SIZE 1, 16 ACTION {|| nAccion++ }

   oDlg:bClose := {|| PideCierre() }

   /* -------------------------------------------------------------
    * comprobaciones antes de activar: sólo objetos y variables
    * ---------------------------------------------------------- */

   oGet:Value( "Carlos" )
   IF cNombre != "Carlos"
      cFallo := "Value( texto ) no escribió en la variable del GET"
   ENDIF

   oCbo:Value( 3 )
   IF nProv != 3 .OR. oCbo:Value() != 3
      cFallo := "el COMBOBOX no escribe/lee la variable"
   ENDIF

   oChk:Value( .T. )
   IF ! lActivo .OR. ! oChk:Value()
      cFallo := "el CHECKBOX no escribe/lee la variable"
   ENDIF

   IF oRad1:Value() != 0 .OR. oRad2:Value() != 2
      cFallo := "los RADIO no reflejan la variable (nPago = 2)"
   ENDIF

   oMarcar:Click()
   IF nAccion != 1
      cFallo := "el ACTION del botón no se evaluó con Click()"
   ENDIF

   oGet:Value( "Carlos" )
   IF ! oGet:Validar()
      cFallo := "VALID debía aceptar un nombre con contenido"
   ENDIF

   oGet:Value( "" )
   IF ! Empty( cNombre )
      cFallo := "Value( cadena vacía ) no escribió en la variable del GET"
   ENDIF
   IF oGet:Validar()
      cFallo := "VALID debía rechazar el campo vacío"
   ENDIF

   nPrevias := nValidaciones
   nCierres := 0

   /* -------------------------------------------------------------
    * el diálogo: dos Tab con validación fallida, y dos cierres
    * ---------------------------------------------------------- */

   IF cFallo == ""
      ? "FORMULARIO LISTO"
      oGet:SetFocus()
      ACTIVATE DIALOG oDlg
   ELSE
      ? "FORMULARIO CON ERRORES PREVIOS:", cFallo
   ENDIF

   /* -------------------------------------------------------------
    * comprobaciones tras cerrar el diálogo
    * ---------------------------------------------------------- */

   IF cFallo == ""
      IF oDlg:IsAlive()
         cFallo := "el diálogo debía quedar destruido"
      ENDIF
   ENDIF
   IF cFallo == ""
      IF nValidaciones < nPrevias + 2
         cFallo := "se esperaban 2 validaciones al Tab y hubo " + ;
                   AllTrim( Str( nValidaciones - nPrevias ) )
      ENDIF
   ENDIF
   IF cFallo == ""
      IF nCierres != 2
         cFallo := "se esperaban 2 peticiones de cierre y hubo " + ;
                   AllTrim( Str( nCierres ) )
      ENDIF
   ENDIF
   IF cFallo == ""
      IF nAccion != 1
         cFallo := "una pulsación externa cambió el contador de acción"
      ENDIF
      IF nProv != 3
         cFallo := "la provincia no está en la variable al cerrar"
      ENDIF
      IF ! lActivo
         cFallo := "el estado del CHECKBOX no está en la variable"
      ENDIF
      IF nPago != 2
         cFallo := "la forma de pago no está en la variable"
      ENDIF
      IF ! Empty( cNombre )
         cFallo := "el nombre quedó con contenido en la variable"
      ENDIF
      IF At( "[v", oDlg:Title() ) == 0
         cFallo := "la validación no registró ningún intento en el título"
      ENDIF
   ENDIF

   ? "Validaciones:", Str( nValidaciones - nPrevias ), ;
     " Cierres:", Str( nCierres ), ;
     " Acción:", Str( nAccion )

   IF cFallo == ""
      ? "formulario: OK"
   ELSE
      ? "formulario: FALLO —", cFallo
      ErrorLevel( 1 )
   ENDIF
   ? ""

RETURN NIL

/*
 * Validación del nombre. Durante ACTIVATE deja el intento en el
 * título del diálogo, que es como el smoke comprueba desde fuera que
 * el foco no salió del campo.
 */
STATIC FUNCTION Valida( cNombre, oDlg )

   nValidaciones++

   IF oDlg:IsActive() .AND. oDlg:IsAlive()
      oDlg:Title( "Formulario de prueba [v" + ;
                  LTrim( Str( nValidaciones ) ) + "]" )
   ENDIF

RETURN ! Empty( AllTrim( cNombre ) )

/* Cierre desde el aspa: la primera vez pregunta, la segunda acepta */
STATIC FUNCTION PideCierre()

   nCierres++

   IF nCierres == 1
      ? "  bClose: primera petición, se responde con el aspa (.F.)"
      RETURN MsgYesNo( "¿Cerrar el formulario?", "Confirme" )
   ENDIF

   ? "  bClose: segunda petición, aceptada (.T.)"
RETURN .T.
