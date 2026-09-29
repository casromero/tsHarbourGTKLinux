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

#define HGTK_OWNER_KEY "harbgtklin-owner"

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

static gboolean hbgtk_wnd_alive( gpointer pWnd )
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
 */
static gboolean hbgtk_on_delete( GtkWidget * pWnd, GdkEvent * pEvent, gpointer pData )
{
   PHB_ITEM pOwner = hbgtk_owner( pWnd );
   gboolean fCancelar = FALSE;

   (void) pEvent;
   (void) pData;

   if( pOwner )
   {
      PHB_ITEM pBloque = hb_gcGripGet( hb_objSendMsg( pOwner, "bClose", 0 ) );

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
      }
   }

   /* un error dentro del bloque no debe dejar la ventana abierta */
   if( hb_vmRequestQuery() )
      fCancelar = FALSE;

   return fCancelar;
}

/*
 * destroy: suelta el grip del propietario y, si esta era la última
 * ventana del proceso, sale del bucle de eventos.
 */
static void hbgtk_on_destroy( GtkWidget * pWnd, gpointer pData )
{
   (void) pData;

   hbgtk_owner_drop( pWnd );
   hbgtk_wnd_del( pWnd );

   if( hbgtk_nVentanas == 0 && hbgtk_nBucle > 0 )
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

   hbgtk_wnd_add( pWnd );

   hb_retptr( pWnd );
}

/* HGtkWndAlive( pWnd ) -> .T. si el widget todavía existe.
 * Sólo compara punteros: nunca desreferencia el widget. */
HB_FUNC( HGTKWNDALIVE )
{
   void * pWnd = hb_parptr( 1 );

   hb_retl( pWnd != NULL && hbgtk_wnd_alive( pWnd ) );
}

/* HGtkWndSetOwner( pWnd, oObjeto ) — sujeta el objeto hasta destruir */
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
 * HGtkMain() — entra en el bucle de eventos de GTK y regresa cuando la
 * última ventana del proceso se ha destruido. No se espera a la
 * interfaz fuera de aquí.
 */
HB_FUNC( HGTKMAIN )
{
   if( hbgtk_nVentanas > 0 )
   {
      hbgtk_nBucle++;
      gtk_main();
      hbgtk_nBucle--;
   }

   hb_ret();
}
