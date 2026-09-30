/*
 * imagen_test.prg — prueba de consola de la fase 3 (imágenes)
 *
 * Comprueba la parte de imagen que NO necesita pantalla: los pixbuf
 * los lee GdkPixbuf, que no exige gtk_init() ni servidor gráfico
 * alguno, así que se puede medir una imagen y montar un TImage en una
 * prueba de consola.
 *
 *   - HGtkImageTam() devuelve el tamaño en píxeles de los PNG de la
 *     muestra (logo 48x48; anadir y salir 24x24);
 *   - un fichero inexistente (o un argumento que no es texto) da {0,0}
 *     y no levanta error;
 *   - un TImage sin padre (cláusula OF) avisa con un error de Harbour
 *     recuperable, no con un abort del proceso;
 *   - con un padre sin pantalla el control se crea igual y Size() lee
 *     la imagen: es la misma llamada que hace con gráficos;
 *   - Value() con una ruta inexistente también es error recuperable y
 *     no cambia la imagen.
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

FUNCTION Main()

   LOCAL cFallo  := ""
   LOCAL cLogo   := Fichero( "samples/04_mantenimiento/logo.png" )
   LOCAL cAnadir := Fichero( "samples/04_mantenimiento/anadir.png" )
   LOCAL cSalir  := Fichero( "samples/04_mantenimiento/salir.png" )
   LOCAL cNoHay  := Fichero( "samples/04_mantenimiento/no_existe.png" )
   LOCAL aTam, oImg := NIL
   LOCAL lRecup := .F.
   LOCAL bAntes := NIL

   /* --- medidas sin pantalla ------------------------------------- */
   IF cFallo == ""
      aTam := HGtkImageTam( cLogo )
      IF ! Dim( aTam, 48, 48 )
         cFallo := "logo.png debía medir 48 x 48"
      ENDIF
   ENDIF

   IF cFallo == ""
      aTam := HGtkImageTam( cAnadir )
      IF ! Dim( aTam, 24, 24 )
         cFallo := "anadir.png debía medir 24 x 24"
      ENDIF
   ENDIF

   IF cFallo == ""
      aTam := HGtkImageTam( cSalir )
      IF ! Dim( aTam, 24, 24 )
         cFallo := "salir.png debía medir 24 x 24"
      ENDIF
   ENDIF

   /* un fichero que no está no es error: es un tamaño nulo */
   IF cFallo == ""
      aTam := HGtkImageTam( cNoHay )
      IF ! Dim( aTam, 0, 0 )
         cFallo := "un fichero inexistente debe dar {0,0} sin error"
      ENDIF
   ENDIF

   IF cFallo == ""
      aTam := HGtkImageTam( NIL )
      IF ! Dim( aTam, 0, 0 )
         cFallo := "un argumento que no es texto debe dar {0,0}"
      ENDIF
   ENDIF

   /* --- sin padre: error recuperable ----------------------------- */
   IF cFallo == ""
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oImg := TImage():New( NIL, cLogo )
      RECOVER
         lRecup := .T.
      END SEQUENCE
      ErrorBlock( bAntes )

      IF ! lRecup
         cFallo := "crear un TImage sin padre debe dar error recuperable"
      ENDIF
   ENDIF

   /* --- con un padre sin pantalla -------------------------------- */
   /* El padre sólo hace falta para colgar el control: uno de mentira
    * basta para crearlo y comprobar que la imagen se lee igual que
    * con gráficos. */
   IF cFallo == ""
      oImg := TImage():New( PadreFalso():New(), cLogo )

      IF oImg == NIL .OR. ! ( oImg:cFile == cLogo )
         cFallo := "el TImage creado debe conservar su ruta"
      ENDIF
   ENDIF

   IF cFallo == ""
      aTam := oImg:Size()
      IF ! Dim( aTam, 48, 48 )
         cFallo := "TImage:Size() debe medir 48 x 48 sin pantalla"
      ENDIF
   ENDIF

   /* --- el uso incorrecto se recupera, no mata el programa -------- */
   IF cFallo == ""
      lRecup := .F.
      bAntes := ErrorBlock( { | oError| Break( oError ) } )
      BEGIN SEQUENCE
         oImg:Value( cNoHay )
      RECOVER
         lRecup := .T.
      END SEQUENCE
      ErrorBlock( bAntes )

      IF ! lRecup
         cFallo := "Value() con ruta inexistente debe dar error recuperable"
      ELSEIF Distinto( oImg:Value(), cLogo )
         cFallo := "un Value() fallido no debe cambiar la imagen"
      ENDIF
   ENDIF

   Fina( cFallo )

RETURN NIL

/* a es { ancho, alto } igual a lo esperado */
STATIC FUNCTION Dim( a, nAncho, nAlto )

RETURN HB_IsArray( a ) .AND. Len( a ) == 2 .AND. ;
       ValType( a[ 1 ] ) == "N" .AND. a[ 1 ] == nAncho .AND. ;
       ValType( a[ 2 ] ) == "N" .AND. a[ 2 ] == nAlto

/*
 * Distinto( x, y ) — desigualdad EXACTA. El "!=" de Harbour es flojo
 * (SET EXACT OFF): "abc" != "ab" es .F. y cualquier cosa != "" es .F.
 * La igualdad exacta es "=="; esto sólo es su negación.
 */
STATIC FUNCTION Distinto( x, y )

RETURN ! ( x == y )

/*
 * Ruta de un fichero de las muestras: primero desde el directorio de
 * trabajo (la raíz del proyecto, que es como lo lanzan make test y
 * make smoke) y si no, derivada de la ruta de este ejecutable, que
 * está en tests/.
 */
STATIC FUNCTION Fichero( cRelativo )

   LOCAL cProg, cDir, cRaiz

   IF File( cRelativo )
      RETURN cRelativo
   ENDIF

   cProg := hb_ProgName()
   cDir  := hb_FNameDir( cProg )
   IF ! Empty( cDir )
      cDir  := SubStr( cDir, 1, Len( cDir ) - 1 )   // sin la barra final
      cRaiz := hb_FNameDir( cDir )
      IF File( cRaiz + cRelativo )
         RETURN cRaiz + cRelativo
      ENDIF
   ENDIF

RETURN cRelativo

/* informa y fija el código de salida */
STATIC FUNCTION Fina( cFallo )

   IF cFallo == ""
      ? "imagen_test: OK"
   ELSE
      ? "imagen_test: FALLO -", cFallo
      ErrorLevel( 1 )
   ENDIF

   ? ""

RETURN NIL

/* ------------------------------------------------------------------ */
/* padre de mentira: sólo hace falta para que Init() no se queje       */
/* ------------------------------------------------------------------ */

CREATE CLASS PadreFalso

   VAR hWnd       INIT  NIL

   METHOD New() CONSTRUCTOR
   METHOD AddControl( oCtrl )

ENDCLASS

METHOD New() CLASS PadreFalso

RETURN SELF

METHOD AddControl( oCtrl ) CLASS PadreFalso

   /* sin ventana no hay dónde colgar nada: no hay nada que hacer.
    * oCtrl no se usa (un parámetro sin usar no es error aquí). */
   RETURN NIL
