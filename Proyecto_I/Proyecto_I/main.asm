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
.cseg

.def	SET_PB_A=R17						//PUERTO C
.def	SET_PB_N=R21						
.def	DISPLAY=R18							//PUERTO D
.def	MULTIPLEX_DISP=R19					//PUERTO B
.def	FLAG_STATE=R20						//Modos		
.equ	T1VALUEH= 0xFC						//Valor inicial para la interrupción de 1 seg
.equ	T1VALUEL= 0x2F
.equ	T0VALUE=100

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
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16						// Habilitar cambio de PRESCALER
	LDI		R16, 0b00000100
	STS		CLKPR, R16						// Configurar Prescaler a 16 F_cpu = 1MH
	
	//Configuración de TIMER0
	LDI		R16, (1<<CS01) | (1<<CS00)		//Prescaler a 64
	OUT		TCCR0B, R16
	
	//Configuración de TIMER1
	LDI		R16, (1<<CS02) | (1<<CS00)		//Prescaler a 1024
	STS		TCCR1B, R16
	LDI		R16, (ICIE1<<1)					//Activar interrupciones timer1
	STS		TIMSK1, R16
	//Cargar el valor inicial al timer1 para interrupción cada segundo
	LDI		R16, T1VALUEH
	STS		TCNT1H, R16	
	LDI		R16, T1VALUEL
	STS		TCNT1L, R16	

	//Configuracion de puerto C
	LDI		R16, 0x20						//PINC0/4 entrada y PC5 salida
	OUT		DDRC, R16
	LDI		R16, 0b00011111						//PINC0/4 pullup activados y PC5 conduce 0 logico
	OUT		PORTC, R16

	//Configuracion de puerto B
	LDI		R16, 0x3F						//Todos los pines como salida
	OUT		DDRB, R16
	LDI		R16, 0x00						//Todos los pines conducen  logico
	OUT		PORTB, R16						

	//Confifuracion de puerto D
	LDI		R16, 0xFF						//Todos los pines como salida
	OUT		DDRD, R16						
	LDI		R16, 0x00						//Todos los pines conducen  logico
	OUT		PORTD, R16

	//Habilitar interrupciones en el puerto c
	LDI		R16, (1<<PCIE1)					//Setear PCIE1 en PCICR
	STS		PCICR, R16						
	LDI		R16, 0x1F						//Activar las interrupciones solo en los pines de botones
	STS		PCMSK1, R16

	//Deshabilitar comunicacion serial
	LDI		R16, 0x00
	STS		UCSR0B, R16

	//Valores iniciales
	LDI		SET_PB_A, 0x1F
	LDI		SET_PB_N, 0x00
	LDI		MULTIPLEX_DISP, 0x0F
	LDI		DISPLAY, 0x00
	LDI		R22, 0x00
	LDI		R23, 0x00
	LDI		FLAG_STATE, 0x00				//Por default inicia en el modo hora.

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
	//LDI		DISPLAY, 0xF3
	OUT		PORTD, DISPLAY
	LDI		MULTIPLEX_DISP, 0x0F
	OUT		PORTB, MULTIPLEX_DISP
	//Apagar todas las leds de estado	
	SBI		PORTB, 5
	SBI		PORTB, 4
	SBI		PORTC, 5						
	RJMP	MAIN

FECHA:
	OUT		PORTD, DISPLAY
	LDI		MULTIPLEX_DISP, 0x01
	OUT		PORTB, MULTIPLEX_DISP
	//Apagar todas las leds de estado
	SBI		PORTB, 5
	SBI		PORTB, 4
	SBI		PORTC, 5						
	RJMP	MAIN
		
CONFI_HORA:
	OUT		PORTD, DISPLAY
	LDI		MULTIPLEX_DISP, 0x02
	OUT		PORTB, MULTIPLEX_DISP
	//encender la led de la hora
	CBI		PORTB, 5
	CBI		PORTB, 4
	CBI		PORTC, 5
	RJMP	MAIN

CONFI_FECHA:
	OUT		PORTD, DISPLAY
	LDI		MULTIPLEX_DISP, 0x03
	OUT		PORTB, MULTIPLEX_DISP
	//Encender la led de la fecha
	CBI		PORTB, 5
	CBI		PORTB, 4
	SBI		PORTC, 5					
	RJMP	MAIN

CONFI_ALARMA:
	OUT		PORTD, DISPLAY
	LDI		MULTIPLEX_DISP, 0x04
	OUT		PORTB, MULTIPLEX_DISP
	SBI		PORTB, 5
	CBI		PORTC, 5
	RJMP	MAIN

OFF_ALARMA:
	OUT		PORTD, DISPLAY
	LDI		MULTIPLEX_DISP, 0x05
	OUT		PORTB, MULTIPLEX_DISP
	//Apagar todas las leds de estado	
	SBI		PORTB, 5
	SBI		PORTB, 4
	SBI		PORTC, 5						
	RJMP	MAIN
//*************Modos**************

//*************Configuración TIMER1**********
ISR_TIMER1:
	PUSH	R16
	//Reiniciar el contador del timer
	LDI		R16, T1VALUEH
	STS		TCNT1H, R16	
	LDI		R16, T1VALUEL
	STS		TCNT1L, R16
	ADIW	Z, 1					////mover el puntero
	//incrementar el contador
	INC		R22						//Incrementar contador
	CPI		R22, 10					//ovf
	BRNE	RETORN1
	//Reiniciar el puntero y contador
	LDI		ZH, HIGH(TABLA<<1)				
	LDI		ZL, LOW(TABLA<<1)									
	LDI		R22, 0x00
RETORN1:
	LPM		DISPLAY, Z
	POP		R16
	RETI
//*************Configuración TIMER1**********

//*************Configuración TIMER0**********

ISR_TIMER0:
	PUSH	R16 
	LDI		R16, 0x00
	STS		TIMSK0, R16						//Deshabilitar las interrupciones del timer0
	//Progra de antirevote
	IN		SET_PB_N, PINC			//Releer el pinc
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
	CP		SET_PB_N, SET_PB_A				
	BREQ	RETORNO	
	//Activar las interrupciones del timer0
	LDI		R16, (1<<TOIE0)
	STS		TIMSK0, R16						//Activar las interrupciones del timer0
	LDI		R16, T0VALUE
	OUT		TCNT0, R16						//establecer el valor inicial a TCNT0 para interrumpir cada 10ms
	RJMP	RETORNO

	//rutina de cambio de modo e incremento
	LDI		SET_PB_A, 0x1F					//El estado actual debe ser de nuevo sin pulsar ningún botón.
	SBRS	SET_PB_N, 4						//Verificar la bandera de cambio de modo
	INC		FLAG_STATE						//Incrementar para cambiar de modo				
	CPI		FLAG_STATE, 0x06				//Regresar al modo de hora.
	BRNE	RETORNO
	LDI		FLAG_STATE, 0x00				//Resetear el estado
RETORNO:
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI
//********Rutinas de interrupcion del pin C*******


// Tabla de conversi?n hexadecimal a 7 segmentos
TABLA:
    .DB 0xF3, 0x81, 0xEA, 0xE9, 0x99, 0x79, 0x7B, 0XC9, 0xFB, 0xF9