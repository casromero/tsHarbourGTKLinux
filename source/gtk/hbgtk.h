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
#endif /* HARBGTK_H */
