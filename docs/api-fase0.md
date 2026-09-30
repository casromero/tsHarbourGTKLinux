# HarbGtkLin — contrato de la API (fase 0)

Documento corto que se congela en la fase 0. Las fases siguientes lo
cumplen: cambiar cualquiera de estos puntos exige una decisión
documentada en `HarbGtkLin.md`.

La fase 1 ha obligado a retocar cuatro puntos de §7 (sintaxis de los
comandos): están al final, en §10, con el porqué de cada uno. El resto
del contrato sigue igual.

Licencia: **LGPL-3.0-or-later** (GTK y GLib son LGPL y se enlazan en
dinámico contra las bibliotecas del sistema).

## 1. Convenciones

| Tema | Regla |
| --- | --- |
| Textos | UTF-8, sin recodificación. El puente no convierte a páginas ANSI |
| Clases | Prefijo `T` (viene de FiveWin) |
| Ficheros y funciones | Prefijo `harbgtk` / `HGtk`; ficheros C `hbgtk_*.c` |
| Include | `harbgtk.ch`; nunca `fivewin.ch`, ni los mismos include guards |
| Punteros | `TWindow:hWnd` es un dato opaco: sólo lo toca el puente C. Su valor sólo es válido mientras `IsAlive()` sea `.T.` |
| Errores de uso | Mecanismo de error de Harbour (`ErrorBlock`), nunca un `abort` de GTK |
| Hilos | Toda la interfaz corre en el hilo que ejecutó `gtk_init`. No se pinta desde otros hilos |
| Esperas | Sólo dentro de `ACTIVATE` (ver §6) |

## 2. Coordenadas: filas y columnas, factor fijo

Unidad de diálogo al estilo FiveWin: **columnas** (ancho medio de
carácter) y **filas** (alto de línea). Conversión a píxeles con un
factor fijo, documentado y no variable dentro de una fase:

| Constante | Valor | Significado |
| --- | --- | --- |
| `HGTK_PX_COLUMNA` | 8 | píxeles por columna |
| `HGTK_PX_FILA` | 16 | píxeles por fila |
| `HGTK_COLS_DEF` | 60 | ancho por omisión de una ventana |
| `HGTK_FILAS_DEF` | 18 | alto por omisión de una ventana |

```harbour
HgtkColToPx( 60 )   // 480
HgtkRowToPx( 18 )   // 288
HgtkSize( 60, 18 )  // { 480, 288 }
```

`FROM r1, c1 TO r2, c2` equivale a `x = c1*8`, `y = r1*16`,
`w = (c2-c1)*8`, `h = (r2-r1)*16`. El programador de las fases 0 a 2 no
maneja píxeles; el modo cajas de GTK llega en la fase 4 como opcional,
sin retirar este modo.

## 3. TApplication: objeto único y arranque

```harbour
oApp := HgtkApplication()      // siempre la misma instancia
oApp := TApplication():New()   // idéntico: segunda llamada devuelve la anterior
```

| Miembro | Tipo | Significado |
| --- | --- | --- |
| `cName` | `C` | `"HarbGtkLin"` |
| `nPhase` | `N` | fase actual (`HGTK_FASE`) |
| `lGui` | `L` | `.T.` si GTK arrancó |
| `cGtkVersion` | `C` | versión de GTK, p. ej. `"3.24.41"` |

Métodos: `New()`, `InitGui()`, `GuiReady()`, `GtkVersion()`.

`gtk_init` se ejecuta **una sola vez** por proceso, en la creación del
primer `TApplication` (que a su vez lo hace la primera ventana). Se usa
`gtk_init_check`: si no hay display, se lanza un error de Harbour,
`GuiReady()` queda en `.F.` y no se crea ninguna ventana.

## 4. TWindow: ventana no modal

```harbour
oWnd := TWindow():New( [ cTitle ], [ nCols ], [ nRows ] )
```

| Miembro | Tipo | Significado |
| --- | --- | --- |
| `oApplication` | objeto | `TApplication` único |
| `hWnd` | puntero | opaco, para el puente |
| `cTitle` | `C` | título en UTF-8 |
| `nWidth`, `nHeight` | `N` | tamaño en píxeles |
| `lActive` | `L` | dentro de `Activate()` |
| `lDestroyed` | `L` | ya se destruyó |
| `bClose` | bloque | ver §5 |

| Método | Comportamiento |
| --- | --- |
| `New()` | crea el widget; no se ve todavía |
| `Activate()` | muestra la ventana y espera hasta que la última se cierre; regresa con la ventana destruida |
| `End()` | destruye la ventana; dentro de `Activate()` hace que éste regrese |
| `Title([ cTitle ])` | lee o escribe el título **real del widget** |
| `IsActive()` | `.T.` mientras se está dentro de `Activate()` |
| `IsAlive()` | `.T.` si el widget existe, aunque se haya cerrado desde la barra de título |

Ciclo de vida: se crea en `New()` (con GTK ya arrancado), se muestra en
`Activate()` y se destruye con `End()` o con la barra de título. La
clase detecta ambos caminos y limpia `hWnd`; un `End()` posterior sobre
una ventana ya cerrada no hace nada.

## 5. Eventos como codeblocks

- `bClose`: se evalúa **sin argumentos** cuando GTK recibe la petición
  de cierre (el aspa de la barra de título). Devolver `.F.` cancela el
  cierre; devolver `.T.` o no tener bloque lo deja pasar.
- El puente mantiene el objeto vivo con un *grip* de GC desde que se
  crea la ventana hasta la señal `destroy`, de modo que `bClose` no se
  libera mientras pueda llamarlo una señal.
- `bClose` sólo se evalúa dentro del bucle de `ACTIVATE`.
- No se espera ni se bloquea dentro de un codeblock: cualquier espera
  larga se deja fuera de la interfaz y se vuelve con lo que añada la
  fase 2 (timer) o la fase 5.
- Las fases siguientes siguen esta misma regla: `bAction` de botones y
  la validación al perder el foco devuelven `.F.` para cancelar.

## 6. `ACTIVATE` y el bucle de eventos

- El **único** sitio donde se espera a la interfaz es `ACTIVATE`. Un
  `while` propio que no bombee el contexto de GLib congela la ventana.
- `ACTIVATE` regresa cuando la última ventana del proceso se ha
  destruido; entonces el proceso termina con código 0.
- `ACTIVATE DIALOG` (fase 1) no regresa hasta que el diálogo se cierra.

## 7. Sintaxis de comandos (congelada aquí; fases 1 a 3 implementadas)

Los comandos se expanden en llamadas a las clases; no llevan lógica
propia. Ningún `.prg` de aplicación incluye `gtk/gtk.h` ni maneja
punteros a widgets.

```harbour
#include "harbgtk.ch"

DEFINE WINDOW <o> [ TITLE <cTitle> ] ;
   [ FROM <nTop>, <nLeft> TO <nBottom>, <nRight> | SIZE <nRows>, <nCols> ]

   DEFINE BUTTON    <o> OF <oW> PROMPT <cText>  [ IMAGE <cFile> ] ;
                                          [ AT <r>, <c> ] [ SIZE <h>, <w> ] ;
                                          ACTION {|| <b1> [, <b2>] [, <b3>] [, <b4>] }
   DEFINE IMAGE     <o> OF <oW> FILE <cFile>    [ AT <r>, <c> ] [ SIZE <h>, <w> ]
   DEFINE SAY       <o> OF <oW> PROMPT <cText>  [ AT <r>, <c> ] [ SIZE <h>, <w> ]
   DEFINE GET       <o> OF <oW> VAR <xVar>      [ AT <r>, <c> ] [ SIZE <h>, <w> ] ;
                                           [ VALID {|| <b1> [, <b2>] [, <b3>] [, <b4>] } ]
   DEFINE CHECKBOX  <o> OF <oW> VAR <lVar> PROMPT <cText> [ AT <r>, <c> ] [ SIZE <h>, <w> ]
   DEFINE RADIO     <o> OF <oW> VAR <nVar> OPTION <nOpt> PROMPT <cText> [ AT <r>, <c> ] ...
   DEFINE COMBOBOX  <o> OF <oW> VAR <xVar> [ ITEMS <a> ] [ AT <r>, <c> ] [ SIZE <h>, <w> ]
   DEFINE GROUP     <o> OF <oW> PROMPT <cText> [ AT <r>, <c> ] [ SIZE <h>, <w> ]

ACTIVATE WINDOW <o>

DEFINE DIALOG <o> [ TITLE <cTitle> ] [ SIZE <nRows>, <nCols> | FROM ... TO ... ]
   ...
ACTIVATE DIALOG <o>

/* fase 2 */
DEFINE MENU        <o> OF <oW>
DEFINE POPUP       <o> OF <oW> PROMPT <cText>
DEFINE MENUITEM    <o> OF <oW> PROMPT <cText>   [ ACTION {|| <b1> [, <b2>] [, <b3>] [, <b4>] } ]
DEFINE BAR         <o> OF <oW>
DEFINE STATUS      <o> OF <oW>
DEFINE LISTBOX     <o> OF <oW> VAR <xVar> ITEMS <a>     [ AT <r>, <c> ] [ SIZE <h>, <w> ] ;
                                                  [ ACTION {|| <b1> [, <b2>] [, <b3>] [, <b4>] } ]
DEFINE BROWSE      <o> OF <oW> VAR <xVar> FIELDS <aCab> DATA <aDat> [ EDIT ] ;
                                                  [ AT <r>, <c> ] [ SIZE <h>, <w> ] ;
                                                  [ ACTION {|| <b1> [, <b2>] [, <b3>] [, <b4>] } ]
DEFINE TIMER       <o> OF <oW> INTERVAL <nMs> ACTION {|| <b1> [, <b2>] [, <b3>] [, <b4>] }

ACTIVATE MENU   <o>
ACTIVATE TIMER  <o>
DEACTIVATE TIMER <o>
```

El orden de las cláusulas es fijo: `OF`, después `PROMPT` o `VAR`
(`OPTION` en los radio; en lista y browse, `ITEMS`, `FIELDS` y `DATA`
siguen a `VAR`), al final `AT`, `SIZE` y, si los hay, `ACTION` o
`VALID`. Una cláusula opcional ausente no cambia el orden ni admite
argumentos «sueltos» después: `[ AT <r>, <c> ]` o `[ SIZE <h>, <w> ]`
se omiten enteras.

Los comandos de la fase 1 se congelan con esta forma:
`DEFINE DIALOG`, `ACTIVATE DIALOG`, `MsgInfo`, `MsgStop`, `MsgYesNo`.

La fase 2 congeló los suyos con la misma forma: `DEFINE MENU`,
`DEFINE POPUP`, `DEFINE MENUITEM`, `ACTIVATE MENU`, `DEFINE BAR`,
`DEFINE STATUS`, `DEFINE LISTBOX`, `DEFINE BROWSE`, `DEFINE TIMER`,
`ACTIVATE TIMER` y `DEACTIVATE TIMER` (detallados en §11). Una clase o
un comando entra cuando el ejemplo de su fase lo usa.

La fase 3 congeló los suyos con la misma forma: `IMAGE` en `DEFINE
BUTTON` (después de `PROMPT` y antes de `AT`), `DEFINE IMAGE` con su
`FILE`, y `EDIT` en `DEFINE BROWSE` (después de `DATA` y antes de
`AT`), detallados en §12.

## 8. Puente C publicado en la fase 0

Una función hace una cosa: crear un widget, cambiar una propiedad, leer
un texto, conectar una señal. No hay lógica de negocio en C.

| Función | Qué hace |
| --- | --- |
| `HGtkInit()` | `gtk_init_check` una vez; error si no hay display |
| `HGtkIsInit()` | estado del arranque |
| `HGtkVersion()` | `"3.24.41"` |
| `HGtkErrArgs( cProc, cMsg )` | error de uso (`EG_ARG`) por `ErrorBlock` |
| `HGtkErrGui( cProc, cMsg )` | error de GUI (`EG_UNSUPPORTED`) |
| `HGtkWndNew( cTitle, nW, nH )` | crea la ventana de nivel superior |
| `HGtkWndSetOwner( pWnd, oObj )` | sujeta el objeto hasta `destroy` |
| `HGtkWndSetTitle / HGtkWndGetTitle` | título del widget |
| `HGtkWndShow( pWnd )` | muestra la ventana |
| `HGtkWndDestroy( pWnd )` | destruye la ventana |
| `HGtkWndAlive( pWnd )` | compara el puntero con la lista de ventanas vivas, sin desreferenciarlo |
| `HGtkMain()` | entra en `gtk_main` y regresa al cerrarse la última ventana |

## 9. Fuera de este contrato

Diálogo modal, controles, menús, browse, pestañas, árbol e impresión:
fases 1 a 4, con la sintaxis de §7 ya escrita. ActiveX/OLE, recursos
`.rc`, GDI+, DDE, MCI e impresión GDI no existen en esta librería
(ver «Qué no entra» en `HarbGtkLin.md`).

## 10. Enmiendas de la fase 1

La fase 1 ha tenido que tocar cuatro puntos de §7. Se dejan aquí, con
el motivo, para que las fases siguientes las respeten:

1. **`ACTION` y `VALID` exigen el codeblock literal `{|| ... }`.**
   `ACTION ( expr )` con una expresión entre paréntesis se evalúa en el
   `DEFINE`, no al pulsar ni al validar (el preprocesador no captura el
   bloque dentro de la cláusula opcional). La cláusula admite hasta
   cuatro elementos separados por coma a nivel superior; los que van
   entre paréntesis no cuentan.
2. **Se retira la cláusula `[ <bClose> ]` de `ACTIVATE DIALOG`.** El
   cierre es un miembro de la clase, `oDlg:bClose`, igual que en
   `TWindow`, y así se evalúa siempre dentro del bucle de `ACTIVATE`.
3. **Se retira `PICTURE` de `DEFINE GET`.** El formato de edición llega
   en la fase 3; añadirlo ahora obligaría a cambiar la firma de
   `TGet:New()`.
4. **Orden fijo de cláusulas** (ya anotado en `include/harbgtk.ch`):
   `OF`, `PROMPT`/`VAR`, `AT`, `SIZE`, y `ACTION`/`VALID` al final.

Y dos comportamientos que §5 y §6 dejan más precisos:

- **La validación se difiere a un giro del bucle de eventos.** GTK
  avisa del `focus-out` también cuando sólo reorganiza el foco interno
  (al activarse la ventana, al abrirse una caja encima); si al bucle el
  campo sigue con el foco, no se valida. Así un campo vacío no lanza un
  aviso sin motivo al abrir el diálogo.
- **Las cajas de mensaje tienen un botón con el foco y con el valor por
  omisión**: `Intro` da la respuesta afirmativa (Aceptar o Sí), que
  también cierra la caja desde teclado en las pruebas.

## 11. Notas de la fase 2

La fase 2 pone en marcha los comandos de §7 y añade los que faltaban.
Quedan congelados con estas formas:

- **Menú**: `DEFINE MENU` crea la barra de la ventana (su `OF` es la
  ventana), `DEFINE POPUP` un ítem con submenú y `DEFINE MENUITEM`
  una orden. Las dos últimas cuelgan de lo que diga su `OF`: un menú o
  otro popup. Cada pieza lleva su `OF`; **no hay bloques de
  anidamiento**: la estructura se lee por el `OF`, no por sangría.
  `ACTIVATE MENU <o>` es el que cuelga la barra en la ventana.
- **Barra y estado**: `DEFINE BAR` y `DEFINE STATUS` llevan `OF` la
  ventana. Los botones de la barra son `DEFINE BUTTON ... OF oBar`,
  los mismos de siempre, y al ir en una barra **no llevan `AT` ni
  `SIZE`**: el orden es el de declaración.
- **Lista y browse**: `DEFINE LISTBOX ... VAR ... ITEMS ...` y
  `DEFINE BROWSE ... VAR ... FIELDS ... DATA ...`. `ITEMS`, `FIELDS`
  y `DATA` ocupan el sitio donde va `PROMPT` en los demás: después de
  `VAR` y antes de `AT`/`SIZE`.
- **Temporizador**: `DEFINE TIMER ... INTERVAL <nMs> ACTION ...` con
  `ACTIVATE TIMER` y `DEACTIVATE TIMER`. `ACTION` es obligatorio y el
  intervalo queda fijo desde el `DEFINE`.

Tres comportamientos que conviene no perder de vista:

1. **Una lista no es enfocable en sí misma.** GTK crea `GtkListBox`
   con `can_focus` apagado: dentro de una lista el foco lo lleva la
   fila elegida. Por eso `oList:SetFocus()` se lo pone a esa fila y
   `oList:HasFocus()` mira dentro de la lista; desde fuera se ve como
   en cualquier otro control, y las Flecha abajo mueven la selección
   sin más.
2. **`TWindow:FocusName()`** devuelve el tipo del widget con el foco
   (`"GtkListBoxRow"`, `"GtkToolButton"`, ...). Es una consulta para
   las pruebas: comprueba por dónde van a ir las teclas sin tener que
   mirar la pantalla.
3. **El menú se abre con Alt+mnemónico**, que en español es `Alt+A`
   en «Archivo»: el texto admite la marca `&x` de FiveWin y el puente
   la convierte en `_x` para GTK. Por eso el smoke llega a
   Archivo/Salir sin ratón.

## 12. Notas de la fase 3

La fase 3 pone en marcha lo que faltaba de §7 y añade la tabla y las
imágenes. Los comandos quedan congelados con estas formas:

- **Imagen en un botón**: `DEFINE BUTTON ... PROMPT <c> IMAGE <cArchivo>`,
  con `IMAGE` después de `PROMPT` y antes de `AT`. La imagen se coloca
  a la izquierda del texto y **el texto se conserva** (GTK guarda la
  etiqueta aparte de la imagen y sigue interpretando el `&` del
  mnemónico). Al ser un argumento más del constructor, la firma de
  `TButton` cambia a
  `TButton():New( oParent, cPrompt, cImage, nRow, nCol, nHeight, nWidth, bAction )`:
  `cImage` ocupa el tercer sitio, y quien llame a `New()` a mano tiene
  que ponerlo (cadena vacía si no hay imagen).
- **Imagen como control**: `DEFINE IMAGE <o> OF <oW> FILE <cArchivo>`
  con `AT` y `SIZE` opcionales, como cualquier otro control. El
  fichero lo lee GdkPixbuf (PNG, JPEG...), y `TImage:Size()` devuelve
  el tamaño en píxeles de la imagen; si el fichero no existe o no se
  puede leer, el control queda creado sin imagen y `Size()` devuelve
  `{ 0, 0 }` en vez de romper.
- **Browse editable**: `DEFINE BROWSE ... DATA <aDat> EDIT`, con `EDIT`
  después de `DATA`. El browse se ordena pulsando la cabecera de la
  columna y también con `Ordenar( nCol [, lDesc ] )`, y su origen
  puede ser un array o un `TDataBase` (cláusula `DATA` con el objeto).
- **Tabla**: `TDataBase():New( cFichero )` envuelve un DBF de Harbour
  sin tocar GTK. Se abre sola si se le pasa la ruta; `Abierta()`,
  `Cantidad()`, `Cargar()`, `Registros()`, `Guardar( nReg, nCampo,
  xValor )` y `Anadir( aValores )` son la cara pública, y el browse
  no pide más: con `DATA oTab` lee, escribe y añade por su cuenta.
  Cada objeto ocupa su propio alias (`HGTK1`, `HGTK2`, ...) y devuelve
  el área que tenía al entrar en cada método.

Seis comportamientos que conviene no perder de vista:

1. **`Return` abre la celda; `F2` no.** En GTK 3.24 la pulsación de
   F2 llega a la vista como el keyval `0xffbf` y la ignoran: no se
   abre el editor. `Return`, en cambio, sí abre `editing-started` con
   su `GtkEntry`, y un `Return` más confirma. La secuencia completa de
   edición es, pues: `Return`, `Ctrl+A` (seleciona lo que había),
   teclear, `Return`. Es lo que hace el smoke en la muestra 04.
2. **El foco puesto antes de `ACTIVATE` no basta.** Si `SetFocus()`
   se llama antes de mostrar la ventana, la vista se queda en un
   estado en el que las teclas llegan pero `Return` no abre la celda;
   por eso `TWindow:Activate()` vuelve a poner el foco después de
   `HGtkWndShow`, con `HGtkWndRefocus( pWnd )`. Poner el foco en el
   `DEFINE` y después de `ACTIVATE` son ambos válidos; el segundo no
   hace falta ya.
3. **Los popups de la barra necesitan iniciales distintas.** Con dos
   ítems de la misma inicial —en español, «Archivo» y «Ayuda»— la
   barra funciona la primera vez que se abre y deja de responder a
   partir de la segunda (medido con GTK 3.24: 1 de 3 elecciones con
   la inicial repetida frente a 3 de 3 con inicial distinta, tanto
   con la librería como con un `GtkMenuBar` a mano). Por eso las
   muestras escriben `&Archivo` y `A&yuda`, y por eso el puente avisa
   por la salida de error en cuanto cuelga un popup que repite la
   inicial de otro: no es un error de ejecución (se puede ignorar),
   pero la barra no va a responder.
4. **`!=` es una comparación floja.** Con `SET EXACT OFF` (el valor por
   omisión), `x != ""` es **siempre `.F.`**: cualquier cadena se
   considera igual a la vacía. Las reglas son usar `==` para igualdad
   exacta, `!( a == b )` para desigualdad exacta, `Empty()` para
   «sin contenido», `Len()` para la longitud y `ValType( x ) != "C"`
   sin riesgo (un carácter contra uno). Para ordenar texto exacto, el
   bloque de comparación es: `IF a < b → -1`, `ELSEIF a == b → 0`,
   `ELSE → 1`.
5. **Editar una celda no reordena la vista.** El browse deja de
   enseñar el orden por el que se ordenó si se cambia el dato de esa
   columna; hay que llamar a `Ordenar( nCol )` (o pulsar la cabecera)
   cuando se quiera. `Anadir()` sí deja elegida la fila nueva, en la
   posición que le toca según el orden vigente.
6. **Un `ErrorBlock` que retorna no recupera.** Devolver del gestor
   de error produce «9001 Error recovery failure»; para seguir hay
   que romper: `ErrorBlock( { | oErr | Break( oErr ) } )` y capturar
   con `BEGIN SEQUENCE ... RECOVER USING ...`. Un `ErrorBlock` que
   sólo informa y devuelve vale para los avisos que no interrumpen,
   no para los que se esperan recuperar.
