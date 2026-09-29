/*
 * button.prg — TButton: botón con una acción
 *
 * bAction se evalúa sin argumentos al pulsar el botón y se puede
 * cambiar en cualquier momento: el puente manda la señal a Click(),
 * que lee el bloque de la clase en ese instante.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TButton FROM TControl

   VAR bAction     INIT  NIL    // codeblock a evaluar al pulsar

   METHOD New( oParent, cPrompt, nRow, nCol, nHeight, nWidth, bAction ) ;
      CONSTRUCTOR
   METHOD Value( x ) SETGET
   METHOD Click()

ENDCLASS

/*
 * New( oParent, cPrompt [, nRow, nCol, nHeight, nWidth [, bAction ]] )
 *   cPrompt  texto del botón (UTF-8)
 *   bAction  bloque sin argumentos; evaluarlo y no devolver nada
 */
METHOD New( oParent, cPrompt, nRow, nCol, nHeight, nWidth, bAction ) ;
      CLASS TButton

   IF PCount() < 2 .OR. ValType( cPrompt ) != "C"
      cPrompt := ""
   ENDIF

   ::Init( oParent, nRow, nCol, nHeight, nWidth )

   ::bAction := IIf( ValType( bAction ) == "B", bAction, NIL )

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkButtonNew( cPrompt ) )
      IF ::IsAlive()
         HGtkSetSignal( ::hWnd, "clicked", {|| ::Click() } )
      ENDIF
   ELSE
      ::Place( NIL )
   ENDIF

RETURN SELF

/* Value() lee o cambia el texto del botón */
METHOD Value( x ) CLASS TButton

   IF PCount() > 0
      IF ValType( x ) != "C"
         HgtkErrArgs( "TButton:Value", "el texto debe ser una cadena" )
      ELSEIF ::IsAlive()
         HGtkSetText( ::hWnd, x )
      ENDIF
   ENDIF

   IF ::IsAlive()
      RETURN HGtkGetText( ::hWnd )
   ENDIF

RETURN ""

/* Evalúa la acción del botón; sin bloque no hace nada */
METHOD Click() CLASS TButton

   IF ::bAction == NIL
      RETURN NIL
   ENDIF
   IF ValType( ::bAction ) != "B"
      HgtkErrArgs( "TButton:Click", "bAction debe ser un codeblock" )
      RETURN NIL
   ENDIF

   Eval( ::bAction )

RETURN NIL
