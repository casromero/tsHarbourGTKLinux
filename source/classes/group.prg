/*
 * group.prg — TGroup: grupo con marco (GtkFrame)
 *
 * Es un control que a la vez es contenedor: los controles que se
 * declaran con "OF oGrupo" se colocan dentro, con coordenadas
 * relativas al grupo.
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "hbclass.ch"
#include "harbgtk.ch"

CLASS TGroup FROM TControl

   VAR aControles  INIT  {}     // controles declarados dentro

   METHOD New( oParent, cPrompt, nRow, nCol, nHeight, nWidth ) CONSTRUCTOR
   METHOD AddControl( oCtrl )
   METHOD Value( x ) SETGET     // texto del título

ENDCLASS

/* New( oParent, cPrompt [, nRow, nCol, nHeight, nWidth ] ) */
METHOD New( oParent, cPrompt, nRow, nCol, nHeight, nWidth ) CLASS TGroup

   IF PCount() < 2 .OR. ValType( cPrompt ) != "C"
      cPrompt := ""
   ENDIF

   ::Init( oParent, nRow, nCol, nHeight, nWidth )

   /* tamaño por omisión: un grupo sin ancho no se ve usar */
   IF ::nHeight == 0
      ::nHeight := HGTK_GRUPO_FILAS_DEF
   ENDIF
   IF ::nWidth == 0
      ::nWidth  := HGTK_GRUPO_COLS_DEF
   ENDIF

   IF ::oWnd != NIL .AND. ::oWnd:hWnd != NIL
      ::Place( HGtkFrameNew( cPrompt ) )
   ELSE
      ::Place( NIL )
   ENDIF

RETURN SELF

/* Registra un control dentro del grupo (lo llama TControl:Place) */
METHOD AddControl( oCtrl ) CLASS TGroup

   IF ValType( oCtrl ) == "O"
      AAdd( ::aControles, oCtrl )
   ENDIF

RETURN NIL

/* Value() lee o cambia el título del grupo */
METHOD Value( x ) CLASS TGroup

   IF PCount() > 0
      IF ValType( x ) != "C"
         HgtkErrArgs( "TGroup:Value", "el texto debe ser una cadena" )
      ELSEIF ::IsAlive()
         HGtkSetText( ::hWnd, x )
      ENDIF
   ENDIF

   IF ::IsAlive()
      RETURN HGtkGetText( ::hWnd )
   ENDIF

RETURN ""
