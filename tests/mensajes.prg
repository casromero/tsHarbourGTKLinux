/*
 * mensajes.prg — prueba gráfica de MsgInfo, MsgStop y MsgYesNo
 *
 * Las tres cajas aparecen en pantalla y las cierra tests/xclose con
 * WM_DELETE_WINDOW, que es lo que hace el gestor de ventanas al
 * pulsar el aspa de la barra de título. El caso que pide la fase 1 es
 * el sí/no al salir: cerrar MsgYesNo con el aspa debe devolver .F.
 *
 * Sale con ErrorLevel( 1 ) si algo falla.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

FUNCTION Main()

   LOCAL nRespuesta
   LOCAL cFallo := ""

   ? "MENSAJES LISTO"

   MsgInfo( "Mensaje de información.", "Información" )
   ? "información: cerrada"

   MsgStop( "Mensaje de error.", "Error" )
   ? "error: cerrada"

   nRespuesta := MsgYesNo( "¿Continuar?", "Confirme" )
   ? "sí/no cerrado con el aspa:", iif( nRespuesta, "sí", "no" )

   IF ValType( nRespuesta ) != "L"
      cFallo := "MsgYesNo no devolvió un lógico"
   ELSEIF nRespuesta
      cFallo := "cerrar MsgYesNo con el aspa debía devolver .F."
   ENDIF

   IF cFallo == ""
      ? "mensajes: OK"
   ELSE
      ? "mensajes: FALLO —", cFallo
      ErrorLevel( 1 )
   ENDIF
   ? ""

RETURN NIL
