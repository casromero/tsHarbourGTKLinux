#!/usr/bin/env bash
#
# smoke.sh — prueba gráfica de las fases 0 y 1, sin mirar la pantalla
#
# Bajo un único Xvfb comprueba que:
#   1. las pruebas de consola pasan;
#   2. samples/01_ventana abre, el título llega al servidor X, se cierra
#      con WM_DELETE (lo mismo que hace el gestor de ventanas al pulsar
#      el aspa) y el proceso termina con código 0;
#   3. el codeblock bClose cancela el primer cierre y acepta el segundo;
#   4. las cajas de mensaje se abren y se cierran con el aspa
#      (tests/mensajes);
#   5. el formulario de la fase 1: con Tab el foco no sale de un campo
#      vacío, el título del diálogo registra cada validación, el sí/no
#      al salir se cancela la primera vez y los valores siguen en las
#      variables Harbour (tests/formulario);
#   6. samples/02_alta_cliente: se teclea en el campo, el aspa del
#      diálogo pregunta y se contesta con Intro.
#
# tests/xclose y tests/xkey hacen de gestor de ventanas: bajo Xvfb no
# hay ninguno, así que ellas envían el aspa, las teclas y el foco de
# entrada (con -t sólo se da el foco).
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
XKEY="$ROOT/tests/xkey"
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

   # ------------------------------------------------------------ ayudas
   # Son las que hacen de gestor de ventanas: esperan ventanas, mandan
   # el aspa, mandan teclas (xkey da antes el foco a la ventana).

   # espera <segundos> <título> — hasta que haya una ventana así
   espera() {
      local seg="$1" texto="$2" i
      for i in $( seq 1 $(( seg * 10 )) ); do
         if "$XCLOSE" -l 2>/dev/null | grep -qF "$texto"; then
            return 0
         fi
         sleep 0.1
      done
      echo "no apareció la ventana «$texto» en ${seg}s"
      return 1
   }

   # titulo <subcadena> — primer título que contiene la subcadena
   titulo() {
      "$XCLOSE" -l 2>/dev/null | grep -m1 -F "$1" || true
   }

   # espera_cambio <subcadena> <título anterior> — que el título cambie
   espera_cambio() {
      local sub="$1" antes="$2" i ahora
      for i in $( seq 1 150 ); do
         ahora=$( titulo "$sub" )
         if [ "$ahora" != "$antes" ]; then
            return 0
         fi
         sleep 0.1
      done
      echo "el título no cambió (seguía en «$antes»)"
      return 1
   }

   # cierra <título> — WM_DELETE, como el aspa de la barra de título
   cierra() {
      "$XCLOSE" -t "$1" -n 1 -d 500
   }

   # tecla <tecla> <título> — xkey da el foco y manda la tecla
   tecla() {
      "$XKEY" -k "$1" -t "$2" -w 12
   }

   # limpia <título> — cierra hasta 4 ventanas con ese título (si las
   # hay; no falla si no las hay)
   limpia() {
      local n=0
      while [ "$n" -lt 4 ]; do
         if "$XCLOSE" -t "$1" -n 0 -d 100 2>/dev/null |
            grep -q "ventana encontrada"; then
            cierra "$1" > /dev/null 2>&1 || true
            sleep 0.6
         else
            break
         fi
         n=$(( n + 1 ))
      done
      return 0
   }

   # contesta <título> [intentos] — Intro hasta que la ventana se vaya
   contesta() {
      local texto="$1" veces="${2:-3}" i
      for i in $( seq 1 "$veces" ); do
         limpia "Error"
         if ! abierta "$texto"; then
            return 0
         fi
         "$XKEY" -k Return -t "$texto" -w 12 > /dev/null 2>&1 || true
         sleep 1
      done
      if abierta "$texto"; then
         echo "la ventana «$texto» no se contestó con Intro"
         return 1
      fi
      return 0
   }

   # abierta <título> — 0 si hay una ventana con ese título
   abierta() {
      "$XCLOSE" -l 2>/dev/null | grep -qF "$1"
   }

   # ------------------------------------------------------------- grafica
   # grafica <nombre> <programa> <título> <envíos> <salida esperada>
   grafica() {
      local nombre="$1" bin="$2" titulo_="$3" envios="$4" texto="$5"
      local codigo

      if [ ! -x "$bin" ]; then
         fallo "$nombre: no existe $bin (¿ make sample / make test ?)"
         return
      fi

      env BIN="$bin" TITULO="$titulo_" ENVIOS="$envios" NOMBRE="$nombre" \
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

      if ! grep -q "$titulo_" "$LOG/$nombre.x.log" 2>/dev/null; then
         fallo "$nombre: el título «$titulo_» no apareció en el servidor X"
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

   # ------------------------------------------------------------ secuencia
   # secuencia <nombre> <programa> <pasos> <salida esperada>
   #
   # Lanza el programa y ejecuta los pasos (una cadena de comandos de
   # bash con las ayudas de arriba). Los pasos corren con set -e: el
   # primero que falle corta la secuencia. Después se espera a que el
   # programa termine y se comprueba su código de salida y su salida.
   secuencia() {
      local nombre="$1" bin="$2" pasos="$3" texto="$4"
      local codigo salida pid i

      if [ ! -x "$bin" ]; then
         fallo "$nombre: no existe $bin (¿ make sample / make test ?)"
         return
      fi

      "$bin" > "$LOG/$nombre.bin.log" 2>&1 &
      pid=$!

      if ( set -e; eval "$pasos" ) > "$LOG/$nombre.pasos.log" 2>&1; then
         codigo=0
      else
         codigo=1
      fi

      # se le da medio minuto a que termine por su cuenta
      for i in $( seq 1 300 ); do
         if ! kill -0 "$pid" 2>/dev/null; then
            break
         fi
         sleep 0.1
      done

      if kill -0 "$pid" 2>/dev/null; then
         fallo "$nombre: el proceso no terminó"
         kill -9 "$pid" 2>/dev/null
         wait "$pid" 2>/dev/null
         sed 's/^/          /' "$LOG/$nombre.pasos.log"
         return
      fi

      wait "$pid"
      salida=$?

      if [ "$codigo" -ne 0 ]; then
         fallo "$nombre: falló un paso de la secuencia"
         sed 's/^/          /' "$LOG/$nombre.pasos.log"
         sed 's/^/          /' "$LOG/$nombre.bin.log"
         return
      fi

      if [ "$salida" -ne 0 ]; then
         fallo "$nombre: salió con código $salida"
         sed 's/^/          /' "$LOG/$nombre.bin.log"
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

   # las tres cajas de mensaje, cada una se cierra con el aspa
   secuencia mensajes "$ROOT/tests/mensajes" \
      'espera 15 "Información"
       cierra  "Información"
       espera 15 "Error"
       cierra  "Error"
       espera 15 "Confirme"
       cierra  "Confirme"' \
      "mensajes: OK"

   # formulario: dos Tab con validación, el sí/no al salir y los valores
   secuencia formulario "$ROOT/tests/formulario" \
      'espera 15 "Formulario de prueba"
       antes=$( titulo "Formulario" )
       tecla Tab "Formulario"
       espera_cambio "Formulario" "$antes"
       antes=$( titulo "Formulario" )
       tecla Tab "Formulario"
       espera_cambio "Formulario" "$antes"
       cierra  "Formulario de prueba"
       espera 15 "Confirme"
       cierra  "Confirme"
       espera 15 "Formulario de prueba"
       cierra  "Formulario de prueba"' \
      "formulario: OK"

   # la muestra: se teclea en el campo, el aspa pregunta y se contesta
   secuencia alta_cliente "$ROOT/samples/02_alta_cliente/02_alta_cliente" \
      'espera 15 "Alta de cliente"
       tecla a "Alta de cliente"
       tecla n "Alta de cliente"
       tecla a "Alta de cliente"
       cierra  "Alta de cliente"
       espera 15 "Confirme"
       contesta "Confirme" 3' \
      "Nombre    : 'ana'"

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
echo "HarbGtkLin — smoke test (fases 0 y 1)"

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
