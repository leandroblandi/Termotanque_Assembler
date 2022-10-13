
;***************************************************************************
; Programa main.asm (PIC16F628A)						Fecha: 04-10-2022	
; Autor: Leandro N. Blandi												
; Este programa simula las temperaturas de agua de un termotanque, desde	
; 35°C hasta 75°C, generando 5 segundos de retardo después de cada limite	
; - Velocidad del Reloj: 4MHz		- Tipo de Reloj: Interno				
; - Perro guardián: OFF												
; - Protección de código: OFF											
;***************************************************************************


;***************************************************************************
; Zona de datos														
;***************************************************************************

		__CONFIG 3F01
		LIST		P=16F628A
		INCLUDE	<P16F628A.INC>
		ERRORLEVEL -302


;***************************************************************************
; Zona de codigos														
;***************************************************************************

TEMP_ACT EQU 0x20		; Lo usaremos para decrementar
TEMP_MIN EQU 0x21		; Lo usaremos como limite superior
TEMP_MAX EQU 0x22		; Lo usaremos como limite inferior

CONTADOR1 EQU 0x23	; Reservamos estas direcciones para los contadores
CONTADOR2 EQU 0x24	; Nos serviran para contar tiempos por software
CONTADOR3 EQU 0x25

		ORG 0x00


;**************************************************************************
; Subrutina principal												   
;**************************************************************************
				
INICIO	MOVLW D'0'			; Cargamos en W el valor inicial de la temperatura actual
		MOVWF TEMP_ACT		; Cargamos el valor de W en la temperatura actual

		MOVLW D'35'			; Cargamos en W el valor de la temperatura minima
		MOVWF TEMP_MIN		; Cargamos el valor de W en la temperatura minima

		MOVLW D'70'			; Cargamos en W el valor de la temperatura maxima
		MOVWF TEMP_MAX		; Cargamos el valor de W en la temperatura maxima
		
		CALL INCREMENTO_TEMP		; Que el agua comience a calentarse hasta el maximo
		CALL ENCENDER_LED_MAXIMO	; Que se encienda el LED para avisar que ya esta caliente
		
		CALL DELAY_1S			; Una vez que calienta el agua espera 5s
		CALL DELAY_1S
		CALL DELAY_1S
		CALL DELAY_1S
		CALL DELAY_1S
		
		CALL DECREMENTO_TEMP		; Que el agua empiece a enfriarse
		CALL ENCENDER_LED_MINIMO	; Que se encienda el LED para avisar que se enfrio
		
		CALL DELAY_1S			; Una vez que se enfria el agua espera 5s
		CALL DELAY_1S
		CALL DELAY_1S
		CALL DELAY_1S
		CALL DELAY_1S
		
		GOTO INICIO			; Volvemos a inicio, logrando un bucle infinito
			

;***************************************************************************
; Subrutina que incrementa registro TEMP_ACT													*
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
; Subrutina que decrementa registro TEMP_ACT							
;***************************************************************************

DECREMENTO_TEMP				; DECREMENTA DESDE TEMP_MAX hasta TEMP_MIN

		DECF TEMP_ACT,F	; Decrementamos la temperatura
		MOVFW TEMP_MIN		; Cargamos el regisro W con el valor de TEMP_ACT
		SUBWF TEMP_ACT,W		; Realizamos la resta entre la temperatura minima y la actual
		
		BTFSS STATUS,Z		; Si la temperatura es la minima que deje de decrementar
		
		GOTO DECREMENTO_TEMP	; Sino, que continue
		
		RETURN

		
;**************************************************************************
; Subrutinas de retardo
;**************************************************************************

DELAY_1MS	MOVLW D'250'				; Cargamos el valor 250 en W	
			MOVWF CONTADOR1			; Cargamos el valor de W en el primer contador

RETARDO_1	NOP
			DECFSZ CONTADOR1,F		; Decrementamos en 1 el primer contador
			GOTO RETARDO_1			; Repetimos la accion hasta que sea 0
			RETURN


DELAY_250MS	MOVLW D'250'				; Cargamos el valor 250 en W
			MOVWF CONTADOR2			; Cargamos el valor de W en el segundo contador

RETARDO_2	CALL DELAY_1MS			; Esperamos 1 milisegundo por cada
			DECFSZ CONTADOR2,F		; decremento del segundo contador
			GOTO RETARDO_2			; Repetimos la accion hasta que sea 0
			RETURN


DELAY_1S		MOVLW D'4'				; Cargamos el valor 4 en W
			MOVWF CONTADOR3			; Cargamos el valor de W en el tercer contador

RETARDO_3	CALL DELAY_250MS			; Esperamos 250 milisegundos por cada
			DECFSZ CONTADOR3,F		; decremento del tercer contador (250ms x 4 = 1000ms)
			GOTO RETARDO_3			; Repetimos la accion hasta que sea 0
			RETURN


;**************************************************************************
; Subrutinas para encender LEDS									   
;**************************************************************************
		
ENCENDER_LED_MAXIMO
		BSF STATUS,RP0	; Cambiamos al banco 1 para poder gestionar TRISB	
		BCF TRISB,1		; Seteamos como salida el bit RB1
		BCF STATUS,RP0	; Volvemos al banco 0 para gestionar PORTB
		BSF PORTB,1		; Habilitamos el pin RB1, es decir, prendemos el LED
		CALL DELAY_1S	; Retardo de 1 segundo
		BCF PORTB,1		; Deshabilitamos el pin RB2
		RETURN


ENCENDER_LED_MINIMO
		BSF STATUS,RP0	; Cambiamos al banco 1 para poder gestionar TRISB
		BCF TRISB,2		; Seteamos como salida el bit RB2
		BCF STATUS,RP0	; Volvemos al banco 0 para gestionar PORTB
		BSF PORTB,2		; Habilitamos el pin RB2, es decir, prendemos el LED
		CALL DELAY_1S	; Retardo de 1 segundo
		BCF PORTB,2		; Deshabilitamos el pin RB2
		RETURN
		
		END