/*
 * tabla_test.prg — prueba de consola de la fase 3
 *
 * Comprueba TDataBase, la envoltura fina sobre un DBF de Harbour, sin
 * pantalla ni GTK:
 *
 *   - abrir, añadir, leer, escribir y cerrar;
 *   - que la edición devuelve lo que quedó realmente en el fichero
 *     (un texto sin sentido en un campo numérico se guarda como 0);
 *   - que el área de trabajo de la aplicación no se toca: después de
 *     cada operación sigue seleccionada la suya;
 *   - que un uso incorrecto (fichero inexistente) es un error de
 *     Harbour recuperable y no un abort del proceso.
 *
 * Todas las comparaciones de cadenas son exactas (Distinto() usa "=="):
 * con SET EXACT OFF, que es la omisión, "x != texto" compara sólo los
 * primeros caracteres y contra "" da siempre .F. (ver api-fase0.md §12).
 *
 * Sale con ErrorLevel( 1 ) si algo falla.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

#define ESTRUCTURA { { "CODIGO", "N", 4, 0 }, ;
                     { "NOMBRE", "C", 20, 0 }, ;
                     { "PROVINCIA", "C", 18, 0 } }

FUNCTION Main()

   LOCAL cFallo  := ""
   LOCAL cDir    := Temporal( "" )
   LOCAL cApp    := cDir + "harbgtklin_app.dbf"
   LOCAL cTabla  := cDir + "harbgtklin_tabla.dbf"
   LOCAL oTab    := NIL
   LOCAL aDat, aRegs, xGuard, lRecup := .F.
   LOCAL bAntes  := NIL

   /* los dos ficheros de esta prueba, hechos de cero */
   Limpia( cApp )
   Limpia( cTabla )

   IF ! dbCreate( cApp, ESTRUCTURA ) .OR. ! dbCreate( cTabla, ESTRUCTURA )
      Fina( "no se pudieron crear los DBF de prueba" )
      RETURN NIL
   ENDIF

   /* la aplicación tiene su propia tabla abierta y seleccionada */
   IF ! dbUseArea( .T., NIL, cApp, "APP", .F., .F. )
      Fina( "no se pudo abrir el DBF de la aplicación" )
      RETURN NIL
   ENDIF

   /* --- abrir ---------------------------------------------------- */
   oTab := TDataBase():New( cTabla )

   IF ! oTab:Abierta()
      cFallo := "TDataBase():New() debía dejar el fichero abierto"
   ELSEIF Distinto( Alias(), "APP" )
      cFallo := "abrir la tabla cambió el área de la aplicación"
   ELSEIF Distinto( oTab:Fichero(), cTabla )
      cFallo := "Fichero() debe devolver la ruta abierta"
   ENDIF

   /* --- altas ---------------------------------------------------- */
   IF cFallo == ""
      IF oTab:Cantidad() != 0
         cFallo := "una tabla recién creada no tiene registros"
      ENDIF
   ENDIF

   IF cFallo == ""
      IF oTab:Anadir( { 1, "Ana Barros", "Cádiz" } ) != 1 .OR. ;
         oTab:Anadir( { 2, "Luis Cifuentes", "Madrid" } ) != 2 .OR. ;
         oTab:Anadir( { 3, "Marta Duque", "Sevilla" } ) != 3
         cFallo := "Anadir() debía devolver el número del registro nuevo"
      ENDIF
   ENDIF

   IF cFallo == ""
      IF oTab:Cantidad() != 3
         cFallo := "tras tres altas debe haber tres registros"
      ELSEIF Distinto( Alias(), "APP" )
         cFallo := "las altas cambiaron el área de la aplicación"
      ENDIF
   ENDIF

   /* --- lecturas ------------------------------------------------- */
   IF cFallo == ""
      aRegs := oTab:Registros()
      IF Len( aRegs ) != 3 .OR. aRegs[ 1 ] != 1 .OR. aRegs[ 3 ] != 3
         cFallo := "Registros() debe devolver el nº de cada fila en orden"
      ENDIF
   ENDIF

   IF cFallo == ""
      IF ! HB_IsArray( oTab:Campos() ) .OR. ;
         Len( oTab:Campos() ) != 3 .OR. ;
         Distinto( oTab:Campos()[ 2 ], "NOMBRE" )
         cFallo := "Campos() debe devolver los nombres del fichero"
      ENDIF
   ENDIF

   IF cFallo == ""
      aDat := oTab:Cargar()
      IF Len( aDat ) != 3
         cFallo := "Cargar() debe devolver un array por registro"
      ELSEIF aDat[ 2, 1 ] != 2 .OR. ;
         Distinto( aDat[ 2, 2 ], "Luis Cifuentes" ) .OR. ;
         Distinto( aDat[ 2, 3 ], "Madrid" )
         cFallo := "Cargar() no devolvió los valores del registro 2"
      ELSEIF Distinto( Alias(), "APP" )
         cFallo := "Cargar() cambió el área de la aplicación"
      ENDIF
   ENDIF

   /* --- escrituras ----------------------------------------------- */
   IF cFallo == ""
      xGuard := oTab:Guardar( 3, 3, "Sevilla la Vieja" )
      IF Distinto( xGuard, "Sevilla la Vieja" ) .OR. ;
         Distinto( oTab:Cargar()[ 3, 3 ], "Sevilla la Vieja" )
         cFallo := "Guardar() debía escribir el campo y devolverlo"
      ENDIF
   ENDIF

   /* texto en un campo numérico: "77" se guarda como 77 y un texto
    * sin número, como 0; en los dos casos se devuelve lo guardado */
   IF cFallo == ""
      xGuard := oTab:Guardar( 1, 1, "77" )
      IF ValType( xGuard ) != "N" .OR. xGuard != 77
         cFallo := "Guardar() debía convertir el texto al tipo del campo"
      ENDIF
   ENDIF

   IF cFallo == ""
      xGuard := oTab:Guardar( 1, 1, "no es un número" )
      IF ValType( xGuard ) != "N" .OR. xGuard != 0
         cFallo := "Guardar() debe devolver lo que quedó en el fichero"
      ELSEIF oTab:Cargar()[ 1, 1 ] != 0
         cFallo := "el campo numérico quedó distinto en el fichero"
      ENDIF
   ENDIF

   /* --- el uso incorrecto se recupera, no mata el programa -------- */
   IF cFallo == ""
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oTab:Use( cDir + "no_existe_harbgtklin.dbf" )
      RECOVER
         lRecup := .T.
      END SEQUENCE
      ErrorBlock( bAntes )

      IF ! lRecup
         cFallo := "abrir un fichero inexistente debe dar error recuperable"
      ELSEIF ! oTab:Abierta()
         cFallo := "un Use() fallido no debe cerrar la tabla abierta"
      ENDIF
   ENDIF

   /* --- cierre --------------------------------------------------- */
   IF cFallo == ""
      oTab:Close()
      IF oTab:Abierta()
         cFallo := "Close() debía dejar la envoltura cerrada"
      ELSEIF Distinto( Alias(), "APP" )
         cFallo := "cerrar la tabla cambió el área de la aplicación"
      ENDIF
   ENDIF

   /* limpieza, haya habido fallo o no */
   IF oTab != NIL
      oTab:Close()
   ENDIF
   IF Select( "APP" ) != 0
      dbSelectArea( "APP" )
      dbCloseArea()
   ENDIF
   Limpia( cApp )
   Limpia( cTabla )

   Fina( cFallo )

RETURN NIL

/*
 * Distinto( x, y ) — desigualdad EXACTA. El "!=" de Harbour es flojo
 * (SET EXACT OFF): "abc" != "ab" es .F. y cualquier cosa != "" es .F.
 * La igualdad exacta es "=="; esto sólo es su negación.
 */
STATIC FUNCTION Distinto( x, y )

RETURN ! ( x == y )

/* ruta en el directorio temporal del sistema */
STATIC FUNCTION Temporal( cNombre )

   LOCAL cDir := hb_DirTemp()

   IF Empty( cDir )
      cDir := "."
   ENDIF
   IF Right( cDir, 1 ) != "/"
      cDir += "/"
   ENDIF

RETURN cDir + cNombre

/* borra el fichero si estaba de otra corrida */
STATIC FUNCTION Limpia( cFichero )

   IF File( cFichero )
      FErase( cFichero )
   ENDIF

RETURN .T.

/* informa y fija el código de salida */
STATIC FUNCTION Fina( cFallo )

   IF cFallo == ""
      ? "tabla_test: OK"
   ELSE
      ? "tabla_test: FALLO -", cFallo
      ErrorLevel( 1 )
   ENDIF

RETURN NIL
