/*
 * hbgtk_timer.c — TTimer: disparo periódico con codeblock
 *
 * GLib tiene relojes (g_timeout_add), no widgets: el temporizador es
 * una estructura con su grip de GC, que se suelta cuando se retira.
 * Se retira al pararlo y destruir la ventana dueña (señal destroy) o,
 * si nadie lo para, en el primer disparo en que ve que la ventana ya
 * no está: así no queda nada colgado de una ventana muerta.
 *
 * El puntero que guarda la clase se comprueba contra la lista de
 * temporizadores vivos, igual que los widgets, sin desreferenciarlo.
 *
 * Licencia: LGPL-3.0-or-later
 */
#include "hbgtk.h"

typedef struct
{
   PHB_ITEM  pBloque;   /* grip del codeblock, suelto al retirarse */
   gpointer  pPadre;    /* ventana dueña: sólo se compara, no se toca */
   guint     nId;       /* id del origen en GLib, 0 si no está corriendo */
   guint     nMs;       /* intervalo en milisegundos */
   int       nDentro;   /* >0 mientras se evalúa el bloque */
   gboolean  fCaduco;   /* la ventana se destruyó durante la evaluación */
} HGTK_TIMER;

static GSList * s_pTimers = NULL;

/* .T. si el puntero es un temporizador todavía creado */
static gboolean hbgtk_timer_valido( gpointer pTimer )
{
   return pTimer != NULL && g_slist_find( s_pTimers, pTimer ) != NULL;
}

/*
 * Retira el temporizador: origen, lista, grip y estructura. Nunca se
 * llama con el origen en medio de su propio disparo (entonces el
 * callback ha puesto nId a 0 y devuelve G_SOURCE_REMOVE, que es lo
 * que retira el origen).
 */
static void hbgtk_timer_liberar( HGTK_TIMER * pTimer )
{
   if( pTimer->nId )
   {
      g_source_remove( pTimer->nId );
      pTimer->nId = 0;
   }

   s_pTimers = g_slist_remove( s_pTimers, pTimer );

   if( pTimer->pBloque )
   {
      hb_gcGripDrop( pTimer->pBloque );
      hbgtk_nGrips--;
      pTimer->pBloque = NULL;
   }
   g_free( pTimer );
}

/* deja de disparar sin retirarlo del todo: se puede volver a arrancar */
static void hbgtk_timer_parar( HGTK_TIMER * pTimer )
{
   if( pTimer->nId )
   {
      /* si está dentro de su propio disparo no se toca el origen: lo
       * retira el callback al regresar, con nId ya a 0 */
      if( pTimer->nDentro == 0 )
         g_source_remove( pTimer->nId );
      pTimer->nId = 0;
   }
}

/* la ventana dueña se ha destruido: se retira sin tocar nada suyo */
static void hbgtk_on_timer_padre_destroy( gpointer pPadre, gpointer pData )
{
   HGTK_TIMER * pTimer = (HGTK_TIMER *) pData;

   g_signal_handlers_disconnect_by_data( pPadre, pTimer );
   pTimer->pPadre = NULL;

   if( pTimer->nDentro > 0 )
      pTimer->fCaduco = TRUE;   /* lo termina el callback, que está en él */
   else
      hbgtk_timer_liberar( pTimer );
}

static gboolean hbgtk_on_timer( gpointer pData )
{
   HGTK_TIMER * pTimer = (HGTK_TIMER *) pData;

   pTimer->nDentro++;

   if( ! pTimer->pPadre || ! hbgtk_wnd_alive( pTimer->pPadre ) )
   {
      pTimer->nDentro--;
      pTimer->nId = 0;      /* para no quitar el origen desde dentro */
      hbgtk_timer_liberar( pTimer );
      return G_SOURCE_REMOVE;
   }

   if( pTimer->pBloque && HB_IS_BLOCK( pTimer->pBloque ) )
      hb_vmEvalBlock( pTimer->pBloque );

   if( hb_vmRequestQuery() )
      hbgtk_timer_parar( pTimer );

   pTimer->nDentro--;

   if( pTimer->fCaduco )
   {
      hbgtk_timer_liberar( pTimer );
      return G_SOURCE_REMOVE;
   }
   if( pTimer->nId == 0 )        /* lo pararon mientras evaluaba */
      return G_SOURCE_REMOVE;

   return G_SOURCE_CONTINUE;
}

/* HGtkTimerNew( pVentana, nMs, bBloque ) -> temporizador parado */
HB_FUNC( HGTKTIMERNEW )
{
   HGTK_TIMER * pTimer;
   gpointer pPadre = hb_parptr( 1 );
   int nMs = hb_parni( 2 );

   if( ! hb_param( 3, HB_IT_BLOCK ) )
   {
      hbgtk_errArgs( "HGtkTimerNew", "hace falta un codeblock" );
      hb_retptr( NULL );
      return;
   }
   if( ! pPadre || ! hbgtk_wnd_alive( pPadre ) )
   {
      hbgtk_errArgs( "HGtkTimerNew", "la ventana no es válida" );
      hb_retptr( NULL );
      return;
   }
   if( nMs < 1 )
      nMs = 1000;

   pTimer = g_new0( HGTK_TIMER, 1 );
   pTimer->pBloque = hb_itemNew( hb_param( 3, HB_IT_BLOCK ) );
   hb_gcGripGet( pTimer->pBloque );
   hbgtk_nGrips++;
   pTimer->pPadre = pPadre;
   pTimer->nMs = (guint) nMs;

   s_pTimers = g_slist_prepend( s_pTimers, pTimer );
   g_signal_connect( pPadre, "destroy",
                     G_CALLBACK( hbgtk_on_timer_padre_destroy ), pTimer );

   hb_retptr( pTimer );
}

/* HGtkTimerStart( pTimer ) -> .T. si vuelve a estar disparando */
HB_FUNC( HGTKTIMERSTART )
{
   HGTK_TIMER * pTimer = (HGTK_TIMER *) hb_parptr( 1 );

   if( hbgtk_timer_valido( pTimer ) && pTimer->nId == 0 &&
       pTimer->pPadre && hbgtk_wnd_alive( pTimer->pPadre ) )
      pTimer->nId = g_timeout_add( pTimer->nMs, hbgtk_on_timer, pTimer );

   hb_retl( hbgtk_timer_valido( pTimer ) && pTimer->nId != 0 );
}

/* HGtkTimerActive( pTimer ) -> .T. si está disparando ahora mismo */
HB_FUNC( HGTKTIMERACTIVE )
{
   HGTK_TIMER * pTimer = (HGTK_TIMER *) hb_parptr( 1 );

   hb_retl( hbgtk_timer_valido( pTimer ) && pTimer->nId != 0 );
}

/* HGtkTimerStop( pTimer ) — deja de disparar (se puede arrancar luego) */
HB_FUNC( HGTKTIMERSTOP )
{
   HGTK_TIMER * pTimer = (HGTK_TIMER *) hb_parptr( 1 );

   if( hbgtk_timer_valido( pTimer ) )
      hbgtk_timer_parar( pTimer );
   hb_ret();
}

/* HGtkTimerAlive( pTimer ) -> .T. mientras siga creado y con ventana */
HB_FUNC( HGTKTIMERALIVE )
{
   HGTK_TIMER * pTimer = (HGTK_TIMER *) hb_parptr( 1 );

   hb_retl( hbgtk_timer_valido( pTimer ) && pTimer->pPadre != NULL );
}

/* temporizadores creados y no retirados — cuenta para las fugas */
int hbgtk_relojes( void )
{
   return g_slist_length( s_pTimers );
}
