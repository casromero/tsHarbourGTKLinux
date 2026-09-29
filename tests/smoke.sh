#!/usr/bin/env bash
#
# smoke.sh — prueba gráfica de la fase 0, sin mirar la pantalla
#
# Bajo un único Xvfb comprueba que:
#   1. las pruebas de consola pasan;
#   2. samples/01_ventana abre, el título llega al servidor X, se cierra
#      con WM_DELETE (lo mismo que hace el gestor de ventanas al pulsar
#      el aspa) y el proceso termina con código 0;
#   3. el codeblock bClose cancela el primer cierre y acepta el segundo.
#
# WSLg activa Wayland y GTK3 prefiere ese backend; para que la ventana
# aparezca en el Xvfb hay que quitar WAYLAND_DISPLAY y fijar GDK_BACKEND.
#
# Uso:  make smoke      (desde la raíz del proyecto)
# Sale con 0 si todo pasa, 1 si algo falla.
#
# Licencia: LGPL-3.0-or-later

set -u

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
LOG="$ROOT/tests/.logs"
XCLOSE="$ROOT/tests/xclose"
SCREEN="-screen 0 1280x1024x24"

mkdir -p "$LOG"
fallos=0

ok()    { echo "  [ok]    $1"; }
fallo() { echo "  [FALLO] $1"; fallos=$(( fallos + 1 )); }

# ------------------------------------------------------------------
# modo gráfico: este proceso se lanza dentro de xvfb-run (make smoke)
# ------------------------------------------------------------------
if [ "${1:-}" = "--x11" ]; then

   unset WAYLAND_DISPLAY
   export GDK_BACKEND=x11

   echo "HarbGtkLin — prueba gráfica (DISPLAY=$DISPLAY, backend X11)"

   # grafica <nombre> <programa> <título> <envíos> <salida esperada>
   grafica() {
      local nombre="$1" bin="$2" titulo="$3" envios="$4" texto="$5"
      local codigo

      if [ ! -x "$bin" ]; then
         fallo "$nombre: no existe $bin (¿ make sample / make test ?)"
         return
      fi

      env BIN="$bin" TITULO="$titulo" ENVIOS="$envios" NOMBRE="$nombre" \
          LOGDIR="$LOG" XCLOSE="$XCLOSE" bash -c '
         set -u

         "$BIN" > "$LOGDIR/$NOMBRE.bin.log" 2>&1 &
         pid=$!

         if ! "$XCLOSE" -t "$TITULO" -w 20 -n "$ENVIOS" -d 700 \
                 > "$LOGDIR/$NOMBRE.x.log" 2>&1; then
            kill "$pid" 2>/dev/null
            wait "$pid" 2>/dev/null
            exit 1
         fi

         for i in $( seq 1 200 ); do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.1
         done

         if kill -0 "$pid" 2>/dev/null; then
            echo "el proceso no terminó después de cerrar la ventana"
            kill -9 "$pid" 2>/dev/null
            wait "$pid" 2>/dev/null
            exit 3
         fi

         wait "$pid"
      ' > "$LOG/$nombre.rc.log" 2>&1
      codigo=$?

      if [ "$codigo" -ne 0 ]; then
         fallo "$nombre (salida $codigo)"
         sed 's/^/          /' "$LOG/$nombre.rc.log"
         [ -f "$LOG/$nombre.bin.log" ] && sed 's/^/          /' "$LOG/$nombre.bin.log"
         [ -f "$LOG/$nombre.x.log" ] && sed 's/^/          /' "$LOG/$nombre.x.log"
         return
      fi

      if ! grep -q "$titulo" "$LOG/$nombre.x.log" 2>/dev/null; then
         fallo "$nombre: el título «$titulo» no apareció en el servidor X"
         sed 's/^/          /' "$LOG/$nombre.x.log"
         return
      fi

      if ! grep -q "$texto" "$LOG/$nombre.bin.log" 2>/dev/null; then
         fallo "$nombre: falta la salida «$texto»"
         sed 's/^/          /' "$LOG/$nombre.bin.log"
         return
      fi

      ok "$nombre"
   }

   # la muestra: abre, se ve el título, se cierra y termina
   grafica 01_ventana \
           "$ROOT/samples/01_ventana/01_ventana" \
           "Gestión de clientes" 1 "Ventana cerrada"

   # bClose cancela el primer cierre y acepta el segundo
   grafica cierre_cancelado \
           "$ROOT/tests/cierre_cancelado" \
           "Cierre cancelado" 2 "cierre_cancelado: OK"

   if [ "$fallos" -eq 0 ]; then
      echo "smoke gráfico: todo correcto"
      exit 0
   fi

   echo "smoke gráfico: $fallos fallo(s). Log en $LOG"
   exit 1
fi

# ------------------------------------------------------------------
# modo normal: pruebas de consola y después un único Xvfb
# ------------------------------------------------------------------
echo "HarbGtkLin — smoke test (fase 0)"

if "$ROOT/tests/coord_test" > "$LOG/coord_test.log" 2>&1; then
   ok "coord_test (consola)"
else
   fallo "coord_test (consola)"
   sed 's/^/          /' "$LOG/coord_test.log"
fi

if xvfb-run -s "$SCREEN" "$0" --x11; then
   ok "pruebas gráficas bajo Xvfb"
else
   fallo "pruebas gráficas bajo Xvfb"
fi

if [ "$fallos" -eq 0 ]; then
   echo "smoke: todo correcto"
   exit 0
fi

echo "smoke: $fallos fallo(s). Log en $LOG"
exit 1
