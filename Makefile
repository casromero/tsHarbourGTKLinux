# HarbGtkLin — Makefile de la fase 1
#
#   make            lib/libharbgtklin.so
#   make sample     samples/01_ventana y samples/02_alta_cliente
#   make test       pruebas de consola (+ helpers X11 de las pruebas)
#   make smoke      prueba gráfica bajo Xvfb, sin mirar la pantalla
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
COORD_TEST := $(TESTDIR)/coord_test
CIERRE     := $(TESTDIR)/cierre_cancelado
FORMULARIO := $(TESTDIR)/formulario
MENSAJES   := $(TESTDIR)/mensajes
XCLOSE     := $(TESTDIR)/xclose
XKEY       := $(TESTDIR)/xkey

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

.PHONY: all sample test smoke clean help

all: $(LIB)

$(LIB): $(PRG_SRCS) $(C_SRCS) $(HDRS)
	@mkdir -p $(LIBDIR)
	$(HB) -hbdyn $(PRG_SRCS) $(C_SRCS) -o$(LIBDIR)/harbgtklin.so \
	   -i$(INCDIR) "-cflag=$(GTK_CFLAGS)" "-dflag=$(GTK_LIBS)" \
	   -dflag+=-Wl,-rpath,$(HB_LIBDIR)
	@echo "librería: $@"

sample: $(SAMPLE01) $(SAMPLE02)

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

test: $(COORD_TEST) $(CIERRE) $(XCLOSE) $(XKEY)
	@$(COORD_TEST)

$(COORD_TEST): $(TESTDIR)/coord_test.prg $(LIB) $(HDRS)
	$(HB) $(TESTDIR)/coord_test.prg -o$(COORD_TEST) \
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
tests/coord_test: $(COORD_TEST) ;
tests/cierre_cancelado: $(CIERRE) ;
tests/formulario: $(FORMULARIO) ;
tests/mensajes: $(MENSAJES) ;
tests/xclose: $(XCLOSE) ;
tests/xkey: $(XKEY) ;

smoke: $(SAMPLE01) $(SAMPLE02) $(COORD_TEST) $(CIERRE) $(FORMULARIO) \
       $(MENSAJES) $(XCLOSE) $(XKEY)
	@bash $(TESTDIR)/smoke.sh

clean:
	rm -rf $(LIBDIR) $(SAMPLE01) $(SAMPLE02) $(COORD_TEST) $(CIERRE) \
	       $(FORMULARIO) $(MENSAJES) $(XCLOSE) $(XKEY) \
	       $(TESTDIR)/.logs $(ROOT)/tests/*.o

help:
	@echo "make            - construye lib/libharbgtklin.so"
	@echo "make sample     - construye las muestras 01_ventana y 02_alta_cliente"
	@echo "make test       - pruebas de consola"
	@echo "make smoke      - prueba gráfica bajo Xvfb"
	@echo "make clean      - limpia"
