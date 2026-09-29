/*
 * harbgtk.ch — comandos y constantes de HarbGtkLin
 *
 * Librería de interfaz de escritorio para Linux (Harbour + GTK 3),
 * al estilo de FiveWin. Este fichero no se llama fivewin.ch y no
 * comparte include guards con él.
 *
 * Licencia: LGPL-3.0-or-later
 */

#ifndef HARBGTK_CH
#define HARBGTK_CH

/* ------------------------------------------------------------------ */
/* Identidad                                                           */
/* ------------------------------------------------------------------ */

#define HGTK_NOMBRE              "HarbGtkLin"
#define HGTK_FASE                0

/* ------------------------------------------------------------------ */
/* Coordenadas                                                         */
/*                                                                     */
/* La primera versión usa unidades de diálogo al estilo FiveWin:       */
/* columnas (ancho medio de carácter) y filas (alto de línea).         */
/* Se convierten a píxeles con este factor fijo.                       */
/* ------------------------------------------------------------------ */

#define HGTK_PX_COLUMNA          8
#define HGTK_PX_FILA             16

/* Tamaño por omisión de una ventana, en unidades de diálogo */
#define HGTK_COLS_DEF            60
#define HGTK_FILAS_DEF           18

/* ------------------------------------------------------------------ */
/* Comandos                                                            */
/*                                                                     */
/* La sintaxis concreta de los comandos (DEFINE WINDOW, ACTIVATE        */
/* WINDOW, ...) se congela en docs/api-fase0.md y se implementa en la   */
/* fase 1, cuando existan los controles que los usan.                  */
/* ------------------------------------------------------------------ */

#endif /* HARBGTK_CH */
