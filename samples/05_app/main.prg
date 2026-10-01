/*
 * 05_app — aplicación de ejemplo (fase 4)
 *
 * Todo lo que añade la fase 4 en una sola pantalla, con datos reales
 * de un fichero DBF creado al arrancar:
 *
 *   - menú Archivo (abrir, exportar a PDF, elegir carpeta, segunda
 *     ventana, salir) y Ayuda, con mnemónicos únicos;
 *   - árbol de zonas con los clientes dentro: los datos salen del
 *     DBF, la variable de VAR guarda la ruta de etiquetas ("Norte/
 *     0001 Aceros del Norte") y el título de la ventana la refleja,
 *     que es lo que deja ver desde fuera que el teclado ha llegado;
 *   - panel con pestañas: los clientes en un browse de solo lectura
 *     y un resumen; cambiar de pestaña actualiza su variable;
 *   - caja de botones abajo (modo de cajas HORIZONTAL): los botones
 *     van en orden de declaración, sin filas ni columnas;
 *   - fuente con TFont y CSS: la ventana pone la suya y el árbol la
 *     hereda (comprobado antes de ACTIVATE);
 *   - listado con TPrint: se exporta a PDF antes de ACTIVATE y el
 *     fichero tiene que salir con cabecera %PDF;
 *   - selector de fichero con los diálogos de GTK (abrir, guardar
 *     y carpeta);
 *   - una segunda ventana abierta desde un menú de la primera: las
 *     dos siguen vivas a la vez (ACTIVATE de cada una espera a la
 *     suya, no a la última del proceso).
 *
 * Un temporizador de 100 ms anota el nodo con el que se abre la
 * ventana: es el que comprueba el informe al terminar, porque de
 * fuera sólo se puede ver el título después de navegar.
 *
 * Compilar:  make sample      (desde la raíz del proyecto)
 * Ejecutar:  samples/05_app/05_app
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

#define ESTRUCTURA { { "CODIGO", "C",  4, 0 }, ;
                     { "NOMBRE", "C", 24, 0 }, ;
                     { "ZONA",   "C", 10, 0 } }

#define TITULO_BASE "Aplicación de ejemplo"

STATIC nNodos   := 0      // nodos elegidos en el árbol (ACTION)
STATIC nPest    := 0      // cambios de pestaña (ACTION)
STATIC cMapRuta := ""     // nodo con el que se abrió la ventana
STATIC cUltRuta := ""     // último nodo elegido

FUNCTION Main()

   LOCAL oWnd, oMenu, oPopArc, oPopAyu
   LOCAL oMnuAbr, oMnuExp, oMnuVen, oMnuSal, oMnuAcerca
   LOCAL oTick
   LOCAL oTree, oTabs, oPagCli, oPagRes, oBrw, oSta
   LOCAL oCaja, oBtExp, oBtAbr, oBtImp, oBtVen
   LOCAL oSayTit, oSayTot, oSayNod
   LOCAL cTabla := Temporal( "harbgtklin_app.dbf" )
   LOCAL cPdf   := Temporal( "harbgtklin_listado.pdf" )
   LOCAL aCab := { "Código", "Nombre", "Zona" }
   LOCAL aCli := { { "0001", "Aceros del Norte",   "Norte" }, ;
                   { "0002", "Bodega Ribera",      "Norte" }, ;
                   { "0003", "Castillo Logística", "Norte" }, ;
                   { "0004", "Delta Ingeniería",   "Norte" }, ;
                   { "0005", "Enlace Central",     "Centro" }, ;
                   { "0006", "Ferretería Ochoa",   "Centro" }, ;
                   { "0007", "Grupo Alcalá",       "Centro" }, ;
                   { "0008", "Hijos de Ibarra",    "Centro" }, ;
                   { "0009", "Instituto Sur",      "Sur" }, ;
                   { "0010", "Jardines Málaga",    "Sur" }, ;
                   { "0011", "Kiosko Costa",       "Sur" }, ;
                   { "0012", "Laguna Verde",       "Sur" } }
   LOCAL oTab := NIL
   LOCAL aZonas := {}
   LOCAL cRuta := "Norte/0001 Aceros del Norte"   // nodo inicial
   LOCAL nPag := 1
   LOCAL nSel := 1
   LOCAL oPrn := NIL
   LOCAL nBytes := 0, lCss := .F.
   LOCAL cFallo := ""

   ? "HarbGtkLin", Str( HGTK_FASE ), "- GTK", ;
     HgtkApplication():GtkVersion()

   /* ---------------------------------------------------------------
    * la tabla: creada desde cero en cada corrida
    * --------------------------------------------------------------- */

   IF ! CreaTabla( cTabla, aCli )
      ? "muestra05: FALLO - no se pudo crear la tabla"
      ErrorLevel( 1 )
      RETURN NIL
   ENDIF

   oTab := TDataBase():New( cTabla )

   IF ! oTab:Abierta()
      ? "muestra05: FALLO - no se pudo abrir la tabla"
      ErrorLevel( 1 )
      RETURN NIL
   ENDIF

   /* el árbol se arma con lo que hay en el fichero: una rama por
    * zona y, dentro, un nodo por cliente */
   aZonas := ArbolDesde( oTab )

   /* ---------------------------------------------------------------
    * la ventana
    * --------------------------------------------------------------- */

   DEFINE WINDOW oWnd TITLE TITULO_BASE SIZE 28, 100

      /* menú: la barra se cuelga con ACTIVATE MENU, al final */
      DEFINE MENU oMenu OF oWnd

      DEFINE POPUP oPopArc OF oMenu PROMPT "&Archivo"
      DEFINE MENUITEM oMnuAbr OF oPopArc PROMPT "&Abrir fichero..." ;
         ACTION {|| AbreFichero( oSta ) }
      DEFINE MENUITEM oMnuExp OF oPopArc PROMPT "&Exportar PDF..." ;
         ACTION {|| Exporta( oSta, oTab ) }
      /* la "c" es de carpeta: no choca con las del menú ni con la
       * pestaña "&Clientes", que sólo se mira con el menú cerrado */
      DEFINE MENUITEM oMnuCar OF oPopArc PROMPT "Elegir &carpeta..." ;
         ACTION {|| AbreCarpeta( oSta ) }
      DEFINE MENUITEM oMnuVen OF oPopArc PROMPT "&Nueva ventana" ;
         ACTION {|| Segunda( oSta ) }
      DEFINE MENUITEM oMnuSal OF oPopArc PROMPT "&Salir" ;
         ACTION {|| oWnd:End() }

      /* la "y" de Ayuda lleva el mnemónico: dos popups con la misma
       * inicial dejan la barra muda (avisado por el puente) */
      DEFINE POPUP oPopAyu OF oMenu PROMPT "A&yuda"
      DEFINE MENUITEM oMnuAcerca OF oPopAyu PROMPT "&Acerca de" ;
         ACTION {|| MsgInfo( "HarbGtkLin fase " + ;
                    LTrim( Str( HGTK_FASE ) ) + ", aplicación de ejemplo", ;
                    "Acerca de" ) }

      ACTIVATE MENU oMenu

      /* árbol de zonas: los datos salen del DBF */
      DEFINE TREE oTree OF oWnd VAR cRuta ITEMS aZonas ;
         AT 1, 1 SIZE 20, 25 ;
         ACTION {|| nNodos := nNodos + 1, cUltRuta := cRuta, ;
                    Refresca( oWnd, oSta, oSayNod, cRuta, nPag ) }

      /* panel con pestañas, en su propio sistema de coordenadas */
      DEFINE TABS oTabs OF oWnd VAR nPag AT 1, 27 SIZE 20, 72 ;
         ACTION {|| nPest := nPest + 1, ;
                    Refresca( oWnd, oSta, oSayNod, cRuta, nPag ) }

      DEFINE PAGE oPagCli OF oTabs PROMPT "&Clientes"
         DEFINE BROWSE oBrw OF oPagCli VAR nSel FIELDS aCab DATA oTab ;
            AT 1, 1 SIZE 17, 70

      DEFINE PAGE oPagRes OF oTabs PROMPT "&Resumen"
         DEFINE SAY oSayTit OF oPagRes PROMPT "Resumen de la tabla" ;
            AT 2, 2 SIZE 1, 40
         DEFINE SAY oSayTot OF oPagRes ;
            PROMPT "Clientes: 12   Zonas: 3" AT 4, 2 SIZE 1, 40
         DEFINE SAY oSayNod OF oPagRes PROMPT "(ningún nodo elegido)" ;
            AT 6, 2 SIZE 1, 60

      /* caja de botones: en fila y en orden de declaración, que es
       * lo que hace el modo de cajas (AT no se usa dentro) */
      DEFINE BOX oCaja OF oWnd HORIZONTAL AT 22, 1 SIZE 3, 98
      DEFINE BUTTON oBtExp OF oCaja PROMPT "&Exportar PDF" ;
         ACTION {|| Exporta( oSta, oTab ) }
      DEFINE BUTTON oBtAbr OF oCaja PROMPT "Abrir fichero" ;
         ACTION {|| AbreFichero( oSta ) }
      DEFINE BUTTON oBtImp OF oCaja PROMPT "&Imprimir" ;
         ACTION {|| Imprime( oSta, oTab ) }
      DEFINE BUTTON oBtVen OF oCaja PROMPT "&Nueva ventana" ;
         ACTION {|| Segunda( oSta ) }

      /* barra de estado */
      DEFINE STATUS oSta OF oWnd

      /* deja anotado el nodo con que se abre, pasados 300 ms — el
       * tiempo que cuesta mostrar la ventana y aplicar la selección
       * inicial (se crea parado: hay que arrancarlo) */
      DEFINE TIMER oTick OF oWnd INTERVAL 300 ;
         ACTION {|| cMapRuta := cRuta, oTick:Deactivate() }
      ACTIVATE TIMER oTick

   /* ---------------------------------------------------------------
     * comprobaciones antes de ACTIVATE: los widgets ya existen
     * --------------------------------------------------------------- */

   /* el panel: dos pestañas, la 1 visible, y Value() sincroniza la
    * variable por la señal switch-page, no a mano */
   IF cFallo == ""
      IF ! oTabs:IsAlive() .OR. Len( oTabs:aPaginas ) != 2
         cFallo := "el panel debe tener dos pestañas"
      ELSEIF oTabs:Value() != 1 .OR. nPag != 1
         cFallo := "la pestaña inicial debe ser la 1"
      ELSE
         oTabs:Value( 2 )
         IF nPag != 2 .OR. oTabs:Value() != 2
            cFallo := "Value(2) no sincronizó la variable de VAR"
         ENDIF
         oTabs:Value( 1 )
         IF nPag != 1
            cFallo := "volver a la pestaña 1 no actualizó la variable"
         ENDIF
      ENDIF
   ENDIF

   /* el árbol tiene las 3 zonas con sus 4 clientes y su variable
    * conserva el valor inicial (la selección se pone al mostrar) */
   IF cFallo == ""
      IF ! oTree:IsAlive() .OR. Len( oTree:aItems ) != 3
         cFallo := "el árbol debe tener las 3 zonas del DBF"
      ELSEIF Len( oTree:aItems[ 1, 2 ] ) != 4
         cFallo := "la primera zona debe tener 4 clientes"
      ELSEIF Distinto( cRuta, "Norte/0001 Aceros del Norte" )
         cFallo := "la variable del árbol perdió el valor inicial"
      ENDIF
   ENDIF

   /* la caja lleva sus 4 botones, dentro del fijo de la ventana */
   IF cFallo == ""
      IF ! oCaja:IsAlive() .OR. Len( oCaja:aControles ) != 4
         cFallo := "la caja debe tener sus 4 botones"
      ENDIF
   ENDIF

   /* el listado: 4 líneas de cabecera, 12 de datos y 2 de pie */
   IF cFallo == ""
      oPrn := MontaListado( oTab )
      IF oPrn:LineCount() != 18
         cFallo := "el listado debe tener 18 líneas, tiene " + ;
                   LTrim( Str( oPrn:LineCount() ) )
      ENDIF
   ENDIF

   /* exportar a PDF sin diálogo: el fichero tiene que ser un PDF */
   IF cFallo == ""
      IF ! oPrn:ToFile( cPdf )
         cFallo := "la exportación a PDF no se completó"
      ELSEIF Distinto( Left( Memoread( cPdf ), 4 ), "%PDF" )
         cFallo := "el fichero exportado no empieza por %PDF"
      ELSE
         nBytes := Len( Memoread( cPdf ) )
         IF nBytes < 1000
            cFallo := "el PDF exportado es sospechosamente pequeño"
         ENDIF
      ENDIF
   ENDIF

   /* la fuente de la ventana la hereda el árbol */
   IF cFallo == ""
      oWnd:Font( TFont():New( "Sans", 9 ) )
      IF Distinto( oTree:Font(), "Sans 9" )
         cFallo := "la fuente no llegó al árbol: " + oTree:Font()
      ENDIF
   ENDIF

   /* CSS de aspecto: un error de sintaxis se recupera y se anota */
   IF cFallo == ""
      BEGIN SEQUENCE
         lCss := HgtkCss( "notebook tab { padding: 3px 12px; }" )
      RECOVER
         lCss := .F.
      END SEQUENCE
      IF ! lCss
         cFallo := "GTK no aceptó la hoja de estilo"
      ENDIF
   ENDIF

   /* el foco empieza en el árbol: con teclado se llega a todo */
   oTree:SetFocus()

   /* ---------------------------------------------------------------
     * la ventana, abierta mientras espera el usuario
     * --------------------------------------------------------------- */

   IF cFallo == ""
      ACTIVATE WINDOW oWnd

      IF oWnd:IsAlive()
         cFallo := "la ventana debía cerrarse y sigue viva"
      ENDIF
   ENDIF

   /* el nodo con que se abrió tiene que seguir siendo el inicial */
   IF cFallo == "" .AND. ;
      Distinto( cMapRuta, "Norte/0001 Aceros del Norte" )
      cFallo := "el nodo inicial no se aplicó al mostrar: '" + ;
                cMapRuta + "'"
   ENDIF

   /* ---------------------------------------------------------------
     * informe: lo que se ha tocado durante la sesión
     * --------------------------------------------------------------- */

   ? ""
   ? "Listado PDF: " + LTrim( Str( nBytes ) ) + " bytes"
   ? "Nodos: " + LTrim( Str( nNodos ) ) + ;
     "  Pestañas: " + LTrim( Str( nPest ) ) + ;
     "  Pestaña final: " + LTrim( Str( nPag ) )
   ? "Nodo inicial: " + cMapRuta
   ? "Último nodo: " + IIF( Empty( cUltRuta ), "(ninguno)", cUltRuta )

   oTab:Close()
   Limpia( cTabla )
   Limpia( cPdf )

   IF cFallo == ""
      ? "muestra05: OK"
   ELSE
      ? "muestra05: FALLO -", cFallo
      ErrorLevel( 1 )
   ENDIF
   ? ""

RETURN NIL

/* ------------------------------------------------------------------ */
/* acciones                                                            */
/* ------------------------------------------------------------------ */

/*
 * Refresca — lo que se ve en la ventana según el estado actual: el
 * título (árbol y pestaña juntos, que es lo que se lee desde fuera),
 * la barra de estado y el nodo de la página de resumen. Le llaman los
 * dos ACTION: el del árbol al elegir nodo, el del panel al cambiar de
 * pestaña.
 */
STATIC FUNCTION Refresca( oWnd, oSta, oSayNod, cRuta, nPag )

   LOCAL cTexto := TITULO_BASE

   IF ! Empty( cRuta )
      cTexto += " — " + cRuta
   ENDIF
   cTexto += " — pestaña " + LTrim( Str( Max( nPag, 1 ) ) )

   IF ValType( oWnd ) == "O"
      oWnd:Title( cTexto )
   ENDIF
   IF ValType( oSta ) == "O"
      oSta:Value( cTexto )
   ENDIF
   IF ValType( oSayNod ) == "O"
      oSayNod:Value( IIF( Empty( cRuta ), "(ningún nodo elegido)", ;
                          cRuta ) )
   ENDIF

RETURN NIL

/* Abrir: el diálogo de GTK para elegir un fichero existente */
STATIC FUNCTION AbreFichero( oSta )

   LOCAL oDlg := TFileDialog():New( "Elegir un fichero", hb_DirTemp() )
   LOCAL cRuta

   cRuta := oDlg:Open( "*.prg;*.txt" )

   IF Empty( cRuta )
      oSta:Value( "No se abrió ningún fichero" )
   ELSE
      oSta:Value( "Fichero elegido: " + cRuta )
   ENDIF

RETURN NIL

/* Elegir carpeta: el diálogo de carpetas del selector */
STATIC FUNCTION AbreCarpeta( oSta )

   LOCAL oDlg := TFileDialog():New( "Elegir carpeta", hb_DirTemp() )
   LOCAL cRuta

   cRuta := oDlg:Directory()

   IF Empty( cRuta )
      oSta:Value( "No se eligió ninguna carpeta" )
   ELSE
      oSta:Value( "Carpeta elegida: " + cRuta )
   ENDIF

RETURN NIL

/* Exportar: el diálogo de guardar y la exportación a PDF */
STATIC FUNCTION Exporta( oSta, oTab )

   LOCAL oDlg := TFileDialog():New( "Guardar listado", hb_DirTemp() )
   LOCAL cRuta := oDlg:Save( "*.pdf", "listado.pdf" )
   LOCAL oPrn

   IF Empty( cRuta )
      oSta:Value( "Exportación cancelada" )
      RETURN NIL
   ENDIF

   oPrn := MontaListado( oTab )
   IF oPrn:ToFile( cRuta )
      oSta:Value( "Exportado: " + cRuta )
   ELSE
      oSta:Value( "No se pudo exportar: " + cRuta )
   ENDIF

RETURN NIL

/* Imprimir: el diálogo de impresión de GTK (camino interactivo) */
STATIC FUNCTION Imprime( oSta, oTab )

   LOCAL oPrn := MontaListado( oTab )

   IF oPrn:Dialog()
      oSta:Value( "Listado enviado a la cola de impresión" )
   ELSE
      oSta:Value( "Impresión cancelada" )
   ENDIF

RETURN NIL

/*
 * Segunda ventana: se abre desde un menú de la primera y ACTIVATE
 * espera a la SUYA, así que las dos reciben teclado y ratón a la vez.
 */
STATIC FUNCTION Segunda( oSta )

   LOCAL oSec

   DEFINE WINDOW oSec TITLE "Ventana secundaria" SIZE 12, 46

      DEFINE SAY oSecTit OF oSec ;
         PROMPT "Esta ventana no bloquea la principal" AT 2, 2 SIZE 1, 42

      DEFINE BUTTON oSecBtn OF oSec PROMPT "&Cerrar" ;
         AT 7, 3 SIZE 1, 12 ACTION {|| oSec:End() }

   ACTIVATE WINDOW oSec

   oSta:Value( "Ventana secundaria cerrada" )

RETURN NIL

/* ------------------------------------------------------------------ */
/* el listado y la tabla                                               */
/* ------------------------------------------------------------------ */

/* MontaListado( oTab ) -> TPrint con el contenido de la tabla */
STATIC FUNCTION MontaListado( oTab )

   LOCAL oPrn := TPrint():New( "Listado de clientes" )
   LOCAL aDatos := oTab:Cargar()
   LOCAL n

   oPrn:AddLine( "Listado de clientes" )
   oPrn:AddLine( "" )
   oPrn:AddLine( PadR( "Código", 6 ) + "  " + PadR( "Nombre", 21 ) + ;
                 "  " + "Zona" )
   oPrn:AddLine( Replicate( "-", 6 ) + "  " + Replicate( "-", 21 ) + ;
                 "  " + Replicate( "-", 4 ) )

   FOR n := 1 TO Len( aDatos )
      oPrn:AddLine( PadR( aDatos[ n, 1 ], 6 ) + "  " + ;
                    PadR( aDatos[ n, 2 ], 21 ) + "  " + ;
                    aDatos[ n, 3 ] )
   NEXT

   oPrn:AddLine( "" )
   oPrn:AddLine( "Total: " + LTrim( Str( Len( aDatos ) ) ) + ;
                 " clientes" )

RETURN oPrn

/*
 * ArbolDesde( oTab ) — un array { zona, { "0001 Nombre", ... } } por
 * cada zona que aparezca en el fichero, en orden de primera aparición.
 */
STATIC FUNCTION ArbolDesde( oTab )

   LOCAL aDatos := oTab:Cargar()
   LOCAL aZonas := {}
   LOCAL cZona, cTexto
   LOCAL n, nZona

   FOR n := 1 TO Len( aDatos )
      cZona  := aDatos[ n, 3 ]
      cTexto := aDatos[ n, 1 ] + " " + aDatos[ n, 2 ]
      nZona  := AScan( aZonas, {| a | a[ 1 ] == cZona } )

      IF nZona == 0
         AAdd( aZonas, { cZona, {} } )
         nZona := Len( aZonas )
      ENDIF
      AAdd( aZonas[ nZona, 2 ], cTexto )
   NEXT

RETURN aZonas

/*
 * CreaTabla( cTabla, aCli ) — deja la tabla creada y con sus
 * registros; siempre la misma, para que cada corrida empiece igual.
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
/* utilidades                                                          */
/* ------------------------------------------------------------------ */

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
