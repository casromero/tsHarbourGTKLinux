/*
 * database.prg — TDataBase: envoltura fina sobre un DBF de Harbour
 *
 * La fase 3 necesita un origen de datos, pero la librería no
 * reimplementa el motor de datos: los DBF son del runtime de Harbour
 * (RDF por omisión) y esta clase sólo los envuelve con los pocos
 * métodos que el browse necesita y con un poco de orden:
 *
 *   - el área de trabajo seleccionada se restaura siempre, para no
 *     dejar al programa de la aplicación en otra tabla;
 *   - Cargar() devuelve la tabla entera como array de arrays, que es
 *     el formato que ya lleva DATA: las tablas de mantenimiento son
 *     pequeñas y el browse no virtualiza;
 *   - Registros() devuelve el número de registro de cada fila en el
 *     mismo orden, que es lo que permite ordenar por columna sin
 *     perder el enlace con el fichero;
 *   - el texto de un campo se devuelve sin el relleno de ancho fijo
 *     del DBF (RTrim), que es espacios que sólo existen en el fichero.
 *
 * Nada de aquí se habla con GTK: es una clase de consola y se puede
 * probar sin pantalla (tests/tabla_test.prg).
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TDataBase

   VAR cFichero   INIT  ""      // ruta del DBF
   VAR cArea      INIT  ""      // alias con el que se abrió
   VAR lAbierta   INIT  .F.

   METHOD New( cFichero ) CONSTRUCTOR
   METHOD Use( cFichero, cRDD )
   METHOD Close()
   METHOD Abierta()
   METHOD Fichero()
   METHOD Campos()              // nombres de los campos
   METHOD Cantidad()            // registros guardados
   METHOD Cargar()              // array de arrays con la tabla
   METHOD Registros()           // nº de registro de cada fila de Cargar()
   METHOD Guardar( nReg, nCampo, xValor )   // escribe y devuelve lo guardado
   METHOD Anadir( aValores )    // registro nuevo; devuelve su nº

ENDCLASS

/*
 * New( [ cFichero ] ) — con ruta, abre el fichero enseguida.
 * Sin ruta queda cerrada y se abre con Use().
 */
METHOD New( cFichero ) CLASS TDataBase

   /* Ojo con "!=" en Harbour: es una comparación floja (SET EXACT OFF)
    * y contra "" da siempre .F. Lo exacto es Empty() o "==". */
   IF ValType( cFichero ) == "C" .AND. ! Empty( cFichero )
      ::Use( cFichero )
   ENDIF

RETURN SELF

/*
 * Use( cFichero [, cRDD ] ) -> .T. si se abrió.
 * Si ya había otro fichero abierto, se cierra antes.
 */
METHOD Use( cFichero, cRDD ) CLASS TDataBase

   LOCAL nArea, cAlias, nAntes

   /* primero se comprueba todo lo que pueda fallar: así un Use()
    * fallido no deja cerrada la tabla que estaba abierta */
   IF ValType( cFichero ) != "C" .OR. Empty( cFichero )
      HgtkErrArgs( "TDataBase:Use", "hace falta la ruta del fichero" )
      RETURN .F.
   ENDIF

   IF ! File( cFichero )
      HgtkErrArgs( "TDataBase:Use", "no existe el fichero " + cFichero )
      RETURN .F.
   ENDIF

   ::Close()

   /* alias único para no pisar el área de la aplicación */
   nArea  := 1
   cAlias := "HGTK" + LTrim( Str( nArea ) )
   DO WHILE Select( cAlias ) != 0
      nArea++
      cAlias := "HGTK" + LTrim( Str( nArea ) )
   ENDDO

   nAntes := Select()

   /* .T. en el primer argumento: área nueva. Con NIL o .F. el fichero
    * se abriría en el área que esté seleccionada, que es de la
    * aplicación, y eso sí que la pisaría. */
   IF ! dbUseArea( .T., IIf( ValType( cRDD ) == "C" .AND. ! Empty( cRDD ), ;
                             cRDD, NIL ), cFichero, cAlias, .F., .F. )
      HgtkErrArgs( "TDataBase:Use", "no se pudo abrir " + cFichero )
      IF nAntes > 0
         dbSelectArea( nAntes )
      ENDIF
      RETURN .F.
   ENDIF

   ::cFichero := cFichero
   ::cArea    := cAlias
   ::lAbierta := .T.

   /* el área seleccionada vuelve a la que estaba, que es de la
    * aplicación: esta clase sólo la toma mientras trabaja */
   IF nAntes > 0
      dbSelectArea( nAntes )
   ENDIF

RETURN .T.

/* Close() — cierra el fichero si está abierto */
METHOD Close() CLASS TDataBase

   LOCAL nAntes := Select(), lMia := ( Alias() == ::cArea )

   IF ::lAbierta
      IF Select( ::cArea ) != 0
         dbSelectArea( ::cArea )
         dbCloseArea()
         /* si el área seleccionada no era la nuestra, se restaura;
          * si lo era, al cerrarla elige Harbour la que quiera */
         IF ! lMia .AND. nAntes > 0
            dbSelectArea( nAntes )
         ENDIF
      ENDIF
      ::lAbierta := .F.
      ::cArea    := ""
   ENDIF

RETURN NIL

/* .T. si hay un fichero abierto */
METHOD Abierta() CLASS TDataBase

RETURN ::lAbierta

/* Ruta del fichero (vacío si no se ha abierto nada) */
METHOD Fichero() CLASS TDataBase

RETURN ::cFichero

/* valor de campo tal como lo ve la aplicación: el texto se devuelve
 * sin los espacios con que el DBF lo rellena a ancho fijo, que sólo
 * sirven para el fichero y molestan al comparar o al pintar */
STATIC FUNCTION ValorCampo( nCampo )

   LOCAL xValor := FieldGet( nCampo )

   IF ValType( xValor ) == "C"
      xValor := RTrim( xValor )
   ENDIF

RETURN xValor

/*
 * AlTipo( xValor, cTipo ) — la celda del browse es texto, pero el
 * fichero tiene tipos y el RDD no admite de todo. Se convierte aquí,
 * antes de escribir: un texto sin número en un campo numérico entra
 * como 0, una fecha imposible queda vacía y un texto en un campo
 * lógico es .T. si empieza por T, S o 1.
 */
STATIC FUNCTION AlTipo( xValor, cTipo )

   DO CASE
   CASE cTipo == "N"
      IF ValType( xValor ) != "N"
         xValor := Val( HgtkTexto( xValor ) )
      ENDIF
   CASE cTipo == "C"
      IF ValType( xValor ) != "C"
         xValor := HgtkTexto( xValor )
      ENDIF
   CASE cTipo == "D"
      IF ValType( xValor ) != "D"
         xValor := CTod( HgtkTexto( xValor ) )
      ENDIF
   CASE cTipo == "L"
      IF ValType( xValor ) != "L"
         xValor := ! Empty( xValor ) .AND. ;
                   HgtkTexto( xValor ) $ "TtYySs1"
      ENDIF
   ENDCASE

RETURN xValor

/* pone el área de esta tabla y devuelve el número de la que estaba
 * antes (0: ninguna seleccionada) */
STATIC FUNCTION AreaMia( oTab )

   LOCAL nAntes := Select()

   dbSelectArea( oTab:cArea )

RETURN nAntes

/* devuelve el área que estaba antes */
STATIC FUNCTION AreaOtra( nAntes )

   IF nAntes > 0
      dbSelectArea( nAntes )
   ENDIF

RETURN NIL

/* Campos() -> {"NOMBRE", "PROVINCIA", ...} en el orden del fichero */
METHOD Campos() CLASS TDataBase

   LOCAL nAntes, aCampos := {}, nCampo

   IF ! ::lAbierta
      HgtkErrArgs( "TDataBase:Campos", "el fichero no está abierto" )
      RETURN aCampos
   ENDIF

   nAntes := AreaMia( SELF )
   FOR nCampo := 1 TO FCount()
      AAdd( aCampos, FieldName( nCampo ) )
   NEXT
   AreaOtra( nAntes )

RETURN aCampos

/* Cantidad() -> número de registros guardados (0 si está cerrada) */
METHOD Cantidad() CLASS TDataBase

   LOCAL nAntes, nTotal := 0

   IF ! ::lAbierta
      RETURN 0
   ENDIF

   nAntes := AreaMia( SELF )
   nTotal := LastRec()
   AreaOtra( nAntes )

RETURN nTotal

/*
 * Cargar() -> array de arrays con todos los registros. Un registro por
 * entrada y un valor por campo, ya convertido a su tipo (texto, número,
 * fecha o lógico): el browse lo convierte a texto al pintarlo.
 */
METHOD Cargar() CLASS TDataBase

   LOCAL nAntes, aFilas := {}, nCampo, aFila

   IF ! ::lAbierta
      HgtkErrArgs( "TDataBase:Cargar", "el fichero no está abierto" )
      RETURN aFilas
   ENDIF

   nAntes := AreaMia( SELF )

   dbGoTop()
   DO WHILE ! Eof()
      aFila := {}
      FOR nCampo := 1 TO FCount()
         AAdd( aFila, ValorCampo( nCampo ) )
      NEXT
      AAdd( aFilas, aFila )
      dbSkip()
   ENDDO
   IF RecNo() == 0      /* tabla vacía: dbSkip se queda en el 0 */
      dbGoTop()
   ENDIF

   AreaOtra( nAntes )

RETURN aFilas

/*
 * Registros() -> { 1, 2, ... } con el número de registro de cada fila
 * de Cargar(). El browse lo lleva a su lado para que, aunque ordene
 * por columna, una edición siga cayendo en su registro.
 */
METHOD Registros() CLASS TDataBase

   LOCAL nAntes, aRegs := {}

   IF ! ::lAbierta
      RETURN aRegs
   ENDIF

   nAntes := AreaMia( SELF )

   dbGoTop()
   DO WHILE ! Eof()
      AAdd( aRegs, RecNo() )
      dbSkip()
   ENDDO
   IF RecNo() == 0
      dbGoTop()
   ENDIF

   AreaOtra( nAntes )

RETURN aRegs

/*
 * Guardar( nReg, nCampo, xValor ) -> el valor que quedó escrito.
 * Se devuelve lo que hay en el fichero, no lo que se dio: si el campo
 * es numérico y llega texto sin sentido, se queda el cero y el browse
 * enseña lo guardado, que es lo que hay.
 */
METHOD Guardar( nReg, nCampo, xValor ) CLASS TDataBase

   LOCAL nAntes, xGuardado := xValor

   IF ! ::lAbierta
      HgtkErrArgs( "TDataBase:Guardar", "el fichero no está abierto" )
      RETURN xValor
   ENDIF

   nAntes := AreaMia( SELF )

   IF nReg < 1 .OR. nReg > LastRec() .OR. ;
      nCampo < 1 .OR. nCampo > FCount()
      HgtkErrArgs( "TDataBase:Guardar", "registro o campo fuera de rango" )
   ELSE
      dbGoto( nReg )
      FieldPut( nCampo, AlTipo( xValor, FieldType( nCampo ) ) )
      xGuardado := ValorCampo( nCampo )
   ENDIF

   AreaOtra( nAntes )

RETURN xGuardado

/*
 * Anadir( aValores ) -> número del registro nuevo, 0 si falló.
 * Cada entrada de aValores va a su campo en orden; los que falten se
 * quedan con su valor por omisión.
 */
METHOD Anadir( aValores ) CLASS TDataBase

   LOCAL nAntes, nReg := 0, nCampo, nHay

   IF ! ::lAbierta
      HgtkErrArgs( "TDataBase:Anadir", "el fichero no está abierto" )
      RETURN 0
   ENDIF
   IF ! HB_IsArray( aValores )
      HgtkErrArgs( "TDataBase:Anadir", "se esperaba un array" )
      RETURN 0
   ENDIF

   nAntes := AreaMia( SELF )

   IF dbAppend( .T. )
      nHay := Min( Len( aValores ), FCount() )
      FOR nCampo := 1 TO nHay
         FieldPut( nCampo, AlTipo( aValores[ nCampo ], ;
                                   FieldType( nCampo ) ) )
      NEXT
      nReg := RecNo()
      dbCommit()
   ENDIF

   AreaOtra( nAntes )

RETURN nReg
