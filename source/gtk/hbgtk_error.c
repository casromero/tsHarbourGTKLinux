/*
 * hbgtk_error.c — errores de uso, por el mecanismo de error de Harbour
 *
 * No hay abort() de GTK aquí: un uso incorrecto se informa con
 * hb_errRT_BASE() y lo gestiona el ErrorBlock() del programa.
 *
 * Licencia: LGPL-3.0-or-later
 */
#include "hbgtk.h"
#include "hbapierr.h"

static void hbgtk_error( HB_ERRCODE nGenCode, const char * szProc, const char * szMsg )
{
   hb_errRT_BASE( nGenCode,
                  1001,
                  ( szMsg && *szMsg ) ? szMsg : "error de HarbGtkLin",
                  ( szProc && *szProc ) ? szProc : "HGTK",
                  HB_ERR_ARGS_BASEPARAMS );
}

void hbgtk_errArgs( const char * szProc, const char * szMsg )
{
   hbgtk_error( EG_ARG, szProc, szMsg );
}

void hbgtk_errGui( const char * szProc, const char * szMsg )
{
   hbgtk_error( EG_UNSUPPORTED, szProc, szMsg );
}

/* HGtkErrArgs( cProcedimiento, cMensaje ) — error de uso, genérico */
HB_FUNC( HGTKERRARGS )
{
   hbgtk_errArgs( hb_pcount() >= 1 ? hb_parc( 1 ) : NULL,
                  hb_pcount() >= 2 ? hb_parc( 2 ) : NULL );
}

/* HGtkErrGui( cProcedimiento, cMensaje ) — GTK no está disponible */
HB_FUNC( HGTKERRGUI )
{
   hbgtk_errGui( hb_pcount() >= 1 ? hb_parc( 1 ) : NULL,
                 hb_pcount() >= 2 ? hb_parc( 2 ) : NULL );
}
