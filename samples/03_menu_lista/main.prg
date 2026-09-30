/*
 * 03_menu_lista — menú, lista y browse (fase 2)
 *
 * Una ventana de escritorio con todo lo que añade la fase:
 *
 *   - menú con Archivo/Refrescar, Archivo/Salir y Ayuda/Acerca de;
 *   - barra de botones (Primero, Último, Salir);
 *   - lista de registros de prueba y un browse que muestra el registro
 *     elegido: los dos van de la mano, cambiar en uno cambia el otro;
 *   - barra de estado con la fila elegida y un reloj que actualiza un
 *     temporizador con codeblock.
 *
 * Antes de ACTIVATE comprueba que el menú dispara, que los botones de
 * la barra mandan y que la lista y el browse se sincronizan en ambos
 * sentidos; después comprueba que el temporizador ha disparado con la
 * ventana abierta y deja en pantalla la selección final, que es lo
 * que el smoke comprueba mandando dos Flecha abajo a la lista.
 *
 * Compilar:  make sample      (desde la raíz del proyecto)
 * Ejecutar:  samples/03_menu_lista/03_menu_lista
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

STATIC nRefrescos := 0      // veces que se ha elegido Refrescar
STATIC nTicks     := 0      // disparos del temporizador

FUNCTION Main()

   LOCAL oWnd, oMenu, oPopArc, oMnuRef, oMnuSal, oPopAyu, oMnuAcerca
   LOCAL oBar, oBtPrim, oBtUlt, oBtSal, oList, oBrw, oSta, oTimer
   LOCAL aCab := { "Código", "Nombre", "Provincia", "Teléfono" }
   LOCAL aCli := { { 1, "Ana Barros",     "Cádiz",    "956 11 22 33" }, ;
                   { 2, "Luis Cifuentes", "Madrid",   "915 44 55 66" }, ;
                   { 3, "Marta Duque",    "Sevilla",  "954 77 88 99" }, ;
                   { 4, "Rafael Esteve",  "Alicante", "965 10 20 30" }, ;
                   { 5, "Nuria Fuentes",  "Burgos",   "947 40 50 60" }, ;
                   { 6, "Diego Gálvez",   "Málaga",   "952 70 80 90" } }
   LOCAL aNom := {}
   LOCAL nSel := 1
   LOCAL cFallo := ""
   LOCAL nAbierta, n

   FOR n := 1 TO Len( aCli )
      AAdd( aNom, aCli[ n, 2 ] )
   NEXT

   ? "HarbGtkLin", Str( HGTK_FASE ), "- GTK", ;
     HgtkApplication():GtkVersion()

   /* ---------------------------------------------------------------
    * la ventana
    * --------------------------------------------------------------- */

   DEFINE WINDOW oWnd TITLE "Clientes de prueba" SIZE 24, 78

      /* menú: la barra se cuelga con ACTIVATE MENU, al final */
      DEFINE MENU oMenu OF oWnd

      DEFINE POPUP oPopArc OF oMenu PROMPT "&Archivo"
      DEFINE MENUITEM oMnuRef OF oPopArc PROMPT "&Refrescar" ;
         ACTION {|| Refrescar( oList, oBrw, aNom, aCli, nSel ) }
      DEFINE MENUITEM oMnuSal OF oPopArc PROMPT "&Salir" ;
         ACTION {|| oWnd:End() }

      DEFINE POPUP oPopAyu OF oMenu PROMPT "&Ayuda"
      DEFINE MENUITEM oMnuAcerca OF oPopAyu PROMPT "&Acerca de" ;
         ACTION {|| oSta:Value( "HarbGtkLin fase 2" ) }

      ACTIVATE MENU oMenu

      /* barra de botones: los botones van "OF oBar" y no llevan AT */
      DEFINE BAR oBar OF oWnd

      DEFINE BUTTON oBtPrim OF oBar PROMPT "&Primero" ;
         ACTION {|| oList:Value( 1 ) }
      DEFINE BUTTON oBtUlt OF oBar PROMPT "Úl&timo" ;
         ACTION {|| oList:Value( Len( aCli ) ) }
      DEFINE BUTTON oBtSal OF oBar PROMPT "&Salir" ;
         ACTION {|| oWnd:End() }

      /* lista y browse: los dos guardan la fila en nSel */
      DEFINE LISTBOX oList OF oWnd VAR nSel ITEMS aNom ;
         AT 1, 1 SIZE 16, 26 ;
         ACTION {|| oBrw:Value( nSel ), ;
                    oSta:Value( Mensaje( nSel, Len( aCli ), .F. ) ) }

      DEFINE BROWSE oBrw OF oWnd VAR nSel FIELDS aCab DATA aCli ;
         AT 1, 30 SIZE 16, 46 ;
         ACTION {|| oList:Value( nSel ) }

      /* barra de estado y reloj */
      DEFINE STATUS oSta OF oWnd

      DEFINE TIMER oTimer OF oWnd INTERVAL 500 ;
         ACTION {|| nTicks := nTicks + 1, ;
                    oSta:Value( Mensaje( nSel, Len( aCli ), .T. ) ) }

   /* ---------------------------------------------------------------
    * comprobaciones antes de ACTIVATE: los widgets ya existen y las
    * señales se disparan aunque no se haya pintado nada todavía
    * --------------------------------------------------------------- */

   IF cFallo == ""
      IF ! oMenu:IsAlive() .OR. ! oMenu:lActivada
         cFallo := "el menú no se colgó en la ventana"
      ENDIF
   ENDIF

   IF cFallo == ""
      IF ! oBar:IsAlive() .OR. ! oSta:IsAlive()
         cFallo := "la barra de botones o la de estado no se crearon"
      ENDIF
   ENDIF

   /* una orden del menú dispara su acción */
   IF cFallo == ""
      oMnuRef:Click()
      IF nRefrescos != 1
         cFallo := "la orden Refrescar del menú no disparó"
      ENDIF
   ENDIF

   /* un botón de la barra dispara y la lista lleva al browse */
   IF cFallo == ""
      oBtUlt:Click()
      IF nSel != Len( aCli ) .OR. oBrw:Value() != Len( aCli )
         cFallo := "el botón Último no llevó la lista al browse"
      ENDIF
   ENDIF

   /* lista -> variable -> browse */
   IF cFallo == ""
      oList:Value( 3 )
      IF nSel != 3 .OR. oBrw:Value() != 3
         cFallo := "la lista no llevó el browse a la fila 3"
      ENDIF
   ENDIF

   /* browse -> variable -> lista */
   IF cFallo == ""
      oBrw:Value( 5 )
      IF nSel != 5 .OR. oList:Value() != 5
         cFallo := "el browse no llevó la lista a la fila 5"
      ENDIF
   ENDIF

   /* la barra de estado refleja la última fila elegida */
   IF cFallo == ""
      IF At( "Registro 5", oSta:Value() ) == 0
         cFallo := "la barra de estado no recoge la fila elegida"
      ENDIF
   ENDIF

   /* el browse enseña los datos de la fila elegida */
   IF cFallo == ""
      IF oBrw:Row()[ 2 ] != "Nuria Fuentes"
         cFallo := "el browse no muestra la fila elegida"
      ENDIF
   ENDIF

   /* se deja todo en el primero, que es como debe abrirse */
   oList:Value( 1 )

   /* ---------------------------------------------------------------
    * la ventana, abierta mientras espera el usuario
    * --------------------------------------------------------------- */

   IF cFallo == ""
      nAbierta := Seconds()
      oList:SetFocus()
      ACTIVATE TIMER oTimer
      ACTIVATE WINDOW oWnd
      nAbierta := Seconds() - nAbierta
      IF nAbierta < 0
         nAbierta += 86400        // medianoche de por medio
      ENDIF

      IF oWnd:IsAlive()
         cFallo := "la ventana debía cerrarse y sigue viva"
      ENDIF
   ENDIF

   /* el temporizador sólo puede disparar dentro de ACTIVATE */
   IF cFallo == ""
      IF nTicks == 0 .AND. nAbierta >= 2
         cFallo := "el temporizador no disparó con la ventana abierta"
      ENDIF
   ENDIF

   ? ""
   ? "Selección final:", LTrim( Str( nSel ) ), ;
     " Temporizador:", LTrim( Str( nTicks ) ), ;
     " Refrescos:", LTrim( Str( nRefrescos ) )

   IF cFallo == ""
      ? "muestra03: OK"
   ELSE
      ? "muestra03: FALLO -", cFallo
      ErrorLevel( 1 )
   ENDIF
   ? ""

RETURN NIL

/* Texto de la barra de estado: fila elegida y, opcionalmente, reloj */
STATIC FUNCTION Mensaje( nSel, nTotal, lReloj )

   LOCAL cTexto := "Registro " + LTrim( Str( nSel ) ) + " de " + ;
                   LTrim( Str( nTotal ) )

   IF lReloj
      cTexto += "    " + Time()
   ENDIF

RETURN cTexto

/*
 * Refrescar: vuelve a cargar la lista y los datos del browse y deja
 * ambos en la fila que estaba elegida. Es la orden del menú Archivo.
 */
STATIC FUNCTION Refrescar( oList, oBrw, aNom, aCli, nSel )

   nRefrescos++

   oList:SetItems( aNom )
   oList:Value( nSel )
   oBrw:SetData( aCli )
   oBrw:Value( nSel )

RETURN NIL
