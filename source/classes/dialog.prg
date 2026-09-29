/*
 * dialog.prg — TDialog: ventana modal
 *
 * Hereda de TWindow (título, cierre con bClose, End, IsAlive) y sólo
 * cambia el arranque: ACTIVATE no entra en el bucle general de GTK
 * sino en gtk_dialog_run(), que no regresa hasta que el diálogo se
 * cierra. Al regresar el diálogo queda destruido.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TDialog FROM TWindow

   METHOD New( cTitle, nCols, nRows ) CONSTRUCTOR
   METHOD Activate()

ENDCLASS

/* New( cTitle [, nCols [, nRows ]] ) — igual que TWindow, modal */
METHOD New( cTitle, nCols, nRows ) CLASS TDialog

   ::InitVentana( cTitle, nCols, nRows, .T. )

RETURN SELF

/*
 * Muestra el diálogo y espera hasta que se cierre; al volver, el
 * diálogo está destruido. Sólo aquí se espera a la interfaz.
 */
METHOD Activate() CLASS TDialog

   IF ::hWnd == NIL
      RETURN SELF
   ENDIF

   IF ! ::lActive
      ::lActive := .T.

      HGtkWndShow( ::hWnd )
      HGtkDlgRun( ::hWnd )

      ::lActive := .F.

      IF HGtkWndAlive( ::hWnd )
         /* regresó sin destruirse (una respuesta, no un cierre):
          * el diálogo siempre queda cerrado al salir de ACTIVATE */
         ::End()
      ELSE
         ::hWnd       := NIL
         ::lDestroyed := .T.
      ENDIF
   ENDIF

RETURN SELF
