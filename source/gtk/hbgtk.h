/*
 * hbgtk.h — estado y prototipos internos del puente C de HarbGtkLin
 *
 * El puente no contiene lógica de negocio: cada función crea un widget,
 * cambia una propiedad, lee un texto o conecta una señal.
 *
 * Licencia: LGPL-3.0-or-later
 */
#ifndef HARBGTK_H
#define HARBGTK_H

#include "hbapi.h"
#include "hbapiitm.h"   /* hb_itemGetL      */
#include "hbapicls.h"   /* hb_objSendMsg    */
#include "hbvm.h"       /* hb_vmEvalBlock   */
#include <gtk/gtk.h>

/* --- errores (hbgtk_error.c) ---------------------------------------- */
void hbgtk_errArgs( const char *szProc, const char *szMsg );
void hbgtk_errGui( const char *szProc, const char *szMsg );

/* --- arranque (hbgtk_init.c) ---------------------------------------- */
HB_BOOL hbgtk_initGTK( void );   /* gtk_init_check() una sola vez */

/* --- ventana y bucle (hbgtk_window.c) ------------------------------- */
extern int hbgtk_nVentanas;      /* ventanas creadas y no destruidas */
extern int hbgtk_nBucle;         /* profundidad de gtk_main()        */

/* --- controles (hbgtk_ctrl.c) --------------------------------------- */

/* Crea el contenedor de posicionamiento (GtkFixed) dentro de una
 * ventana, un diálogo o un grupo, y lo guarda en el propio widget.
 * Los controles se colocan ahí con HGtkAdd(). */
void hbgtk_crear_fixed( GtkWidget * pPadre );

/* Guarda otro contenedor de posicionamiento (la caja de una página de
 * pestañas o la propia TBox) en la clave del padre, que es donde lo
 * busca HGtkAdd(). */
void hbgtk_contenedor_pon( GtkWidget * pPadre, GtkWidget * pContenedor );

/* .T. si el puntero corresponde a un control todavía vivo. Sólo se
 * compara con la lista, sin desreferenciar el widget. */
HB_BOOL hbgtk_ctrl_alive( gpointer pCtrl );

/* Igual, para ventanas y diálogos (lista de hbgtk_window.c). */
HB_BOOL hbgtk_wnd_alive( gpointer pWnd );

/* Anota un widget recién creado en la lista de vivos y le conecta la
 * señal destroy, que suelta los codeblocks y lo borra de la lista. */
void hbgtk_ctrl_init( GtkWidget * pCtrl );

/* Widget del parámetro iPar comprobado contra la lista (sin
 * desreferenciarlo antes); error de Harbour si no es válido. */
GtkWidget * hbgtk_cpar( int iPar, const char * szProc );

/* Si el widget es un marco de desplazamiento, lo que tiene dentro (el
 * browse de la fase 3 vive en uno para tener barra: el foco hay que
 * ponerlo en la vista, no en el marco); si no, el propio widget. */
GtkWidget * hbgtk_desenvuelve( GtkWidget * pWidget );

/* Pixbuf de un fichero (PNG, JPEG...), o NULL si no se lee. Va con
 * GdkPixbuf y no necesita pantalla: sirve en pruebas de consola. */
GdkPixbuf * hbgtk_pixbuf( const char * szFichero );

/* Marca de mnemónico: "&x" de FiveWin a "_x" de GTK, "&&" a "&".
 * Devuelve una cadena que se libera con g_free(). */
char * hbgtk_mnemonico( const char * szTexto );

/* Huecos de la caja vertical de una ventana o un diálogo (fase 2):
 * barra de menú (0), barra de botones (1), barra de estado (2). */
#define HGTK_CAJA_MENUBAR 0
#define HGTK_CAJA_BARRA   1
#define HGTK_CAJA_ESTADO  2

gboolean hbgtk_caja_cuelga( GtkWidget * pPadre, GtkWidget * pHijo,
                            int nTipo );
#endif /* HARBGTK_H */
