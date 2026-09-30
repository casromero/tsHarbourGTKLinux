/*
 * 04_mantenimiento — mantenimiento de una tabla con teclado (fase 3)
 *
 * Una tabla pequeña (14 registros) en un fichero DBF de Harbour, con
 * todo lo que añade la fase:
 *
 *   - el browse se llena con el propio TDataBase (cláusula DATA con
 *     un objeto en vez de un array) y escribe en el fichero;
 *   - orden por columna: las cabeceras son pulsables y Ordenar()
 *     también está a mano de cualquier código;
 *   - edición de celda con EDIT: Return abre la celda y Return la
 *     confirma; lo escrito acaba en el DBF;
 *   - alta con la orden Archivo/Añadir (o el botón de la barra);
 *   - barra de desplazamiento: las 14 filas no caben en la ventana y
 *     End lleva el cursor a la última, que la vista se desplaza sola;
 *   - imágenes: el logotipo es un TImage, los botones de la barra
 *     llevan su icono, y todo sale de GdkPixbuf (PNG);
 *   - el foco se lleva al browse antes de ACTIVATE: con teclado
 *     basta, no hace falta el ratón en ningún momento.
 *
 * Antes de ACTIVATE comprueba que la imagen mide lo que debe, que el
 * botón con icono conserva su texto, que ordenar por Código y por
 * Nombre hace lo que debe en los dos sentidos (y que los números de
 * registro se reordenan con sus filas), que escribir una celda llega
 * al fichero y que el browse queda en la fila 1. Después comprueba
 * que la ventana se ha cerrado y deja en pantalla la fila 1, las
 * altas y la fila final, que es lo que comprueba el smoke mandando
 * Return, un texto, Return, End y el menú Archivo (Alt+A) dos veces.
 *
 * La muestra crea su tabla de prueba al arrancar, así que cada
 * corrida empieza con los mismos 14 registros.
 *
 * Compilar:  make sample      (desde la raíz del proyecto)
 * Ejecutar:  samples/04_mantenimiento/04_mantenimiento
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

#define ESTRUCTURA { { "CODIGO",    "N",  4, 0 }, ;
                     { "NOMBRE",    "C", 24, 0 }, ;
                     { "PROVINCIA", "C", 18, 0 }, ;
                     { "TELEFONO",  "C", 16, 0 } }

STATIC nAltas     := 0      // altas hechas durante la sesión
STATIC nRefrescos := 0      // veces que se ha elegido Refrescar

FUNCTION Main()

   LOCAL oWnd, oMenu, oPopArc, oMnuAdd, oMnuRef, oMnuSal, oPopAyu
   LOCAL oMnuAcerca
   LOCAL oBar, oBtAdd, oBtSal, oTit, oLogo, oBrw, oSta
   LOCAL oTab := NIL
   LOCAL cTabla := Temporal( "harbgtklin_mantenimiento.dbf" )
   LOCAL cLogo  := Ruta( "logo.png" )
   LOCAL cAnadir := Ruta( "anadir.png" )
   LOCAL cSalir := Ruta( "salir.png" )
   LOCAL aCab := { "Código", "Nombre", "Provincia", "Teléfono" }
   LOCAL aCli := { {  1, "Ana Barros",     "Cádiz",      "956 11 22 33" }, ;
                   {  2, "Luis Cifuentes", "Madrid",     "915 44 55 66" }, ;
                   {  3, "Marta Duque",    "Sevilla",    "954 77 88 99" }, ;
                   {  4, "Rafael Esteve",  "Alicante",   "965 10 20 30" }, ;
                   {  5, "Nuria Fuentes",  "Burgos",     "947 40 50 60" }, ;
                   {  6, "Diego Gálvez",   "Málaga",     "952 70 80 90" }, ;
                   {  7, "Elena Ibáñez",   "Toledo",     "925 12 34 56" }, ;
                   {  8, "Pablo Jara",     "Granada",    "958 23 45 67" }, ;
                   {  9, "Sonia Lara",     "Zaragoza",   "976 34 56 78" }, ;
                   { 10, "Oscar Mena",     "Valladolid", "983 45 67 89" }, ;
                   { 11, "Teresa Nogal",   "Santander",  "942 56 78 90" }, ;
                   { 12, "Vera Otero",     "A Coruña",   "981 67 89 01" }, ;
                   { 13, "Ignacio Paz",    "Córdoba",    "957 78 90 12" }, ;
                   { 14, "Rosa Quintana",  "Ourense",    "988 89 01 23" } }
   LOCAL aFila := {}
   LOCAL nSel := 1
   LOCAL cFallo := ""
   LOCAL aTam, n

   ? "HarbGtkLin", Str( HGTK_FASE ), "- GTK", ;
     HgtkApplication():GtkVersion()

   /* ---------------------------------------------------------------
    * la tabla de prueba: creada desde cero en cada corrida
     * --------------------------------------------------------------- */

   IF ! CreaTabla( cTabla, aCli )
      ? "muestra04: FALLO - no se pudo crear la tabla de prueba"
      ErrorLevel( 1 )
      RETURN NIL
   ENDIF

   oTab := TDataBase():New( cTabla )

   IF ! oTab:Abierta()
      ? "muestra04: FALLO - no se pudo abrir la tabla de prueba"
      ErrorLevel( 1 )
      RETURN NIL
   ENDIF

   /* ---------------------------------------------------------------
    * la ventana
     * --------------------------------------------------------------- */

   DEFINE WINDOW oWnd TITLE "Mantenimiento de clientes" SIZE 22, 96

      /* menú: la barra se cuelga con ACTIVATE MENU, al final */
      DEFINE MENU oMenu OF oWnd

      DEFINE POPUP oPopArc OF oMenu PROMPT "&Archivo"
      DEFINE MENUITEM oMnuAdd OF oPopArc PROMPT "&Añadir" ;
         ACTION {|| Alta( oBrw, oTab ) }
      DEFINE MENUITEM oMnuRef OF oPopArc PROMPT "&Refrescar" ;
         ACTION {|| nRefrescos := nRefrescos + 1, oBrw:SetData( oTab ) }
      DEFINE MENUITEM oMnuSal OF oPopArc PROMPT "&Salir" ;
         ACTION {|| oWnd:End() }

      /* la "y" de Ayuda lleva el mnemónico: con dos popups de la
       * misma inicial (Archivo y Ayuda) la barra deja de responder
       * desde la segunda vez que se abre (avisado por el puente) */
      DEFINE POPUP oPopAyu OF oMenu PROMPT "A&yuda"
      DEFINE MENUITEM oMnuAcerca OF oPopAyu PROMPT "&Acerca de" ;
         ACTION {|| oSta:Value( "HarbGtkLin fase 3" ) }

      ACTIVATE MENU oMenu

      /* barra de botones con imagen; sin marca de mnemónico para que
       * Alt+A siga siendo la orden Archivo del menú */
      DEFINE BAR oBar OF oWnd

      DEFINE BUTTON oBtAdd OF oBar PROMPT "Añadir" IMAGE cAnadir ;
         ACTION {|| Alta( oBrw, oTab ) }
      DEFINE BUTTON oBtSal OF oBar PROMPT "Salir" IMAGE cSalir ;
         ACTION {|| oWnd:End() }

      /* logotipo y rótulo */
      DEFINE IMAGE oLogo OF oWnd FILE cLogo AT 1, 1
      DEFINE SAY oTit OF oWnd PROMPT "Clientes" AT 1, 8 SIZE 3, 40

      /* el browse: los datos salen del fichero y EDIT abre la celda */
      DEFINE BROWSE oBrw OF oWnd VAR nSel FIELDS aCab DATA oTab EDIT ;
         AT 5, 1 SIZE 12, 94 ;
         ACTION {|| Estado( oSta, oWnd, nSel, oTab:Cantidad() ) }

      /* barra de estado */
      DEFINE STATUS oSta OF oWnd

   /* ---------------------------------------------------------------
     * comprobaciones antes de ACTIVATE: los widgets ya existen y las
     * señales se disparan aunque no se haya pintado nada todavía
     * --------------------------------------------------------------- */

   /* la imagen del logotipo está viva y mide lo que debe */
   IF cFallo == ""
      aTam := oLogo:Size()
      IF ! oLogo:IsAlive()
         cFallo := "el logotipo no está en la ventana"
      ELSEIF ! HB_IsArray( aTam ) .OR. aTam[ 1 ] != 48 .OR. aTam[ 2 ] != 48
         cFallo := "TImage:Size() debía devolver 48 x 48"
      ENDIF
   ENDIF

   /* el botón con icono conserva su texto (GTK guarda la etiqueta
    * aparte de la imagen) */
   IF cFallo == ""
      IF ! oBtAdd:IsAlive() .OR. Distinto( oBtAdd:Value(), "Añadir" )
         cFallo := "el botón con imagen no conserva su texto"
      ENDIF
   ENDIF

   /* el browse está vivo, editable y en la fila 1 */
   IF cFallo == ""
      aFila := oBrw:Row()
      IF ! oBrw:IsAlive() .OR. ! oBrw:lEditar
         cFallo := "el browse no está vivo y editable (cláusula EDIT)"
      ELSEIF oBrw:Value() != 1 .OR. ! HB_IsArray( aFila ) .OR. ;
             Distinto( aFila[ 2 ], "Ana Barros" )
         cFallo := "el browse debe empezar en la fila 1"
      ENDIF
   ENDIF

   /* orden por Código: de menor a mayor y al revés */
   IF cFallo == ""
      oBrw:Ordenar( 1 )
      IF oBrw:aDatos[ 1, 1 ] != 1 .OR. ;
         oBrw:aDatos[ Len( oBrw:aDatos ), 1 ] != Len( aCli )
         cFallo := "orden por Código no va de menor a mayor"
      ENDIF
   ENDIF

   IF cFallo == ""
      oBrw:Ordenar( 1, .T. )
      IF oBrw:aDatos[ 1, 1 ] != Len( aCli )
         cFallo := "orden descendente por Código no empieza en el mayor"
      ENDIF
   ENDIF

   /* orden por Nombre: alfabético exacto en los dos sentidos, y el
    * número de registro se reordena con su fila */
   IF cFallo == ""
      oBrw:Ordenar( 2 )
      n := Len( oBrw:aDatos )
      IF Distinto( oBrw:aDatos[ 1, 2 ], "Ana Barros" ) .OR. ;
         Distinto( oBrw:aDatos[ n, 2 ], "Vera Otero" )
         cFallo := "orden por Nombre no va de la A a la Z"
      ELSEIF oBrw:aReg[ 1 ] != 1 .OR. oBrw:aReg[ n ] != 12
         cFallo := "los nº de registro no se reordenaron con sus filas"
      ENDIF
   ENDIF

   IF cFallo == ""
      oBrw:Ordenar( 2, .T. )
      IF Distinto( oBrw:aDatos[ 1, 2 ], "Vera Otero" ) .OR. ;
         Distinto( oBrw:aDatos[ Len( oBrw:aDatos ), 2 ], "Ana Barros" )
         cFallo := "orden descendente por Nombre no va de la Z a la A"
      ENDIF
   ENDIF

   /* de vuelta al orden por Código, con la fila 1 elegida: es como
    * debe abrirse */
   IF cFallo == ""
      oBrw:Ordenar( 1 )
      IF oBrw:Value() != 1 .OR. oBrw:aDatos[ 1, 1 ] != 1
         cFallo := "al volver al orden por Código la fila 1 debe seguir ahí"
      ENDIF
   ENDIF

   /* escribir una celda: en la vista, en el array y en el fichero */
   IF cFallo == ""
      IF Distinto( oBrw:Poner( 3, 3, "Huelva" ), "Huelva" ) .OR. ;
         Distinto( oBrw:aDatos[ 3, 3 ], "Huelva" ) .OR. ;
         Distinto( oTab:Cargar()[ 3, 3 ], "Huelva" )
         cFallo := "Poner() debía cambiar la celda en la vista y en el fichero"
      ENDIF
   ENDIF

   IF cFallo == ""
      oBrw:Poner( 3, 3, "Sevilla" )
      IF Distinto( oTab:Cargar()[ 3, 3 ], "Sevilla" )
         cFallo := "no se pudo deshacer el cambio de celda"
      ENDIF
   ENDIF

   /* se deja todo en el primero y el foco en el browse: el teclado
    * no necesita el ratón para nada */
   oBrw:Value( 1 )
   oBrw:SetFocus()

   /* ---------------------------------------------------------------
     * la ventana, abierta mientras espera el usuario
     * --------------------------------------------------------------- */

   IF cFallo == ""
      ACTIVATE WINDOW oWnd

      IF oWnd:IsAlive()
         cFallo := "la ventana debía cerrarse y sigue viva"
      ENDIF
   ENDIF

   /* ---------------------------------------------------------------
     * informe: lo que se ha tocado durante la sesión
     * --------------------------------------------------------------- */

   IF oTab:Abierta()
      aFila := oTab:Cargar()[ 1 ]
   ENDIF
   IF ! HB_IsArray( aFila ) .OR. Len( aFila ) < 2
      aFila := { 0, "?" }
   ENDIF

   ? ""
   ? "Fila 1: " + LTrim( Str( aFila[ 1 ] ) ) + " " + aFila[ 2 ]
   ? "Altas: " + LTrim( Str( nAltas ) ) + ;
     "  Registros: " + LTrim( Str( oTab:Cantidad() ) ) + ;
     "  Fila final: " + LTrim( Str( nSel ) ) + ;
     "  Refrescos: " + LTrim( Str( nRefrescos ) )

   oTab:Close()
   Limpia( cTabla )

   IF cFallo == ""
      ? "muestra04: OK"
   ELSE
      ? "muestra04: FALLO -", cFallo
      ErrorLevel( 1 )
   ENDIF
   ? ""

RETURN NIL

/* ------------------------------------------------------------------ */
/* la tabla de prueba                                                  */
/* ------------------------------------------------------------------ */

/*
 * CreaTabla( cTabla, aCli ) — deja la tabla creada y con sus registros.
 * Se borra lo que hubiera de corridas anteriores: la muestra empieza
 * siempre con los mismos datos, que es lo que luego se comprueba.
 */
STATIC FUNCTION CreaTabla( cTabla, aCli )

   LOCAL oTab, n, lBien := .T.

   Limpia( cTabla )

   IF ! dbCreate( cTabla, ESTRUCTURA )
      RETURN .F.
   ENDIF

   oTab := TDataBase():New( cTabla )
   IF ! oTab:Abierta()
      RETURN .F.
   ENDIF

   FOR n := 1 TO Len( aCli )
      IF oTab:Anadir( aCli[ n ] ) < 1
         lBien := .F.
         EXIT
      ENDIF
   NEXT

   oTab:Close()

RETURN lBien

/* ------------------------------------------------------------------ */
/* acciones de menú y barra                                            */
/* ------------------------------------------------------------------ */

/* Alta: un registro nuevo en el fichero, con el número que toque. La
 * fila nueva queda elegida en el browse. */
STATIC FUNCTION Alta( oBrw, oTab )

   nAltas++

   oBrw:Anadir( { oTab:Cantidad() + 1, "Nuevo registro", "Sin asignar", ;
                  "" } )

RETURN NIL

/*
 * Estado: la fila elegida, en la barra de estado y en el título. Que
 * el título cambie con la fila es lo que deja ver desde fuera (el
 * smoke) que el cursor ha llegado a otra fila con el teclado.
 */
STATIC FUNCTION Estado( oSta, oWnd, nSel, nTotal )

   LOCAL cTexto := "Registro " + LTrim( Str( Max( nSel, 0 ) ) ) + ;
                   " de " + LTrim( Str( nTotal ) )

   IF oSta != NIL .AND. ValType( oSta ) == "O"
      oSta:Value( cTexto )
   ENDIF
   IF oWnd != NIL .AND. ValType( oWnd ) == "O"
      oWnd:Title( "Mantenimiento de clientes — " + cTexto )
   ENDIF

RETURN NIL

/* ------------------------------------------------------------------ */
/* utilidades                                                          */
/* ------------------------------------------------------------------ */

/*
 * Distinto( x, y ) — desigualdad EXACTA. El "!=" de Harbour es flojo
 * (SET EXACT OFF): "abc" != "ab" es .F. y cualquier cosa != "" es .F.
 * La igualdad exacta es "=="; esto sólo es su negación.
 */
STATIC FUNCTION Distinto( x, y )

RETURN ! ( x == y )

/* Ruta de un PNG de esta muestra: primero junto al ejecutable (que es
 * donde están) y si no, desde la raíz del proyecto. */
STATIC FUNCTION Ruta( cNombre )

   LOCAL cJunto := hb_FNameDir( hb_ProgName() ) + cNombre
   LOCAL cRaiz  := "samples/04_mantenimiento/" + cNombre

   IF File( cJunto )
      RETURN cJunto
   ENDIF

RETURN cRaiz

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

/* borra la tabla si estaba de otra corrida */
STATIC FUNCTION Limpia( cFichero )

   IF File( cFichero )
      FErase( cFichero )
   ENDIF

RETURN .T.
