# HarbGtkLin

Librería de interfaz de escritorio para Linux escrita en Harbour, al
estilo de FiveWin: clases `T*` y comandos `DEFINE` / `ACTIVATE` por
encima de **GTK 3**. El programador escribe `.prg`; GTK queda detrás de
un puente en C (`HB_FUNC`), de modo que ningún `.prg` de aplicación
incluye `gtk/gtk.h` ni maneja punteros a widgets.

**Estado: fase 3 (datos, browse editable e imágenes).** Contrato de la
API congelado en [`docs/api-fase0.md`](docs/api-fase0.md): enmiendas de
la fase 1 en su §10, notas de la fase 2 en su §11 y notas de la fase 3
en su §12. La hoja de ruta completa vive en `HarbGtkLin.md` (raíz del
árbol de FiveWin, como referencia).

## Requisitos

Ubuntu 24.04 LTS 64 bits en WSL2 (o cualquier distro con GTK 3, GCC y
Harbour compilado), con las herramientas de la sección 2 de la hoja de
ruta:

| Herramienta | Comprobación |
| --- | --- |
| GCC | `gcc --version` |
| GTK 3 | `pkg-config --modversion gtk+-3.0` |
| Harbour | `harbour -build`, `hbmk2 -build` |
| Entorno gráfico | `gtk3-demo` abre una ventana (WSLg) |
| Display virtual | `xvfb-run -a gtk3-demo --help` termina sin error |

## Construir y probar

```bash
cd ~/src/harbgtklin
make            # lib/libharbgtklin.so
make sample     # samples/01_ventana a 04_mantenimiento
make test       # pruebas de consola
make smoke      # prueba gráfica completa bajo Xvfb
make clean
```

`make smoke` ejecuta, sin mirar la pantalla:

1. las pruebas de consola (`coord_test`, `texto_test`, `tabla_test` e
   `imagen_test`);
2. la muestra 01: abre, el título —con acento, para probar UTF-8— llega
   al servidor X, se cierra con `WM_DELETE_WINDOW` (lo mismo que hace
   el gestor de ventanas al pulsar el aspa) y el proceso termina con
   código 0;
3. `tests/cierre_cancelado.prg`: el primer cierre lo cancela `bClose`
   con `.F.` y el segundo se acepta;
4. `tests/mensajes.prg`: `MsgInfo`, `MsgStop` y `MsgYesNo`, cada una
   cerrada con el aspa (el sí/no devuelve `.F.` al cerrarlo así);
5. `tests/formulario.prg`: con `Tab` el foco no sale de un campo vacío,
   el título del diálogo lleva un número que crece con cada
   validación, el sí/no al salir se cancela la primera vez y los
   valores siguen en las variables Harbour con el diálogo ya
   destruido;
6. la muestra 02: se teclea en el campo, el aspa del diálogo pregunta y
   se contesta con `Intro`;
7. la muestra 03 (fase 2): dos Flecha abajo cambian la fila de la lista
   —que lleva al browse— y el menú Archivo/Salir, abierto con `Alt+A`,
   cierra la ventana con la `s`; en la salida quedan la fila final y
   los disparos del temporizador, que sólo pueden ocurrir dentro de
   `ACTIVATE`;
8. la muestra 04 (fase 3): `Return` abre la celda de la fila 1, el
   código tecleado se guarda con `Return` en el fichero, `End` lleva
   el cursor a la última fila y el menú Archivo se usa **dos veces
   seguidas** (Añadir y después Salir), que es lo que comprueba que la
   barra sigue respondiendo tras la primera elección.

Además, cada secuencia comprueba que la salida no trae avisos de GTK
(`WARNING` o `CRITICAL`), que serían algo mal hecho por el puente.

Los registros quedan en `tests/.logs/` (uno por programa y otro por los
pasos de cada secuencia).

Para ver la ventana en el escritorio de Windows (WSLg):

```bash
samples/02_alta_cliente/02_alta_cliente
```

Ciérrala con el aspa de la barra de título: el proceso debe terminar y
devolver el prompt.

## Qué contiene cada directorio

```
include/harbgtk.ch     comandos y constantes
source/classes/        clases T*  (ventana, diálogo, controles, menú,
                                   barra, lista, browse, tabla, imagen,
                                   temporizador)
source/rtl/            arranque, aplicación, bucle (TApplication), coordenadas,
                       mensajes, conversión a texto
source/gtk/            puente C  (hbgtk_*.c) contra GTK 3
samples/01_ventana/    un programa por fase
samples/02_alta_cliente/
samples/03_menu_lista/ fase 2: menú, barra, lista, browse y temporizador
samples/04_mantenimiento/  fase 3: tabla DBF, orden, edición de celda,
                       alta con el menú e imágenes
tests/                 pruebas de consola (coord_test, texto_test,
                       tabla_test, imagen_test) y smoke gráfico
                       (xclose, xkey)
docs/api-fase0.md      contrato de la API congelado (§10 enmiendas de la
                       fase 1, §11 notas de la fase 2, §12 notas de la fase 3)
Makefile               hbmk2 + gcc + pkg-config
```

## Un vistazo

```harbour
#include "harbgtk.ch"

FUNCTION Main()

   LOCAL oWnd, oMenu, oPop, oItem, oList, oBrw, oTimer
   LOCAL aNombres := { "Ana", "Luis", "Marta" }
   LOCAL aDatos   := { { 1, "Ana" }, { 2, "Luis" }, { 3, "Marta" } }
   LOCAL nSel     := 1

   DEFINE WINDOW oWnd TITLE "Clientes" SIZE 20, 60

      DEFINE MENU oMenu OF oWnd
      DEFINE POPUP oPop OF oMenu PROMPT "&Archivo"
      DEFINE MENUITEM oItem OF oPop PROMPT "&Salir" ACTION {|| oWnd:End() }
      ACTIVATE MENU oMenu

      DEFINE LISTBOX oList OF oWnd VAR nSel ITEMS aNombres ;
         AT 1, 1 SIZE 10, 20 ;
         ACTION {|| oBrw:Value( nSel ) }

      DEFINE BROWSE oBrw OF oWnd VAR nSel FIELDS { "Código", "Nombre" } ;
         DATA aDatos EDIT AT 1, 24 SIZE 10, 34 ;
         ACTION {|| oList:Value( nSel ) }

      DEFINE TIMER oTimer OF oWnd INTERVAL 1000 ;
         ACTION {|| oWnd:Title( "Clientes " + Time() ) }

   ACTIVATE TIMER oTimer
   ACTIVATE WINDOW oWnd

RETURN NIL
```

La lista y el browse guardan la fila elegida en la misma variable, de
modo que cambiar en uno mueve el otro. El menú se abre desde teclado
con `Alt+A` (el `&` de FiveWin es el mnemónico de GTK). El browse lleva
`EDIT`: `Return` abre la celda, se teclea y otro `Return` la guarda.

## Enlazar un programa propio

La librería es una biblioteca compartida más los `.prg` de las clases
(ya incluidos en la `.so`). Un programa externo necesita el include y
la `.so`:

```bash
hbmk2 miapp.prg -i~/src/harbgtklin/include \
   -L~/src/harbgtklin/lib -lharbgtklin \
   -ldflag+=-Wl,-rpath,'$ORIGIN/../lib' \
   -ldflag+=-Wl,-rpath,/usr/local/lib/harbour
```

`-gtcgi` en la línea de `hbmk2` deja la salida de consola en texto
plano, útil para volcarla a un log.

## Notas sobre el entorno

- **Wayland y Xvfb.** WSLg define `WAYLAND_DISPLAY` y GTK 3 prefiere
  ese backend, de modo que la ventana no llega al Xvfb. Las pruebas
  gráficas quitan `WAYLAND_DISPLAY` y fijan `GDK_BACKEND=x11`.
- **Xwayland de WSLg.** En el display real `:0`, con Weston como gestor
  de ventanas, el título de la ventana no se puede leer con
  `WM_NAME`/`_NET_WM_NAME` (le pasa también a `gtk3-demo`); `tests/xclose`
  sólo se usa contra Xvfb.
- **Sin `sudo`.** Los binarios llevan `rpath` a `libharbgtklin.so` y a
  `libharbour`, así que no hace falta `LD_LIBRARY_PATH` ni `ldconfig`.

## Licencia

LGPL-3.0-or-later: véase [`LICENSE`](LICENSE). GTK y GLib son LGPL y se
enlazan en dinámico contra las bibliotecas del sistema.
