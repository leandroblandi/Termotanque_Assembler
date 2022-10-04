
;***************************************************************************
; Programa main.asm (PIC16F628A)						Fecha: 04-10-2022	*
; Autor: Leandro N. Blandi												*
; Este programa simula las temperaturas de agua de un termotanque, desde	*
; 35°C hasta 75°C, generando 5 segundos de retardo después de cada limite	*
; - Velocidad del Reloj: 4MHz		- Tipo de Reloj: XT					*
; - Perro guardián: OFF												*
; - Protección de código: OFF											*
;***************************************************************************


; Zona de Datos

		__CONFIG 3F10
		LIST		P=16F628A
		INCLUDE	<P16F628A.INC>


; Zona de códigos

TEMP_ACT EQU 0x20
TEMP_MIN EQU 0x21
TEMP_MAX EQU 0x22
CONTADOR EQU 0x23

		ORG 0x00				; Cargamos la primera instrucción


				
INICIO	BCF 	STATUS,RP0		; Nos posicionamos en el banco 0
		MOVLW D'35'			; 
		MOVWF TEMP_MIN		; Alojamos la temperatura mínima en 0x21

		MOVLW D'70'			;
		MOVWF TEMP_MAX		; Alojamos la temperatura máxima en 0x22
		
		CALL INCREMENTO_TEMP	; Incrementamos en 1 a la temperatura actual, en la posición 0x20
		CALL RETARDO_0
		
		GOTO INICIO			; Bucle inf en INICIO
			

		
INCREMENTO_TEMP	
		INCF TEMP_ACT, 1		; Vamos subiendo la temperatura actual	
		
		MOVFW TEMP_ACT		; Cargamos el registro W con el valor de TEMP_ACT
		SUBWF TEMP_MAX,0		; Realizamos la resta entre la temperatura maxima y la actual
		
		BTFSS STATUS,Z		; Si la temperatura llego a su limite (se salta el GOTO)
	
		GOTO INCREMENTO_TEMP	; Si aun no llego que siga incrementando
		RETURN


RETARDO_0
		MOVLW d'255'
		MOVWF CONTADOR
			
RETARDO	
		DECFSZ CONTADOR,F
		GOTO RETARDO		
		RETURN

		END		