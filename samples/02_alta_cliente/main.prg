/*
 * 02_alta_cliente — alta ficticia de cliente (fase 1)
 *
 * Un diálogo modal con todos los controles de la fase: campos, grupo,
 * desplegable, casilla y radios. Muestra las tres cosas que pide el
 * criterio de hecho de la fase:
 *
 *   1. validación de un campo vacío (el foco no sale del campo);
 *   2. un sí/no al salir (cerrar con el aspa pregunta primero);
 *   3. los valores en variables Harbour al cerrar el diálogo.
 *
 * Compilar:  make sample      (desde la raíz del proyecto)
 * Ejecutar:  samples/02_alta_cliente/02_alta_cliente
 *
 * Licencia: LGPL-3.0-or-later
 */

#include "harbgtk.ch"

FUNCTION Main()

   LOCAL oDlg, oGrp, oGetNom, oGetTel, oCbo, oChk, oRad1, oRad2
   LOCAL aProvincias := { "Madrid", "Sevilla", "Cádiz", "Málaga" }
   LOCAL cNombre     := Space( 30 )
   LOCAL cTelefono   := Space( 12 )
   LOCAL nProvincia  := 1
   LOCAL lActivo     := .T.
   LOCAL nPago       := 1

   ? "HarbGtkLin", Str( HGTK_FASE ), "- GTK", ;
     HgtkApplication():GtkVersion()

   DEFINE DIALOG oDlg TITLE "Alta de cliente" SIZE 26, 76

   DEFINE GROUP oGrp OF oDlg PROMPT "Datos del cliente" ;
      AT 1, 1 SIZE 16, 74

      DEFINE SAY oSayNom OF oGrp PROMPT "Nombre"      AT 2, 2
      DEFINE GET oGetNom OF oGrp VAR cNombre           AT 2, 14 ;
         SIZE 1, 40 VALID {|| ValidaNombre( cNombre ) }

      DEFINE SAY oSayTel OF oGrp PROMPT "Teléfono"     AT 4, 2
      DEFINE GET oGetTel OF oGrp VAR cTelefono         AT 4, 14 ;
         SIZE 1, 18

      DEFINE SAY oSayPro OF oGrp PROMPT "Provincia"    AT 6, 2
      DEFINE COMBOBOX oCbo OF oGrp VAR nProvincia      AT 6, 14 ;
         SIZE 1, 30 ITEMS aProvincias

      DEFINE CHECKBOX oChk OF oGrp VAR lActivo ;
         PROMPT "Cliente activo" AT 8, 14

      DEFINE SAY oSayPag OF oGrp PROMPT "Pago"         AT 10, 2
      DEFINE RADIO oRad1 OF oGrp VAR nPago OPTION 1 ;
         PROMPT "Efectivo" AT 10, 14
      DEFINE RADIO oRad2 OF oGrp VAR nPago OPTION 2 ;
         PROMPT "Crédito"  AT 12, 14

   DEFINE BUTTON oOk  OF oDlg PROMPT "Aceptar"  AT 19, 44 ;
      SIZE 1, 14 ACTION {|| iif( oGetNom:Validar(), oDlg:End(), NIL ) }
   DEFINE BUTTON oCan OF oDlg PROMPT "Cancelar" AT 19, 60 ;
      SIZE 1, 14 ACTION {|| oDlg:End() }

   /* cerrar con el aspa pregunta antes: si la respuesta es no, el
      diálogo sigue abierto */
   oDlg:bClose := {|| MsgYesNo( "¿Cerrar el alta sin guardar?", ;
                                "Confirme" ) }

   oGetNom:SetFocus()

   ACTIVATE DIALOG oDlg

   ? ""
   ? "Valores en variables Harbour al cerrar el diálogo:"
   ? "  Nombre    :", "'" + AllTrim( cNombre ) + "'"
   ? "  Teléfono  :", "'" + AllTrim( cTelefono ) + "'"
   ? "  Provincia :", aProvincias[ nProvincia ]
   ? "  Activo    :", iif( lActivo, "sí", "no" )
   ? "  Pago      :", iif( nPago == 2, "crédito", "efectivo" )
   ? ""

RETURN NIL

/* Validación del nombre: sin contenido no se puede salir del campo */
STATIC FUNCTION ValidaNombre( cNombre )

   IF Empty( AllTrim( cNombre ) )
      MsgStop( "El nombre no puede quedar vacío.", "Error" )
      RETURN .F.
   ENDIF

RETURN .T.
