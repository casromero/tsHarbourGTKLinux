# HarbGtkLin — contrato de la API (fase 0)

Documento corto que se congela en la fase 0. Las fases siguientes lo
cumplen: cambiar cualquiera de estos puntos exige una decisión
documentada en `HarbGtkLin.md`.

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

## 7. Sintaxis de comandos (congelada aquí, implementada en la fase 1)

Los comandos se expanden en llamadas a las clases; no llevan lógica
propia. Ningún `.prg` de aplicación incluye `gtk/gtk.h` ni maneja
punteros a widgets.

```harbour
#include "harbgtk.ch"

DEFINE WINDOW oWnd ;
   [ TITLE <cTitle> ] ;
   [ FROM <nTop>, <nLeft> TO <nBottom>, <nRight> | SIZE <nRows>, <nCols> ]

   DEFINE BUTTON  oBtn  OF oWnd PROMPT <cText>  ACTION <bAction>
   DEFINE SAY     oSay  OF oWnd PROMPT <cText>  [ AT <nRow>, <nCol> ]
   DEFINE GET     oGet  OF oWnd VAR <xVar>      [ PICTURE <cPict> ] ;
                [ VALID <bValid> ]

ACTIVATE WINDOW oWnd

DEFINE DIALOG oDlg [ TITLE <cTitle> ] [ SIZE <nRows>, <nCols> ]
   ...
ACTIVATE DIALOG oDlg [ <bClose> ]
```

Los comandos de la fase 1 se congelan con esta forma:
`DEFINE DIALOG`, `ACTIVATE DIALOG`, `MsgInfo`, `MsgStop`, `MsgYesNo`.
La fase 2 añade `DEFINE MENU`, `DEFINE POPUP`, `DEFINE MENUITEM`,
`ACTIVATE MENU`. Una clase o un comando entra cuando el ejemplo de su
fase lo usa.

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
