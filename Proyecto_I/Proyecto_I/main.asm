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

.def	SET_PB=R17							//PUERTO C
.def	DISPLAY=R18							//PUERTO D
.def	MULTIPLEX_DISP=R19					//PUERTO B


.org 0x0000
	RJMP SETUP								//Ir a la configuraciOn al inicio


.org PCI1addr								//Vector de interrupcion para PCINT1 (PORTC) //0x0008
    RJMP ISR_PCINT1

//Configurar MCU
SETUP:
	 CLI									//Deshabilitar interrupciones globales

	// Configurar Prescaler "Principal"
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16						// Habilitar cambio de PRESCALER
	LDI		R16, 0b00000100
	STS		CLKPR, R16						// Configurar Prescaler a 16 F_cpu = 1MH

	//Configuracion de puerto C
	LDI		R16, 0x10						//PINC0/4 entrada y PC5 salida
	OUT		DDRC, R16
	LDI		R16, 0x0F						//PINC0/4 pullup activados y PC5 conduce 0 logico
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
	LDI		R16, (PCIE1<<1)					//Setear PCIE1 en PCICR
	OUT		PCICR, R16						
	LDI		R16, 0x1F						//Activar las interrupciones solo en los pines de botones
	OUT		PCMSK1, R16

	//Deshabilitar comunicacion serial
	LDI		R16, 0x00
	STS		UCSR0B, R16

	//Valores iniciales
	LDI		SET_PB, 0x00
	LDI		MULTIPLEX_DISP, 0x00
	LDI		DISPLAY, 0x00
	
	//Usar el puntero Z como salida de display
	LDI		ZH, HIGH(TABLA<<1)				//Carga la parte alta de la direcci?n de tabla en el registro ZH
	LDI		ZL, LOW(TABLA<<1)				//Carga la parte baja de la direcci?n de la tabla en el registro ZL
	LPM		DISPLAY, Z						//Carga en R18 el valor de la tabla en ela dirrecion Z
	OUT		PORTD, DISPLAY					//Muestra en el puerto D el valor leido de la tabla

	SEI										//Habilitar interrupciones globales

MAIN:
	RJMP MAIN




ISR_PCINT1:
	RETI

// Tabla de conversi?n hexadecimal a 7 segmentos
TABLA:
    .DB 0x77, 0x50, 0x3B, 0x7A, 0x5C, 0x6E, 0x6F, 0x70, 0x7F, 0x7E, 0x7D, 0x4F, 0x27, 0x5B, 0x2F, 0x2D	