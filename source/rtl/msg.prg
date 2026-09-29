/*
 * msg.prg — MsgInfo, MsgStop, MsgYesNo
 *
 * Cajas de mensaje modales: no regresan hasta que el usuario las
 * cierra. Cerrarlas con el aspa de la barra de título vale como
 * respuesta negativa en MsgYesNo.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "harbgtk.ch"

/* Información: sólo aceptar */
FUNCTION MsgInfo( cTexto, cTitulo )

RETURN HgtkMensaje( cTexto, cTitulo, HGTK_MSG_INFO )

/* Aviso de error: sólo aceptar */
FUNCTION MsgStop( cTexto, cTitulo )

RETURN HgtkMensaje( cTexto, cTitulo, HGTK_MSG_STOP )

/* Pregunta sí/no; devuelve .T. sólo si el usuario responde que sí */
FUNCTION MsgYesNo( cTexto, cTitulo )

RETURN HgtkMensaje( cTexto, cTitulo, HGTK_MSG_YESNO )

/*
 * HgtkMensaje( cTexto, cTitulo, nTipo ) -> lRespuesta
 * Valida los argumentos, normaliza los saltos de línea (los textos de
 * FiveWin traen CR+LF y GTK sólo entiende LF) y llama al puente.
 */
STATIC FUNCTION HgtkMensaje( cTexto, cTitulo, nTipo )

   IF ValType( cTexto ) != "C"
      HgtkErrArgs( "MsgInfo", "el texto debe ser una cadena" )
      RETURN .F.
   ENDIF
   IF cTitulo == NIL .OR. ValType( cTitulo ) != "C"
      cTitulo := HGTK_NOMBRE
   ENDIF

   cTexto := StrTran( cTexto, Chr( 13 ) + Chr( 10 ), Chr( 10 ) )
   cTexto := StrTran( cTexto, Chr( 13 ), Chr( 10 ) )

RETURN HGtkMsgBox( cTitulo, cTexto, nTipo )
