/*
 * timer.prg — TTimer: dispara un bloque cada cierto tiempo
 *
 * No hay widget: el disparo lo hace GLib en el mismo bucle de eventos
 * que las ventanas, así que el bloque corre dentro de ACTIVATE, como
 * una señal más. El codeblock lo sujeta el puente mientras el
 * temporizador exista.
 *
 * La vida la decide la ventana dueña: al destruirla se retira solo.
 * End() lo para antes y Activate() lo vuelve a arrancar con el mismo
 * intervalo.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TTimer

   VAR oWnd        INIT  NIL    // ventana dueña (cláusula OF)
   VAR hWnd        INIT  NIL    // puntero opaco del puente
   VAR nInterval   INIT  0      // milisegundos entre disparos
   VAR bAction     INIT  NIL    // codeblock a evaluar

   METHOD New( oParent, nMs, bAction ) CONSTRUCTOR
   METHOD Activate()
   METHOD Deactivate()
   METHOD End()
   METHOD IsActive()
   METHOD IsAlive()

ENDCLASS

/* New( oParent, nMs, bAction ) — nMs es el intervalo en milisegundos */
METHOD New( oParent, nMs, bAction ) CLASS TTimer

   IF ValType( nMs ) != "N" .OR. nMs < 1
      nMs := HGTK_TIMER_MS_DEF
   ENDIF

   IF ValType( bAction ) != "B"
      HgtkErrArgs( "TTimer:New", "se esperaba un codeblock (ACTION)" )
      bAction := NIL
   ENDIF

   IF ValType( oParent ) != "O" .OR. ! __objHasMsg( oParent, "AddControl" )
      HgtkErrArgs( "TTimer:New", ;
                   "el temporizador necesita una ventana (cláusula OF)" )
      RETURN SELF
   ENDIF

   ::oWnd      := oParent
   ::nInterval := Int( nMs )
   ::bAction   := bAction

   IF ::bAction != NIL .AND. ::oWnd:hWnd != NIL
      ::hWnd := HGtkTimerNew( ::oWnd:hWnd, ::nInterval, ::bAction )
      IF ::hWnd != NIL
         ::oWnd:AddControl( SELF )
      ENDIF
   ENDIF

RETURN SELF

/* Empieza a disparar (si ya disparaba, no hace falta nada) */
METHOD Activate() CLASS TTimer

   IF ! ::IsAlive()
      HgtkErrArgs( "TTimer:Activate", "el temporizador no existe" )
      RETURN NIL
   ENDIF

   HGtkTimerStart( ::hWnd )

RETURN NIL

/* Deja de disparar; el temporizador se conserva y se puede arrancar */
METHOD Deactivate() CLASS TTimer

   IF ::IsAlive()
      HGtkTimerStop( ::hWnd )
   ENDIF

RETURN NIL

/* Lo mismo que Deactivate(): toda clase termina con End() */
METHOD End() CLASS TTimer

RETURN ::Deactivate()

/* .T. si está creado y su ventana sigue viva */
METHOD IsAlive() CLASS TTimer

RETURN ::hWnd != NIL .AND. HGtkTimerAlive( ::hWnd )

/* .T. si está disparando ahora mismo */
METHOD IsActive() CLASS TTimer

RETURN ::IsAlive() .AND. HGtkTimerActive( ::hWnd )
