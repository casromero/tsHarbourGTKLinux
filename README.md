# HarbGtkLin

Librería de interfaz de escritorio para Linux escrita en Harbour, al
estilo de FiveWin: clases `T*` y comandos `DEFINE` / `ACTIVATE` por
encima de **GTK 3**. El programador escribe `.prg`; GTK queda detrás de
un puente en C (`HB_FUNC`), de modo que ningún `.prg` de aplicación
incluye `gtk/gtk.h` ni maneja punteros a widgets.

**Estado: fase 5 (solidez: pruebas de los comandos sin pantalla,
revisión de fugas abriendo y cerrando ventanas en bucle, empaquetado
y guía de portación), más dos ampliaciones posteriores: maximizar,
minimizar y restaurar la ventana (`MAXIMIZED`), con los botones
correspondientes en la barra, y centrar diálogos (`CENTER`).** Contrato de la API
congelado en [`docs/api-fase0.md`](docs/api-fase0.md): enmiendas de la
fase 1 en su §10, notas de la fase 2 en su §11, notas de la fase 3 en
su §12, notas de la fase 4 en su §13, notas de la fase 5 en su §14 y
notas de las ampliaciones en sus §15 y §16.
Para venir de FiveWin está [`docs/portacion.md`](docs/portacion.md)
(tabla de clases cubiertas y de clases que no existen) y para enlazar
un programa ajeno [`docs/enlace.md`](docs/enlace.md) (va dentro del
paquete de `make package`). La hoja de ruta completa vive en
`HarbGtkLin.md` (raíz del árbol de FiveWin, como referencia).

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
make sample     # samples/01_ventana a 05_app
make test       # pruebas de consola
make smoke      # prueba gráfica completa bajo Xvfb
make package    # dist/harbgtklin-fase5.tar.gz (.so, .ch y nota)
make clean
```

`make smoke` ejecuta, sin mirar la pantalla:

1. las pruebas de consola (`coord_test`, `texto_test`, `tabla_test`,
   `imagen_test`, `impresion_test` y `comandos_test`, esta última de
   la fase 5: los comandos con un padre sin pantalla);
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
   barra sigue respondiendo tras la primera elección;
9. la muestra 05 (fase 4): el menú lleva a los tres diálogos del
   selector (fichero, guardar y carpeta: se abren y se cierran con el
   aspa), con la ventana secundaria abierta la principal sigue respondiendo —una Flecha
   abajo cambia su título: ventanas no modales—, el panel cambia de
   pestaña con `Tab` y `Ctrl+Siguiente`, el «Acerca de» se abre desde
   Ayuda y Salir cierra todo; la salida trae los autochequeos previos
   (PDF exportado, nodo inicial del árbol y pestaña final);
10. `tests/fugas_test.prg` (fase 5): dos familias de ventana se abren
    y se cierran en bucle —cada una se cierra sola con su
    temporizador— y tras cada ciclo las cuatro cuentas del puente
    (ventanas, controles, relojes y grips de GC) vuelven a las de
    partida; si un codeblock se quedara sujeto, los grips crecerían
    sin parar. Al final también se crean y destruyen ventanas sin
    activarlas;
11. `tests/maximizar.prg` (ampliación): la cláusula `MAXIMIZED` deja
    la ventana por maximizada en cuanto se muestra —una ventana
    escrita sin ella, no—, los cuatro métodos de estado (`Maximize`,
    `Minimize`, `Restore` e `IsMaximized`) se llaman en cada disparo
    y también sobre la ventana ya destruida, al terminar las cuentas
    siguen a cero y el layout de decoración de GTK acaba con los
    botones de maximizar y minimizar (donde la sesión sólo trae la X,
    el arranque de la decoración la completa);
12. `tests/centrado.prg` (ampliación): la cláusula `CENTER` de
    `DEFINE DIALOG` centra el diálogo en el monitor —gana sobre
    `FROM..TO`—, un diálogo sin cláusula ya sale centrado por defecto
    y el de control con `FROM..TO` y sin `CENTER` se queda donde se
    pidió (sólo significa algo en X11: en Wayland el protocolo no
    deja que el cliente coloque un toplevel; ver §16.4 del contrato).

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
                                   temporizador, pestañas, página, árbol,
                                   caja, selector de fichero, impresión,
                                   fuentes)
source/rtl/            arranque, aplicación, bucle (TApplication), coordenadas,
                       mensajes, conversión a texto
source/gtk/            puente C  (hbgtk_*.c) contra GTK 3
samples/01_ventana/    un programa por fase
samples/02_alta_cliente/
samples/03_menu_lista/ fase 2: menú, barra, lista, browse y temporizador
samples/04_mantenimiento/  fase 3: tabla DBF, orden, edición de celda,
                       alta con el menú e imágenes
samples/05_app/        fase 4: aplicación de ejemplo con menú, ficha en
                       pestañas, árbol de categorías y listado a PDF
tests/                 pruebas de consola (coord_test, texto_test,
                       tabla_test, imagen_test, impresion_test,
                       comandos_test) y smoke gráfico (fugas_test,
                       maximizar, centrado, cierre_cancelado,
                       formulario, mensajes, xclose, xkey)
docs/api-fase0.md      contrato de la API congelado (§10 enmiendas de la
                       fase 1, §11 notas de la fase 2, §12 notas de la
                       fase 3, §13 notas de la fase 4, §14 notas de la
                       fase 5, §15 notas de la ampliación MAXIMIZED,
                       §16 notas de la ampliación CENTER)
docs/portacion.md      guía corta de portación desde FiveWin
docs/enlace.md         nota de cómo enlazar un programa ajeno (dentro
                       del paquete de make package)
dist/                  paquete (make package; no se versiona)
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
plano, útil para volcarla a un log. Ajuste el rpath a la posición
relativa de la `.so` respecto al ejecutable (`$ORIGIN/../lib` si el
binario queda un nivel por debajo, `$ORIGIN/lib` si comparten
directorio).

Para llevarse sólo lo necesario —`.so`, `.ch` y la nota de enlace
completa, con un ejemplo mínimo probado de punta a punta— está
`make package`, que deja `dist/harbgtklin-fase5.tar.gz`. La nota es
[`docs/enlace.md`](docs/enlace.md).

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
