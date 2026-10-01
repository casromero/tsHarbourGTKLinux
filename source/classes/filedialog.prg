/*
 * filedialog.prg — TFileDialog: selector de fichero o de directorio
 *
 * El diálogo de GTK (GtkFileChooserNative): se crea con el título y
 * la carpeta de partida, y cada llamada lo muestra y espera. Open()
 * pide un fichero existente, Save() uno por escribir (con su nombre
 * inicial y aviso si va a sobrescribir) y Directory() una carpeta.
 * Devuelven el camino elegido o la cadena vacía si el usuario la
 * canceló —o cierra la ventana con la X, que cuenta como cancelar.
 *
 * La máscara es una lista de patrones separados por punto y coma:
 * "*.dbf;*.txt". Sin máscara se ven todos los ficheros.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TFileDialog

   VAR cTitulo     INIT  ""
   VAR cDir        INIT  ""     // carpeta de partida

   METHOD New( cTitulo, cDir ) CONSTRUCTOR
   METHOD Open( cMascara )
   METHOD Save( cMascara, cNombre )
   METHOD Directory()

ENDCLASS

/* New( cTitulo [, cDir ] ) — cadena vacía si no hay gráficas */
METHOD New( cTitulo, cDir ) CLASS TFileDialog

   IF PCount() >= 1
      IF ValType( cTitulo ) != "C"
         HgtkErrArgs( "TFileDialog:New", "el título debe ser una cadena" )
      ELSE
         ::cTitulo := cTitulo
      ENDIF
   ENDIF
   IF PCount() >= 2
      IF ValType( cDir ) != "C"
         HgtkErrArgs( "TFileDialog:New", "la carpeta debe ser una cadena" )
      ELSE
         ::cDir := cDir
      ENDIF
   ENDIF

   IF ! HgtkApplication():GuiReady()
      HgtkErrGui( "TFileDialog:New", ;
                  "GTK no está inicializado: no hay diálogo" )
   ENDIF

RETURN SELF

/* Open( [ cMascara ] ) -> camino del fichero elegido, o "" */
METHOD Open( cMascara ) CLASS TFileDialog

   IF PCount() < 1 .OR. cMascara == NIL
      cMascara := ""
   ENDIF
   IF ValType( cMascara ) != "C"
      HgtkErrArgs( "TFileDialog:Open", "la máscara debe ser una cadena" )
      RETURN ""
   ENDIF

RETURN HGtkFileDlg( 1, ::cTitulo, ::cDir, cMascara, "" )

/* Save( [ cMascara [, cNombre ] ] ) -> camino elegido, o "" */
METHOD Save( cMascara, cNombre ) CLASS TFileDialog

   IF PCount() < 1 .OR. cMascara == NIL
      cMascara := ""
   ENDIF
   IF PCount() < 2 .OR. cNombre == NIL
      cNombre := ""
   ENDIF
   IF ValType( cMascara ) != "C" .OR. ValType( cNombre ) != "C"
      HgtkErrArgs( "TFileDialog:Save", ;
                   "la máscara y el nombre deben ser cadenas" )
      RETURN ""
   ENDIF

RETURN HGtkFileDlg( 2, ::cTitulo, ::cDir, cMascara, cNombre )

/* Directory() -> carpeta elegida, o "" */
METHOD Directory() CLASS TFileDialog

RETURN HGtkFileDlg( 3, ::cTitulo, ::cDir, "", "" )
