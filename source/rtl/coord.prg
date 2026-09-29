/*
 * coord.prg — conversión de coordenadas de diálogo a píxeles
 *
 * Unidad de diálogo: columna y fila al estilo FiveWin, convertidas a
 * píxeles con el factor fijo documentado en include/harbgtk.ch y en
 * docs/api-fase0.md. El factor no cambia dentro de una fase.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "harbgtk.ch"

FUNCTION HgtkColToPx( nCols )

   IF ValType( nCols ) != "N"
      HgtkErrArgs( "HgtkColToPx", "se esperaba un número de columnas" )
   ENDIF

RETURN Int( nCols * HGTK_PX_COLUMNA )

FUNCTION HgtkRowToPx( nRows )

   IF ValType( nRows ) != "N"
      HgtkErrArgs( "HgtkRowToPx", "se esperaba un número de filas" )
   ENDIF

RETURN Int( nRows * HGTK_PX_FILA )

/* Devuelve una ventana de nCols x nRows unidades de diálogo */
FUNCTION HgtkSize( nCols, nRows )

RETURN { HgtkColToPx( nCols ), HgtkRowToPx( nRows ) }
