
;***************************************************************************
; Programa main.asm (PIC16F628A)						Fecha: 04-10-2022	*
; Autor: Leandro N. Blandi												*
; Este programa simula las temperaturas de agua de un termotanque, desde	*
; 35°C hasta 75°C, generando 5 segundos de retardo después de cada limite	*
; - Velocidad del Reloj: 4MHz		- Tipo de Reloj: XT					*
; - Perro guardián: OFF												*
; - Protección de código: OFF											*
;***************************************************************************


;***************************************************************************
; Zona de datos														*
;***************************************************************************

		__CONFIG 3F01
		LIST		P=16F628A
		INCLUDE	<P16F628A.INC>
		ERRORLEVEL -302


;***************************************************************************
; Zona de codigos														*
;***************************************************************************

TEMP_ACT EQU 0x20		; Lo usaremos para decrementar
TEMP_MIN EQU 0x21		; Lo usaremos como limite superior
TEMP_MAX EQU 0x22		; Lo usaremos como limite inferior

CONTADOR1 EQU 0x23	; Usado para el retardo de 5segs
CONTADOR2 EQU 0x24	; Idem comentario anterior
CONTADOR3 EQU 0x25	; Usado par el retardo de encendido de LED

		ORG 0x00


;**************************************************************************
; Subrutina principal												   *
;**************************************************************************
				
INICIO	MOVLW D'35'
		MOVWF TEMP_MIN		; Alojamos la temperatura mínima en 0x21

		MOVLW D'70'			;
		MOVWF TEMP_MAX		; Alojamos la temperatura máxima en 0x22
		CALL INCREMENTO_TEMP	; Incrementamos en 1 a la temperatura actual, en la posición 0x20
		CALL SET_CONTADOR2
		CALL ENCENDER_LED_MAXIMO
		CALL RETARDO_5SEGS_SUBRUTINA
		CALL DECREMENTO_TEMP
		CALL ENCENDER_LED_MINIMO	
		GOTO INICIO			; Bucle inf en INICIO
			

;***************************************************************************
; Subrutina que incrementa registro TEMP_ACT							*						*
;***************************************************************************
		
INCREMENTO_TEMP				; INCREMENTA DESDE 0 o TEMP_MIN hasta TEMP_MAX
		INCF TEMP_ACT,F		; Vamos subiendo la temperatura actual	
		
		MOVFW TEMP_ACT		; Cargamos el registro W con el valor de TEMP_ACT
		SUBWF TEMP_MAX,W		; Realizamos la resta entre la temperatura maxima y la actual
		
		BTFSS STATUS,Z		; Si la temperatura llego a su limite (se salta el GOTO)
	
		GOTO INCREMENTO_TEMP	; Si aun no llego que siga incrementando
		
		BCF STATUS,Z			; Limpiamos el bit Z del status para usarlo luego
		
		RETURN


;***************************************************************************
; Subrutina que decrementa registro TEMP_ACT							*
;***************************************************************************

DECREMENTO_TEMP				; DECREMENTA DESDE TEMP_MAX hasta TEMP_MIN

		DECF TEMP_ACT,F	; Decrementamos la temperatura
		MOVFW TEMP_MIN		; Cargamos el regisro W con el valor de TEMP_ACT
		SUBWF TEMP_ACT,W		; Realizamos la resta entre la temperatura minima y la actual
		
		BTFSS STATUS,Z		; Si la temperatura es la minima que deje de decrementar
		
		GOTO DECREMENTO_TEMP	; Sino, que continue
		
		RETURN

		
;**************************************************************************
; Subrutina de retardo para ver la luz del LED						   *
;**************************************************************************

RETARDO_LED
		MOVLW D'250'
		MOVWF CONTADOR3
		
RETARDO_LED_0	
		NOP
		DECFSZ CONTADOR3,F
		GOTO RETARDO_LED_0
		RETURN

;**************************************************************************
; Subrutinas de retardo aproximado 5 segs							   *
;**************************************************************************

SET_CONTADOR2
		MOVLW D'100'			; Cargo el valor del segundo contador para el retardo
		MOVWF CONTADOR2
		RETURN	

RETARDO_5SEGS_SUBRUTINA
		MOVLW D'250'
		MOVWF CONTADOR1
			
RETARDO_5SEGS_BUCLE				; BUCLE ANIDADO
		NOP						; 1us
		DECFSZ CONTADOR1,F		; Decremento desde 250 hasta 0
		GOTO RETARDO_5SEGS_BUCLE	
		DECFSZ CONTADOR2,F		; Una vez que salta decremento 1 unidad del contador 2 y 
		GOTO RETARDO_5SEGS_SUBRUTINA	; Vuelvo a decrementar desde 250
		RETURN


;**************************************************************************
; Subrutinas para encender LEDS									   *
;**************************************************************************
		
ENCENDER_LED_MAXIMO
		BSF STATUS,RP0
		BCF TRISB,1
		BCF STATUS,RP0
		BSF PORTB,1	; PRENDEMOS EL LED
		CALL RETARDO_LED
		BCF PORTB,1
		RETURN


ENCENDER_LED_MINIMO
		BSF STATUS,RP0
		BCF TRISB,2
		BCF STATUS,RP0
		BSF PORTB,2	; PRENDEMOS EL LED
		CALL RETARDO_LED
		BCF PORTB,2
		RETURN
		
		END