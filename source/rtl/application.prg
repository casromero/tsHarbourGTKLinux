/*
 * application.prg — TApplication: objeto único y arranque de GTK
 *
 * Fuente de arranque, aplicación y bucle (source/rtl).
 * gtk_init se ejecuta una sola vez, en el primer TApplication.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

STATIC s_oApplication

/*
 * Devuelve la única instancia de TApplication. La primera llamada
 * arranca GTK; si no hay display, se lanza el error y se devuelve
 * un objeto con GuiReady() == .F.
 */
FUNCTION HgtkApplication()

   IF s_oApplication == NIL
      s_oApplication := TApplication():New()
   ENDIF

RETURN s_oApplication

CLASS TApplication

   VAR cName       INIT  HGTK_NOMBRE
   VAR nPhase      INIT  HGTK_FASE
   VAR lGui        INIT  .F.
   VAR cGtkVersion INIT  ""

   METHOD New() CONSTRUCTOR
   METHOD InitGui()
   METHOD GuiReady()
   METHOD GtkVersion()

ENDCLASS

/* TApplication():New() devuelve siempre la misma instancia */
METHOD New() CLASS TApplication

   IF s_oApplication != NIL
      RETURN s_oApplication
   ENDIF

   ::InitGui()
   s_oApplication := SELF

RETURN SELF

METHOD InitGui() CLASS TApplication

   IF ! ::lGui
      ::lGui := HGtkInit()
      IF ::lGui
         ::cGtkVersion := HGtkVersion()
      ENDIF
   ENDIF

RETURN ::lGui

METHOD GuiReady() CLASS TApplication

RETURN ::lGui

METHOD GtkVersion() CLASS TApplication

RETURN ::cGtkVersion
