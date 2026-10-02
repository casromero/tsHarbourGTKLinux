/*
 * harbgtk.ch — comandos y constantes de HarbGtkLin
 *
 * Librería de interfaz de escritorio para Linux (Harbour + GTK 3),
 * al estilo de FiveWin. Este fichero no se llama fivewin.ch y no
 * comparte include guards con él.
 *
 * Los comandos se expanden en llamadas a las clases: no llevan
 * lógica propia. El orden de las cláusulas es fijo (ver
 * docs/api-fase0.md §7): OF, PROMPT o VAR, AT, SIZE y al final
 * ACTION o VALID.
 *
 * Licencia: LGPL-3.0-or-later
 */

#ifndef HARBGTK_CH
#define HARBGTK_CH

/* ------------------------------------------------------------------ */
/* Identidad                                                           */
/* ------------------------------------------------------------------ */

#define HGTK_NOMBRE              "HarbGtkLin"
#define HGTK_FASE                5

/* ------------------------------------------------------------------ */
/* Coordenadas                                                         */
/*                                                                     */
/* La primera versión usa unidades de diálogo al estilo FiveWin:       */
/* columnas (ancho medio de carácter) y filas (alto de línea).         */
/* Se convierten a píxeles con este factor fijo.                       */
/* ------------------------------------------------------------------ */

#define HGTK_PX_COLUMNA          8
#define HGTK_PX_FILA             16

/* Tamaño por omisión de una ventana, en unidades de diálogo */
#define HGTK_COLS_DEF            60
#define HGTK_FILAS_DEF           18

/* Posición por omisión de un control (cláusula AT ausente) */
#define HGTK_AT_COL_DEF          1
#define HGTK_AT_FILA_DEF         1

/* Ancho por omisión de un campo de entrada y de un desplegable */
#define HGTK_GET_COLS_DEF        20

/* Tamaño por omisión de un grupo, en unidades de diálogo */
#define HGTK_GRUPO_COLS_DEF      40
#define HGTK_GRUPO_FILAS_DEF     10

/* Intervalo por omisión de un temporizador, en milisegundos */
#define HGTK_TIMER_MS_DEF        1000

/* ------------------------------------------------------------------ */
/* Cajas de mensaje (MsgInfo, MsgStop, MsgYesNo)                       */
/* ------------------------------------------------------------------ */

#define HGTK_MSG_INFO            1
#define HGTK_MSG_STOP            2
#define HGTK_MSG_YESNO           3

/* ------------------------------------------------------------------ */
/* Impresión (TPrint -> HGtkPrintRun)                                  */
/* ------------------------------------------------------------------ */

#define HGTK_PRINT_DIALOGO      0   /* diálogo de impresión de GTK    */
#define HGTK_PRINT_EXPORTA      1   /* exportar a fichero, sin diálogo */

/* ------------------------------------------------------------------ */
/* Comandos                                                            */
/* ------------------------------------------------------------------ */

/* --- ventana y diálogo ------------------------------------------------ */

#xcommand DEFINE WINDOW <o> [ TITLE <c> ] ;
   FROM <nTop>, <nLeft> TO <nBottom>, <nRight> ;
   => [ <o> ] := TWindow():New( [ <c> ], <nRight> - <nLeft>, ;
                                <nBottom> - <nTop> ) ;;
      [ <o> ]:Move( <nLeft>, <nTop> )

#xcommand DEFINE WINDOW <o> [ TITLE <c> ] [ SIZE <nRows>, <nCols> ] ;
   => [ <o> ] := TWindow():New( [ <c> ], [ <nCols> ], [ <nRows> ] )

#xcommand DEFINE DIALOG <o> [ TITLE <c> ] ;
   FROM <nTop>, <nLeft> TO <nBottom>, <nRight> ;
   => [ <o> ] := TDialog():New( [ <c> ], <nRight> - <nLeft>, ;
                                <nBottom> - <nTop> ) ;;
      [ <o> ]:Move( <nLeft>, <nTop> )

#xcommand DEFINE DIALOG <o> [ TITLE <c> ] [ SIZE <nRows>, <nCols> ] ;
   => [ <o> ] := TDialog():New( [ <c> ], [ <nCols> ], [ <nRows> ] )

#xcommand ACTIVATE WINDOW <o> => [ <o> ]:Activate()

#xcommand ACTIVATE DIALOG <o> => [ <o> ]:Activate()

/* --- controles -------------------------------------------------------- */

/* El bloque de un botón (ACTION) y de un campo (VALID) se escriben
 * como codeblock literal {|| ... }, que es como en FiveWin. La llave
 * no es decorativa: sin ella la expresión se evaluaría en el momento
 * del DEFINE, y no al pulsar o al validar. Por eso la cláusula sólo
 * admite el bloque, y una expresión entre paréntesis no compila.
 * Dentro del bloque caben hasta cuatro elementos separados por coma
 * (los que van entre paréntesis no cuentan). */

/* IMAGE, entre PROMPT y AT: la imagen va a la izquierda del texto y
 * su ruta es un fichero que lea GdkPixbuf (PNG, JPEG...). Sin IMAGE,
 * el hueco queda vacío (se le pasa una cadena sin usar). */

#xcommand DEFINE BUTTON <o> OF <oW> PROMPT <c> [ IMAGE <i> ] ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   ACTION {|| <b1> [, <b2>] [, <b3>] [, <b4>] } ;
   => [ <o> ] := TButton():New( <oW>, <c>, [ <i> ], [ <nRow> ], ;
                                [ <nCol> ], [ <nHeight> ], [ <nWidth> ], ;
                                {|| <b1> [, <b2>] [, <b3>] [, <b4>] } )

#xcommand DEFINE BUTTON <o> OF <oW> PROMPT <c> [ IMAGE <i> ] ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   => [ <o> ] := TButton():New( <oW>, <c>, [ <i> ], [ <nRow> ], ;
                                [ <nCol> ], [ <nHeight> ], [ <nWidth> ] )

/* una imagen como control */
#xcommand DEFINE IMAGE <o> OF <oW> FILE <c> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   => [ <o> ] := TImage():New( <oW>, <c>, [ <nRow> ], [ <nCol> ], ;
                               [ <nHeight> ], [ <nWidth> ] )

#xcommand DEFINE SAY <o> OF <oW> PROMPT <c> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   => [ <o> ] := TSay():New( <oW>, <c>, [ <nRow> ], [ <nCol> ], ;
                             [ <nHeight> ], [ <nWidth> ] )

#xcommand DEFINE GET <o> OF <oW> VAR <v> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   VALID {|| <b1> [, <b2>] [, <b3>] [, <b4>] } ;
   => [ <o> ] := TGet():New( <oW>, ;
        {|x| iif( PCount() > 0, <v> := x, <v> ) }, ;
        [ <nRow> ], [ <nCol> ], [ <nHeight> ], [ <nWidth> ], ;
        {|| <b1> [, <b2>] [, <b3>] [, <b4>] } )

#xcommand DEFINE GET <o> OF <oW> VAR <v> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   => [ <o> ] := TGet():New( <oW>, ;
        {|x| iif( PCount() > 0, <v> := x, <v> ) }, ;
        [ <nRow> ], [ <nCol> ], [ <nHeight> ], [ <nWidth> ] )

#xcommand DEFINE CHECKBOX <o> OF <oW> VAR <l> PROMPT <c> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   => [ <o> ] := TCheckBox():New( <oW>, ;
        {|x| iif( PCount() > 0, <l> := x, <l> ) }, ;
        <c>, [ <nRow> ], [ <nCol> ], [ <nHeight> ], [ <nWidth> ] )

#xcommand DEFINE RADIO <o> OF <oW> VAR <v> OPTION <nOpt> PROMPT <c> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   => [ <o> ] := TRadio():New( <oW>, <(v)>, <nOpt>, ;
        {|x| iif( PCount() > 0, <v> := x, <v> ) }, ;
        <c>, [ <nRow> ], [ <nCol> ], [ <nHeight> ], [ <nWidth> ] )

#xcommand DEFINE COMBOBOX <o> OF <oW> VAR <v> ;
   [ ITEMS <a> ] [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   => [ <o> ] := TComboBox():New( <oW>, ;
        {|x| iif( PCount() > 0, <v> := x, <v> ) }, ;
        [ <a> ], [ <nRow> ], [ <nCol> ], [ <nHeight> ], [ <nWidth> ] )

#xcommand DEFINE GROUP <o> OF <oW> PROMPT <c> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   => [ <o> ] := TGroup():New( <oW>, <c>, [ <nRow> ], [ <nCol> ], ;
                               [ <nHeight> ], [ <nWidth> ] )

/* --- menú ------------------------------------------------------------- */
/*
 * Un menú se declara pieza a pieza, cada una con su OF, sin bloques de
 * anidamiento: DEFINE MENU crea la barra de la ventana, DEFINE POPUP
 * un ítem con submenú (en la barra o en otro POPUP) y DEFINE MENUITEM
 * una orden al final de un POPUP o de la barra. ACTIVATE MENU cuelga
 * la barra en la ventana, que es cuando aparece en pantalla.
 *
 * El texto admite la marca de mnemónico "&x" de FiveWin (ATRAS se
 * convierte en la "A" con Alt en GTK); "&" sola se escribe "&&".
 */

#xcommand DEFINE MENU <o> OF <oW> ;
   => [ <o> ] := TMenu():New( <oW> )

#xcommand DEFINE POPUP <o> OF <oW> PROMPT <c> ;
   => [ <o> ] := TPopup():New( <oW>, <c> )

#xcommand DEFINE MENUITEM <o> OF <oW> PROMPT <c> ;
   ACTION {|| <b1> [, <b2>] [, <b3>] [, <b4>] } ;
   => [ <o> ] := TMenuItem():New( <oW>, <c>, ;
        {|| <b1> [, <b2>] [, <b3>] [, <b4>] } )

#xcommand DEFINE MENUITEM <o> OF <oW> PROMPT <c> ;
   => [ <o> ] := TMenuItem():New( <oW>, <c> )

#xcommand ACTIVATE MENU <o> => [ <o> ]:Activate()

/* --- barra de botones y barra de estado -------------------------------- */
/*
 * DEFINE BAR crea la barra de botones que va debajo del menú; los
 * botones se declaran con DEFINE BUTTON como siempre, pero con "OF
 * oBar", y entonces no llevan AT ni SIZE: el orden es el de
 * declaración. DEFINE STATUS crea la barra de estado de una línea, que
 * se llena con oEstado:Value( cTexto ).
 */

#xcommand DEFINE BAR <o> OF <oW> ;
   => [ <o> ] := TBar():New( <oW> )

#xcommand DEFINE STATUS <o> OF <oW> ;
   => [ <o> ] := TStatus():New( <oW> )

/* --- lista, browse y temporizador -------------------------------------- */
/*
 * La lista y el browse guardan su fila elegida en la variable de VAR,
 * la misma forma que el desplegable, y ACTION se evalúa al cambiar de
 * fila. En el browse, FIELDS son los títulos de las columnas y DATA
 * los datos, un array de arrays.
 */

#xcommand DEFINE LISTBOX <o> OF <oW> VAR <v> ITEMS <a> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   ACTION {|| <b1> [, <b2>] [, <b3>] [, <b4>] } ;
   => [ <o> ] := TListBox():New( <oW>, ;
        {|x| iif( PCount() > 0, <v> := x, <v> ) }, ;
        <a>, [ <nRow> ], [ <nCol> ], [ <nHeight> ], [ <nWidth> ], ;
        {|| <b1> [, <b2>] [, <b3>] [, <b4>] } )

#xcommand DEFINE LISTBOX <o> OF <oW> VAR <v> ITEMS <a> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   => [ <o> ] := TListBox():New( <oW>, ;
        {|x| iif( PCount() > 0, <v> := x, <v> ) }, ;
        <a>, [ <nRow> ], [ <nCol> ], [ <nHeight> ], [ <nWidth> ] )

#xcommand DEFINE BROWSE <o> OF <oW> VAR <v> FIELDS <aC> DATA <aD> EDIT ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   ACTION {|| <b1> [, <b2>] [, <b3>] [, <b4>] } ;
   => [ <o> ] := TBrowse():New( <oW>, ;
        {|x| iif( PCount() > 0, <v> := x, <v> ) }, ;
        <aC>, <aD>, [ <nRow> ], [ <nCol> ], [ <nHeight> ], [ <nWidth> ], ;
        {|| <b1> [, <b2>] [, <b3>] [, <b4>] }, .T. )

#xcommand DEFINE BROWSE <o> OF <oW> VAR <v> FIELDS <aC> DATA <aD> EDIT ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   => [ <o> ] := TBrowse():New( <oW>, ;
        {|x| iif( PCount() > 0, <v> := x, <v> ) }, ;
        <aC>, <aD>, [ <nRow> ], [ <nCol> ], [ <nHeight> ], [ <nWidth> ], ;
        NIL, .T. )

#xcommand DEFINE BROWSE <o> OF <oW> VAR <v> FIELDS <aC> DATA <aD> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   ACTION {|| <b1> [, <b2>] [, <b3>] [, <b4>] } ;
   => [ <o> ] := TBrowse():New( <oW>, ;
        {|x| iif( PCount() > 0, <v> := x, <v> ) }, ;
        <aC>, <aD>, [ <nRow> ], [ <nCol> ], [ <nHeight> ], [ <nWidth> ], ;
        {|| <b1> [, <b2>] [, <b3>] [, <b4>] } )

#xcommand DEFINE BROWSE <o> OF <oW> VAR <v> FIELDS <aC> DATA <aD> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   => [ <o> ] := TBrowse():New( <oW>, ;
        {|x| iif( PCount() > 0, <v> := x, <v> ) }, ;
        <aC>, <aD>, [ <nRow> ], [ <nCol> ], [ <nHeight> ], [ <nWidth> ] )

#xcommand DEFINE TIMER <o> OF <oW> INTERVAL <nMs> ;
   ACTION {|| <b1> [, <b2>] [, <b3>] [, <b4>] } ;
   => [ <o> ] := TTimer():New( <oW>, <nMs>, ;
        {|| <b1> [, <b2>] [, <b3>] [, <b4>] } )

#xcommand ACTIVATE TIMER <o> => [ <o> ]:Activate()

#xcommand DEACTIVATE TIMER <o> => [ <o> ]:Deactivate()

/* --- cajas, pestañas y árbol (fase 4) ---------------------------------- */
/*
 * DEFINE BOX crea una caja de empaquetado: dentro, los controles
 * declarados "OF oCaja" llevan el orden de declaración en vez de
 * fila y columna (AT se ignora dentro de una caja; SIZE sí fija el
 * tamaño que pide cada control). Sin HORIZONTAL, la caja apila en
 * vertical; con HORIZONTAL, hace fila. La caja misma sí va donde se
 * diga, con AT y SIZE, dentro de su ventana.
 *
 * DEFINE TABS y DEFINE PAGE forman el panel con pestañas: el panel va
 * en la ventana (AT/SIZE) y cada pestaña es un contenedor con su
 * propio sistema de coordenadas, como un grupo. La variable de VAR
 * guarda la pestaña visible (1 por la primera) y ACTION se evalúa al
 * cambiar de ella.
 *
 * DEFINE TREE es el árbol de categorías: ITEMS es un array de textos
 * o de arrays { texto, hijos }, anidado; la variable de VAR guarda la
 * ruta de etiquetas del nodo elegido unida con "/" ("Clientes/Zona
 * norte") y ACTION se evalúa al elegir nodo. El orden de las
 * cláusulas es el de siempre: OF, VAR, ITEMS, AT, SIZE y ACTION.
 */

#xcommand DEFINE BOX <o> OF <oW> HORIZONTAL ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   => [ <o> ] := TBox():New( <oW>, .T., [ <nRow> ], [ <nCol> ], ;
                             [ <nHeight> ], [ <nWidth> ] )

#xcommand DEFINE BOX <o> OF <oW> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   => [ <o> ] := TBox():New( <oW>, .F., [ <nRow> ], [ <nCol> ], ;
                             [ <nHeight> ], [ <nWidth> ] )

#xcommand DEFINE TABS <o> OF <oW> VAR <v> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   ACTION {|| <b1> [, <b2>] [, <b3>] [, <b4>] } ;
   => [ <o> ] := TTabs():New( <oW>, ;
        {|x| iif( PCount() > 0, <v> := x, <v> ) }, ;
        [ <nRow> ], [ <nCol> ], [ <nHeight> ], [ <nWidth> ], ;
        {|| <b1> [, <b2>] [, <b3>] [, <b4>] } )

#xcommand DEFINE TABS <o> OF <oW> VAR <v> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   => [ <o> ] := TTabs():New( <oW>, ;
        {|x| iif( PCount() > 0, <v> := x, <v> ) }, ;
        [ <nRow> ], [ <nCol> ], [ <nHeight> ], [ <nWidth> ] )

#xcommand DEFINE PAGE <o> OF <oT> PROMPT <c> ;
   => [ <o> ] := TPage():New( <oT>, <c> )

#xcommand DEFINE TREE <o> OF <oW> VAR <v> ITEMS <a> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   ACTION {|| <b1> [, <b2>] [, <b3>] [, <b4>] } ;
   => [ <o> ] := TTree():New( <oW>, ;
        {|x| iif( PCount() > 0, <v> := x, <v> ) }, ;
        <a>, [ <nRow> ], [ <nCol> ], [ <nHeight> ], [ <nWidth> ], ;
        {|| <b1> [, <b2>] [, <b3>] [, <b4>] } )

#xcommand DEFINE TREE <o> OF <oW> VAR <v> ITEMS <a> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   => [ <o> ] := TTree():New( <oW>, ;
        {|x| iif( PCount() > 0, <v> := x, <v> ) }, ;
        <a>, [ <nRow> ], [ <nCol> ], [ <nHeight> ], [ <nWidth> ] )

#endif /* HARBGTK_CH */
