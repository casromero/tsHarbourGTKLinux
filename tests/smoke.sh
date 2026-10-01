#!/usr/bin/env bash
#
# smoke.sh — prueba gráfica de las fases 0 a 4, sin mirar la pantalla
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
#      diálogo pregunta y se contesta con Intro;
#   7. samples/03_menu_lista (fase 2): dos Flecha abajo cambian la fila
#      de la lista, que lleva al browse, y el menú Archivo/Salir se
#      abre con Alt+A y se elige con la «s»: la ventana se cierra sola
#      y en la salida queda la fila final y los disparos del
#      temporizador;
#   8. samples/04_mantenimiento (fase 3): Return abre la celda de la
#      fila 1, un código tecleado se guarda con Return en el fichero,
#      End lleva el cursor a la última fila y el menú Archivo se usa
#      dos veces seguidas (Añadir y después Salir), que es lo que
#      comprueba que la barra sigue respondiendo después de la
#      primera elección;
#   9. samples/05_app (fase 4): el menú lleva a los tres diálogos del
#      selector (fichero, guardar y carpeta: se abren y se cierran con
#      el aspa), con la ventana secundaria abierta la principal sigue respondiendo (una Flecha
#      abajo cambia su título: ventanas no modales), el panel cambia
#      de pestaña con Tab y Ctrl+Siguiente, el «Acerca de» se abre
#      desde Ayuda y Salir cierra la aplicación; la salida trae los
#      autochequeos previos (PDF exportado, selección inicial del
#      árbol y pestaña final).
#
# Las secuencias comprueban además que la salida no trae avisos de GTK
# (CRITICAL o WARNING), que serían algo mal hecho por el puente.
#
# tests/xclose y tests/xkey hacen de gestor de ventanas: bajo Xvfb no
# hay ninguno, así que ellas envían el aspa, las teclas y el foco de
# entrada (con -t sólo se da el foco; -m mantiene Alt, Ctrl o Shift
# pulsado mientras manda la tecla, que es como se llega a un menú).
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

   # tecla <tecla> <título> — xkey da el foco y manda la tecla. Con
   # "alt+a" (o ctrl+, shift+) mantiene el modificador pulsado, que es
   # como se llega a un menú.
   tecla() {
      case "$1" in
      *+*) "$XKEY" -m "${1%%+*}" -k "${1#*+}" -t "$2" -w 12 ;;
      *)   "$XKEY" -k "$1" -t "$2" -w 12 ;;
      esac
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
   # (la salida puede llevar varios textos separados por «|»)
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

      local partes parte
      IFS='|' read -r -a partes <<< "$texto"
      for parte in "${partes[@]}"; do
         if ! grep -q "$parte" "$LOG/$nombre.bin.log" 2>/dev/null; then
            fallo "$nombre: falta la salida «$parte»"
            sed 's/^/          /' "$LOG/$nombre.bin.log"
            return
         fi
      done

      # un aviso de GTK en la salida es algo mal hecho por el puente:
      # el programa funciona, pero deja la protesta del sistema
      if grep -qE "(Gtk|Gdk|GLib)[-_].*(WARNING|CRITICAL|ERROR)" \
              "$LOG/$nombre.bin.log" 2>/dev/null; then
         fallo "$nombre: avisos de GTK en la salida"
         grep -E "(Gtk|Gdk|GLib)[-_].*(WARNING|CRITICAL|ERROR)" \
              "$LOG/$nombre.bin.log" | sed 's/^/          /'
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
   # programa termine y se comprueba su código de salida y su salida,
   # que puede llevar varios textos separados por «|» (todos tienen
   # que aparecer: aquí el «|» sólo separa, no es un "o" de la
   # expresión regular).
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

      local partes parte
      IFS='|' read -r -a partes <<< "$texto"
      for parte in "${partes[@]}"; do
         if ! grep -q "$parte" "$LOG/$nombre.bin.log" 2>/dev/null; then
            fallo "$nombre: falta la salida «$parte»"
            sed 's/^/          /' "$LOG/$nombre.bin.log"
            return
         fi
      done

      # un aviso de GTK en la salida es algo mal hecho por el puente:
      # el programa funciona, pero deja la protesta del sistema
      if grep -qE "(Gtk|Gdk|GLib)[-_].*(WARNING|CRITICAL|ERROR)" \
              "$LOG/$nombre.bin.log" 2>/dev/null; then
         fallo "$nombre: avisos de GTK en la salida"
         grep -E "(Gtk|Gdk|GLib)[-_].*(WARNING|CRITICAL|ERROR)" \
              "$LOG/$nombre.bin.log" | sed 's/^/          /'
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

   # la muestra de la fase 2: dos Flecha abajo cambian la fila de la
   # lista (que lleva al browse) y el menú Archivo/Salir, abierto con
   # Alt+A, cierra la ventana con la «s». La fila final en la salida
   # prueba el recorrido del teclado; que salga con 0 prueba los
   # controles previos (menú, barra, sincronización) y el temporizador,
   # que sólo puede disparar dentro de ACTIVATE.
   secuencia menu_lista "$ROOT/samples/03_menu_lista/03_menu_lista" \
      'espera 15 "Clientes de prueba"
       tecla Down "Clientes de prueba"
       tecla Down "Clientes de prueba"
       sleep 2
       tecla alt+a "Clientes de prueba"
       sleep 1
       tecla s "Clientes de prueba"' \
      "Selección final: 3"

   # la muestra de la fase 3: Return abre la celda de la fila 1, el
   # código tecleado se guarda con Return en el fichero, End lleva el
   # cursor a la última fila y el menú Archivo se usa dos veces
   # seguidas (Añadir y después Salir). La segunda vuelta es la que
   # prueba que la barra sigue respondiendo tras la primera elección,
   # y lo de la fila final comprueba que Anadir() deja elegida la fila
   # nueva (15, la última, porque el código 0 sigue ordenando la 1
   # la primera).
   secuencia mantenimiento \
       "$ROOT/samples/04_mantenimiento/04_mantenimiento" \
      'espera 15 "Mantenimiento de clientes"
       tecla Return "Mantenimiento de clientes"
       tecla ctrl+a "Mantenimiento de clientes"
       tecla 0 "Mantenimiento de clientes"
       tecla Return "Mantenimiento de clientes"
       antes=$( titulo "Mantenimiento de clientes" )
       tecla End "Mantenimiento de clientes"
       espera_cambio "Mantenimiento de clientes" "$antes"
       antes=$( titulo "Mantenimiento de clientes" )
       tecla alt+a "Mantenimiento de clientes"
       sleep 1
       tecla a "Mantenimiento de clientes"
       espera_cambio "Mantenimiento de clientes" "$antes"
       tecla alt+a "Mantenimiento de clientes"
       sleep 1
       tecla s "Mantenimiento de clientes"' \
      "Fila 1: 0 Ana Barros|Altas: 1  Registros: 15  Fila final: 15|muestra04: OK"

   # la muestra de la fase 4: el menú lleva a los tres diálogos del
   # selector (se abren y se cierran con el aspa, que es como GTK
   # devuelve la cancelación), con la ventana secundaria abierta la
   # principal sigue respondiendo —una Flecha abajo cambia su título:
   # ahí están las ventanas no modales—, el panel cambia de pestaña
   # con Tab y Ctrl+Siguiente, el «Acerca de» se abre desde Ayuda y
   # Salir cierra todo. La salida trae los autochequeos previos a
   # ACTIVATE: el PDF exportado, el nodo inicial del árbol (se aplica
   # al mostrarse) y la pestaña final.
   secuencia aplicacion "$ROOT/samples/05_app/05_app" \
      'espera 15 "Aplicación de ejemplo"
       tecla alt+a "Aplicación de ejemplo"
       sleep 1
       tecla a "Aplicación de ejemplo"
       espera 15 "Elegir un fichero"
       cierra "Elegir un fichero"
       sleep 0.5
       tecla alt+a "Aplicación de ejemplo"
       sleep 1
       tecla e "Aplicación de ejemplo"
       espera 15 "Guardar listado"
       cierra "Guardar listado"
       sleep 0.5
       tecla alt+a "Aplicación de ejemplo"
       sleep 1
       tecla c "Aplicación de ejemplo"
       espera 15 "Elegir carpeta"
       cierra "Elegir carpeta"
       sleep 0.5
       tecla alt+a "Aplicación de ejemplo"
       sleep 1
       tecla n "Aplicación de ejemplo"
       espera 15 "Ventana secundaria"
       antes=$( titulo "Aplicación de ejemplo" )
       tecla Down "Aplicación de ejemplo"
       espera_cambio "Aplicación de ejemplo" "$antes"
       cierra "Ventana secundaria"
       sleep 0.5
       tecla Tab "Aplicación de ejemplo"
       sleep 0.5
       antes=$( titulo "Aplicación de ejemplo" )
       tecla ctrl+Next "Aplicación de ejemplo"
       espera_cambio "Aplicación de ejemplo" "$antes"
       tecla alt+y "Aplicación de ejemplo"
       sleep 1
       tecla a "Aplicación de ejemplo"
       espera 15 "Acerca de"
       cierra "Acerca de"
       sleep 0.5
       tecla alt+a "Aplicación de ejemplo"
       sleep 1
       tecla s "Aplicación de ejemplo"' \
      "muestra05: OK|Nodo inicial: Norte/0001 Aceros del Norte|Pestaña final: 2"

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
echo "HarbGtkLin — smoke test (fases 0 a 4)"

# consola <programa> — se ejecuta fuera de X, con lo que se comprueba
# el lado que no toca gráficas (coordenadas, texto, tabla, imagen)
consola() {
   local nom="$1"
   if ! [ -x "$ROOT/tests/$nom" ]; then
      fallo "$nom (consola): no existe (¿ make test ?)"
      return
   fi
   if "$ROOT/tests/$nom" > "$LOG/$nom.log" 2>&1; then
      ok "$nom (consola)"
   else
      fallo "$nom (consola)"
      sed 's/^/          /' "$LOG/$nom.log"
   fi
}

consola coord_test
consola texto_test
consola tabla_test
consola imagen_test
consola impresion_test

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
