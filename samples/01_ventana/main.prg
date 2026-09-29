/*
 * 01_ventana — primera muestra de HarbGtkLin (fase 0)
 *
 * Abre una ventana con título UTF-8 y espera a que el programador la
 * cierre con el aspa de la barra de título. Al cerrarse, el proceso
 * termina sin quedarse colgado.
 *
 * Compilar:  make sample      (desde la raíz del proyecto)
 * Ejecutar:  samples/01_ventana/01_ventana
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "harbgtk.ch"

FUNCTION Main()

   LOCAL oWnd

   oWnd := TWindow():New( "Gestión de clientes", 60, 18 )

   ? "HarbGtkLin", Str( HGTK_FASE ), "- GTK", ;
     HgtkApplication():GtkVersion()
   ? "Título guardado en el widget:", oWnd:Title()

   oWnd:Activate()

   ? "Ventana cerrada. El proceso termina."

   ? ""   /* deja el final de línea para el prompt de la shell */

RETURN NIL
