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
#define HGTK_FASE                1

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

/* ------------------------------------------------------------------ */
/* Cajas de mensaje (MsgInfo, MsgStop, MsgYesNo)                       */
/* ------------------------------------------------------------------ */

#define HGTK_MSG_INFO            1
#define HGTK_MSG_STOP            2
#define HGTK_MSG_YESNO           3

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

#xcommand DEFINE BUTTON <o> OF <oW> PROMPT <c> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   ACTION {|| <b1> [, <b2>] [, <b3>] [, <b4>] } ;
   => [ <o> ] := TButton():New( <oW>, <c>, [ <nRow> ], [ <nCol> ], ;
                                [ <nHeight> ], [ <nWidth> ], ;
                                {|| <b1> [, <b2>] [, <b3>] [, <b4>] } )

#xcommand DEFINE BUTTON <o> OF <oW> PROMPT <c> ;
   [ AT <nRow>, <nCol> ] [ SIZE <nHeight>, <nWidth> ] ;
   => [ <o> ] := TButton():New( <oW>, <c>, [ <nRow> ], [ <nCol> ], ;
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

#endif /* HARBGTK_CH */
