/*
 * print.prg — TPrint: listado de texto por GtkPrintOperation
 *
 * No hay motor de informes: hay un array de líneas que se pasan
 * tal cual a GTK, que pagina según la fuente (mide cuántas caben) y
 * dibuja. Dos caminos:
 *
 *   - Dialog()  muestra el diálogo de impresión de GTK y espera;
 *   - ToFile()  exporta a un fichero sin preguntar nada: con nombre
 *               ".pdf" sale un PDF (el backend "file" de GTK), que es
 *               el camino que se comprueba solo, sin impresora.
 *
 * Ambas devuelven .T. si llegó a imprimirse o a exportarse y .F. si
 * se canceló o GTK falló (un fallo de GTK también llega al
 * ErrorBlock). El título es el nombre del trabajo y la fuente, por
 * omisión, "Monospace 10".
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TPrint

   VAR cTitulo     INIT  ""
   VAR cFuente     INIT  "Monospace 10"
   VAR aLineas     INIT  {}

   METHOD New( cTitulo, cFuente ) CONSTRUCTOR
   METHOD AddLine( cTexto )
   METHOD Clear()
   METHOD LineCount()
   METHOD Dialog()
   METHOD ToFile( cFichero )

ENDCLASS

/* New( [ cTitulo [, cFuente ] ] ) */
METHOD New( cTitulo, cFuente ) CLASS TPrint

   IF PCount() >= 1
      IF ValType( cTitulo ) != "C"
         HgtkErrArgs( "TPrint:New", "el título debe ser una cadena" )
      ELSE
         ::cTitulo := cTitulo
      ENDIF
   ENDIF
   IF PCount() >= 2
      IF ValType( cFuente ) != "C" .OR. Empty( cFuente )
         HgtkErrArgs( "TPrint:New", "la fuente debe ser una cadena" )
      ELSE
         ::cFuente := cFuente
      ENDIF
   ENDIF

RETURN SELF

/* AddLine( cTexto ) — añade una línea al final del listado */
METHOD AddLine( cTexto ) CLASS TPrint

   IF ValType( cTexto ) != "C"
      cTexto := ""
   ENDIF
   AAdd( ::aLineas, cTexto )

RETURN Len( ::aLineas )

/* Clear() — el listado empieza de cero */
METHOD Clear() CLASS TPrint

   ::aLineas := {}

RETURN NIL

/* LineCount() -> número de líneas del listado */
METHOD LineCount() CLASS TPrint

RETURN Len( ::aLineas )

/* Dialog() -> .T. si el usuario imprimió desde el diálogo de GTK */
METHOD Dialog() CLASS TPrint

RETURN HGtkPrintRun( ::cTitulo, ::cFuente, HGTK_PRINT_DIALOGO, "", ;
                     ::aLineas )

/* ToFile( cFichero ) -> .T. si se exportó; por ejemplo a "listado.pdf" */
METHOD ToFile( cFichero ) CLASS TPrint

   IF ValType( cFichero ) != "C" .OR. Empty( cFichero )
      HgtkErrArgs( "TPrint:ToFile", "hace falta el fichero de destino" )
      RETURN .F.
   ENDIF

RETURN HGtkPrintRun( ::cTitulo, ::cFuente, HGTK_PRINT_EXPORTA, ;
                     cFichero, ::aLineas )
