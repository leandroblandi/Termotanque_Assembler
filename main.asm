
;***************************************************************************
; Programa main.asm (PIC16F628A)	Fecha de inicio de proyecto: 04-10-2022	
; Autor: Leandro N. Blandi												
; Este programa simula las temperaturas de agua de un termotanque, desde	
; 35°C hasta 70°C, generando 5 segundos de retardo después de cada limite
; implementando un registro CANILLA_ABIERTA que varia la velocidad de 
; enfriamiento.
; - Velocidad del Reloj: 4MHz		- Tipo de Reloj: Interno				
; - Perro guardián: OFF			- Protección de código: OFF											
;***************************************************************************


;***************************************************************************
; Zona de datos														
;***************************************************************************

		__CONFIG 3F10
		LIST		P=16F628A
		INCLUDE	<P16F628A.INC>
		ERRORLEVEL -302


;***************************************************************************
; Zona de codigos														
;***************************************************************************
	
		CBLOCK 0x20		; Reservamos una serie de direcciones de memoria para los alias
		
		TEMP_ACT			; 0x20	Esta temperatura sera dinamica
		TEMP_MIN			; 0x21	Este servira como limite inferior
		TEMP_MAX			; 0x22	'''  '''     '''  '''    superior
		
		CANILLA_ABIERTA	; 0x23	Este registro se ira complementando
				
		CONTADOR1		; 0x24	Registros para los retardos
		CONTADOR2		; 0x25	'''
		CONTADOR3		; 0x26	'''
		CONTADOR4		; 0x27	'''
	
		ENDC

		ORG 0x00
		
		CALL CONFIGURAR_PUERTOS	; Configuramos los puertos de salida
		CALL CONFIGURAR_SENSORES	; Seteamos los valores iniciales de los 'sensores'
		GOTO INICIO


;**************************************************************************
; Subrutina principal												   
;**************************************************************************
				
INICIO	
		COMF CANILLA_ABIERTA,F	; Complementa el registro canilla
		
		CALL CALENTAR_AGUA	; Que el agua comience a calentarse hasta el maximo
		CALL DELAY_5S		; Una vez que calienta el agua espera 5s
		
		CALL ENFRIAR_AGUA		; Que el agua empiece a enfriarse
		CALL DELAY_5S		; Una vez que se enfria el agua espera 5s
		
		GOTO INICIO			; Volvemos a inicio, logrando un bucle infinito


;***************************************************************************
; Subrutina de configuracion de sensores
;***************************************************************************

CONFIGURAR_SENSORES
		MOVLW D'25'			; Cargamos en W el valor inicial de la temperatura actual
		MOVWF TEMP_ACT		; Cargamos el valor de W en la temperatura actual

		MOVLW D'35'			; Cargamos en W el valor de la temperatura minima
		MOVWF TEMP_MIN		; Cargamos el valor de W en la temperatura minima

		MOVLW D'70'			; Cargamos en W el valor de la temperatura maxima
		MOVWF TEMP_MAX		; Cargamos el valor de W en la temperatura maxima
		
		CLRF CANILLA_ABIERTA	; Que por defecto la canilla este 'cerrada'
		
		RETURN


;***************************************************************************
; Subrutina que incrementa registro TEMP_ACT													*
;***************************************************************************

CALENTAR_AGUA
		MOVFW TEMP_ACT		; Restamos TEMP_MAX - TEMP_ACT
		SUBWF TEMP_MAX,W		; Para cerciorarnos de que TEMP_ACT > TEMP_ACT

		BTFSC STATUS,C		; Si TEMP_ACT > TEMP_MAX salta
		CALL CALENTAR_AGUA_0	; Si TEMP_ACT < TEM_MAX ejecuta CALENTAR_AGUA_0

		CALL ENCENDER_LED_MAXIMO	; Que se encienda el LED para avisar que ya esta caliente

		RETURN
		
		
CALENTAR_AGUA_0	
		
		INCF TEMP_ACT,F			; Es como TEMP_ACT = TEMP_ACT + 1	
		CALL LED_RESISTENCIA_PRENDIDA
		
		MOVFW TEMP_ACT			; Restamos TEMP_MAX - TEMP_ACT
		SUBWF TEMP_MAX,W			; Si son iguales, el Z del status tiene que ser 1
		
		BTFSS STATUS,Z			; Salta si STATUS,Z es 1
		GOTO CALENTAR_AGUA_0		; Si no llego que siga incrementando
		
		RETURN


;***************************************************************************
; Subrutina que decrementa registro TEMP_ACT							
;***************************************************************************

ENFRIAR_AGUA
		MOVFW TEMP_MIN			; Verificamos que la temperatura actual sea mayor que
		SUBWF TEMP_ACT,W			; la minima mediante la resta W = TEMP_ACT - TEMP_MIN
		
		BTFSC STATUS,C			; Si la temperatura es menor que la minima, que salte
		
		CALL ENFRIAR_AGUA_0		; Sino que decremente
		CALL ENCENDER_LED_MINIMO	; Que se encienda el LED para avisar que se enfrio
		
		RETURN

ENFRIAR_AGUA_0
		DECF TEMP_ACT,F			; Decrementamos la temperatura en 1
		CALL LED_RESISTENCIA_APAGADA
		
		BTFSC CANILLA_ABIERTA,0		; Si la canilla esta abierta
		CALL ENFRIAR_AGUA_MAS_RAPIDO	; Entonces que decremente de a 5
		
		MOVFW TEMP_MIN			; Cargamos el regisro W con el valor de TEMP_ACT
		SUBWF TEMP_ACT,W			; Realizamos la resta entre la temperatura minima y la actual	
		
		BTFSS STATUS,Z			; Si la temperatura es la minima que deje de decrementar	
		GOTO ENFRIAR_AGUA_0		; Sino, que continue
		
		RETURN
		
		
		
		
ENFRIAR_AGUA_MAS_RAPIDO
		MOVLW D'4'				; Cargamos el valor a decrementar
		SUBWF TEMP_ACT,F			; Es como TEMP_ACT = TEMP_ACT - 4
		RETURN

		
;**************************************************************************
; Subrutinas de retardo
;**************************************************************************

DELAY_1MS	
		MOVLW D'250'				; Cargamos el valor 250 en W	
		MOVWF CONTADOR1			; Cargamos el valor de W en el primer contador

RETARDO_1	
		NOP
		DECFSZ CONTADOR1,F		; Decrementamos en 1 el primer contador
		GOTO RETARDO_1			; Repetimos la accion hasta que sea 0
		RETURN


DELAY_250MS	
		MOVLW D'250'				; Cargamos el valor 250 en W
		MOVWF CONTADOR2			; Cargamos el valor de W en el segundo contador

RETARDO_2	
		CALL DELAY_1MS			; Esperamos 1 milisegundo por cada
		DECFSZ CONTADOR2,F		; decremento del segundo contador
		GOTO RETARDO_2			; Repetimos la accion hasta que sea 0
		RETURN


DELAY_1S		
		MOVLW D'4'				; Cargamos el valor 4 en W
		MOVWF CONTADOR3			; Cargamos el valor de W en el tercer contador

RETARDO_3	
		CALL DELAY_250MS			; Esperamos 250 milisegundos por cada
		DECFSZ CONTADOR3,F		; decremento del tercer contador (250ms x 4 = 1000ms)
		GOTO RETARDO_3			; Repetimos la accion hasta que sea 0
		RETURN

DELAY_5S		
		MOVLW D'5'				; Cargamos el valor 4 en W
		MOVWF CONTADOR4			; Cargamos el valor de W en el cuarto contador

RETARDO_4	
		CALL DELAY_1S			; Esperamos 1 segundo por cada decremento
		DECFSZ CONTADOR4,F		; del cuarto contador (1s x 5 = 5s)
		GOTO RETARDO_4			; Repetimos la accion hasta que sea 0
		RETURN


;**************************************************************************
; Subrutinas de configuracion de puertos									   
;**************************************************************************

CONFIGURAR_PUERTOS	
		BSF	STATUS,RP0
		MOVLW B'11110000'		; Seteamos RB0, RB1, RB2 como salida	
		MOVWF TRISB			; En TRISB
		BCF STATUS,RP0
		RETURN


;**************************************************************************
; Subrutinas para encender LEDS									   
;**************************************************************************

LED_RESISTENCIA_APAGADA
		BCF STATUS,RP0	; Volvemos al banco 0 para gestionar PORTB
		BSF PORTB,0		; Habilitamos RB0, es decir, prendemos el LED
		CALL DELAY_250MS	; Retardo de 250ms
		BCF PORTB,0		; Deshabilitamos RB0
		RETURN
		

ENCENDER_LED_MAXIMO
		BCF STATUS,RP0	; Volvemos al banco 0 para gestionar PORTB
		BSF PORTB,1		; Habilitamos el pin RB1, es decir, prendemos el LED
		CALL DELAY_250MS	; Retardo de 250ms
		BCF PORTB,1		; Deshabilitamos el pin RB1
		RETURN


LED_RESISTENCIA_PRENDIDA
		BCF STATUS,RP0	; Volvemos al banco 0 para gestionar PORTB
		BSF PORTB,2		; Habilitamos RB2, es decir prendemos el LED
		CALL DELAY_250MS	; Retardo de 250ms
		BCF PORTB,2		; Deshabilitamos RB2
		RETURN
		

ENCENDER_LED_MINIMO
		BCF STATUS,RP0	; Volvemos al banco 0 para gestionar PORTB
		BSF PORTB,3		; Habilitamos el pin RB2, es decir, prendemos el LED
		CALL DELAY_250MS	; Retardo de 1 segundo
		BCF PORTB,3		; Deshabilitamos el pin RB2
		RETURN
		END