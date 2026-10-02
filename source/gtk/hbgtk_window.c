/*
 * hbgtk_window.c — ventana de nivel superior y su bucle de eventos
 *
 * El puntero al GtkWidget sale en hb_retptr() y vuelve en hb_parptr().
 * El objeto Harbour que la creó (TWindow) queda sujeto con un grip de
 * GC mientras la ventana exista, de modo que el codeblock bClose no se
 * libera mientras haya una señal que pueda llamarlo. Al destruir la
 * ventana se suelta ese grip.
 *
 * Licencia: LGPL-3.0-or-later
 */
#include <stdio.h>
#include "hbgtk.h"
#include "hbapierr.h"

#define HGTK_OWNER_KEY  "harbgtklin-owner"
#define HGTK_CIERRE_KEY "harbgtklin-cierre"

int hbgtk_nVentanas = 0;
int hbgtk_nBucle = 0;

/* ventanas creadas y todavía no destruidas. Sirve para saber si un
 * puntero sigue vivo sin desreferenciarlo (un widget destruido puede
 * estar liberado): sólo se compara con la lista. */
static GSList * s_pVentanas = NULL;

static void hbgtk_wnd_add( GtkWidget * pWnd )
{
   s_pVentanas = g_slist_prepend( s_pVentanas, pWnd );
   hbgtk_nVentanas++;
}

static void hbgtk_wnd_del( GtkWidget * pWnd )
{
   s_pVentanas = g_slist_remove( s_pVentanas, pWnd );
   if( hbgtk_nVentanas > 0 )
      hbgtk_nVentanas--;
}

HB_BOOL hbgtk_wnd_alive( gpointer pWnd )
{
   return g_slist_find( s_pVentanas, pWnd ) != NULL;
}

/* ------------------------------------------------------------------ */
/* propietario: el objeto Harbour que creó la ventana                  */
/* ------------------------------------------------------------------ */

static PHB_ITEM hbgtk_owner( GtkWidget * pWnd )
{
   return (PHB_ITEM) g_object_get_data( G_OBJECT( pWnd ), HGTK_OWNER_KEY );
}

/* suelta el grip del propietario (si lo hay) */
static void hbgtk_owner_drop( GtkWidget * pWnd )
{
   PHB_ITEM pOwner = hbgtk_owner( pWnd );

   if( pOwner )
   {
      g_object_set_data( G_OBJECT( pWnd ), HGTK_OWNER_KEY, NULL );
      hb_gcGripDrop( pOwner );
      hbgtk_nGrips--;
   }
}

/* puntero de ventana validado; si es inválido, error de Harbour */
static GtkWidget * hbgtk_wnd_par( int iPar, const char * szProc )
{
   GtkWidget * pWnd = (GtkWidget *) hb_parptr( iPar );

   if( ! pWnd || ! GTK_IS_WINDOW( pWnd ) )
   {
      hbgtk_errArgs( szProc, "puntero de ventana no válido" );
      return NULL;
   }
   return pWnd;
}

/* ------------------------------------------------------------------ */
/* señales                                                             */
/* ------------------------------------------------------------------ */

/*
 * delete-event: el aspa de la barra de título. Devolver TRUE a GTK
 * cancela el cierre. Si el objeto tiene un bClose y devuelve .F.,
 * se cancela; si no hay bloque, o el bloque devuelve .T., se cierra.
 *
 * La respuesta queda marcada en el widget (HGTK_CIERRE_KEY: 2 si se
 * cancela, 1 si se acepta) para que HGtkDlgRun, que no siempre ve
 * correr esta rutina, sepa si ya se preguntó y con qué resultado.
 */
static gboolean hbgtk_pregunta_cierre( GtkWidget * pWnd )
{
   PHB_ITEM pOwner = hbgtk_owner( pWnd );
   gboolean fCancelar = FALSE;

   if( pOwner )
   {
      PHB_ITEM pBloque = hb_gcGripGet( hb_objSendMsg( pOwner, "bClose", 0 ) );

      hbgtk_nGrips++;
      if( pBloque )
      {
         if( HB_IS_BLOCK( pBloque ) )
         {
            PHB_ITEM pResultado = hb_vmEvalBlock( pBloque );

            if( pResultado && HB_IS_LOGICAL( pResultado ) &&
                ! hb_itemGetL( pResultado ) )
               fCancelar = TRUE;
         }
         hb_gcGripDrop( pBloque );
         hbgtk_nGrips--;
      }
   }

   /* un error dentro del bloque no debe dejar la ventana abierta */
   if( hb_vmRequestQuery() )
      fCancelar = FALSE;

   g_object_set_data( G_OBJECT( pWnd ), HGTK_CIERRE_KEY,
                      GINT_TO_POINTER( fCancelar ? 2 : 1 ) );

   return fCancelar;
}

static gboolean hbgtk_on_delete( GtkWidget * pWnd, GdkEvent * pEvent,
                                 gpointer pData )
{
   (void) pEvent;
   (void) pData;

   return hbgtk_pregunta_cierre( pWnd );
}

/*
 * destroy: suelta el grip del propietario y, si esta era la última
 * ventana del proceso, sale del bucle de eventos. Sólo se llama a
 * gtk_main_quit() si hay realmente un gtk_main corriendo: el bucle de
 * una ventana se sale solo, en cuanto esa ventana deja de existir.
 */
static void hbgtk_on_destroy( GtkWidget * pWnd, gpointer pData )
{
   (void) pData;

   hbgtk_owner_drop( pWnd );
   hbgtk_wnd_del( pWnd );

   if( hbgtk_nVentanas == 0 && hbgtk_nBucle > 0 && gtk_main_level() > 0 )
      gtk_main_quit();
}

/* ------------------------------------------------------------------ */
/* funciones del puente                                                */
/* ------------------------------------------------------------------ */

/* HGtkWndNew( cTitulo, nAncho, nAlto ) -> puntero de la ventana */
HB_FUNC( HGTKWNDNEW )
{
   const char * szTitulo;
   int nAncho, nAlto;
   GtkWidget * pWnd;

   if( hb_pcount() >= 1 && ! HB_ISCHAR( 1 ) )
   {
      hbgtk_errArgs( "HGtkWndNew", "el título debe ser una cadena" );
      hb_retptr( NULL );
      return;
   }

   szTitulo = hb_pcount() >= 1 ? hb_parc( 1 ) : "";
   if( ! szTitulo )
      szTitulo = "";

   nAncho = hb_parni( 2 );
   nAlto  = hb_parni( 3 );

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   pWnd = gtk_window_new( GTK_WINDOW_TOPLEVEL );
   gtk_window_set_title( GTK_WINDOW( pWnd ), szTitulo );
   if( nAncho > 0 && nAlto > 0 )
      gtk_window_set_default_size( GTK_WINDOW( pWnd ), nAncho, nAlto );
   gtk_window_set_position( GTK_WINDOW( pWnd ), GTK_WIN_POS_CENTER );

   g_signal_connect( pWnd, "delete-event", G_CALLBACK( hbgtk_on_delete ), NULL );
   g_signal_connect( pWnd, "destroy", G_CALLBACK( hbgtk_on_destroy ), NULL );

   hbgtk_crear_fixed( pWnd );
   hbgtk_wnd_add( pWnd );

   hb_retptr( pWnd );
}

/* HGtkDlgNew( cTitulo, nAncho, nAlto ) -> puntero del diálogo modal.
 * Un diálogo es una ventana (GtkDialog hereda de GtkWindow): mismas
 * señales de cierre y misma lista de ventanas vivas. */
HB_FUNC( HGTKDLGNEW )
{
   const char * szTitulo;
   int nAncho, nAlto;
   GtkWidget * pWnd;

   if( hb_pcount() >= 1 && ! HB_ISCHAR( 1 ) )
   {
      hbgtk_errArgs( "HGtkDlgNew", "el título debe ser una cadena" );
      hb_retptr( NULL );
      return;
   }

   szTitulo = hb_pcount() >= 1 ? hb_parc( 1 ) : "";
   if( ! szTitulo )
      szTitulo = "";

   nAncho = hb_parni( 2 );
   nAlto  = hb_parni( 3 );

   if( ! hbgtk_initGTK() )
   {
      hb_retptr( NULL );
      return;
   }

   pWnd = gtk_dialog_new();
   gtk_window_set_title( GTK_WINDOW( pWnd ), szTitulo );
   if( nAncho > 0 && nAlto > 0 )
      gtk_window_set_default_size( GTK_WINDOW( pWnd ), nAncho, nAlto );
   gtk_window_set_position( GTK_WINDOW( pWnd ), GTK_WIN_POS_CENTER );

   g_signal_connect( pWnd, "delete-event", G_CALLBACK( hbgtk_on_delete ), NULL );
   g_signal_connect( pWnd, "destroy", G_CALLBACK( hbgtk_on_destroy ), NULL );

   hbgtk_crear_fixed( pWnd );
   hbgtk_wnd_add( pWnd );

   hb_retptr( pWnd );
}

/*
 * HGtkWndSetMenu / HGtkWndSetBar / HGtkWndSetStatus — cuelgan la
 * barra de menú, la de botones o la de estado en la caja vertical de
 * la ventana (se crea al construirla). La ventana y la barra han de
 * seguir vivas: se comprueba contra las listas, sin desreferenciar.
 */
static void hbgtk_wnd_cuelga( int nTipo, const char * szProc )
{
   GtkWidget * pWnd = hbgtk_wnd_par( 1, szProc );
   GtkWidget * pBar = (GtkWidget *) hb_parptr( 2 );
   const char * szError = NULL;

   if( ! pWnd )
   {
      hb_ret();
      return;
   }

   if( ! pBar || ! hbgtk_ctrl_alive( pBar ) )
      szError = "puntero de widget no válido";
   else if( ! hbgtk_caja_cuelga( pWnd, pBar, nTipo ) )
      szError = "esa ventana no admite esa barra";

   if( szError )
      hbgtk_errArgs( szProc, szError );

   hb_ret();
}

/* HGtkWndSetMenu( pWnd, pMenuBar ) — barra de menú de la ventana */
HB_FUNC( HGTKWNDSETMENU )
{
   hbgtk_wnd_cuelga( HGTK_CAJA_MENUBAR, "HGtkWndSetMenu" );
}

/* HGtkWndSetBar( pWnd, pBarra ) — barra de botones de la ventana */
HB_FUNC( HGTKWNDSETBAR )
{
   hbgtk_wnd_cuelga( HGTK_CAJA_BARRA, "HGtkWndSetBar" );
}

/* HGtkWndSetStatus( pWnd, pEstado ) — barra de estado de la ventana */
HB_FUNC( HGTKWNDSETSTATUS )
{
   hbgtk_wnd_cuelga( HGTK_CAJA_ESTADO, "HGtkWndSetStatus" );
}

/* HGtkWndMove( pWnd, nX, nY ) — posición en píxeles del widget */
HB_FUNC( HGTKWNDMOVE )
{
   GtkWidget * pWnd = hbgtk_wnd_par( 1, "HGtkWndMove" );

   if( ! pWnd )
   {
      hb_ret();
      return;
   }

   gtk_window_set_position( GTK_WINDOW( pWnd ), GTK_WIN_POS_NONE );
   gtk_window_move( GTK_WINDOW( pWnd ), hb_parni( 2 ), hb_parni( 3 ) );
   hb_ret();
}

/*
 * HGtkDlgRun( pDlg ) — muestra el diálogo modal y no regresa hasta
 * que se cierra. Devuelve la respuesta de GTK (no la usa la clase:
 * el diálogo se destruye siempre al salir).
 *
 * El aspa no destruye un GtkDialog: llega como respuesta de borrado
 * y con el diálogo todavía en pantalla. Aquí es donde se pregunta el
 * bClose; si dice que no, se vuelve a entrar a esperar. Ese es el
 * comportamiento de fase 1: salir con sí/no al salir.
 */
HB_FUNC( HGTKDLGRUN )
{
   GtkWidget * pWnd = hbgtk_wnd_par( 1, "HGtkDlgRun" );
   gint nRespuesta;
   gboolean fOtraVez;

   if( ! pWnd )
   {
      hb_retni( -1 );
      return;
   }
   if( ! GTK_IS_DIALOG( pWnd ) )
   {
      hbgtk_errArgs( "HGtkDlgRun", "el widget no es un diálogo" );
      hb_retni( -1 );
      return;
   }

   gtk_widget_show_all( pWnd );

   do
   {
      fOtraVez = FALSE;
      nRespuesta = gtk_dialog_run( GTK_DIALOG( pWnd ) );

      if( nRespuesta == GTK_RESPONSE_DELETE_EVENT &&
          hbgtk_wnd_alive( pWnd ) && ! gtk_widget_in_destruction( pWnd ) )
      {
         gpointer pMarca = g_object_get_data( G_OBJECT( pWnd ),
                                              HGTK_CIERRE_KEY );

         if( pMarca == GINT_TO_POINTER( 2 ) )
            fOtraVez = TRUE;              /* cancelaron: sigue abierto */
         else if( ! pMarca )              /* nadie preguntó aún */
            fOtraVez = hbgtk_pregunta_cierre( pWnd );
         /* pMarca == 1 → aceptaron: se sale y Activate() lo destruye */
      }
      g_object_set_data( G_OBJECT( pWnd ), HGTK_CIERRE_KEY, NULL );
   }
   while( fOtraVez );

   hb_retni( nRespuesta );
}

/* HGtkWndAlive( pWnd ) -> .T. si el widget todavía existe.
 * Sólo compara punteros: nunca desreferencia el widget. */
HB_FUNC( HGTKWNDALIVE )
{
   void * pWnd = hb_parptr( 1 );

   hb_retl( pWnd != NULL && hbgtk_wnd_alive( pWnd ) );
}

/* HGtkWndSetOwner( pWnd, oObjeto ) — sujeta el objeto hasta destruir */
/* HGtkWndFocus( pVentana ) -> tipo del widget que tiene el foco
 * ("GtkListBox", "GtkToolButton", ...); "" si no lo tiene ninguno.
 * Sólo consulta el foco previsto, no lo mueve: sirve para comprobar
 * por dónde van a ir las teclas sin tener que mirar la pantalla. */
HB_FUNC( HGTKWNDFOCUS )
{
   GtkWidget * pWnd = hbgtk_wnd_par( 1, "HGtkWndFocus" );
   GtkWidget * pFoco;

   if( ! pWnd || ! GTK_IS_WINDOW( pWnd ) )
   {
      hb_retc( "" );
      return;
   }

   pFoco = gtk_window_get_focus( GTK_WINDOW( pWnd ) );
   hb_retc( pFoco ? G_OBJECT_TYPE_NAME( pFoco ) : "" );
}

HB_FUNC( HGTKWNDSETOWNER )
{
   GtkWidget * pWnd = hbgtk_wnd_par( 1, "HGtkWndSetOwner" );
   PHB_ITEM pOwner;

   if( ! pWnd )
   {
      hb_ret();
      return;
   }

   if( hb_pcount() >= 2 && ! HB_ISOBJECT( 2 ) )
   {
      hbgtk_errArgs( "HGtkWndSetOwner", "se esperaba un objeto Harbour" );
      hb_ret();
      return;
   }

   pOwner = hb_pcount() >= 2 ? hb_param( 2, HB_IT_OBJECT ) : NULL;

   hbgtk_owner_drop( pWnd );
   if( pOwner )
      g_object_set_data( G_OBJECT( pWnd ), HGTK_OWNER_KEY,
                         hb_gcGripGet( pOwner ) );

   hb_ret();
}

/* HGtkWndSetTitle( pWnd, cTitulo ) */
HB_FUNC( HGTKWNDSETTITLE )
{
   GtkWidget * pWnd = hbgtk_wnd_par( 1, "HGtkWndSetTitle" );

   if( ! pWnd )
   {
      hb_ret();
      return;
   }
   if( hb_pcount() < 2 || ! HB_ISCHAR( 2 ) )
   {
      hbgtk_errArgs( "HGtkWndSetTitle", "el título debe ser una cadena" );
      hb_ret();
      return;
   }

   gtk_window_set_title( GTK_WINDOW( pWnd ), hb_parc( 2 ) );
   hb_ret();
}

/* HGtkWndGetTitle( pWnd ) -> cTitulo */
HB_FUNC( HGTKWNDGETTITLE )
{
   GtkWidget * pWnd = hbgtk_wnd_par( 1, "HGtkWndGetTitle" );
   const char * szTitulo;

   if( ! pWnd )
   {
      hb_retc( "" );
      return;
   }

   szTitulo = gtk_window_get_title( GTK_WINDOW( pWnd ) );
   hb_retc( szTitulo ? szTitulo : "" );
}

/* HGtkWndShow( pWnd ) — muestra la ventana en pantalla */
HB_FUNC( HGTKWNDSHOW )
{
   GtkWidget * pWnd = hbgtk_wnd_par( 1, "HGtkWndShow" );

   if( ! pWnd )
   {
      hb_ret();
      return;
   }

   gtk_widget_show_all( pWnd );
   hb_ret();
}

/* HGtkWndRefocus( pWnd ) — vuelve a aplicar el foco que la ventana ya
 * tenía guardado. Pedir el foco antes de mostrar no basta: al mapear
 * la ventana GTK rehace el foco y el widget se queda a medias, y
 * aunque las teclas siguen llegando, Return ya no abre la edición de
 * una celda. Se llama nada más mostrar, desde TWindow:Activate. */
HB_FUNC( HGTKWNDREFOCUS )
{
   GtkWidget * pWnd = hbgtk_wnd_par( 1, "HGtkWndRefocus" );
   GtkWidget * pFoco;

   if( ! pWnd )
   {
      hb_ret();
      return;
   }

   pFoco = gtk_window_get_focus( GTK_WINDOW( pWnd ) );
   if( pFoco )
      gtk_widget_grab_focus( pFoco );

   hb_ret();
}

/* HGtkWndDestroy( pWnd ) — destruye la ventana */
HB_FUNC( HGTKWNDDESTROY )
{
   GtkWidget * pWnd = hbgtk_wnd_par( 1, "HGtkWndDestroy" );

   if( ! pWnd )
   {
      hb_ret();
      return;
   }

   gtk_widget_destroy( pWnd );
   hb_ret();
}

/*
 * HGtkMain( [ pVentana ] ) — bucle de eventos de GTK.
 *
 * Con la ventana, espera hasta que ÉSA ventana se cierre. Se puede
 * llamar desde una acción de otra ventana que siga abierta: las dos
 * reciben eventos a la vez, porque el bucle de la segunda es un bucle
 * anidado que procesa todo lo que entra, y el ACTIVATE de la primera
 * sólo regresa cuando se cierre la suya. Así varias ventanas no son
 * modales entre sí.
 *
 * Sin ventana, el comportamiento de siempre: entra en gtk_main() y
 * regresa cuando se ha destruido la última ventana del proceso.
 */
HB_FUNC( HGTKMAIN )
{
   void * pWnd = ( hb_pcount() >= 1 && HB_ISPOINTER( 1 ) ) ?
                 hb_parptr( 1 ) : NULL;

   if( pWnd )
   {
      hbgtk_nBucle++;
      while( hbgtk_wnd_alive( pWnd ) )
         g_main_context_iteration( NULL, TRUE );
      hbgtk_nBucle--;
   }
   else if( hbgtk_nVentanas > 0 )
   {
      hbgtk_nBucle++;
      gtk_main();
      hbgtk_nBucle--;
   }

   hb_ret();
}
