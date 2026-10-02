# Portar desde FiveWin

Guía corta para quien tiene código FiveWin de Windows y lo quiere pasar
a HarbGtkLin (Linux, GTK 3). El proyecto no copia FiveWin entera:
cubre lo que la hoja de ruta (fases 0 a 5) y esta es la tabla de lo
que hay, de lo que no, y de lo que cambia de comportamiento.

## Arranque

- El include es `#include "harbgtk.ch"` (en lugar de `fivewin.ch`).
- No hay `SET PROCEDURE`, ni `REQUEST`, ni DLLs: la `.so` lleva ya
  dentro todas las clases y el puente C.
- No hay que crear aplicación ni arrancar nada a mano: basta con
  `DEFINE WINDOW` y `ACTIVATE WINDOW`. El arranque de GTK ocurre solo
  al crear la primera ventana (`HgtkApplication()` lo hace por
  dentro). La línea de compilación está en `docs/enlace.md`.

## Comandos: tabla de equivalencias

El orden de las cláusulas es siempre el mismo: `OF`, `PROMPT`/`VAR`,
`AT`, `SIZE`, `ACTION`/`VALID`.

| FiveWin | HarbGtkLin | notas |
|---|---|---|
| `@ f,c SAY ...` | `DEFINE SAY o OF oWnd PROMPT "..." AT f,c SIZE h,w` | sin cláusulas de color ni picture |
| `@ f,c GET ... VAR` | `DEFINE GET o OF oWnd VAR v AT f,c SIZE h,w [VALID {|| }]` | sin `PICTURE` ni `VISUAL` |
| `@ f,c BUTTON ... ACTION` | `DEFINE BUTTON o OF oWnd PROMPT "&Texto" AT f,c SIZE h,w ACTION {|| }` | `oBoton:Click()` evalúa el bloque a mano |
| `@ f,c CHECK ...` | `DEFINE CHECKBOX o OF oWnd VAR l PROMPT "..." ...` | |
| `@ f,c RADIO ...` | `DEFINE RADIO o OF oWnd VAR n OPTION 2 PROMPT "..." ...` | |
| `@ f,c COMBOBOX ...` | `DEFINE COMBOBOX o OF oWnd VAR n ITEMS aCadenas ...` | |
| `@ f,c LISTBOX ...` | `DEFINE LISTBOX o OF oWnd VAR n ITEMS aCadenas ... ACTION {|| }` | la acción va al cambiar de fila |
| `@ f,c GROUP ...` | `DEFINE GROUP o OF oWnd PROMPT "..." ...` | |
| cajas / `@ ... BOX` | `DEFINE BOX o OF oWnd [HORIZONTAL] ...` | caja de empaquetado: dentro, el orden es el de declaración y `AT` se ignora (fase 4) |
| `DEFINE WINDOW` + `ACTIVATE WINDOW` | igual, con `SIZE filas, columnas` | la ventana NO es modal: pueden haber dos vivas a la vez. `bCancel`/`bClose` devuelve `.F.` para cancelar el cierre, como en FiveWin |
| `DEFINE DIALOG` + `ACTIVATE DIALOG` | igual | modal: `ACTIVATE` espera a ÉSE diálogo |
| `DEFINE MENU` / `POPUP` / `MENUITEM` | iguales, todos con su `OF` (sin bloques de anidamiento) y `ACTIVATE MENU o` antes del `ACTIVATE WINDOW` | el mnemónico es `&x` |
| `DEFINE BAR` + botones | `DEFINE BAR o OF oWnd` y luego `DEFINE BUTTON ... OF oBar` sin `AT` ni `SIZE` | el orden es el de declaración |
| `DEFINE STATUS` | igual; texto con `oEstado:Value( "..." )` | |
| `DEFINE TIMER` | `DEFINE TIMER o OF oWnd INTERVAL nMs ACTION {|| }` + `ACTIVATE TIMER o` | nace parado |
| `GetFile()` / `cGetFile` | `TFileDialog():New( titulo, dir )` con `Open( mascara )`, `Save( mascara, nombre )` o `Directory()` | diálogo nativo de GTK |
| `Msg*()` | `MsgInfo()`, `MsgStop()`, `MsgYesNo()` | sólo dentro de `ACTIVATE` |
| impresión / informes | `TPrint():New(...)` con `AddLine()`, `Dialog()` o `ToFile( "listado.pdf", HGTK_PRINT_EXPORTA )` | sin motor de informes: el texto se acumula línea a línea |
| `TFont` | `TFont( "DejaVu Sans", 12, .T. )` | familia, tamaño, negrita, cursiva |
| `DEFINE IMAGE ... FILE` | igual | PNG |
| browse | `DEFINE BROWSE o OF oWnd VAR n FIELDS aCabeceras DATA aDatos [EDIT] ... ACTION {|| }` | `DATA` es array de arrays, o el de `TDataBase:Cargar()` |
| pestañas (`TTabs` de otros portes) | `DEFINE TABS o OF oWnd VAR nPag ... ACTION {|| }` + `DEFINE PAGE oP OF oTabs PROMPT "..."` | fase 4 |
| árbol (`TTree`) | `DEFINE TREE o OF oWnd VAR cRuta ITEMS aItems ... ACTION {|| }` | fase 4: `ITEMS` es array anidado de textos `{ texto, hijos }` y `VAR` guarda la ruta "Zona/nodo" |

## Clases que existen

| clase | para qué |
|---|---|
| `TApplication` | arranque de GTK; singleton por `HgtkApplication()` (interna) |
| `TWindow`, `TDialog` | ventana no modal y diálogo modal |
| `TControl` | base de todos los controles (interna) |
| `TButton`, `TSay`, `TGet`, `TCheckBox`, `TRadio`, `TComboBox` | los controles de siempre |
| `TGroup`, `TBox` | marco con título y caja de empaquetado |
| `TListBox`, `TBrowse` | lista y tabla (columnas ordenables y edición) |
| `TMenu`, `TPopup`, `TMenuItem`, `TBar`, `TStatus` | menú, submenús, barra de botones y barra de estado |
| `TTimer` | disparo periódico de un codeblock |
| `TImage` | imagen PNG en un control |
| `TDataBase` | DBF: `Use()`, `Cargar()`, `Guardar()`, `Anadir()`, `Close()` |
| `TTabs`, `TPage` | panel con pestañas |
| `TTree` | árbol de categorías con ruta en VAR |
| `TFileDialog` | selector de fichero y de carpeta con diálogo nativo |
| `TPrint` | impresión: diálogo de GTK o exportación a PDF |
| `TFont` | fuentes |

Y las funciones `MsgInfo()`, `MsgStop()`, `MsgYesNo()`,
`HgtkColToPx()`, `HgtkRowToPx()`, `HgtkSize()`, `HgtkTexto()` y
`HgtkCss()` (CSS mínimo por programa). El detalle de cada una está en
`docs/api-fase0.md`.

## Clases que NO existen

| de FiveWin | estado |
|---|---|
| splitter / `TSplitter` | no; a la lista de "sólo si una aplicación real lo pide" |
| calendario y selector de fecha | no, igual |
| editor de texto multilínea con deshacer (`TMemo`) | no: `TGet` es de una línea |
| iconos en bandeja del sistema | no |
| arrastrar y soltar (drag & drop) | no |
| temas claros y oscuros | no; sólo CSS mínimo con `HgtkCss()` |
| motor de informes (`TFixedReport`, plantillas, paginación) | no: sólo `TPrint`, que manda líneas a un diálogo o a un PDF |
| `TField`, `TDbf` con validación de campo, `PICTURE` en `GET` | no: los datos pasan por `TDataBase` y arrays |
| `TWBrowse` con extras (imágenes en celdas, textos de pie) | no: `TBrowse` cubre columnas ordenables, edición y los datos de `TDataBase` |
| gráficos (`TChart`, ...), FTP, sockets, activex, DLLs, API de Win32 | no |
| `SET KEY` (teclas de función globales) | no; los atajos son los mnemónicos de menú (`Alt+letra`) |

## Diferencias que hay que conocer

1. **Sólo dentro de `ACTIVATE` se espera a la interfaz.** Los
   `Msg*()`, los diálogos y las esperas funcionan dentro del bucle de
   `ACTIVATE`; fuera, el puente lanza un error recuperable. Mismo
   criterio que la hoja de ruta: nada de esperas fuera del bucle.
2. **Coordenadas.** `AT` y `SIZE` van en unidades de diálogo con un
   factor fijo de conversión (no píxeles crudos): la misma ventana
   calcula igual en cualquier pantalla.
3. **Temporizadores y menú.** El temporizador nace parado: hace falta
   `ACTIVATE TIMER`. El menú se cuelga con `ACTIVATE MENU` antes del
   `ACTIVATE WINDOW`.
4. **Mnemónicos.** `&x` se convierte en la marca de GTK (`_x`). Ojo
   con repetir la misma letra entre widgets visibles a la vez (una
   entrada de barra y un botón con la misma letra dejan a GTK sin
   responder a cada segundo `Alt+letra`).
5. **Errores de uso.** Los parámetros mal dados no matan el programa:
   suben como error recuperable (`ErrorBlock` + `BEGIN
   SEQUENCE...RECOVER`) y el mensaje trae la clase y el método
   (`"TGet:New: se esperaba un bloque de enlace (VAR)"`). No hay
   mensajes de Windows que sustituir.
6. **`??` dentro de un codeblock** no compila (límite de Harbour al
   escribir la expresión en línea): en los `ACTION` se usa `DevOut()`
   o se escribe fuera del bloque.
7. **Impresión sin plantillas.** `TPrint` acumula líneas
   (`AddLine()`) y luego `Dialog()` abre el diálogo de impresión de
   GTK o `ToFile( fichero, HGTK_PRINT_EXPORTA )` escribe un PDF; la
   paginación y las cabeceras se programan a mano.
8. **Datos.** `TDataBase` abre el DBF y lo pasa al browse con
   `Cargar()`; `Guardar()` y `Anadir()` escriben registro a registro.
   No hay capa de `TField` ni validaciones de campo.
9. **Cierre.** `bClose` devuelve `.F.` para cancelar el cierre, igual
   que en FiveWin; el resto de la vida de la ventana la decide
   `End()`.
