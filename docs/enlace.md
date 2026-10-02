# Enlazar una aplicación a HarbGtkLin

Nota de enlace para quien recibe el paquete `dist/harbgtklin-fase5.tar.gz`
y no tiene este árbol de fuentes a mano.

## Qué hay dentro

```
harbgtklin-fase5/
├── lib/libharbgtklin.so     la librería (clases y puente ya compilados)
├── include/harbgtk.ch       los comandos DEFINE/ACTIVATE y las constantes
├── docs/enlace.md           esta nota
└── LICENSE                  LGPL-3.0-or-later
```

Los `.prg` de las clases están ya dentro de la `.so`: no hay que
compilar nada más. El `.ch` es el único fichero de include que hace
falta.

## Requisitos

- Harbour (`hbmk2` en el `PATH`); sólo hace falta para compilar su
  programa, no para ejecutarlo.
- GTK 3 en tiempo de ejecución (`libgtk-3-0` en Ubuntu/Debian, ya
  instalado en cualquier escritorio).
- X11 o Wayland: un display gráfico. En WSL2 con WSLg viene solo.

## Situar los ficheros

Descomprima el tarball donde quiera. Aquí se supone que queda así,
junto a su programa:

```
mi_proyecto/
├── miprimera.prg        su programa
├── lib/libharbgtklin.so
└── include/harbgtk.ch
```

## Compilar

```bash
hbmk2 miprimera.prg -iinclude -Llib -lharbgtklin \
   -ldflag+=-Wl,-rpath,'$ORIGIN/lib' \
   -ldflag+=-Wl,-rpath,$(hbmk2 --hbdirlib)
```

Qué hace cada parte:

| parte | para qué |
|---|---|
| `-iinclude` | encuentra `harbgtk.ch` (el valor va pegado: `-i` con espacio no lo coge `hbmk2`) |
| `-Llib -lharbgtklin` | enlaza contra `libharbgtklin.so` |
| `-rpath '$ORIGIN/lib'` | al ejecutar, busca la `.so` en `lib/` junto al programa, sin `LD_LIBRARY_PATH` (`$ORIGIN` es el directorio del ejecutable: si la `.so` queda en el padre, la ruta es `$ORIGIN/../lib`; si va al lado del ejecutable, `.`) |
| `-rpath $(hbmk2 --hbdirlib)` | idem con `libharbour.so` |
| `-gtcgi` (opcional) | salida de consola en texto plano, para volcarla a un log |

Si prefiere no usar rpath, la alternativa es exportar antes de
ejecutar:

```bash
export LD_LIBRARY_PATH="$(pwd)/lib:/usr/local/lib/harbour:$LD_LIBRARY_PATH"
```

## Ejemplo mínimo

```prg
/*
 * miprimera.prg — la ventana más pequeña con HarbGtkLin
 *
 * Compilar:  hbmk2 miprimera.prg -iinclude -Llib -lharbgtklin \
 *               -ldflag+=-Wl,-rpath,'$ORIGIN/lib' \
 *               -ldflag+=-Wl,-rpath,$(hbmk2 --hbdirlib)
 */

#include "harbgtk.ch"

FUNCTION Main()

   LOCAL oWnd

   DEFINE WINDOW oWnd TITLE "Mi primera ventana" SIZE 12, 40
   ACTIVATE WINDOW oWnd

RETURN NIL
```

`ACTIVATE` es el bucle de eventos: no vuelve hasta que la ventana se
cierre. Ahí dentro se evalúan las señales, los temporizadores y las
cajas de mensaje; fuera de `ACTIVATE` no se espera a la interfaz.

## Notas

- **`HGTK_FASE`** (`harbgtk.ch`) indica la fase de la librería. El
  empaquetado de esta fase lo deja en 5.
- **Errores de uso.** Los parámetros mal dados no abortan el
  programa: suben como error recuperable con el nombre de quien los
  dio (`"TGet:New: se esperaba un bloque de enlace (VAR)"`...), con
  el `ErrorBlock`/`BEGIN SEQUENCE...RECOVER` de siempre.
- **Sin símbolos de depuración.** La `.so` no lleva `-g`; los
  mensajes de error son el mapa.
- **Licencia.** LGPL-3.0-or-later: enlazado dinámico permitido (y
  obligatorio si redistribuye). La aplicación propia puede llevar la
  licencia que quiera.
- El detalle de comandos y clases está en `docs/api-fase0.md` del
  proyecto, y la guía de portación desde FiveWin en
  `docs/portacion.md`.
