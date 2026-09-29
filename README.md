# HarbGtkLin

Librería de interfaz de escritorio para Linux escrita en Harbour, al
estilo de FiveWin: clases `T*` y comandos `DEFINE` / `ACTIVATE` por
encima de **GTK 3**. El programador escribe `.prg`; GTK queda detrás de
un puente en C (`HB_FUNC`), de modo que ningún `.prg` de aplicación
incluye `gtk/gtk.h` ni maneja punteros a widgets.

**Estado: fase 0 (cimientos).** Contrato de la API congelado en
[`docs/api-fase0.md`](docs/api-fase0.md). La hoja de ruta completa vive
en `HarbGtkLin.md` (raíz del árbol de FiveWin, como referencia).

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
make sample     # samples/01_ventana/01_ventana
make test       # pruebas de consola
make smoke      # prueba gráfica completa bajo Xvfb
make clean
```

`make smoke` ejecuta, sin mirar la pantalla:

1. las pruebas de consola (`tests/coord_test.prg`);
2. la muestra: abre, el título —con acento, para probar UTF-8— llega
   al servidor X, se cierra con `WM_DELETE_WINDOW` (lo mismo que hace
   el gestor de ventanas al pulsar el aspa) y el proceso termina con
   código 0;
3. `tests/cierre_cancelado.prg`: el primer cierre lo cancela `bClose`
   con `.F.` y el segundo se acepta.

Los registros quedan en `tests/.logs/`.

Para ver la ventana en el escritorio de Windows (WSLg):

```bash
samples/01_ventana/01_ventana
```

Ciérrala con el aspa de la barra de título: el proceso debe terminar y
devolver el prompt.

## Qué contiene cada directorio

```
include/harbgtk.ch     comandos y constantes
source/classes/        clases T*  (TWindow)
source/rtl/            arranque, aplicación, bucle (TApplication), coordenadas
source/gtk/            puente C  (hbgtk_*.c) contra GTK 3
samples/01_ventana/    un programa por fase
tests/                 pruebas de consola y smoke gráfico
docs/api-fase0.md      contrato de la API congelado en la fase 0
Makefile               hbmk2 + gcc + pkg-config
```

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
