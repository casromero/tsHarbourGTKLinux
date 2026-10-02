# HarbGtkLin — Makefile de las fases 1 a 5
#
#   make            lib/libharbgtklin.so
#   make sample     las muestras 01_ventana a 05_app
#   make test       pruebas de consola (+ helpers X11 de las pruebas)
#   make smoke      prueba gráfica bajo Xvfb, sin mirar la pantalla
#   make package    dist/harbgtklin-fase5.tar.gz (.so, .ch y nota)
#   make clean      borra los resultados de la compilación
#
# Los tres pasos de la construcción:
#   1. harbour (vía hbmk2) compila las clases .prg;
#   2. gcc compila el puente .c con las banderas de pkg-config gtk+-3.0;
#   3. hbmk2 enlaza libharbgtklin.so y el ejecutable de la muestra.
#
# Licencia: LGPL-3.0-or-later

SHELL      := /bin/bash
HB         := hbmk2
CC         ?= gcc
ROOT       := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
INCDIR     := $(ROOT)/include
LIBDIR     := $(ROOT)/lib
TESTDIR    := $(ROOT)/tests

GTK_CFLAGS := $(shell pkg-config --cflags gtk+-3.0)
GTK_LIBS   := $(shell pkg-config --libs gtk+-3.0)
X11_CFLAGS := $(shell pkg-config --cflags x11)
X11_LIBS   := $(shell pkg-config --libs x11)
XTST_CFLAGS:= $(shell pkg-config --cflags xtst)
XTST_LIBS  := $(shell pkg-config --libs xtst)
HB_LIBDIR  := $(shell $(HB) --hbdirlib 2>/dev/null)

PRG_SRCS   := $(sort $(wildcard $(ROOT)/source/classes/*.prg) \
                          $(wildcard $(ROOT)/source/rtl/*.prg))
C_SRCS     := $(sort $(wildcard $(ROOT)/source/gtk/*.c))
HDRS       := $(wildcard $(ROOT)/source/gtk/*.h) $(INCDIR)/harbgtk.ch

LIB        := $(LIBDIR)/libharbgtklin.so
SAMPLE01   := $(ROOT)/samples/01_ventana/01_ventana
SAMPLE02   := $(ROOT)/samples/02_alta_cliente/02_alta_cliente
SAMPLE03   := $(ROOT)/samples/03_menu_lista/03_menu_lista
SAMPLE04   := $(ROOT)/samples/04_mantenimiento/04_mantenimiento
SAMPLE05   := $(ROOT)/samples/05_app/05_app
COORD_TEST := $(TESTDIR)/coord_test
TEXTO_TEST := $(TESTDIR)/texto_test
TABLA_TEST := $(TESTDIR)/tabla_test
IMAGEN_TEST := $(TESTDIR)/imagen_test
IMPRESION_TEST := $(TESTDIR)/impresion_test
COMANDOS_TEST := $(TESTDIR)/comandos_test
FUGAS_TEST := $(TESTDIR)/fugas_test
MAXIMIZAR_TEST := $(TESTDIR)/maximizar
CIERRE     := $(TESTDIR)/cierre_cancelado
FORMULARIO := $(TESTDIR)/formulario
MENSAJES   := $(TESTDIR)/mensajes
XCLOSE     := $(TESTDIR)/xclose
XKEY       := $(TESTDIR)/xkey

# Paquete de la fase 5: .so + .ch + nota de enlace (+ licencia)
PAQUETE    := $(ROOT)/dist/harbgtklin-fase5.tar.gz
PAQUETE_DIR := $(ROOT)/dist/harbgtklin-fase5

# Banderas para enlazar un programa contra la librería:
# encuentra libharbgtklin.so junto al ejecutable y libharbour en su
# directorio de instalación, sin necesidad de LD_LIBRARY_PATH.
# (los binarios de tests/ están un nivel más arriba que la muestra)
RPATH_SAMPLE := -ldflag+=-Wl,-rpath,'$$ORIGIN/../../lib'
RPATH_TEST   := -ldflag+=-Wl,-rpath,'$$ORIGIN/../lib'
RPATH_HB     := -ldflag+=-Wl,-rpath,$(HB_LIBDIR)

# Salida de consola en texto plano (sin controles de terminal): los
# programas de esta fase son de escritorio y sus mensajes van a un log.
GT_PLANO     := -gtcgi

.PHONY: all sample test smoke package clean help

all: $(LIB)

$(LIB): $(PRG_SRCS) $(C_SRCS) $(HDRS)
	@mkdir -p $(LIBDIR)
	$(HB) -hbdyn $(PRG_SRCS) $(C_SRCS) -o$(LIBDIR)/harbgtklin.so \
	   -i$(INCDIR) "-cflag=$(GTK_CFLAGS)" "-dflag=$(GTK_LIBS)" \
	   -dflag+=-Wl,-rpath,$(HB_LIBDIR)
	@echo "librería: $@"

sample: $(SAMPLE01) $(SAMPLE02) $(SAMPLE03) $(SAMPLE04) $(SAMPLE05)

$(SAMPLE01): $(ROOT)/samples/01_ventana/main.prg $(LIB) $(HDRS)
	$(HB) $(ROOT)/samples/01_ventana/main.prg -o$(SAMPLE01) \
	   -i$(INCDIR) -L$(LIBDIR) -lharbgtklin \
	   $(RPATH_SAMPLE) $(RPATH_HB) $(GT_PLANO)
	@echo "muestra:  $@"

$(SAMPLE02): $(ROOT)/samples/02_alta_cliente/main.prg $(LIB) $(HDRS)
	$(HB) $(ROOT)/samples/02_alta_cliente/main.prg -o$(SAMPLE02) \
	   -i$(INCDIR) -L$(LIBDIR) -lharbgtklin \
	   $(RPATH_SAMPLE) $(RPATH_HB) $(GT_PLANO)
	@echo "muestra:  $@"

$(SAMPLE03): $(ROOT)/samples/03_menu_lista/main.prg $(LIB) $(HDRS)
	$(HB) $(ROOT)/samples/03_menu_lista/main.prg -o$(SAMPLE03) \
	   -i$(INCDIR) -L$(LIBDIR) -lharbgtklin \
	   $(RPATH_SAMPLE) $(RPATH_HB) $(GT_PLANO)
	@echo "muestra:  $@"

$(SAMPLE04): $(ROOT)/samples/04_mantenimiento/main.prg \
             $(wildcard $(ROOT)/samples/04_mantenimiento/*.png) \
             $(LIB) $(HDRS)
	$(HB) $(ROOT)/samples/04_mantenimiento/main.prg -o$(SAMPLE04) \
	   -i$(INCDIR) -L$(LIBDIR) -lharbgtklin \
	   $(RPATH_SAMPLE) $(RPATH_HB) $(GT_PLANO)
	@echo "muestra:  $@"

$(SAMPLE05): $(ROOT)/samples/05_app/main.prg $(LIB) $(HDRS)
	$(HB) $(ROOT)/samples/05_app/main.prg -o$(SAMPLE05) \
	   -i$(INCDIR) -L$(LIBDIR) -lharbgtklin \
	   $(RPATH_SAMPLE) $(RPATH_HB) $(GT_PLANO)
	@echo "muestra:  $@"

test: $(COORD_TEST) $(TEXTO_TEST) $(TABLA_TEST) $(IMAGEN_TEST) \
      $(IMPRESION_TEST) $(COMANDOS_TEST) $(CIERRE) $(XCLOSE) $(XKEY)
	@$(COORD_TEST)
	@$(TEXTO_TEST)
	@$(TABLA_TEST)
	@$(IMAGEN_TEST)
	@$(IMPRESION_TEST)
	@$(COMANDOS_TEST)

$(COORD_TEST): $(TESTDIR)/coord_test.prg $(LIB) $(HDRS)
	$(HB) $(TESTDIR)/coord_test.prg -o$(COORD_TEST) \
	   -i$(INCDIR) -L$(LIBDIR) -lharbgtklin \
	   $(RPATH_TEST) $(RPATH_HB) $(GT_PLANO)

$(TEXTO_TEST): $(TESTDIR)/texto_test.prg $(LIB) $(HDRS)
	$(HB) $(TESTDIR)/texto_test.prg -o$(TEXTO_TEST) \
	   -i$(INCDIR) -L$(LIBDIR) -lharbgtklin \
	   $(RPATH_TEST) $(RPATH_HB) $(GT_PLANO)

$(TABLA_TEST): $(TESTDIR)/tabla_test.prg $(LIB) $(HDRS)
	$(HB) $(TESTDIR)/tabla_test.prg -o$(TABLA_TEST) \
	   -i$(INCDIR) -L$(LIBDIR) -lharbgtklin \
	   $(RPATH_TEST) $(RPATH_HB) $(GT_PLANO)

$(IMAGEN_TEST): $(TESTDIR)/imagen_test.prg $(LIB) $(HDRS)
	$(HB) $(TESTDIR)/imagen_test.prg -o$(IMAGEN_TEST) \
	   -i$(INCDIR) -L$(LIBDIR) -lharbgtklin \
	   $(RPATH_TEST) $(RPATH_HB) $(GT_PLANO)

$(IMPRESION_TEST): $(TESTDIR)/impresion_test.prg $(LIB) $(HDRS)
	$(HB) $(TESTDIR)/impresion_test.prg -o$(IMPRESION_TEST) \
	   -i$(INCDIR) -L$(LIBDIR) -lharbgtklin \
	   $(RPATH_TEST) $(RPATH_HB) $(GT_PLANO)

$(COMANDOS_TEST): $(TESTDIR)/comandos_test.prg $(LIB) $(HDRS)
	$(HB) $(TESTDIR)/comandos_test.prg -o$(COMANDOS_TEST) \
	   -i$(INCDIR) -L$(LIBDIR) -lharbgtklin \
	   $(RPATH_TEST) $(RPATH_HB) $(GT_PLANO)

$(FUGAS_TEST): $(TESTDIR)/fugas_test.prg $(LIB) $(HDRS)
	$(HB) $(TESTDIR)/fugas_test.prg -o$(FUGAS_TEST) \
	   -i$(INCDIR) -L$(LIBDIR) -lharbgtklin \
	   $(RPATH_TEST) $(RPATH_HB) $(GT_PLANO)

$(MAXIMIZAR_TEST): $(TESTDIR)/maximizar.prg $(LIB) $(HDRS)
	$(HB) $(TESTDIR)/maximizar.prg -o$(MAXIMIZAR_TEST) \
	   -i$(INCDIR) -L$(LIBDIR) -lharbgtklin \
	   $(RPATH_TEST) $(RPATH_HB) $(GT_PLANO)

$(CIERRE): $(TESTDIR)/cierre_cancelado.prg $(LIB) $(HDRS)
	$(HB) $(TESTDIR)/cierre_cancelado.prg -o$(CIERRE) \
	   -i$(INCDIR) -L$(LIBDIR) -lharbgtklin \
	   $(RPATH_TEST) $(RPATH_HB) $(GT_PLANO)

$(FORMULARIO): $(TESTDIR)/formulario.prg $(LIB) $(HDRS)
	$(HB) $(TESTDIR)/formulario.prg -o$(FORMULARIO) \
	   -i$(INCDIR) -L$(LIBDIR) -lharbgtklin \
	   $(RPATH_TEST) $(RPATH_HB) $(GT_PLANO)

$(MENSAJES): $(TESTDIR)/mensajes.prg $(LIB) $(HDRS)
	$(HB) $(TESTDIR)/mensajes.prg -o$(MENSAJES) \
	   -i$(INCDIR) -L$(LIBDIR) -lharbgtklin \
	   $(RPATH_TEST) $(RPATH_HB) $(GT_PLANO)

$(XCLOSE): $(TESTDIR)/xclose.c
	$(CC) -O2 -Wall -o $@ $< $(X11_CFLAGS) $(X11_LIBS)

$(XKEY): $(TESTDIR)/xkey.c
	$(CC) -O2 -Wall -o $@ $< $(X11_CFLAGS) $(X11_LIBS) $(XTST_LIBS)

# Alias en forma relativa: evitan que make caiga en sus reglas implícitas
lib/libharbgtklin.so: $(LIB) ;
samples/01_ventana/01_ventana: $(SAMPLE01) ;
samples/02_alta_cliente/02_alta_cliente: $(SAMPLE02) ;
samples/03_menu_lista/03_menu_lista: $(SAMPLE03) ;
samples/04_mantenimiento/04_mantenimiento: $(SAMPLE04) ;
samples/05_app/05_app: $(SAMPLE05) ;
tests/coord_test: $(COORD_TEST) ;
tests/texto_test: $(TEXTO_TEST) ;
tests/tabla_test: $(TABLA_TEST) ;
tests/imagen_test: $(IMAGEN_TEST) ;
tests/impresion_test: $(IMPRESION_TEST) ;
tests/comandos_test: $(COMANDOS_TEST) ;
tests/fugas_test: $(FUGAS_TEST) ;
tests/maximizar: $(MAXIMIZAR_TEST) ;
tests/cierre_cancelado: $(CIERRE) ;
tests/formulario: $(FORMULARIO) ;
tests/mensajes: $(MENSAJES) ;
tests/xclose: $(XCLOSE) ;
tests/xkey: $(XKEY) ;

smoke: $(SAMPLE01) $(SAMPLE02) $(SAMPLE03) $(SAMPLE04) $(SAMPLE05) \
       $(COORD_TEST) $(TEXTO_TEST) $(TABLA_TEST) $(IMAGEN_TEST) \
       $(IMPRESION_TEST) $(COMANDOS_TEST) $(FUGAS_TEST) \
       $(MAXIMIZAR_TEST) \
       $(CIERRE) $(FORMULARIO) $(MENSAJES) \
       $(XCLOSE) $(XKEY)
	@bash $(TESTDIR)/smoke.sh

# --- empaquetado (fase 5) --------------------------------------------
# Un tarball con lo mínimo para usar la librería desde fuera del
# proyecto: la biblioteca .so, el .ch de comandos, la nota de cómo
# enlaza una aplicación ajena (docs/enlace.md) y la licencia. El .ch
# es el de este árbol porque también lleva las constantes de fase.
package: $(PAQUETE)

$(PAQUETE): $(LIB) $(INCDIR)/harbgtk.ch $(ROOT)/docs/enlace.md \
            $(ROOT)/LICENSE
	rm -rf $(PAQUETE_DIR)
	mkdir -p $(PAQUETE_DIR)/lib $(PAQUETE_DIR)/include \
	         $(PAQUETE_DIR)/docs
	cp $(LIB) $(PAQUETE_DIR)/lib/
	cp $(INCDIR)/harbgtk.ch $(PAQUETE_DIR)/include/
	cp $(ROOT)/docs/enlace.md $(PAQUETE_DIR)/docs/
	cp $(ROOT)/LICENSE $(PAQUETE_DIR)/
	tar -C $(ROOT)/dist -czf $(PAQUETE) $(notdir $(PAQUETE_DIR))
	rm -rf $(PAQUETE_DIR)
	@echo "paquete: $@"

clean:
	rm -rf $(LIBDIR) $(SAMPLE01) $(SAMPLE02) $(SAMPLE03) $(SAMPLE04) \
	       $(SAMPLE05) \
	       $(COORD_TEST) $(TEXTO_TEST) $(TABLA_TEST) $(IMAGEN_TEST) \
	       $(IMPRESION_TEST) $(COMANDOS_TEST) $(FUGAS_TEST) \
	       $(MAXIMIZAR_TEST) \
	       $(CIERRE) $(FORMULARIO) $(MENSAJES) $(XCLOSE) $(XKEY) \
	       $(ROOT)/dist \
	       $(TESTDIR)/.logs $(ROOT)/tests/*.o

help:
	@echo "make            - construye lib/libharbgtklin.so"
	@echo "make sample     - construye las muestras 01 a 05"
	@echo "make test       - pruebas de consola"
	@echo "make smoke      - prueba gráfica bajo Xvfb"
	@echo "make package    - tarball con .so, .ch y nota de enlace"
	@echo "make clean      - limpia"
