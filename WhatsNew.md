# Qué hay de nuevo

Registro de los cambios del proyecto, ordenado por fecha (lo más
reciente primero). Cada entrada agrupa lo que se hizo ese día y
termina con el identificador del commit, cuando existe.

Formato: al añadir algo, se crea una sección nueva con la fecha y se
añade al principio del fichero. Nada se reescribe de las anteriores.

---

## 2026-10-01 — Fase 4: pestañas, árbol, cajas, selector, impresión y fuentes

Commit `5284955` (25 ficheros, 3.110 líneas nuevas).

- **Clases nuevas**: `TTabs`/`TPage` (GtkNotebook; la pestaña visible
  vive en su `VAR` y `ACTION` recibe el número), `TTree` (GtkTreeView
  de selección única; `Value()` devuelve la ruta de etiquetas unida con
  «/» y `HGtkTreeSelect()` lógico), `TBox` (modo de cajas mínimo,
  `HORIZONTAL` o vertical, sin repartir el espacio), `TFileDialog`
  (`Open`, `Save` y `Directory` sobre `GtkFileChooserNative`; devuelven
  cadena vacía al cancelar o al cerrar con el aspa), `TPrint`
  (`AddLine`, `LineCount`, `Clear`, `ToFile` y `Dialog` sobre
  `GtkPrintOperation`) y `TFont`. `TWindow` y `TControl` ganan
  `Font()` como GETSET (CSS en el contexto del widget, heredable a los
  hijos).
- **Comandos**: `DEFINE BOX`, `DEFINE TABS VAR` con `ACTION`,
  `DEFINE PAGE PROMPT` y `DEFINE TREE VAR ITEMS` con `ACTION`, con
  `HGTK_FASE 4` y las constantes `HGTK_PRINT_DIALOGO`/`HGTK_PRINT_EXPORTA`.
- **Puente C**: `hbgtk_tabs.c`, `hbgtk_tree.c`, `hbgtk_file.c`,
  `hbgtk_print.c` y `hbgtk_style.c` (más `hbgtk_ctrl.c` con los
  mnemónicos de caja y página). `HGtkMain` acepta ventana: itera el
  mismo contexto mientras ésta viva, así que `ACTIVATE` de una segunda
  ventana no bloquea la primera —ahí están las ventanas no modales—.
- **Medidas empíricas de la fase** (todas en GTK 3.24): `switch-page`
  se emite **antes** de cambiar la página, así que el número nuevo sale
  del argumento de la señal y no de `get_current_page()`; la selección
  inicial del árbol no se puede fijar antes de mostrar (queda
  pendiente para un `g_idle` posterior al `map`); `set_filter` se queda
  con la referencia flotante del filtro y un `g_object_unref` posterior
  provoca use-after-free al abrir el diálogo (banco f11); un mnemónico
  repetido entre widgets visibles hace que GtkWindow atienda sólo cada
  segunda `Alt+letra` (banco f15: `1,0,1,0` con la colisión,
  `1,1,1,1` sin ella — por eso el botón «Abrir fichero» de la muestra
  va sin `&`); los temporizadores nacen parados (hace falta
  `ACTIVATE TIMER`) y `ToFile("")`/`Dialog()` se rechazan en Harbour
  antes de tocar GTK.
- **Muestra**: `samples/05_app` con menú Archivo/Ayuda, ficha en
  pestañas, árbol de categorías sacado de un DBF creado en cada
  corrida, caja de botones, fuente y CSS, segunda ventana no modal y
  listado: el PDF se exporta antes de `ACTIVATE` y tiene que salir con
  cabecera `%PDF`. Autochequeos previos (fuente `Sans 9` en el árbol,
  CSS aceptado, ruta inicial del árbol, `Value(2)`/`Value(1)`
  sincronizados) y final `muestra05: OK`.
- **Pruebas**: `tests/impresion_test.prg` (consola: `TPrint`, `TFont`,
  `TFileDialog` y `TTree` con `ErrorBlock` que rompe, aviso de
  `HgtkCss`); el smoke recoge ya **cinco** pruebas de consola y añade
  la secuencia `aplicacion` (los tres diálogos del selector abiertos y
  cerrados con el aspa, ventana secundaria no modal —una Flecha abajo
  en la principal la sigue moviendo—, cambio de pestaña con
  `Tab`+`Ctrl+Siguiente`, «Acerca de» y `Salir`).
- **Contrato**: `docs/api-fase0.md` §7 ampliado con los comandos de la
  fase y §13 nuevo con lo congelado y las ocho notas (signal de
  pestañas, selección del árbol, filtro con referencia flotante,
  impresión, fuentes, mnemónicos repetidos, temporizadores y ventanas
  no modales, cajas que no reparten); `README.md` con la muestra 05 y
  las cinco pruebas de consola.

---

## 2026-09-30 — Fase 3: tabla, browse editable e imágenes

Commit `f167d3c` (25 ficheros, 2.612 líneas nuevas).

- **Clases nuevas**: `TDataBase`, envoltura fina de un DBF de Harbour
  sin GTK (alias `HGTK<n>`, el área que había se restaura al salir de
  cada método, comprueba ruta y `File()` antes de cerrar nada, alta
  con `dbAppend(.T.)` y conversión de tipo antes de `FieldPut`), y
  `TImage` (`Size()` devuelve los píxeles de la imagen leída con
  GdkPixbuf; si el fichero no se pudo leer, devuelve `{ 0, 0 }` en vez
  de romper).
- **TBrowse ampliado**: orden por columna (cabecera pulsable con
  flecha y `Ordenar( nCol [, lDesc ] )`), edición de celda con la
  cláusula `EDIT`, `aReg` con el número de registro de cada fila para
  que ordenar no descuadre nada, `Anadir()` (deja elegida la fila
  nueva, en la posición que le toca), `Poner()` (escribe en la vista y
  en el fichero), `SetData()` y `Editada()`. El `DATA` admite un array
  o un `TDataBase`.
- **Comandos**: `IMAGE` en `DEFINE BUTTON` (después de `PROMPT`),
  `DEFINE IMAGE <o> OF <oW> FILE <c>` y `EDIT` en `DEFINE BROWSE`
  (entre `DATA` y `AT`), con las cuatro variantes de la cláusula;
  `HGTK_FASE` pasa a 3.
- **Firma nueva**: `TButton():New( oParent, cPrompt, cImage, nRow,
  nCol, nHeight, nWidth, bAction )` — `cImage` ocupa el tercer sitio,
  y quien llame a `New()` a mano tiene que ponerlo (cadena vacía si no
  hay imagen).
- **Puente C**: `hbgtk_image.c` (`hbgtk_pixbuf` y `HGtkImageNew`,
  `HGtkImageSet`, `HGtkImageTam`) y `hbgtk_list.c` ampliado: el browse
  se monta sobre un `GtkScrolledWindow` con el `GtkTreeView` dentro,
  la cabecera marca el orden, la celda se edita con
  `GtkCellRendererText` y `HGtkTreeViewSelect` lleva el cursor.
- **Edición con teclado (empirismo GTK 3.24)**: **F2 no abre la
  celda** —llega a la vista como keyval `0xffbf` y la ignoran— y
  **`Return` sí** —dispara `editing-started` con su `GtkEntry`—, así
  que la secuencia es `Return`, `Ctrl+A`, texto, `Return`.
- **Foco**: `HGtkWndRefocus( pWnd )` (nuevo en `hbgtk_window.c`);
  `TWindow:Activate()` repite el foco después de `HGtkWndShow`,
  porque ponerlo antes de mostrar deja la vista en un estado en que
  `Return` no abre la celda aunque las teclas lleguen.
- **Menú con inicial repetida**: dos popups con la misma inicial —en
  español, «Archivo» y «Ayuda»— dejan la barra sin respuesta desde la
  segunda apertura: medido con GTK 3.24, 1 de 3 elecciones con la
  inicial repetida frente a 3 de 3 con inicial distinta, igual con la
  librería que con un `GtkMenuBar` escrito a mano. `HGtkMenuAdd` avisa
  por la salida de error al colgar el segundo popup y las muestras
  escriben `&Archivo` y `A&yuda`.
- **Trampa de Harbour encontrada y arreglada**: `!=` es comparación
  floja y `x != ""` da **siempre `.F.`**: `texto_test` comprobaba que
  un array y `NIL` se convertían en vacío con esa comparación, de
  modo que habría pasado aunque fallaran. Reglas: `==`, `!( a == b )`,
  `Empty()`, `Len()` y `ValType( x ) != "C"` (un carácter, seguro).
- **Muestra**: `samples/04_mantenimiento`, auto-comprobada antes y
  después de `ACTIVATE`: 14 registros en un DBF creado en cada
  corrida, orden por Código y por Nombre en los dos sentidos, `Poner`
  que llega al fichero, tallas de las imágenes, texto del botón con
  icono y el título de la ventana con «Registro n de m», que es lo
  que lee el smoke.
- **Pruebas**: `tests/tabla_test.prg` (consola: `TDataBase` sobre un
  DBF) y `tests/imagen_test.prg` (consola: medidas del PNG, `{ 0, 0 }`
  en fallo y `PadreFalso` para crear controles sin pantalla). El smoke
  recoge ahora las cuatro pruebas de consola y añade la secuencia
  `mantenimiento` (editar la fila 1, `End`, y el menú Archivo dos
  veces seguidas: Añadir y Salir); `secuencia()` admite varios textos
  esperados separados por `|`.
- **Contrato**: `docs/api-fase0.md` §7 ampliado con los comandos de la
  fase y §12 nuevo con lo congelado y las trampas (edición con
  `Return`, foco tras `ACTIVATE`, inicial repetida, `!=`, orden al
  editar y `ErrorBlock` que rompe).

---

## 2026-09-30 — Fase 2: menús, barra, listas, browse y temporizador

Commit `ed92579` (27 ficheros, 2.535 líneas nuevas).

- **Clases nuevas**: `TMenu`, `TPopup`, `TMenuItem`, `TBar`, `TStatus`,
  `TListBox`, `TBrowse` (todas de `TControl`) y `TTimer`
  (independiente, no cuelga de un widget). `TControl` gana
  `lFueraDelFijo`: lo que no va en el `GtkFixed` del padre —menú,
  barra de botones y barra de estado— lo cuelga la ventana desde su
  propia caja. `TButton` detecta una barra
  (`__objHasMsg( ::oWnd, "EsBarra" )`) y crea un botón de barra en vez
  de un botón de formulario.
- **Comandos**: `DEFINE MENU/POPUP/MENUITEM`, `ACTIVATE MENU`,
  `DEFINE BAR`, `DEFINE STATUS`, `DEFINE LISTBOX ... VAR ... ITEMS`,
  `DEFINE BROWSE ... VAR ... FIELDS ... DATA`, `DEFINE TIMER ...
  INTERVAL ... ACTION` y `ACTIVATE/DEACTIVATE TIMER`, con el mismo
  orden fijo de cláusulas; `HGTK_FASE` pasa a 2.
- **Puente C nuevo**: `hbgtk_menu.c` (barra de menú, popups, órdenes,
  barra de botones y barra de estado), `hbgtk_list.c` (`GtkListBox`
  para la lista y `GtkTreeView` sobre `GtkTreeStore` para el browse) y
  `hbgtk_timer.c` (relojes de GLib con grip, auto-liberación y señal
  `destroy` de la ventana dueña).
- **Caja vertical**: `hbgtk_crear_fixed` deja de crear sólo el
  `GtkFixed`: en ventana/diálogo crea una caja vertical que lleva
  [menú][barra][fijo][estado], y `hbgtk_caja_cuelga` reordena con
  `gtk_box_reorder_child` (menú→0, barra→1) y suelta el estado con
  `gtk_box_pack_end`.
- **Mnemónicos**: `hbgtk_mnemonico()` convierte la marca `&x` de
  FiveWin en `_x` para GTK, en botones, botones de barra y menús: el
  menú se abre con `Alt+A` en «Archivo».
- **Foco en las listas**: GTK crea `GtkListBox` con `can_focus`
  apagado —dentro de una lista el foco lo lleva la fila elegida—, así
  que `HGtkFocus` se lo pone a la fila seleccionada y `HGtkHasFocus`
  mira dentro de la lista. Sin esto, `SetFocus()` antes de `ACTIVATE`
  no servía y las Flecha abajo no llegaban.
- **`TWindow:FocusName()`** (nuevo): devuelve el tipo del widget que
  tiene el foco; lo usan las pruebas para saber por dónde van las
  teclas sin mirar la pantalla.
- **Muestra**: `samples/03_menu_lista`, auto-comprobada: menú
  Archivo/Salir y Ayuda/Acerca de, barra de botones, lista de seis
  registros y browse sincronizado en ambos sentidos, barra de estado y
  temporizador. Comprueba antes de `ACTIVATE` que menú, barra y
  sincronización funcionan y después que el temporizador ha disparado
  (sólo puede hacerlo dentro de `ACTIVATE`).
- **Pruebas**: `tests/texto_test.prg` (consola: `HgtkTexto` y
  `HgtkTextos`), `xkey -m alt|ctrl|shift` para mandar teclas con
  modificador, y en el smoke la secuencia `menu_lista`: dos Flecha
  abajo cambian la fila y `Alt+A`, `s` cierran la ventana por el menú.
  Todas las secuencias comprueban además que la salida no trae avisos
  de GTK (`WARNING` o `CRITICAL`).
- **Contrato**: `docs/api-fase0.md` §7 ampliado con los comandos de la
  fase y §11 nuevo con los comportamientos congelados.

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

*Estado: fase 4 completada (commit `5284955`). Pendiente de la fase 5:
pruebas de los comandos que no necesitan pantalla (seguir ampliando),
revisión de fugas abriendo y cerrando ventanas en bucle comprobando
que los bloques no se acumulan, empaquetado (`.so`, `.ch` y nota de
cómo enlaza una aplicación ajena) y guía corta de portación para quien
viene de FiveWin.*
