# Qué hay de nuevo

Registro de los cambios del proyecto, ordenado por fecha (lo más
reciente primero). Cada entrada agrupa lo que se hizo ese día y
termina con el identificador del commit, cuando existe.

Formato: al añadir algo, se crea una sección nueva con la fecha y se
añade al principio del fichero. Nada se reescribe de las anteriores.

---

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

*Pendiente de la fase 1: `TButton`, `TSay`, `TGet`, `TCheckBox`,
`TRadio`, `TComboBox`, `TGroup`, `TDialog`, `MsgInfo/MsgStop/MsgYesNo`
y los comandos `DEFINE`/`ACTIVATE`, con el ejemplo del alta de cliente.*
