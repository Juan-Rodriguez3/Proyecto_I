;*******************************************
; Universidad del Valle de Guatemala
; IE2025: Programacion de Microcontroladores
;
; Author: Juan Rodriguez
; Proyecto: Proyecto I
; Hardware: ATmega328P
; Creado: 07/03/2025
; Modificado: 07/03/2025
; Descripcion: Reloj Digital con 4 modos.
;*****************************************

.include "M328PDEF.inc"
.def	SET_PB_A=R17						//PUERTO C
.def	SET_PB_N=R21						//Estado nuevo de botones
.def	DISPLAY=R18							//PUERTO D
.def	MULTIPLEX_DISP=R19					//PUERTO B
.def	FLAG_STATE=R20						//Bandera de Modos
.def	CONTADOR=R22						//Contador para displays	
.def	FLAG_POINTS=R23						//Bandera para parpadeo de puntos
.equ	T1VALUE= 0						//Valor inicial para la interrupción de 1 seg
.equ	T0VALUE=100
.equ	T2VALUE=225
.dseg

.org	SRAM_START
CPOINT: .byte	1
UMIN:	.byte	1
DMIN:	.byte	1
UHOR:	.byte	1
DHOR:	.byte	1

.cseg

.org 0x0000
	RJMP	SETUP								//Ir a la configuraciOn al inicio


.org PCI1addr								//Vector de interrupcion para PCINT1 (PORTC) //0x0008
    RJMP	ISR_PCINT1

.org OVF1addr
	RJMP	ISR_TIMER1

.org OVF0addr
	RJMP	ISR_TIMER0


	//Configuracion de pila //0x08FF
	LDI		R16, LOW(RAMEND)			// Cargar 0xFF a R16
	OUT		SPL, R16					// Cargar 0xFF a SPL
	LDI		R16, HIGH(RAMEND)			//	
	OUT		SPH, R16					// Cargar 0x08 a SPH

//Configurar MCU
SETUP:
	 CLI									//Deshabilitar interrupciones globales

	// Configurar Prescaler "Principal"
	LDI		R16, (1 << CLKPCE)  ; Cargar valor para habilitar cambios en CLKPR
    STS		CLKPR, R16          ; Escribir en CLKPR
    LDI		R16, (1 << CLKPS3)  ; Configurar prescaler en 8 (CLKPS3 = 1 -> Divisor 8)
    STS		CLKPR, r16          ; Escribir en CLKPR						// Configurar Prescaler a 16 F_cpu = 1MH

	//Configuración de TIMER2 
	LDI		R16, T2VALUE
    STS     TCNT2, R16							//Cargar el valor inicial para interupcion cada 5ms
    LDI     R16, (1 << CS21) | (1 << CS20)					//Prescaler de 8
    STS     TCCR2B, R16
	
	//Configuración de TIMER0
	LDI		R16, (1<<CS01) | (1<<CS00)			//Prescaler a 64
	OUT		TCCR0B, R16
	
	//Configuración de TIMER1
	LDI		R16,  (1 << CS12) | (1 << CS10)		//Prescaler a 1024
	STS		TCCR1B, R16
	LDI		R16, (1<<ICIE1)						//Activar interrupciones timer1
	STS		TIMSK1, R16

	//Cargar el valor inicial al timer1 para interrupción cada segundo
	LDI		R16, HIGH(T1VALUE)
	STS		TCNT1H, R16	
	LDI		R16, LOW(T1VALUE)
	STS		TCNT1L, R16	

	//Configuracion de puerto C
	LDI		R16, 0x30							//PINC0/3 entrada y PC5/4 salida
	OUT		DDRC, R16
	LDI		R16, 0b00001111						//PINC0/4 pullup activados y PC5/4 conduce 0 logico
	OUT		PORTC, R16

	//Configuracion de puerto B
	LDI		R16, 0x2F							//Todos los pines como salida excepto PB4
	OUT		DDRB, R16
	LDI		R16, 0x10							//Todos los pines conducen  logico y activar pullup PB4
	OUT		PORTB, R16						

	//Confifuracion de puerto D
	LDI		R16, 0xFF						//Todos los pines como salida
	OUT		DDRD, R16						
	LDI		R16, 0x00						//Todos los pines conducen  logico
	OUT		PORTD, R16

	//Habilitar interrupciones en el puerto C
	LDI		R16, (1<<PCIE1)					//Setear PCIE1 en PCICR
	STS		PCICR, R16						
	LDI		R16, 0x1F						//Activar las interrupciones solo en los pines de botones
	STS		PCMSK1, R16
	//Habilitar interrupciones en el puerto B
	LDI		R16, (1<<PCIE0)					//Setear PCIE0 en PCICR
	STS		PCICR, R16
	LDI		R16, 0x10						//Activar las interrupciones solo en el PINB4
	STS		PCMSK0, R16 

	//Deshabilitar comunicacion serial
	LDI		R16, 0x00
	STS		UCSR0B, R16

	//Valores iniciales
	LDI		R16, 0x10
	MOV		R3, R16
	LDI		R16, 0x30
	MOV		R2, R16
	LDI		SET_PB_A, 0x1F
	LDI		SET_PB_N, 0x00
	LDI		MULTIPLEX_DISP, 0x0F
	LDI		DISPLAY, 0x00
	LDI		FLAG_POINTS, 0x00					//Bandera para los puntos
	LDI		FLAG_STATE, 0x00					//Por default inicia en el modo hora.
	LDI		R16, 0x00
	STS		UMIN, R16	
	STS		DMIN, R16
	STS		UHOR, R16
	STS		DHOR, R16
	STS		CPOINT, R16
	LDS		CONTADOR, UMIN
	

	//Usar el puntero Z como salida de display
	LDI		ZH, HIGH(TABLA<<1)				//Carga la parte alta de la direcci?n de tabla en el registro ZH
	LDI		ZL, LOW(TABLA<<1)				//Carga la parte baja de la direcci?n de la tabla en el registro ZL
	LPM		DISPLAY, Z						//Carga en R18 el valor de la tabla en ela dirrecion Z
	OUT		PORTD, DISPLAY					//Muestra en el puerto D el valor leido de la tabla

	SEI										//Habilitar interrupciones globales

MAIN:
	//Utilizo flag state para saber en que modo estoy
	CPI		FLAG_STATE, 0x00
	BREQ	HORA
	CPI		FLAG_STATE, 0x01
	BREQ	FECHA
	CPI		FLAG_STATE, 0x02
	BREQ	CONFI_HORA
	CPI		FLAG_STATE, 0x03
	BREQ	CONFI_FECHA
	CPI		FLAG_STATE, 0x04
	BREQ	CONFI_ALARMA
	CPI		FLAG_STATE, 0x05   
	BREQ	OFF_ALARMA
	RJMP	MAIN

//*************Modos**************
HORA:
	//Apagar todas las leds de estado	
	SBI		PORTC, 4
	SBI		PORTC, 5
	//Multiplexeo
	//Unidades de minutos
	LDS		CONTADOR, UMIN
	CALL	MOV_POINTER
	SBI		PORTB, 3
	CALL	DELAY
	CBI		PORTB, 3
	//Decenas de minutos
	LDS		CONTADOR, DMIN
	CALL	MOV_POINTER2
	SBI		PORTB, 2
	CALL	DELAY
	CBI		PORTB, 2
	//Unidades de horas
	LDS		CONTADOR, UHOR
	CALL	MOV_POINTER
	SBI		PORTB, 1
	CALL	DELAY
	CBI		PORTB, 1
	//Decenas de horas
	LDS		CONTADOR, DHOR
	CALL	MOV_POINTER
	SBI		PORTB, 0
	CALL	DELAY
	CBI		PORTB, 0				
	RJMP	MAIN

FECHA:
	//Apagar todas las leds de estado
	SBI		PORTC, 4
	SBI		PORTC, 5						
	RJMP	MAIN
		
CONFI_HORA:
	OUT		PORTD, DISPLAY
	LDI		MULTIPLEX_DISP, 0x02
	OUT		PORTB, MULTIPLEX_DISP
	//encender la led de la hora
	CBI		PORTC, 4
	CBI		PORTC, 5
	RJMP	MAIN

CONFI_FECHA:
	OUT		PORTD, DISPLAY
	LDI		MULTIPLEX_DISP, 0x03
	OUT		PORTB, MULTIPLEX_DISP
	//Encender la led de la fecha
	CBI		PORTC, 4
	SBI		PORTC, 5					
	RJMP	MAIN

CONFI_ALARMA:
	OUT		PORTD, DISPLAY
	LDI		MULTIPLEX_DISP, 0x04
	OUT		PORTB, MULTIPLEX_DISP
	CBI		PORTC, 5
	SBI		PORTC, 4
	RJMP	MAIN

OFF_ALARMA:
	OUT		PORTD, DISPLAY
	LDI		MULTIPLEX_DISP, 0x05
	OUT		PORTB, MULTIPLEX_DISP
	//Apagar todas las leds de estado	
	SBI		PORTC, 4
	SBI		PORTC, 5						
	RJMP	MAIN
//*************Modos**************

//*************Configuración TIMER1**********
ISR_TIMER1:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16
	//Reiniciar el contador del timer
	LDI		R16, HIGH(T1VALUE)
	STS		TCNT1H, R16	
	LDI		R16, LOW(T1VALUE)
	STS		TCNT1L, R16	

	//incrementar el contador de unidades	
	LDS		CONTADOR, UMIN					//Pasar las UMIN al contador
	INC		CONTADOR						//Incrementar contador
	STS		UMIN, CONTADOR					//Actualizar el valor de UMIN

	//Overflow en unidades de minuto (10 minutos)
	CPI		CONTADOR, 10					//ovf
	BRNE	RETORN1

	//Reiniciar el contador de Unidades de minutos							
	LDI		CONTADOR, 0x00
	STS		UMIN, CONTADOR
	//Incrementar el contador de decenas de minutos
	LDS		CONTADOR, DMIN
	INC		CONTADOR
	STS		DMIN, CONTADOR
	//Overflow en decenas de minuto
	CPI		CONTADOR, 6 
	BRNE	RETORN1

	//Reiniciar el contador de decenas de minutos (60)
	LDI		CONTADOR, 0x00
	STS		DMIN, CONTADOR
	//Incrementar el contador de unidades de hora
	LDS		CONTADOR, UHOR
	INC		CONTADOR
	STS		UHOR, CONTADOR

	//El overflow de las unidades de hora dependen de las decenas de hora
	// si decenas= 1 | 0 el overflow >>> es en 9
	// si decenas=2  el overflow >>> es en 4
	LDS		CONTADOR, DHOR
	CPI		CONTADOR, 2
	BREQ	OVERF_2	

	//Overflow de unidades de hora con
	LDS		CONTADOR, UHOR					//Se vuelve a cargar para
	CPI		CONTADOR, 10
	BRNE	RETORN1
	LDI		CONTADOR, 0x00
	STS		UHOR, CONTADOR
	//Incrementar el contador de decenas de horas
	LDS		CONTADOR, DHOR
	INC		CONTADOR
	STS		DHOR, CONTADOR
	RJMP	RETORN1

OVERF_2:
	LDS		CONTADOR, UHOR					//Se vuelve a cargar para
	CPI		CONTADOR, 4
	BRNE	RETORN1
	//Reiniciar los contadores de unidades y decenas de hora
	LDI		CONTADOR, 0x00
	STS		UHOR, CONTADOR
	STS		DHOR, CONTADOR
	
RETORN1:
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI
//*************Configuración TIMER1**********

//*************Configuración TIMER0**********

ISR_TIMER0:
	PUSH	R16 
	IN		R16, SREG
	PUSH	R16
	LDI		R16, 0x00
	STS		TIMSK0, R16						//Deshabilitar las interrupciones del timer0
	//Progra de antirevote
	IN		SET_PB_N, PINC					//Releer el pinc
	EOR		SET_PB_N, R3					//Borrar el valor de PC4 y PC5 que son salidas
	IN		R16, PINB						//Releer el boton de cambio de modo
	SBRS	R16, 4
	EOR		SET_PB_N, R3					//Cambiar el bit 4
	CP		SET_PB_N, SET_PB_A
	BREQ	RETORN0
	MOV		SET_PB_A,SET_PB_N				//Actualizar el estado de los botones
	SBRS	SET_PB_N, 4
	INC		FLAG_STATE
	CPI		FLAG_STATE,0x06
	BRNE	RETORN0
	LDI		FLAG_STATE, 0x00
RETORN0:
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI
//*************Configuración TIMER1**********

//********Rutinas de interrupcion del pin C*******
ISR_PCINT1:
	//Guardar SREG y R16
	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	//Progra de antirebote
	IN		SET_PB_N, PINC					//Leer el puerto C
	EOR		SET_PB_N, R3					//Borrar el valor de PC4 y PC5 que son salidas
	IN		R16, PINB						//Leer el boton de cambio de modo
	SBRS	R16, 4
	EOR		SET_PB_N, R3					//Cambiar el bit 4 
	CP		SET_PB_N, SET_PB_A				
	BREQ	RETORNO	
	//Activar las interrupciones del timer0
	LDI		R16, (1<<TOIE0)
	STS		TIMSK0, R16						//Activar las interrupciones del timer0
	LDI		R16, T0VALUE
	OUT		TCNT0, R16						//establecer el valor inicial a TCNT0 para interrumpir cada 10ms
RETORNO:
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI
//********Rutinas de interrupcion del pin C*******

//********Subrutina**********
DELAY:
	IN		R16, TIFR2
	SBRS	R16, TOV2							//Hasta que la bandera de overflow se active
    RJMP    DELAY								//Se va a repetir el ciclo
    SBI		TIFR2, TOV2							//Limpiar la bandera
	LDI		R16, T2VALUE
    STS     TCNT2, R16							//Cargar el valor inicial 
    RET

MOV_POINTER:
	LDI		ZH, HIGH(TABLA<<1)				
	LDI		ZL, LOW(TABLA<<1)
	ADD		ZL, CONTADOR					//Se incrementa la parte baja
	ADC		ZH, R1							//Se suma 0 y el carro de la parte baja	
	LPM		DISPLAY, Z
	OUT		PORTD, DISPLAY 
	RET

MOV_POINTER2:
	LDI		ZH, HIGH(TABLA2<<1)				
	LDI		ZL, LOW(TABLA2<<1)
	ADD		ZL, CONTADOR					//Se incrementa la parte baja
	ADC		ZH, R1							//Se suma 0 y el carro de la parte baja	
	LPM		DISPLAY, Z
	OUT		PORTD, DISPLAY 
	RET

//********Subrutinas**********

// Tabla de conversi?n hexadecimal a 7 segmentos
TABLA:
    .DB 0xF3, 0x81, 0xEA, 0xE9, 0x99, 0x79, 0x7B, 0xC1, 0xFB, 0xF9

TABLA2:
	.DB 0xF3, 0x12, 0xE6, 0xE5, 0x95, 0x75