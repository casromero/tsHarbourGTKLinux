/*
 * texto.prg — de cualquier valor a texto de pantalla
 *
 * Los controles de GTK trabajan con cadenas UTF-8. Aquí se convierte
 * lo que el programador pase por una lista o una columna: cadenas tal
 * cual, números sin el relleno de Str(), fechas con DToC y lógicos
 * como .T., y el resto vacío (un array o un objeto no cabe
 * razonablemente en una celda).
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

/* HgtkTexto( x ) — texto de una sola entrada */
FUNCTION HgtkTexto( x )

   DO CASE
   CASE ValType( x ) == "C"        // la cadena, tal cual
      RETURN x
   CASE ValType( x ) == "N"        // sin los rellenos de Str()
      RETURN LTrim( hb_ValToStr( x ) )
   CASE ValType( x ) == "D"
      RETURN DToC( x )
   CASE ValType( x ) == "L"
      RETURN hb_ValToStr( x )
   ENDCASE

RETURN ""                          // arrays, objetos, NIL, bloques

/* HgtkTextos( a ) — un array de textos, entrada por entrada */
FUNCTION HgtkTextos( a )

   LOCAL aTexto := {}
   LOCAL n

   IF ! HB_IsArray( a )
      RETURN aTexto
   ENDIF

   FOR n := 1 TO Len( a )
      AAdd( aTexto, HgtkTexto( a[ n ] ) )
   NEXT

RETURN aTexto
