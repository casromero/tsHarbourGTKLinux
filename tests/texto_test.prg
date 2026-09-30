/*
 * texto_test.prg — prueba de consola de la fase 2
 *
 * Comprueba HgtkTexto() y HgtkTextos(), la conversión que usan la
 * lista y el browse para llevar cualquier valor a las cadenas con que
 * GTK pinta. No necesita pantalla: es una prueba de consola y corre en
 * "make test".
 *
 * Sale con ErrorLevel( 1 ) si algo falla.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

FUNCTION Main()

   LOCAL cFallo := ""
   LOCAL aFila  := { 7, "Ana", .T., 3.5 }
   LOCAL aTexto
   LOCAL dFch   := Date()
   LOCAL n

   IF HgtkTexto( "Cádiz" ) != "Cádiz"
      cFallo := "una cadena debe pasar tal cual"
   ENDIF
   IF cFallo == "" .AND. HgtkTexto( 7 ) != "7"
      cFallo := "un número debe convertirse a texto"
   ENDIF
   IF cFallo == "" .AND. HgtkTexto( 3.5 ) != "3.5"
      cFallo := "un decimal debe convertirse a texto"
   ENDIF
   IF cFallo == "" .AND. HgtkTexto( .T. ) != ".T."
      cFallo := "un lógico debe convertirse a texto"
   ENDIF
   IF cFallo == "" .AND. HgtkTexto( dFch ) != DToC( dFch )
      cFallo := "una fecha debe convertirse como se lee en pantalla"
   ENDIF
   IF cFallo == "" .AND. HgtkTexto( {} ) != ""
      cFallo := "un array no cabe en una celda: debe dar vacío"
   ENDIF
   IF cFallo == "" .AND. HgtkTexto( NIL ) != ""
      cFallo := "NIL no cabe en una celda: debe dar vacío"
   ENDIF

   IF cFallo == ""
      aTexto := HgtkTextos( aFila )
      IF ! HB_IsArray( aTexto ) .OR. Len( aTexto ) != Len( aFila )
         cFallo := "HgtkTextos debe devolver una entrada por fila"
      ELSE
         FOR n := 1 TO Len( aFila )
            IF aTexto[ n ] != HgtkTexto( aFila[ n ] )
               cFallo := "la entrada " + Str( n ) + " no se convirtió"
               EXIT
            ENDIF
         NEXT
      ENDIF
   ENDIF

   IF cFallo == ""
      aTexto := HgtkTextos( "no es un array" )
      IF Len( aTexto ) != 0
         cFallo := "sin array, HgtkTextos debe devolver uno vacío"
      ENDIF
   ENDIF

   IF cFallo == ""
      ? "texto_test: OK"
   ELSE
      ? "texto_test: FALLO -", cFallo
      ErrorLevel( 1 )
   ENDIF

RETURN NIL
