/*
 * hbgtk_msg.c — cajas de mensaje modales (MsgInfo, MsgStop, MsgYesNo)
 *
 * Una sola función C que crea la caja, la muestra sin regresar hasta
 * que el usuario la cierra y devuelve si la respuesta fue afirmativa.
 * La caja no forma parte de la lista de ventanas del proceso: es
 * transitoria y no alimenta el bucle de ACTIVATE.
 *
 * Licencia: LGPL-3.0-or-later
 */
#include "hbgtk.h"

#define HGTK_MSG_DESTRUYE "harbgtklin-msg-destruido"

/* tipos de mensaje, en los mismos valores que HGTK_MSG_* de harbgtk.ch */
#define HGTK_MSG_TIPO_INFO  1
#define HGTK_MSG_TIPO_STOP  2
#define HGTK_MSG_TIPO_YESNO 3

/* al destruir la caja se marca, para no destruirla dos veces */
static void hbgtk_on_msg_destroy( GtkWidget * pMsg, gpointer pData )
{
   (void) pData;
   g_object_set_data( G_OBJECT( pMsg ), HGTK_MSG_DESTRUYE,
                      GINT_TO_POINTER( 1 ) );
}

/* HGtkMsgBox( cTitulo, cTexto, nTipo ) -> .T. si la respuesta fue
 * afirmativa (o el usuario aceptó la caja de aviso). Cerrar la caja
 * con el aspa de la barra de título cuenta como respuesta negativa. */
HB_FUNC( HGTKMSGBOX )
{
   const char * szTitulo, * szTexto;
   GtkMessageType tTipo;
   GtkButtonsType tBotones;
   GtkWidget * pMsg, * pBoton;
   gint nRespuesta;
   gint nAfirmativa;

   if( hb_pcount() < 3 || ! HB_ISCHAR( 1 ) || ! HB_ISCHAR( 2 ) ||
       ! HB_ISNUM( 3 ) )
   {
      hbgtk_errArgs( "HGtkMsgBox",
                     "se esperaba (cTitulo, cTexto, nTipo)" );
      hb_retl( FALSE );
      return;
   }

   szTitulo = hb_parc( 1 );
   szTexto  = hb_parc( 2 );

   switch( hb_parni( 3 ) )
   {
      case HGTK_MSG_TIPO_INFO:
         tTipo       = GTK_MESSAGE_INFO;
         tBotones    = GTK_BUTTONS_OK;
         nAfirmativa = GTK_RESPONSE_OK;
         break;
      case HGTK_MSG_TIPO_STOP:
         tTipo       = GTK_MESSAGE_ERROR;
         tBotones    = GTK_BUTTONS_OK;
         nAfirmativa = GTK_RESPONSE_OK;
         break;
      case HGTK_MSG_TIPO_YESNO:
         tTipo       = GTK_MESSAGE_QUESTION;
         tBotones    = GTK_BUTTONS_YES_NO;
         nAfirmativa = GTK_RESPONSE_YES;
         break;
      default:
         hbgtk_errArgs( "HGtkMsgBox", "tipo de mensaje no válido" );
         hb_retl( FALSE );
         return;
   }

   if( ! hbgtk_initGTK() )
   {
      hb_retl( FALSE );
      return;
   }

   pMsg = gtk_message_dialog_new( NULL, GTK_DIALOG_MODAL, tTipo, tBotones,
                                  "%s", szTexto );
   gtk_window_set_title( GTK_WINDOW( pMsg ), szTitulo );

   /* El botón afirmativo se queda con el foco y con el valor por
    * omisión: Intro cierra la caja con la respuesta afirmativa, como
    * en los diálogos de siempre, y así también se puede contestar a
    * una caja con el teclado sin mirar la pantalla (tests/xkey). */
   pBoton = gtk_dialog_get_widget_for_response( GTK_DIALOG( pMsg ),
                                                nAfirmativa );
   if( pBoton )
   {
      gtk_dialog_set_default_response( GTK_DIALOG( pMsg ), nAfirmativa );
      gtk_widget_grab_focus( pBoton );
   }

   /* la referencia propia evita que el widget quede liberado si el
    * usuario la cierra desde la barra de título */
   g_object_ref( pMsg );
   g_signal_connect( pMsg, "destroy", G_CALLBACK( hbgtk_on_msg_destroy ),
                     NULL );

   nRespuesta = gtk_dialog_run( GTK_DIALOG( pMsg ) );

   if( ! g_object_get_data( G_OBJECT( pMsg ), HGTK_MSG_DESTRUYE ) )
      gtk_widget_destroy( pMsg );
   g_object_unref( pMsg );

   hb_retl( nRespuesta == GTK_RESPONSE_YES || nRespuesta == GTK_RESPONSE_OK );
}
