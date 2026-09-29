/*
 * coord_test.prg — pruebas de consola de la fase 0
 *
 * No necesita display: sólo comprueba la conversión de coordenadas y
 * el include de constantes. Sale con ErrorLevel( 1 ) si algo falla.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "harbgtk.ch"

STATIC nFallos := 0

PROCEDURE Main()

   chk( HgtkColToPx( 1 ) == HGTK_PX_COLUMNA, "1 columna = 8 px" )
   chk( HgtkRowToPx( 1 ) == HGTK_PX_FILA, "1 fila = 16 px" )
   chk( HgtkColToPx( 60 ) == 480, "60 columnas = 480 px" )
   chk( HgtkRowToPx( 18 ) == 288, "18 filas = 288 px" )
   chk( HgtkColToPx( 0 ) == 0, "0 columnas = 0 px" )
   chk( HgtkSize( 60, 18 )[ 1 ] == 480 .AND. HgtkSize( 60, 18 )[ 2 ] == 288, ;
        "HgtkSize devuelve el par" )

   chk( HGTK_PX_COLUMNA > 0 .AND. HGTK_PX_FILA > 0, "factor de conversión positivo" )
   chk( HGTK_COLS_DEF > 0 .AND. HGTK_FILAS_DEF > 0, "tamaño por omisión positivo" )
   chk( HGTK_NOMBRE == "HarbGtkLin", "nombre del proyecto" )

   IF nFallos == 0
      ? "coord_test: OK"
   ELSE
      ? "coord_test:" + Str( nFallos ) + " fallo(s)"
      ErrorLevel( 1 )
   ENDIF

   ? ""

RETURN

STATIC PROCEDURE chk( lOk, cMsg )

   IF ! lOk
      nFallos++
      ? "  FALLO: " + cMsg
   ENDIF

RETURN
