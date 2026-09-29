# Qué hay de nuevo

Registro de los cambios del proyecto, ordenado por fecha (lo más
reciente primero). Cada entrada agrupa lo que se hizo ese día y
termina con el identificador del commit, cuando existe.

Formato: al añadir algo, se crea una sección nueva con la fecha y se
añade al principio del fichero. Nada se reescribe de las anteriores.

---

## 2026-09-29 — Fase 1: controles, diálogos y cajas de mensaje

Commit `4fab78c` (26 ficheros, 3.029 líneas).

- **Clases**: `TControl` (base con `Place/Move/Show/Hide/SetFocus` y
  `aControles`), `TButton`, `TSay`, `TGet`, `TCheckBox`, `TRadio`,
  `TComboBox`, `TGroup` y `TDialog`. `TWindow` pasa a ser contenedora
  (`AddControl`, `Move`, `InitVentana()` compartido con el diálogo).
- **Comandos**: `DEFINE WINDOW/DIALOG/BUTTON/SAY/GET/CHECKBOX/RADIO/
  COMBOBOX/GROUP` y `ACTIVATE DIALOG`, con el orden fijo de cláusulas
  `OF`, `PROMPT`/`VAR`, `AT`, `SIZE`, `ACTION`/`VALID`.
- **Puente C**: `hbgtk_ctrl.c` (GtkFixed, señales, validación) y
  `hbgtk_msg.c` (cajas de mensaje). Lista de controles vivos para
  comprobar la vida sin desreferenciar, igual que la de ventanas.
- **Validación difierida a un giro del bucle**: GTK avisa del
  `focus-out` también cuando sólo reorganiza el foco interno (al
  activarse la ventana, al abrirse una caja encima); si al bucle el
  campo sigue con el foco no se valida, así un campo vacío no lanza un
  aviso sin motivo. Si el bloque devuelve `.F.`, el foco se recupera
  con `g_idle_add` (hacerlo dentro del propio evento provocaba
  críticas de GLib-GObject).
- **Cierre de diálogos**: `bClose` es miembro de `TDialog` (se retira
  la cláusula `[ <bClose> ]` de `ACTIVATE DIALOG`); `HGtkDlgRun` hace
  un bucle sobre `GTK_RESPONSE_DELETE_EVENT` con la respuesta del
  usuario marcada por señal, así una caja anidada puede cancelar y el
  diálogo sigue abierto.
- **Cajas de mensaje**: botón afirmativo con foco y con el valor por
  omisión, de modo que `Intro` cierra la caja (y permite contestar
  desde las pruebas).
- **Muestra**: `samples/02_alta_cliente` (GET, CHECKBOX, COMBOBOX,
  RADIO sobre un grupo y botones con `ACTION {|| }`).
- **Pruebas**: `tests/formulario.prg` (validación con Tab, sí/no al
  salir y valores al cerrar) y `tests/mensajes.prg` (las tres cajas).
- **Helpers**: `xclose` con búsqueda por subcadena, `-l` (lista los
  títulos) y `-n 0` (sondeo); `xkey` nuevo: da el foco a la ventana
  con `XSetInputFocus` —bajo Xvfb no hay gestor de ventanas— y manda
  la tecla, con modo sólo-foco (`sin -k`).
- **smoke.sh**: `secuencia()` arranca el programa y ejecuta pasos con
  `set -e` (esperas por título, teclas, aspas, cierres); cubre
  `mensajes`, `formulario` y la muestra 02 además de lo de la fase 0.
- **Contrato**: `docs/api-fase0.md` §10 recoge las enmiendas de la
  fase (codeblocks literales en `ACTION`/`VALID`, sin cláusula de
  cierre en `ACTIVATE DIALOG`, sin `PICTURE`, orden de cláusulas).

## 2026-09-29 — Publicación en GitHub

- Clave SSH `ed25519` como *deploy key* con escritura para
  `github.com/casromero/tsHarbourGTKLinux.git` (tras descartar token y
  `gh` CLI).
- Identidad git local: `Carlos Romero <sistemaempresarialapp@gmail.com>`.
- Rama `main` publicada y sincronizada con `origin/main`.

## 2026-09-29 — Fase 0: cimientos

Commit `cddf943` (18 ficheros, 1.757 líneas).

- **Repositorio**: estructura `include/ source/classes/ source/gtk/
  source/rtl/ samples/ tests/ docs/`, `Makefile` como único punto de
  entrada (`make`, `make sample`, `make test`, `make smoke`,
  `make clean`).
- **Licencia**: LGPL-3.0-or-later, fijada antes del primer código
  público (GTK y GLib se enlazan en dinámico).
- **Empaquetado**: `lib/libharbgtklin.so` construido desde la fase 0,
  con `.prg` de clases.
- **Clases**: `TApplication` (único por proceso, `gtk_init_check` una
  sola vez) y `TWindow` (`New/Activate/End/Title/IsActive/IsAlive`,
  codeblock `bClose`).
- **Puente C**: `hbgtk_init.c`, `hbgtk_window.c`, `hbgtk_error.c`.
  Puntero opaco en `hWnd`, grip de GC para el propietario, lista de
  ventanas vivas para comprobar vida sin desreferenciar, errores con
  `hb_errRT_BASE` (nunca `abort`).
- **Coordenadas**: unidades de diálogo con factor fijo
  (`HGTK_PX_COLUMNA` = 8, `HGTK_PX_FILA` = 16), conversión en
  `source/rtl/coord.prg`.
- **Muestra**: `samples/01_ventana` («Gestión de clientes»), se cierra
  con el aspa y termina con código 0.
- **Pruebas**: `tests/coord_test.prg` (consola),
  `tests/cierre_cancelado.prg` (`bClose` cancela el primer cierre),
  `tests/smoke.sh` + `tests/xclose.c` (smoke gráfico bajo Xvfb,
  cierra con `WM_DELETE_WINDOW`, fuerza `GDK_BACKEND=x11` porque WSLg
  define `WAYLAND_DISPLAY`).
- **Documentación**: contrato congelado `docs/api-fase0.md` (coordenadas,
  `TApplication`, `TWindow`, eventos como codeblocks, `ACTIVATE`,
  sintaxis de comandos) y `README.md` con build, pruebas y notas de
  entorno.

---

*Estado: fase 1 completada (commit `4fab78c`). Pendiente de la fase 2:
`TMenu` y `TMenuItem` con barra de menú, barra de botones, `TListBox` y
`TBrowse` de solo lectura, timer con codeblock y barra de estado, con el
ejemplo de menú Archivo/Salir y una lista de registros de prueba.*
