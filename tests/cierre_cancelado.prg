/*
 * cierre_cancelado.prg — prueba gráfica de la fase 0
 *
 * Comprueba, en una sola ejecución bajo Xvfb:
 *   - que TApplication es único y conoce la versión de GTK;
 *   - que la ventana nace viva y sin estar en ACTIVATE;
 *   - que el primer WM_DELETE se cancela porque bClose devuelve .F.;
 *   - que el segundo se acepta, el proceso termina con la ventana
 *     destruida y el código de salida 0.
 *
 * El WM_DELETE lo envía tests/xclose, que es lo mismo que hace el
 * gestor de ventanas al pulsar el aspa de la barra de título.
 *
 * Sale con ErrorLevel( 1 ) si algo falla.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

STATIC nPeticiones := 0

FUNCTION Main()

   LOCAL oWnd, oApp, oApp2
   LOCAL cFallo := ""

   /* aplicación única */
   oApp  := HgtkApplication()
   oApp2 := TApplication():New()
   oApp:cName := "prueba-unica"
   IF oApp2:cName != "prueba-unica"
      cFallo := "TApplication no es único"
   ENDIF
   IF Empty( oApp:GtkVersion() )
      cFallo := "TApplication no tiene versión de GTK"
   ENDIF

   oWnd := TWindow():New( "Cierre cancelado", 44, 12 )

   IF ! oWnd:IsAlive() .OR. oWnd:IsActive()
      cFallo := "la ventana debía estar viva y sin activar"
   ENDIF

   oWnd:bClose := {|| pideCierre() }

   ? "Ventana lista. Esperando la petición de cierre..."
   oWnd:Activate()

   IF oWnd:IsAlive()
      cFallo := "la ventana debía quedar destruida al cerrarse"
   ENDIF
   IF nPeticiones != 2
      cFallo := "se esperaban 2 peticiones de cierre y hubo " + ;
                AllTrim( Str( nPeticiones ) )
   ENDIF

   /* End() sobre una ventana ya cerrada no debe hacer nada */
   oWnd:End()

   ? "Peticiones de cierre:", Str( nPeticiones )

   IF cFallo == ""
      ? "cierre_cancelado: OK"
   ELSE
      ? "cierre_cancelado: FALLO —", cFallo
      ErrorLevel( 1 )
   ENDIF

   ? ""

RETURN NIL

STATIC FUNCTION pideCierre()

   nPeticiones++

   IF nPeticiones == 1
      ? "  bClose: primer cierre cancelado (.F.)"
      RETURN .F.
   ENDIF

   ? "  bClose: segundo cierre aceptado (.T.)"
   RETURN .T.
