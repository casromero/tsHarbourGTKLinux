/*
 * hbgtk_ctrl.c — controles de formulario y su colocación
 *
 * Cada función hace una cosa: crear un widget, colocarlo, cambiar una
 * propiedad, leer un texto o conectar una señal a un codeblock. El
 * puntero al widget sale en hb_retptr() y vuelve en hb_parptr(); la
 * clase lo guarda y nunca lo interpreta.
 *
 * Los codeblocks que conecta una señal quedan sujetos con un grip de
 * GC mientras el widget exista: se sueltan en la señal destroy. Un
 * widget destruido no se desreferencia nunca: para comprobar si sigue
 * vivo se usa la lista de controles (hbgtk_ctrl_alive).
 *
 * Licencia: LGPL-3.0-or-later
 */
#include "hbgtk.h"
#include "hbapierr.h"

#define HGTK_FIXED_KEY   "harbgtklin-fixed"
#define HGTK_CAJA_KEY    "harbgtklin-caja"
#define HGTK_MENU_KEY    "harbgtklin-menu"
#define HGTK_BARRA_KEY   "harbgtklin-barra"
#define HGTK_ESTADO_KEY  "harbgtklin-estado"
#define HGTK_ACCION_KEY  "harbgtklin-accion"
#define HGTK_ACCION_ON   "harbgtklin-accion-on"
#define HGTK_VALID_KEY   "harbgtklin-valid"
#define HGTK_VALID_ON    "harbgtklin-valid-on"

/* controles creados y todavía no destruidos: sólo se comparan punteros */
static GSList * s_pCtrls = NULL;

/* grips de GC sujetos por el puente: uno que no se suelta deja su
 * codeblock vivo para siempre. La cuenta está desde el primer grip
 * para que tests/fugas_test.prg compare antes y después de abrir y
 * cerrar ventanas en bucle. */
int hbgtk_nGrips = 0;

static void hbgtk_ctrl_add( GtkWidget * pCtrl )
{
   s_pCtrls = g_slist_prepend( s_pCtrls, pCtrl );
}

static void hbgtk_ctrl_del( GtkWidget * pCtrl )
{
   s_pCtrls = g_slist_remove( s_pCtrls, pCtrl );
}

HB_BOOL hbgtk_ctrl_alive( gpointer pCtrl )
{
   return pCtrl != NULL && g_slist_find( s_pCtrls, pCtrl ) != NULL;
}

/* puntero de control validado; si es inválido, error de Harbour.
 * Primero se compara con la lista, sin desreferenciar el widget. */
GtkWidget * hbgtk_cpar( int iPar, const char * szProc )
{
   GtkWidget * pCtrl = (GtkWidget *) hb_parptr( iPar );

   if( ! hbgtk_ctrl_alive( pCtrl ) )
   {
      hbgtk_errArgs( szProc, "puntero de widget no válido" );
      return NULL;
   }
   return pCtrl;
}

/* El browse de la fase 3 vive dentro de un marco de desplazamiento
 * (GtkScrolledWindow) para tener barra: el widget que se lleva la
 * clase es el marco, pero el control de verdad —la que recibe el foco—
 * es lo que hay dentro. Si el widget no es un marco, se devuelve tal
 * cual. */
GtkWidget * hbgtk_desenvuelve( GtkWidget * pWidget )
{
   if( pWidget && GTK_IS_SCROLLED_WINDOW( pWidget ) )
   {
      GList * pHijos = gtk_container_get_children( GTK_CONTAINER( pWidget ) );
      GtkWidget * pHijo = pHijos ? (GtkWidget *) pHijos->data : NULL;

      g_list_free( pHijos );
      if( pHijo )
         return pHijo;
   }
   return pWidget;
}

/* ------------------------------------------------------------------ */
/* contenedor de posicionamiento                                       */
/* ------------------------------------------------------------------ */

/* al destruir el padre se anulan las referencias al contenedor */
static void hbgtk_on_fixed_destroy( GtkWidget * pPadre, gpointer pData )
{
   (void) pData;
   g_object_set_data( G_OBJECT( pPadre ), HGTK_FIXED_KEY, NULL );
   g_object_set_data( G_OBJECT( pPadre ), HGTK_CAJA_KEY, NULL );
   g_object_set_data( G_OBJECT( pPadre ), HGTK_MENU_KEY, NULL );
   g_object_set_data( G_OBJECT( pPadre ), HGTK_BARRA_KEY, NULL );
   g_object_set_data( G_OBJECT( pPadre ), HGTK_ESTADO_KEY, NULL );
}

/* Guarda el contenedor de posicionamiento de un padre que no es una
 * ventana ni un grupo —una página de pestañas o una caja— en la misma
 * clave que ellos, y lo anula al destruir el padre. */
void hbgtk_contenedor_pon( GtkWidget * pPadre, GtkWidget * pContenedor )
{
   g_object_set_data( G_OBJECT( pPadre ), HGTK_FIXED_KEY, pContenedor );
   g_signal_connect( pPadre, "destroy",
                     G_CALLBACK( hbgtk_on_fixed_destroy ), NULL );
}

/*
 * Los controles van en un GtkFixed, que es lo que permite ponerlos en
 * filas y columnas como en FiveWin. En una ventana o un diálogo ese
 * GtkFixed es un hijo más de una caja vertical, para que encima quepa
 * la barra de menú y la de botones y debajo la barra de estado (fase
 * 2). En un grupo (GtkFrame) el fijo es el único hijo, como en la
 * fase 1: un GtkBin no admite más.
 */
void hbgtk_crear_fixed( GtkWidget * pPadre )
{
   GtkWidget * pFixed = gtk_fixed_new();
   GtkWidget * pContenedor = pPadre;

   /* un GtkDialog ya trae su propio hijo (el área de contenido, un
    * GtkBox con la barra de botones): dentro de ese área va la caja,
    * no en el diálogo, porque GtkBin sólo admite un hijo */
   if( GTK_IS_DIALOG( pPadre ) )
      pContenedor = gtk_dialog_get_content_area( GTK_DIALOG( pPadre ) );

   if( GTK_IS_WINDOW( pPadre ) )
   {
      GtkWidget * pCaja = gtk_box_new( GTK_ORIENTATION_VERTICAL, 0 );

      gtk_container_add( GTK_CONTAINER( pContenedor ), pCaja );
      gtk_box_pack_start( GTK_BOX( pCaja ), pFixed, TRUE, TRUE, 0 );
      g_object_set_data( G_OBJECT( pPadre ), HGTK_CAJA_KEY, pCaja );
   }
   else
      gtk_container_add( GTK_CONTAINER( pContenedor ), pFixed );

   hbgtk_contenedor_pon( pPadre, pFixed );
}

/*
 * hbgtk_caja_cuelga( pPadre, pHijo, nTipo ) — cuelga la barra de menú
 * (0), la de botones (1) o la de estado (2) en la caja de la ventana.
 * El orden de arriba abajo es: menú, barra de botones, controles y,
 * al final, la barra de estado. Devuelve FALSE si la ventana no tiene
 * caja (un grupo, por ejemplo).
 */
gboolean hbgtk_caja_cuelga( GtkWidget * pPadre, GtkWidget * pHijo,
                            int nTipo )
{
   GtkWidget * pCaja, * pMenu, * pBarra;
   int nOrden = 0;

   if( ! pPadre || ! pHijo || ! GTK_IS_WIDGET( pHijo ) )
      return FALSE;

   pCaja = (GtkWidget *) g_object_get_data( G_OBJECT( pPadre ),
                                            HGTK_CAJA_KEY );
   if( ! pCaja || ! GTK_IS_BOX( pCaja ) )
      return FALSE;

   if( nTipo == HGTK_CAJA_ESTADO )
   {
      gtk_box_pack_end( GTK_BOX( pCaja ), pHijo, FALSE, FALSE, 0 );
      g_object_set_data( G_OBJECT( pPadre ), HGTK_ESTADO_KEY, pHijo );
   }
   else
   {
      gtk_box_pack_start( GTK_BOX( pCaja ), pHijo, FALSE, FALSE, 0 );
      g_object_set_data( G_OBJECT( pPadre ),
                         nTipo == HGTK_CAJA_MENUBAR ? HGTK_MENU_KEY
                                                    : HGTK_BARRA_KEY,
                         pHijo );

      /* el menú arriba y la barra de botones debajo, venga antes o
       * después el GtkFixed, que queda después de las dos */
      pMenu = (GtkWidget *) g_object_get_data( G_OBJECT( pPadre ),
                                               HGTK_MENU_KEY );
      pBarra = (GtkWidget *) g_object_get_data( G_OBJECT( pPadre ),
                                                HGTK_BARRA_KEY );
      if( pMenu )
      {
         gtk_box_reorder_child( GTK_BOX( pCaja ), pMenu, nOrden );
         nOrden++;
      }
      if( pBarra )
      {
         gtk_box_reorder_child( GTK_BOX( pCaja ), pBarra, nOrden );
         nOrden++;
      }
   }

   gtk_widget_show_all( pHijo );
   return TRUE;
}

/*
 * hbgtk_mnemonico( cTexto ) — marca de mnemónico para GTK. FiveWin
 * usa "&" delante de la letra de atajo (ATRAS); GTK usa "_". "&&" es
 * una "&" literal, y un "_" del texto se dobla para no tomarlo por
 * marca. Devuelve una cadena con g_free().
 */
char * hbgtk_mnemonico( const char * szTexto )
{
   GString * pRes = g_string_new( NULL );
   const char * p = szTexto ? szTexto : "";

   while( *p )
   {
      if( *p == '&' )
      {
         if( p[ 1 ] == '&' )
         {
            g_string_append_c( pRes, '&' );
            p++;
         }
         else
            g_string_append_c( pRes, '_' );
      }
      else if( *p == '_' )
         g_string_append( pRes, "__" );
      else
         g_string_append_c( pRes, *p );
      p++;
   }

   return g_string_free( pRes, FALSE );
}

/* ------------------------------------------------------------------ */
/* codeblocks sujetos a un widget                                      */
/* ------------------------------------------------------------------ */

/* suelta el bloque guardado en la clave (si lo hay) */
static void hbgtk_bloque_drop( GtkWidget * pCtrl, const char * szClave )
{
   PHB_ITEM pBloque = (PHB_ITEM) g_object_get_data( G_OBJECT( pCtrl ),
                                                    szClave );
   if( pBloque )
   {
      g_object_set_data( G_OBJECT( pCtrl ), szClave, NULL );
      hb_gcGripDrop( pBloque );
      hbgtk_nGrips--;
   }
}

/* guarda el parámetro iPar (un codeblock) sujeto al widget */
static void hbgtk_bloque_set( GtkWidget * pCtrl, const char * szClave,
                              int iPar )
{
   hbgtk_bloque_drop( pCtrl, szClave );

   if( hb_pcount() >= iPar && HB_ISBLOCK( iPar ) )
   {
      PHB_ITEM pBloque = hb_itemNew( hb_param( iPar, HB_IT_BLOCK ) );

      hb_gcGripGet( pBloque );
      hbgtk_nGrips++;
      g_object_set_data( G_OBJECT( pCtrl ), szClave, pBloque );
   }
}

/* evaluate del bloque guardado en la clave; sin bloque no hace nada */
static void hbgtk_bloque_eval( GtkWidget * pCtrl, const char * szClave )
{
   PHB_ITEM pBloque = (PHB_ITEM) g_object_get_data( G_OBJECT( pCtrl ),
                                                    szClave );
   if( pBloque && HB_IS_BLOCK( pBloque ) )
      hb_vmEvalBlock( pBloque );
}

/*
 * Señal sin argumentos (clicked, toggled, changed): evalúa el bloque
 * conectado. El bloque se lee en cada disparo, de modo que cambiar el
 * codeblock de la clase surte efecto sin reconectar.
 */
static void hbgtk_on_senal( GtkWidget * pCtrl, gpointer pData )
{
   hbgtk_bloque_eval( pCtrl, (const char *) pData );
}

/*
 * Restituir el foco, pero en el siguiente giro del bucle de eventos.
 * Hacerlo dentro del propio focus-out hace que GTK toque objetos ya
 * deshechos (críticas de GLib-GObject), porque el cambio de foco está
 * en marcha; con el idle, el cambio se completa primero y después se
 * recupera el foco. La referencia sujeta el widget mientras espera.
 */
static gboolean hbgtk_foco_pendiente( gpointer pData )
{
   GtkWidget * pCtrl = GTK_WIDGET( pData );

   if( hbgtk_ctrl_alive( pCtrl ) && ! gtk_widget_in_destruction( pCtrl ) )
   {
      GtkWidget * pAlto = gtk_widget_get_toplevel( pCtrl );

      if( pAlto && hbgtk_wnd_alive( pAlto ) &&
          ! gtk_widget_in_destruction( pAlto ) &&
          gtk_widget_get_mapped( pCtrl ) )
         gtk_widget_grab_focus( pCtrl );
   }

   g_object_unref( pCtrl );
   return G_SOURCE_REMOVE;
}

/*
 * La validación se difiere a un giro del bucle de eventos. GTK avisa
 * del focus-out también cuando sólo reorganiza el foco interno (al
 * activarse la ventana, al abrirse una caja encima): en ese caso el
 * campo sigue o vuelve a tener el foco y no hay nada que validar.
 * Esperar al bucle permite distinguirlo de una salida de foco de
 * verdad, y así un campo vacío no lanza un aviso sin motivo.
 *
 * Si el bloque devuelve .F., el foco se devuelve al campo (se agota en
 * hbgtk_foco_pendiente): no se puede salir de él. Un error dentro del
 * bloque no deja al usuario atrapado: el foco pasa igual.
 */
static gboolean hbgtk_valid_pendiente( gpointer pData )
{
   GtkWidget * pCtrl = GTK_WIDGET( pData );
   gboolean fValido = TRUE;

   if( hbgtk_ctrl_alive( pCtrl ) && ! gtk_widget_in_destruction( pCtrl ) )
   {
      GtkWidget * pAlto = gtk_widget_get_toplevel( pCtrl );

      if( pAlto && hbgtk_wnd_alive( pAlto ) &&
          ! gtk_widget_in_destruction( pAlto ) &&
          gtk_widget_get_mapped( pCtrl ) &&
          ! gtk_widget_has_focus( pCtrl ) )
      {
         PHB_ITEM pBloque = (PHB_ITEM) g_object_get_data( G_OBJECT( pCtrl ),
                                                          HGTK_VALID_KEY );

         if( pBloque && HB_IS_BLOCK( pBloque ) )
         {
            PHB_ITEM pResultado = hb_vmEvalBlock( pBloque );

            if( pResultado && HB_IS_LOGICAL( pResultado ) &&
                ! hb_itemGetL( pResultado ) )
               fValido = FALSE;
         }

         if( hb_vmRequestQuery() )
            fValido = TRUE;

         if( ! fValido )
            g_idle_add( hbgtk_foco_pendiente, g_object_ref( pCtrl ) );
      }
   }

   g_object_unref( pCtrl );
   return G_SOURCE_REMOVE;
}

static gboolean hbgtk_on_valid( GtkWidget * pCtrl, GdkEventFocus * pEvent,
                                gpointer pData )
{
   (void) pEvent;
   (void) pData;

   if( ! hbgtk_ctrl_alive( pCtrl ) || gtk_widget_in_destruction( pCtrl ) )
      return FALSE;

   g_idle_add( hbgtk_valid_pendiente, g_object_ref( pCtrl ) );

   return FALSE;
}

/* al destruir el widget se sueltan sus codeblocks y sale de la lista */
static void hbgtk_on_ctrl_destroy( GtkWidget * pCtrl, gpointer pData )
{
   (void) pData;

   hbgtk_bloque_drop( pCtrl, HGTK_ACCION_KEY );
   hbgtk_bloque_drop( pCtrl, HGTK_VALID_KEY );
   hbgtk_ctrl_del( pCtrl );
}

/* registro común de un control recién creado */
void hbgtk_ctrl_init( GtkWidget * pCtrl )
{
   g_signal_connect( pCtrl, "destroy",
                     G_CALLBACK( hbgtk_on_ctrl_destroy ), NULL );
   hbgtk_ctrl_add( pCtrl );
}

/* ------------------------------------------------------------------ */
/* colocación y propiedades                                            */
/* ------------------------------------------------------------------ */

/* HGtkAdd( pPadre, pHijo, nX, nY ) — coloca el hijo en el padre.
 * Si el padre es un GtkFixed, la posición manda (modo de siempre);
 * si es una caja (TBox, modo de cajas), el hijo se empaqueta y las
 * coordenadas no se usan: el orden es el de declaración. */
HB_FUNC( HGTKADD )
{
   GtkWidget * pPadre = (GtkWidget *) hb_parptr( 1 );
   GtkWidget * pHijo  = (GtkWidget *) hb_parptr( 2 );
   GtkWidget * pFixed;

   if( ! pPadre || ! pHijo || ! GTK_IS_WIDGET( pPadre ) ||
       ! GTK_IS_WIDGET( pHijo ) )
   {
      hbgtk_errArgs( "HGtkAdd", "puntero de widget no válido" );
      hb_ret();
      return;
   }

   pFixed = (GtkWidget *) g_object_get_data( G_OBJECT( pPadre ),
                                             HGTK_FIXED_KEY );
   if( ! pFixed || ! GTK_IS_WIDGET( pFixed ) )
   {
      hbgtk_errArgs( "HGtkAdd",
                     "el padre no tiene contenedor de posicionamiento" );
      hb_ret();
      return;
   }

   if( GTK_IS_FIXED( pFixed ) )
      gtk_fixed_put( GTK_FIXED( pFixed ), pHijo, hb_parni( 3 ),
                     hb_parni( 4 ) );
   else if( GTK_IS_BOX( pFixed ) )
      gtk_box_pack_start( GTK_BOX( pFixed ), pHijo, FALSE, FALSE, 0 );
   else
      hbgtk_errArgs( "HGtkAdd", "contenedor de posicionamiento desconocido" );

   hb_ret();
}

/*
 * Widget que lleva las señales de un control: si el que dio la clase
 * es un marco de desplazamiento (el browse de la fase 3), la vista de
 * dentro, que es la que dispara "cursor-changed" y la que puede
 * recibir el foco. Se registra ahí también, para que sus codeblocks
 * se suelten cuando la vista se acabe.
 */
static GtkWidget * hbgtk_senal_obj( GtkWidget * pCtrl )
{
   GtkWidget * pObj = hbgtk_desenvuelve( pCtrl );

   if( pObj != pCtrl && ! hbgtk_ctrl_alive( pObj ) )
      hbgtk_ctrl_init( pObj );
   return pObj;
}

/* HGtkSetSignal( pWidget, cSeñal, bBloque ) — conecta una señal.
 * Un bloque vacío desconecta el código anterior.
 *
 * El widget que se conecta es el control de verdad: si el que da la
 * clase es un marco de desplazamiento (el browse de la fase 3), la
 * señal es de la vista de dentro, que es también donde se sujeta el
 * bloque y donde se suelta al destruirla. */
HB_FUNC( HGTKSETSIGNAL )
{
   GtkWidget * pCtrl = hbgtk_cpar( 1, "HGtkSetSignal" );
   GtkWidget * pObj;
   const char * szSenal;

   if( ! pCtrl )
   {
      hb_ret();
      return;
   }
   if( hb_pcount() < 2 || ! HB_ISCHAR( 2 ) )
   {
      hbgtk_errArgs( "HGtkSetSignal", "la señal debe ser una cadena" );
      hb_ret();
      return;
   }

   pObj   = hbgtk_senal_obj( pCtrl );
   szSenal = hb_parc( 2 );

   if( g_signal_lookup( szSenal, G_OBJECT_TYPE( pObj ) ) == 0 )
   {
      hbgtk_errArgs( "HGtkSetSignal", "el widget no tiene esa señal" );
      hb_ret();
      return;
   }

   hbgtk_bloque_set( pObj, HGTK_ACCION_KEY, 3 );

   if( ! g_object_get_data( G_OBJECT( pObj ), HGTK_ACCION_ON ) )
   {
      g_signal_connect( pObj, szSenal, G_CALLBACK( hbgtk_on_senal ),
                        (gpointer) HGTK_ACCION_KEY );
      g_object_set_data( G_OBJECT( pObj ), HGTK_ACCION_ON,
                         GINT_TO_POINTER( 1 ) );
   }
   hb_ret();
}

/* HGtkSetValid( pWidget, bBloque ) — validación al perder el foco */
HB_FUNC( HGTKSETVALID )
{
   GtkWidget * pCtrl = hbgtk_cpar( 1, "HGtkSetValid" );
   GtkWidget * pObj;

   if( ! pCtrl )
   {
      hb_ret();
      return;
   }

   pObj = hbgtk_senal_obj( pCtrl );

   hbgtk_bloque_set( pObj, HGTK_VALID_KEY, 2 );

   if( ! g_object_get_data( G_OBJECT( pObj ), HGTK_VALID_ON ) )
   {
      g_signal_connect( pObj, "focus-out-event",
                        G_CALLBACK( hbgtk_on_valid ), NULL );
      g_object_set_data( G_OBJECT( pObj ), HGTK_VALID_ON,
                         GINT_TO_POINTER( 1 ) );
   }
   hb_ret();
}

/* HGtkCtrlAlive( pWidget ) -> .T. si el control todavía existe.
 * Sólo compara punteros: nunca desreferencia el widget. */
HB_FUNC( HGTKCTRLALIVE )
{
   hb_retl( hbgtk_ctrl_alive( hb_parptr( 1 ) ) );
}

/* HGtkCtrlDestroy( pWidget ) — destruye el widget de un control */
HB_FUNC( HGTKCTRLDESTROY )
{
   GtkWidget * pCtrl = hbgtk_cpar( 1, "HGtkCtrlDestroy" );

   if( pCtrl )
      gtk_widget_destroy( pCtrl );
   hb_ret();
}

/* HGtkSetSize( pWidget, nAncho, nAlto ) — en píxeles; 0 = tamaño
 * natural, es decir, lo que GTK elija para ese widget. */
HB_FUNC( HGTKSETSIZE )
{
   GtkWidget * pCtrl = hbgtk_cpar( 1, "HGtkSetSize" );
   int nAncho, nAlto;

   if( ! pCtrl )
   {
      hb_ret();
      return;
   }

   nAncho = hb_parni( 2 );
   nAlto  = hb_parni( 3 );
   gtk_widget_set_size_request( pCtrl,
                                nAncho > 0 ? nAncho : -1,
                                nAlto  > 0 ? nAlto  : -1 );
   hb_ret();
}

/* HGtkSetText( pWidget, cTexto ) — etiqueta, entrada, botón o grupo */
HB_FUNC( HGTKSETTEXT )
{
   GtkWidget * pCtrl = hbgtk_cpar( 1, "HGtkSetText" );
   const char * szTexto;

   if( ! pCtrl )
   {
      hb_ret();
      return;
   }
   if( hb_pcount() < 2 || ! HB_ISCHAR( 2 ) )
   {
      hbgtk_errArgs( "HGtkSetText", "el texto debe ser una cadena" );
      hb_ret();
      return;
   }

   szTexto = hb_parc( 2 );

   if( GTK_IS_LABEL( pCtrl ) )
      gtk_label_set_text( GTK_LABEL( pCtrl ), szTexto );
   else if( GTK_IS_ENTRY( pCtrl ) )
      gtk_entry_set_text( GTK_ENTRY( pCtrl ), szTexto );
   else if( GTK_IS_BUTTON( pCtrl ) )
      gtk_button_set_label( GTK_BUTTON( pCtrl ), szTexto );
   else if( GTK_IS_TOOL_BUTTON( pCtrl ) )
      gtk_tool_button_set_label( GTK_TOOL_BUTTON( pCtrl ), szTexto );
   else if( GTK_IS_MENU_ITEM( pCtrl ) )
   {
      /* sólo un ítem de texto: si lleva un submenú, cambiarle la
       * etiqueta lo destruiría (GTK la reemplaza si no es una etiqueta) */
      GtkWidget * pHijo = gtk_bin_get_child( GTK_BIN( pCtrl ) );

      if( pHijo && GTK_IS_LABEL( pHijo ) )
         gtk_menu_item_set_label( GTK_MENU_ITEM( pCtrl ), szTexto );
      else
         hbgtk_errArgs( "HGtkSetText", "ese widget no lleva texto" );
   }
   else if( GTK_IS_FRAME( pCtrl ) )
      gtk_frame_set_label( GTK_FRAME( pCtrl ), szTexto );
   else
      hbgtk_errArgs( "HGtkSetText", "ese widget no lleva texto" );

   hb_ret();
}

/* HGtkGetText( pWidget ) -> cTexto */
HB_FUNC( HGTKGETTEXT )
{
   GtkWidget * pCtrl = hbgtk_cpar( 1, "HGtkGetText" );
   const char * szTexto = NULL;

   if( ! pCtrl )
   {
      hb_retc( "" );
      return;
   }

   if( GTK_IS_LABEL( pCtrl ) )
      szTexto = gtk_label_get_text( GTK_LABEL( pCtrl ) );
   else if( GTK_IS_ENTRY( pCtrl ) )
      szTexto = gtk_entry_get_text( GTK_ENTRY( pCtrl ) );
   else if( GTK_IS_BUTTON( pCtrl ) )
      szTexto = gtk_button_get_label( GTK_BUTTON( pCtrl ) );
   else if( GTK_IS_TOOL_BUTTON( pCtrl ) )
      szTexto = gtk_tool_button_get_label( GTK_TOOL_BUTTON( pCtrl ) );
   else if( GTK_IS_MENU_ITEM( pCtrl ) )
      szTexto = gtk_menu_item_get_label( GTK_MENU_ITEM( pCtrl ) );
   else if( GTK_IS_FRAME( pCtrl ) )
      szTexto = gtk_frame_get_label( GTK_FRAME( pCtrl ) );
   else
      hbgtk_errArgs( "HGtkGetText", "ese widget no lleva texto" );

   hb_retc( szTexto ? szTexto : "" );
}

/* HGtkSetActive( pWidget, lActivo ) — casilla o radio */
HB_FUNC( HGTKSETACTIVE )
{
   GtkWidget * pCtrl = hbgtk_cpar( 1, "HGtkSetActive" );

   if( ! pCtrl )
   {
      hb_ret();
      return;
   }
   if( ! GTK_IS_TOGGLE_BUTTON( pCtrl ) )
   {
      hbgtk_errArgs( "HGtkSetActive", "ese widget no es conmutable" );
      hb_ret();
      return;
   }

   gtk_toggle_button_set_active( GTK_TOGGLE_BUTTON( pCtrl ), hb_parl( 2 ) );
   hb_ret();
}

/* HGtkGetActive( pWidget ) -> .T. si está marcado */
HB_FUNC( HGTKGETACTIVE )
{
   GtkWidget * pCtrl = hbgtk_cpar( 1, "HGtkGetActive" );

   if( ! pCtrl )
   {
      hb_retl( FALSE );
      return;
   }
   if( ! GTK_IS_TOGGLE_BUTTON( pCtrl ) )
   {
      hbgtk_errArgs( "HGtkGetActive", "ese widget no es conmutable" );
      hb_retl( FALSE );
      return;
   }

   hb_retl( gtk_toggle_button_get_active( GTK_TOGGLE_BUTTON( pCtrl ) ) );
}

/*
 * HGtkFocus( pWidget ) — pone el foco de teclado en el widget.
 *
 * Una lista (GtkListBox) no es enfocable en sí misma (GTK la crea con
 * can_focus apagado): en una lista el foco lo lleva la fila elegida,
 * así que el foco se le pone a ella. Si no hay fila elegida no hay
 * dónde ponerlo y la ventana hace lo que tenga por defecto.
 *
 * El marco de desplazamiento del browse tampoco es enfocable: el foco
 * es de la vista de dentro, así que primero se desenvuelve (ver
 * hbgtk_desenvuelve).
 */
HB_FUNC( HGTKFOCUS )
{
   GtkWidget * pCtrl = hbgtk_cpar( 1, "HGtkFocus" );

   if( pCtrl )
   {
      pCtrl = hbgtk_desenvuelve( pCtrl );

      if( GTK_IS_LIST_BOX( pCtrl ) )
      {
         GtkListBoxRow * pFila =
            gtk_list_box_get_selected_row( GTK_LIST_BOX( pCtrl ) );

         if( pFila )
            pCtrl = GTK_WIDGET( pFila );
      }
      gtk_widget_grab_focus( pCtrl );
   }
   hb_ret();
}

/* HGtkHasFocus( pWidget ) -> .T. si el widget tiene el foco.
 * En una lista el foco lo lleva la fila elegida y en el browse la
 * vista de dentro del marco, así que ahí se comprueba, igual que al
 * ponerlo (ver HGtkFocus). */
HB_FUNC( HGTKHASFOCUS )
{
   GtkWidget * pCtrl = hbgtk_cpar( 1, "HGtkHasFocus" );
   gboolean fFoco = FALSE;

   if( pCtrl )
   {
      pCtrl = hbgtk_desenvuelve( pCtrl );

      if( GTK_IS_LIST_BOX( pCtrl ) )
      {
         GtkWidget * pAlto = gtk_widget_get_toplevel( pCtrl );
         GtkWidget * pFoco = ( pAlto && GTK_IS_WINDOW( pAlto ) ) ?
                             gtk_window_get_focus( GTK_WINDOW( pAlto ) ) :
                             NULL;

         fFoco = pFoco != NULL &&
                 ( pFoco == pCtrl || gtk_widget_is_ancestor( pFoco, pCtrl ) );
      }
      else
         fFoco = gtk_widget_has_focus( pCtrl );
   }

   hb_retl( fFoco );
}

/* ------------------------------------------------------------------ */
/* creación de widgets                                                 */
/* ------------------------------------------------------------------ */

/* HGtkLabelNew( cTexto ) -> etiqueta (TSay) */
HB_FUNC( HGTKLABELNEW )
{
   GtkWidget * pCtrl;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   pCtrl = gtk_label_new( hb_pcount() >= 1 && HB_ISCHAR( 1 ) ?
                          hb_parc( 1 ) : "" );
   hbgtk_ctrl_init( pCtrl );
   hb_retptr( pCtrl );
}

/* HGtkButtonNew( cTexto [, cImagen ] ) -> botón (TButton). El texto
 * admite la marca de mnemónico "&x" de FiveWin, convertida a "_x" de
 * GTK. La imagen (ruta de un fichero que lea GdkPixbuf) se pone a la
 * izquierda del texto: GTK la guarda aparte de la etiqueta, así que
 * leer o cambiar el texto con HGtkGetText/HGtkSetText sigue igual. */
HB_FUNC( HGTKBUTTONNEW )
{
   GtkWidget * pCtrl;
   char * szTexto;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   szTexto = hbgtk_mnemonico( hb_pcount() >= 1 && HB_ISCHAR( 1 ) ?
                              hb_parc( 1 ) : "" );
   pCtrl = gtk_button_new_with_mnemonic( szTexto );
   g_free( szTexto );

   if( hb_pcount() >= 2 && HB_ISCHAR( 2 ) && hb_parc( 2 )[ 0 ] != '\0' )
   {
      GdkPixbuf * pPix = hbgtk_pixbuf( hb_parc( 2 ) );

      if( pPix )
      {
         GtkWidget * pImagen = gtk_image_new_from_pixbuf( pPix );

         g_object_unref( pPix );   /* la imagen ya tiene la suya */
         gtk_button_set_image( GTK_BUTTON( pCtrl ), pImagen );
      }
      else
         hbgtk_errGui( "HGtkButtonNew", "no se pudo leer la imagen" );
   }

   hbgtk_ctrl_init( pCtrl );
   hb_retptr( pCtrl );
}

/* HGtkEntryNew( cTexto ) -> campo de entrada (TGet) */
HB_FUNC( HGTKENTRYNEW )
{
   GtkWidget * pCtrl;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   pCtrl = gtk_entry_new();
   if( hb_pcount() >= 1 && HB_ISCHAR( 1 ) )
      gtk_entry_set_text( GTK_ENTRY( pCtrl ), hb_parc( 1 ) );
   hbgtk_ctrl_init( pCtrl );
   hb_retptr( pCtrl );
}

/* HGtkCheckNew( cTexto ) -> casilla (TCheckBox) */
HB_FUNC( HGTKCHECKNEW )
{
   GtkWidget * pCtrl;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   pCtrl = gtk_check_button_new_with_label( hb_pcount() >= 1 &&
                                            HB_ISCHAR( 1 ) ? hb_parc( 1 ) :
                                            "" );
   hbgtk_ctrl_init( pCtrl );
   hb_retptr( pCtrl );
}

/* HGtkRadioNew( cTexto, pAnterior ) -> botón de radio (TRadio).
 * Si pAnterior viene, el nuevo botón entra en su mismo grupo. */
HB_FUNC( HGTKRADIONEW )
{
   GtkWidget * pCtrl;
   GtkWidget * pAnterior = (GtkWidget *) hb_parptr( 2 );
   const char * szTexto = hb_pcount() >= 1 && HB_ISCHAR( 1 ) ?
                          hb_parc( 1 ) : "";

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }
   if( pAnterior && ! GTK_IS_RADIO_BUTTON( pAnterior ) )
   {
      hbgtk_errArgs( "HGtkRadioNew", "el botón anterior no es un radio" );
      hb_retptr( NULL );
      return;
   }

   pCtrl = pAnterior ?
           gtk_radio_button_new_with_label_from_widget(
              GTK_RADIO_BUTTON( pAnterior ), szTexto ) :
           gtk_radio_button_new_with_label( NULL, szTexto );
   hbgtk_ctrl_init( pCtrl );
   hb_retptr( pCtrl );
}

/* HGtkComboNew() -> desplegable (TComboBox) */
HB_FUNC( HGTKCOMBONEW )
{
   GtkWidget * pCtrl;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   pCtrl = gtk_combo_box_text_new();
   hbgtk_ctrl_init( pCtrl );
   hb_retptr( pCtrl );
}

/* HGtkComboAdd( pCombo, cTexto ) — añade una entrada al final */
HB_FUNC( HGTKCOMBOADD )
{
   GtkWidget * pCtrl = hbgtk_cpar( 1, "HGtkComboAdd" );

   if( ! pCtrl )
   {
      hb_ret();
      return;
   }
   if( hb_pcount() < 2 || ! HB_ISCHAR( 2 ) )
   {
      hbgtk_errArgs( "HGtkComboAdd", "la entrada debe ser una cadena" );
      hb_ret();
      return;
   }
   if( ! GTK_IS_COMBO_BOX_TEXT( pCtrl ) )
   {
      hbgtk_errArgs( "HGtkComboAdd", "ese widget no es un desplegable" );
      hb_ret();
      return;
   }

   gtk_combo_box_text_append_text( GTK_COMBO_BOX_TEXT( pCtrl ),
                                   hb_parc( 2 ) );
   hb_ret();
}

/* HGtkComboIndex( pCombo ) -> nEntrada (1 por omisión; 0 = ninguna) */
HB_FUNC( HGTKCOMBOINDEX )
{
   GtkWidget * pCtrl = hbgtk_cpar( 1, "HGtkComboIndex" );
   gint nActivo;

   if( ! pCtrl || ! GTK_IS_COMBO_BOX( pCtrl ) )
   {
      if( pCtrl )
         hbgtk_errArgs( "HGtkComboIndex", "ese widget no es un desplegable" );
      hb_retni( 0 );
      return;
   }

   nActivo = gtk_combo_box_get_active( GTK_COMBO_BOX( pCtrl ) );
   hb_retni( nActivo < 0 ? 0 : nActivo + 1 );
}

/* HGtkComboSelect( pCombo, nEntrada ) — selecciona (1-based) */
HB_FUNC( HGTKCOMBOSELECT )
{
   GtkWidget * pCtrl = hbgtk_cpar( 1, "HGtkComboSelect" );
   int nEntrada;

   if( ! pCtrl )
   {
      hb_ret();
      return;
   }
   if( ! GTK_IS_COMBO_BOX( pCtrl ) )
   {
      hbgtk_errArgs( "HGtkComboSelect", "ese widget no es un desplegable" );
      hb_ret();
      return;
   }

   nEntrada = hb_parni( 2 );
   gtk_combo_box_set_active( GTK_COMBO_BOX( pCtrl ),
                             nEntrada >= 1 ? nEntrada - 1 : -1 );
   hb_ret();
}

/* HGtkFrameNew( cTexto ) -> grupo con marco (TGroup) */
HB_FUNC( HGTKFRAMENEW )
{
   GtkWidget * pCtrl;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   pCtrl = gtk_frame_new( hb_pcount() >= 1 && HB_ISCHAR( 1 ) ?
                          hb_parc( 1 ) : NULL );
   hbgtk_crear_fixed( pCtrl );
   hbgtk_ctrl_init( pCtrl );
   hb_retptr( pCtrl );
}

/*
 * HGtkBoxNew( lHorizontal ) -> caja de empaquetado (TBox): el modo de
 * cajas de la fase 4. La caja es a la vez hijo de su padre (se coloca
 * en su GtkFixed, con AT y SIZE como cualquier control) y contenedor
 * de los suyos, que se empaquetan en orden: HGtkAdd la distingue porque
 * su clave de posicionamiento apunta a ella misma y es un GtkBox.
 */
HB_FUNC( HGTKBOXNEW )
{
   GtkWidget * pCaja;

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   pCaja = gtk_box_new( hb_pcount() >= 1 && HB_ISLOG( 1 ) &&
                        hb_parl( 1 ) ?
                        GTK_ORIENTATION_HORIZONTAL :
                        GTK_ORIENTATION_VERTICAL, 6 );
   hbgtk_contenedor_pon( pCaja, pCaja );
   hbgtk_ctrl_init( pCaja );
   hb_retptr( pCaja );
}

/*
 * HGtkCuentas() -> { ventanas, controles, relojes, grips }
 *
 * Las cuatro cuentas que comprueba tests/fugas_test.prg tras abrir y
 * cerrar ventanas en bucle: si algún codeblock se quedara sujeto, el
 * número de grips no volvería al de partida y crecería con cada
 * ciclo. Ningún programa de aplicación la necesita: es de pruebas.
 */
HB_FUNC( HGTKCUENTAS )
{
   PHB_ITEM pRes = hb_itemArrayNew( 4 );

   hb_arraySetNI( pRes, 1, hbgtk_nVentanas );
   hb_arraySetNI( pRes, 2, g_slist_length( s_pCtrls ) );
   hb_arraySetNI( pRes, 3, hbgtk_relojes() );
   hb_arraySetNI( pRes, 4, hbgtk_nGrips );
   hb_itemReturnRelease( pRes );
}
