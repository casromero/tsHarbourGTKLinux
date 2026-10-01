/*
 * impresion_test — comprobaciones de consola de la fase 4
 *
 * Aquí sólo se toca lo que funciona sin ventana: la impresión, las
 * fuentes, el CSS y el selector se prueban de verdad en la secuencia
 * gráfica del smoke, porque abrir un diálogo en consola bloquearía el
 * proceso. Lo que sí se comprueba en frío, sin gráficas:
 *
 *   - TPrint arma el listado y lo cuenta, y ToFile sin destino se
 *     rechaza en Harbour, antes de tocar GTK;
 *   - TFont guarda lo bueno y rechaza lo que no sirve;
 *   - TFileDialog y TTree piden padre y cadena, y sin gráficas no
 *     hay diálogo (el arranque de GTK se lanza como error recuperable);
 *   - HgtkCss sólo acepta cadenas.
 *
 * El error se instala a mano como Break(), que es como se recupera en
 * Harbour: el fallo salta al RECOVER y el programa sigue.
 *
 * Compilar:  make test       (desde la raíz del proyecto)
 * Ejecutar:  tests/impresion_test
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

FUNCTION Main()

   LOCAL cFallo := ""
   LOCAL oPrn, oFont, oDlg, oTree, oError
   LOCAL bAntes, lRecup, lGraficas

   ? "HarbGtkLin " + LTrim( Str( HGTK_FASE ) ) + ;
     " - prueba de consola de impresión y fuentes"

   /* --------------------------------------------------------------
    * TPrint: el listado se arma y se cuenta sin GTK
    * -------------------------------------------------------------- */

   IF cFallo == ""
      oPrn := TPrint():New( "Listado de prueba" )

      IF ValType( oPrn ) != "O" .OR. ;
         Distinto( oPrn:cTitulo, "Listado de prueba" )
         cFallo := "TPrint():New no guarda el título"
      ENDIF
   ENDIF

   IF cFallo == ""
      oPrn:AddLine( "uno" )
      oPrn:AddLine( "dos" )
      oPrn:AddLine( "tres" )

      IF oPrn:LineCount() != 3
         cFallo := "LineCount debía ser 3 y es " + ;
                   LTrim( Str( oPrn:LineCount() ) )
      ENDIF
   ENDIF

   /* AddLine sin texto suma una línea vacía y devuelve su posición */
   IF cFallo == ""
      IF oPrn:AddLine() != 4 .OR. oPrn:LineCount() != 4
         cFallo := "AddLine sin texto debía dejar 4 líneas"
      ENDIF
   ENDIF

   /* la fuente por omisión del listado es Monospace 10 */
   IF cFallo == ""
      IF Distinto( oPrn:cFuente, "Monospace 10" )
         cFallo := "la fuente por omisión debe ser Monospace 10"
      ENDIF
   ENDIF

   /* Clear deja el listado vacío */
   IF cFallo == ""
      oPrn:Clear()
      IF oPrn:LineCount() != 0
         cFallo := "Clear no dejó el listado vacío"
      ENDIF
   ENDIF

   /* --------------------------------------------------------------
    * ToFile sin destino: el error es de Harbour y no toca GTK
    * -------------------------------------------------------------- */

   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oPrn:ToFile( "" )
      RECOVER USING oError
         lRecup := .T.
         IF !( AT( "TPrint:ToFile", Detalles( oError ) ) > 0 .OR. ;
               AT( "falta el fichero", Detalles( oError ) ) > 0 )
            cFallo := "el error no dice quién lo dio: " + ;
                      Detalles( oError )
         ENDIF
      END SEQUENCE
      ErrorBlock( bAntes )

      IF cFallo == "" .AND. ! lRecup
         cFallo := "ToFile sin destino debe dar error recuperable"
      ENDIF
   ENDIF

   /* ToFile con número también es error de uso */
   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oPrn:ToFile( 7 )
      RECOVER
         lRecup := .T.
      END SEQUENCE
      ErrorBlock( bAntes )

      IF ! lRecup
         cFallo := "ToFile con número debe dar error recuperable"
      ENDIF
   ENDIF

   /* --------------------------------------------------------------
    * TFont: lo que sirve se guarda y lo que no se rechaza
    * -------------------------------------------------------------- */

   IF cFallo == ""
      oFont := TFont():New( "DejaVu Sans Mono", 12, .T., .T. )

      IF Distinto( oFont:cFace, "DejaVu Sans Mono" ) .OR. ;
         oFont:nSize != 12 .OR. ;
         ! oFont:lBold .OR. ! oFont:lItalic
         cFallo := "TFont():New no guarda lo que se le dio"
      ENDIF
   ENDIF

   IF cFallo == ""
      IF Distinto( oFont:Descripcion(), ;
                   "DejaVu Sans Mono 12 +negrita +cursiva" )
         cFallo := "Descripcion(): " + oFont:Descripcion()
      ENDIF
   ENDIF

   /* familia vacía: error de uso */
   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oFont := TFont():New( "", 9 )
      RECOVER
         lRecup := .T.
      END SEQUENCE
      ErrorBlock( bAntes )

      IF ! lRecup
         cFallo := "una familia vacía debe dar error recuperable"
      ENDIF
   ENDIF

   /* tamaño negativo: error de uso */
   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oFont := TFont():New( "Sans", -3 )
      RECOVER
         lRecup := .T.
      END SEQUENCE
      ErrorBlock( bAntes )

      IF ! lRecup
         cFallo := "un tamaño negativo debe dar error recuperable"
      ENDIF
   ENDIF

   /* --------------------------------------------------------------
    * TFileDialog: con gráficas se crea sin más (el diálogo sólo se
    * abre con Open/Save/Directory), y sin ellas lo que se da es un
    * error recuperable. Primero se sonríe el arranque de GTK: si no
    * hay display, se lanza y aquí se recoge.
    * -------------------------------------------------------------- */

   IF cFallo == ""
      lGraficas := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         lGraficas := HgtkApplication():GuiReady()
      RECOVER
         lGraficas := .F.
      END SEQUENCE
      ErrorBlock( bAntes )

      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oDlg := TFileDialog():New( "Prueba", hb_DirTemp() )
      RECOVER
         lRecup := .T.
      END SEQUENCE
      ErrorBlock( bAntes )

      IF lGraficas
         IF lRecup .OR. ValType( oDlg ) != "O" .OR. ;
            Distinto( oDlg:cTitulo, "Prueba" )
            cFallo := "con gráficas, TFileDialog:New debía crearse"
         ENDIF
      ELSEIF ! lRecup
         cFallo := "TFileDialog:New sin gráficas debe dar error"
      ENDIF
   ENDIF

   /* el título debe ser cadena */
   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oDlg := TFileDialog():New( 5 )
      RECOVER
         lRecup := .T.
      END SEQUENCE
      ErrorBlock( bAntes )

      IF ! lRecup
         cFallo := "TFileDialog:New con número debe dar error de uso"
      ENDIF
   ENDIF

   /* --------------------------------------------------------------
    * TTree sin padre: no se crea nada y se dice a mano
    * -------------------------------------------------------------- */

   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oTree := TTree():New( NIL, NIL, { "raíz" } )
      RECOVER
         lRecup := .T.
      END SEQUENCE
      ErrorBlock( bAntes )

      IF ! lRecup
         cFallo := "TTree():New sin padre debe dar error de uso"
      ENDIF
   ENDIF

   /* --------------------------------------------------------------
    * HgtkCss: sólo cadenas (el contenido lo juzga GTK, con gráficas)
    * -------------------------------------------------------------- */

   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         HgtkCss( 123 )
      RECOVER
         lRecup := .T.
      END SEQUENCE
      ErrorBlock( bAntes )

      IF ! lRecup
         cFallo := "HgtkCss con número debe dar error de uso"
      ENDIF
   ENDIF

   /* --------------------------------------------------------------
    * informe
    * -------------------------------------------------------------- */

   ? ""

   IF cFallo == ""
      ? "impresion_test: OK"
   ELSE
      ? "impresion_test: FALLO -", cFallo
      ErrorLevel( 1 )
   ENDIF
   ? ""

RETURN NIL

/* ------------------------------------------------------------------ */
/* utilidades                                                          */
/* ------------------------------------------------------------------ */

/* Detalles( oError ) — todo lo que el error traiga consigo, en una
 * sola cadena: mensaje, operación y subsistema (los que existan) */
STATIC FUNCTION Detalles( oError )

   LOCAL cRes := ""

   IF ValType( oError ) != "O"
      RETURN cRes
   ENDIF

   IF __objHasMsg( oError, "DESCRIPTION" )
      cRes += oError:description + " "
   ENDIF
   IF __objHasMsg( oError, "OPERATION" )
      cRes += oError:operation + " "
   ENDIF
   IF __objHasMsg( oError, "SUBSYSTEM" )
      cRes += oError:subsystem + " "
   ENDIF

RETURN cRes

/*
 * Distinto( x, y ) — desigualdad EXACTA. El "!=" de Harbour es flojo
 * (SET EXACT OFF): "abc" != "ab" es .F. y cualquier cosa != "" es .F.
 * La igualdad exacta es "=="; esto sólo es su negación.
 */
STATIC FUNCTION Distinto( x, y )

RETURN ! ( x == y )
