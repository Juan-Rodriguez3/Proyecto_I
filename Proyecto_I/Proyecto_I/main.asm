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
.def	FLAG_STATE=R20						//Modos	


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
	LDI		R16, (PCIE1<<1)					//Setear PCIE1 en PCICR
	STS		PCICR, R16						
	LDI		R16, 0x1F						//Activar las interrupciones solo en los pines de botones
	STS		PCMSK1, R16

	//Deshabilitar comunicacion serial
	LDI		R16, 0x00
	STS		UCSR0B, R16

	//Valores iniciales
	LDI		SET_PB, 0x00
	LDI		MULTIPLEX_DISP, 0x00
	LDI		DISPLAY, 0x00
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
	LPM		DISPLAY, Z
	OUT		PORTD, DISPLAY
	LDI		R16,  0b00001111					//Encender los display.
	OUT		PORTB, R16
	//Apagar todas las leds de estado	
	CBI		PORTB, 4
	CBI		PORTB, 3   
	SBI		PORTC, 5						
	RJMP	MAIN

FECHA:
	LPM		DISPLAY, Z
	OUT		PORTD, DISPLAY
	LDI		R16,  0x01						//Encender el primero display.
	OUT		PORTB, R16
	//Apagar todas las leds de estado
	SBI		PORTB, 4
	SBI		PORTC, 5						
	RJMP	MAIN
		
CONFI_HORA:
	LPM		DISPLAY, Z
	OUT		PORTD, DISPLAY
	LDI		R16,  0x02						//Encender el primero display.
	OUT		PORTB, R16
	//encender la led de la hora
	SBI		PORTB, 4
	CBI		PORTC, 5
	RJMP	MAIN

CONFI_FECHA:
	LPM		DISPLAY, Z
	OUT		PORTD, DISPLAY
	LDI		R16,  0x03						//Encender el primero display.
	OUT		PORTB, R16
	LDI		MULTIPLEX_DISP, 0x07
	//Encender la led de la fecha
	CBI		PORTB, 4
	CBI		PORTC, 5					
	RJMP	MAIN

CONFI_ALARMA:
	LPM		DISPLAY, Z
	OUT		PORTD, DISPLAY
	LDI		R16,  0x04						//Encender el primero display.
	OUT		PORTB, R16
	//Encender la led de la alarma
	//LDI		R16, 0b00011111	
	//OUT		PORTC, R16
	SBI		PORTB, 4
	SBI		PORTC, 5
	RJMP	MAIN

OFF_ALARMA:
	LPM		DISPLAY, Z
	OUT		PORTD, DISPLAY
	LDI		R16,  0x05						//Encender el primero display.
	OUT		PORTB, R16
	//Apagar todas las leds de estado	
	SBI		PORTB, 4
	SBI		PORTC, 5						
	RJMP	MAIN
//*************Modos**************


ISR_PCINT1:
	IN		SET_PB, PINC					//Leer el puerto C
	SBRS	SET_PB, 4						//Verificar la bandera de cambio de modo
	INC		FLAG_STATE						//Incrementar para cambiar de modo				
	CPI		FLAG_STATE, 0x06				//Regresar al modo de hora.
	BRNE	RETORNO
	ADIW	Z, 1
	LD		DISPLAY, Z
	LDI		FLAG_STATE, 0x00				//Resetear el estado
RETORNO:
	RETI

// Tabla de conversi?n hexadecimal a 7 segmentos
TABLA:
    .DB 0xF3, 0x81, 0xEA, 0xE9, 0x99, 0x79, 0x7B, 0XC9, 0xFB, 0xF9