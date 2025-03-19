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
.def	SET_PB_A=R17						//Estado de los botones
.def	SET_PB_N=R18						//PUERTO C
.def	DISPLAY=R19							//PUERTO D
.def	FLAG_STATE=R20						//Bandera de Modos
.def	CONTADOR=R21						//Contador para displays	
.def	FLAGS_MP=R22						//Bandera Multiproposito
.def	LIMIT_OVF=R23						//Contador de dias y meses
.def	DIAS=R24							//Contador de dias y meses
.equ	T1VALUE= 64558						//Valor inicial para la interrupci?n de 1 seg
.equ	T0VALUE=100							//Valor para interrupci?n de 10 ms
.equ	T2VALUE=224							//Valor para interrupci?n de 2 ms
.dseg

.org	SRAM_START
UMIN:	.byte	1
DMIN:	.byte	1
UHOR:	.byte	1
DHOR:	.byte	1
UDIAS:	.byte	1
DDIAS:	.byte	1
UMES:	.byte	1
DMES:	.byte	1

.cseg

.org 0x0000
	RJMP	SETUP								//Ir a la configuraciOn al inicio

.org PCI1addr
	RJMP	ISR_PCINT1

.org OVF1addr
	RJMP	ISR_TIMER1

.org OVF0addr
	RJMP	ISR_TIMER0

		//Configuracion de pila //0x08FF
	LDI		R16, LOW(RAMEND)						// Cargar 0xFF a R16
	OUT		SPL, R16								// Cargar 0xFF a SPL
	LDI		R16, HIGH(RAMEND)						//	
	OUT		SPH, R16								// Cargar 0x08 a SPH

//Configurar MCU
SETUP:
	CLI												//Deshabilitar interrupciones globales

	// Configurar Prescaler "Principal"
	LDI R16, (1 << CLKPCE)
	STS CLKPR, R16									// Habilitar cambio de PRESCALER
	LDI R16, 0b00000100
	STS CLKPR, R16									// Configurar Prescaler a 16 F_cpu = 1MHz

	//Configuracion de TIMER2 
	LDI		R16, T2VALUE
    STS     TCNT2, R16								//Cargar el valor inicial para interupcion cada 2ms
    LDI     R16, (1 << CS21) | (1 << CS20)			//Prescaler de 64
    STS     TCCR2B, R16
	
	//Configuracion de TIMER0
	LDI		R16, (1<<CS01) | (1<<CS00)				//Prescaler a 64
	OUT		TCCR0B, R16
	
	//Configuracion de TIMER1
	LDI		R16,  0x05								//Prescaler a 1024
	STS		TCCR1B, R16
	LDI		R16, (1 << TOIE1)						//Activar interrupciones timer1
	STS		TIMSK1, R16

	//Cargar el valor inicial al timer1 para interrupci?n cada segundo
	LDI		R16, HIGH(T1VALUE)
	STS		TCNT1H, R16	
	LDI		R16, LOW(T1VALUE)
	STS		TCNT1L, R16	

	//Configuracion de puerto C
	LDI		R16, 0x30								//PINC0/3 entrada y PC5/4 salida
	OUT		DDRC, R16
	LDI		R16, 0b00001111							//PINC0/4 pullup activados y PC5/4 conduce 0 logico
	OUT		PORTC, R16

	//Configuracion de puerto B
	LDI		R16, 0x2F								//Todos los pines como salida excepto PB4
	OUT		DDRB, R16
	LDI		R16, 0x10								//Todos los pines conducen  logico y activar pullup PB4
	OUT		PORTB, R16						

	//Confifuracion de puerto D
	LDI		R16, 0xFF								//Todos los pines como salida
	OUT		DDRD, R16								
	LDI		R16, 0x00								//Todos los pines conducen  logico
	OUT		PORTD, R16								
													
	//Habilitar interrupciones en el puerto C		
	LDI		R16, (1<<PCIE1)							//Setear PCIE1 en PCICR
	STS		PCICR, R16								
	LDI		R16, 0x0F								//Activar las interrupciones solo en los pines de botones
	STS		PCMSK1, R16								
													
	//Deshabilitar comunicacion serial				
	LDI		R16, 0x00								
	STS		UCSR0B, R16								
													
	//Valores iniciales								
	LDI		SET_PB_A, 0x1F							
	LDI		SET_PB_N, 0x00							
	LDI		DISPLAY, 0x00							
	LDI		FLAGS_MP, 0x00							//Bandera para los puntos
	LDI		FLAG_STATE, 0x00						//Por default inicia en el modo hora.
	LDI		LIMIT_OVF, 0x00							//Comparar los dias con este registro
	LDI		DIAS, 28
	LDI		R25, 32									//OVF de mes para meses que terminan 1
	LDI		R26, 31									//OVF de mes para meses que terminan 0
	//HORA
	STS		UMIN, R16								
	STS		DMIN, R16								
	STS		UHOR, R16								
	STS		DHOR, R16		
	//DIAS																	
	STS		DMES, R16
	LDI		R16, 0x01
	STS		UMES, R16
	LDI		R16, 0x08
	STS		UDIAS, R16
	LDI		R16, 0x02	
	STS		DDIAS, R16								
	LDS		CONTADOR, UMIN							
													
													
	//Usar el puntero Z como salida de display		
	LDI		ZH, HIGH(TABLA<<1)						//Carga la parte alta de la direcci?n de tabla en el registro ZH
	LDI		ZL, LOW(TABLA<<1)						//Carga la parte baja de la direcci?n de la tabla en el registro ZL
	LPM		DISPLAY, Z								//Carga en R18 el valor de la tabla en ela dirrecion Z
	OUT		PORTD, DISPLAY							//Muestra en el puerto D el valor leido de la tabla
													
	SEI												//Habilitar interrupciones globales
	RJMP MAIN										
													
//Coloco este estado aca por el limite del	BREQ
/********************Modos********************/	
OFFAA:
	//Verificar los datos para el multiplexeo HORAS
	LDI		R16, 0x40								//LDI	R16, (1<<HORA)
	//Encender la bandera de HORA
	SBRS	FLAGS_MP, 6
	EOR		FLAGS_MP, R16

	LDI		R16, 0x80								//LDI	R16, (1<<FECHA)
	//Apagar la bandera de fecha
	SBRC	FLAGS_MP, 7
	EOR		FLAGS_MP, R16
													
	//Apagar todas las leds de estado				
	SBI		PORTB, 4								
	SBI		PORTC, 5		
	
	//Actualizar CLK							
	SBRC	FLAGS_MP, 5								//Si el bit CLK esta LOW saltar
	CALL	LOGICH

	//Actualizar fecha
	SBRC	FLAGS_MP, 0								//Si FLAG OVFD >> SET actualizar fecha																																			
	CALL	LOGICF	
							
	RJMP	MAIN													

CONFI_ALARMA:
	//Verificar los datos para el multiplexeo HORAS
	LDI		R16, 0x40								//LDI	R16, (1<<HORA)
	
	//Encender la bandera de HORA
	SBRS	FLAGS_MP, 6
	EOR		FLAGS_MP, R16
	LDI		R16, 0x80								//LDI	R16, (1<<FECHA)
	
	//Apagar la bandera de fecha
	SBRC	FLAGS_MP, 7
	EOR		FLAGS_MP, R16								
	
	//Encender la led de alarma (ROJA)				
	SBI		PORTC, 5								
	CBI		PORTC, 4
	
	//Actualizar CLK							
	SBRC	FLAGS_MP, 5								//Si el bit CLK esta LOW saltar
	CALL	LOGICH
	
	//Actualizar fecha
	SBRC	FLAGS_MP, 0								//Si FLAG OVFD >> SET actualizar fecha																																			
	CALL	LOGICF					
				
	RJMP	MAIN												
/********************Modos********************/
													
/******************LOOP***********************/		
MAIN:												
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
	BREQ	OFFAA									
	RJMP	MAIN									
/*******************LOOP***********************/		
													
													
/********************Modos********************/		
HORA:
	//Verificar los datos para el multiplexeo HORAS
	LDI		R16, 0x40								//LDI	R16, (1<<HORA)
	//Encender la bandera de HORA
	SBRS	FLAGS_MP, 6
	EOR		FLAGS_MP, R16

	LDI		R16, 0x80								//LDI	R16, (1<<FECHA)
	//Apagar la bandera de fecha
	SBRC	FLAGS_MP, 7
	EOR		FLAGS_MP, R16						
										
	//Apagar todas las leds de estado				
	SBI		PORTC, 4								
	SBI		PORTC, 5	

	//Actualizar reloj							
	SBRC	FLAGS_MP, 5								//Si el bit CLK esta LOW saltar
	CALL	LOGICH	

	//Actualizar fecha
	SBRC	FLAGS_MP, 0
	CALL	LOGICF

	//Multiplexeo								
	CALL	MULTIPLEX								
	RJMP	MAIN									
													
FECHA:		
	//Verificar los datos para el multiplexeo FECHAS
	LDI		R16, 0x40								//LDI	R16, (1<<HORA)
	//Apagar la bandera de HORA
	SBRC	FLAGS_MP, 6
	EOR		FLAGS_MP, R16

	LDI		R16, 0x80								//LDI	R16, (1<<FECHA)
	//Encender la bandera de fecha
	SBRS	FLAGS_MP, 7
	EOR		FLAGS_MP, R16
											
	//Apagar todas las leds de estado				
	SBI		PORTC, 4								
	SBI		PORTC, 5

	//Actualizar CLK							
	SBRC	FLAGS_MP, 5								//Si el bit CLK esta LOW saltar
	CALL	LOGICH		

	//Mostrar fecha						
	SBRC	FLAGS_MP, 0								//Si FLAG OVFD >> SET actualizar fecha																																			
	CALL	LOGICF										
	CALL	MULTIPLEX								
	RJMP	MAIN									
													
CONFI_HORA:	
	//encender la led de la hora (AZUL)				
	CBI		PORTC, 4								
	CBI		PORTC, 5	

	//Verificar los datos para el multiplexeo HORAS
	LDI		R16, 0x40								//LDI	R16, (1<<HORA)
	//Encender la bandera de HORA
	SBRS	FLAGS_MP, 6
	EOR		FLAGS_MP, R16

	LDI		R16, 0x80								//LDI	R16, (1<<FECHA)
	//Apagar la bandera de fecha
	SBRC	FLAGS_MP, 7
	EOR		FLAGS_MP, R16

	//Unidades o decenas


	//Incrementar o decrementar
	SBRC	FLAGS_MP, 1								// Si Incrementar --> 1 incrementar
	CALL	INCREMENTAR
	SBRC	FLAGS_MP, 2								//Si Decrementar --> 1 decrementar
	CALL	DECREMENTAR
	CALL	MULTIPLEX											
	RJMP	MAIN									
													
CONFI_FECHA:	
	//Encender la led de la fecha (VERDE)			
	SBI		PORTC, 4								
	CBI		PORTC, 5

	//Verificar los datos para el multiplexeo FECHAS
	LDI		R16, 0x40								//LDI	R16, (1<<HORA)
	//Apagar la bandera de HORA
	SBRC	FLAGS_MP, 6
	EOR		FLAGS_MP, R16
	
	LDI		R16, 0x80								//LDI	R16, (1<<FECHA)
	//Encender la bandera de fecha
	SBRS	FLAGS_MP, 7
	EOR		FLAGS_MP, R16
	
	//Incrementar o decrementar
	SBRC	FLAGS_MP, 1								// Si Incrementar --> 1 incrementar
	CALL	INCREMENTAR
	SBRC	FLAGS_MP, 2								//Si Decrementar --> 1 decrementar
	CALL	DECREMENTAR
	CALL	MULTIPLEX						
	RJMP	MAIN																	
													
/*************Modos**************/					
													
/*************Configuraci?n TIMER1**********/		
ISR_TIMER1:																			
	PUSH	R16										
	IN		R16, SREG								
	PUSH	R16										
	//Reiniciar el contador del timer				
	LDI		R16, HIGH(T1VALUE)						
	STS		TCNT1H, R16								
	LDI		R16, LOW(T1VALUE)						
	STS		TCNT1L, R16				
	
	//Activar bandera para incrementar unidades de tiempo
	LDI		R16, 0x20								//LDI R16, (1<<CLK)
	EOR		FLAGS_MP, R16	
		
	//Retorno	
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI		
/***************Configuraci?n TIMER1************/

/***************Configuraci?n TIMER0************/

ISR_TIMER0:
	PUSH	R16 
	IN		R16, SREG
	PUSH	R16
	LDI		R16, 0x00
	STS		TIMSK0, R16									//Deshabilitar las interrupciones del timer0

	//Progra de antirevote
	IN		SET_PB_N, PINC								//Releer el pinc
	CP		SET_PB_N, SET_PB_A
	BREQ	RETORN0
	MOV		SET_PB_A,SET_PB_N							//Actualizar el estado de los botones
	//Revisar que boton se presiono
	//Botones de configuracion.
	LDI		R16, 0x02									//LDI	R16, (1<<Incrementar)
	SBRS	SET_PB_N, 0									//Si presiono el boton 0, el bit 0 esta en LOW
	EOR		FLAGS_MP, R16								//encender la bandera de incremento
	LDI		R16, 0x04									//LDI	R16, (1<<Decrementar)
	SBRS	SET_PB_N, 1									//Si presiono el boton 1, el bit 1 esta en LOW
	EOR		FLAGS_MP, R16								//Encender la bandera de decremento
	LDI		R16, 0x08									//LDI	R16, (1<<UNIDEC) 
	SBRS	SET_PB_N, 2									//Si presiono el boton 2, el bit 2 esta en LOW
	EOR		FLAGS_MP, R16									//Encender la bandera de uni
	//Boton de cambio de modo
	SBRS	SET_PB_N, 3
	INC		FLAG_STATE
	CPI		FLAG_STATE,0x06
	BRNE	RETORN0
	LDI		FLAG_STATE, 0x00

RETORN0:
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI
//*************Configuraci?n TIMER1**********

//********Rutinas de interrupcion del pin C*******
ISR_PCINT1:
	//Guardar SREG y R16
	PUSH	R16
	IN		R16, SREG
	PUSH	R16
	//Progra de antirebote
	IN		SET_PB_N, PINC								//Leer el puerto C
	CP		SET_PB_N, SET_PB_A				
	BREQ	RETORNO	
	//Activar las interrupciones del timer0
	LDI		R16, (1<<TOIE0)
	STS		TIMSK0, R16									//Activar las interrupciones del timer0
	LDI		R16, T0VALUE
	OUT		TCNT0, R16									//establecer el valor inicial a TCNT0 para interrumpir cada 10ms
RETORNO:
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI
//********Rutinas de interrupcion del pin C*******

/***************Subrutinas***************/
DELAY:
	IN		R16, TIFR2
	SBRS	R16, TOV2									//Hasta que la bandera de overflow se active
    RJMP    DELAY										//Se va a repetir el ciclo
    SBI		TIFR2, TOV2									//Limpiar la bandera
	LDI		R16, T2VALUE
    STS     TCNT2, R16									//Cargar el valor inicial 
    RET

/***************Mover los punteros***************/
MOV_POINTER:
	LDI		ZH, HIGH(TABLA<<1)				
	LDI		ZL, LOW(TABLA<<1)
	ADD		ZL, CONTADOR								//Se incrementa la parte baja
	ADC		ZH, R1										//Se suma 0 y el carro de la parte baja	
	LPM		DISPLAY, Z
	OUT		PORTD, DISPLAY 
	RET

MOV_POINTER2:
	LDI		ZH, HIGH(TABLA2<<1)				
	LDI		ZL, LOW(TABLA2<<1)
	ADD		ZL, CONTADOR								//Se incrementa la parte baja
	ADC		ZH, R1										//Se suma 0 y el carro de la parte baja	
	LPM		DISPLAY, Z
	OUT		PORTD, DISPLAY 
	RET
/***************Mover los punteros***************/

/***************Multiplexeo para fechas***************/
MULTIPLEX:
	//Unidades de minutos/MES
	SBRC	FLAGS_MP, 6								// HORA --> 1 usar unidades de minuto
	LDS		CONTADOR, UMIN
	SBRC	FLAGS_MP, 7								// FECHA --> 1 usar unidades mes
	LDS		CONTADOR, UMES
	CALL	MOV_POINTER
	SBI		PORTB, 3
	CALL	DELAY
	CBI		PORTB, 3

	//Decenas de minutos/MES
	SBRC	FLAGS_MP, 6								// HORA --> 1 usar decenas de minuto
	LDS		CONTADOR, DMIN
	SBRC	FLAGS_MP, 7								// FECHA --> 1 usar decenas mes
	LDS		CONTADOR, DMES
	CALL	MOV_POINTER2
	SBI		PORTB, 2
	CALL	DELAY
	CBI		PORTB, 2

	//Unidades de horas/dias
	SBRC	FLAGS_MP, 6								// HORA --> 1 usar unidades de horas
	LDS		CONTADOR, UHOR
	SBRC	FLAGS_MP, 7								// FECHA --> 1 usar Unidades de dias
	LDS		CONTADOR, UDIAS
	CALL	MOV_POINTER
	SBI		PORTB, 1
	CALL	DELAY
	CBI		PORTB, 1

	//Decenas de horas/dias
	SBRC	FLAGS_MP, 6								// HORA --> 1 usar decenas de hpras
	LDS		CONTADOR, DHOR
	SBRC	FLAGS_MP, 7								// FECHA --> 1 usar decenas dias
	LDS		CONTADOR, DDIAS
	CALL	MOV_POINTER
	SBI		PORTB, 0
	CALL	DELAY
	CBI		PORTB, 0
	RET
/***************Multiplexeo para fechas**********************/

/***************Logica de CLK**********************/
LOGICH:	
	//Limpiar bandera de clock
	LDI		R16, 0x20								//LDI	R16, (1<<CLK)
	EOR		FLAGS_MP, R16
													
	//incrementar el contador de unidades			
	LDS		CONTADOR, UMIN							//Pasar las UMIN al contador
	INC		CONTADOR								//Incrementar contador
	STS		UMIN, CONTADOR							//Actualizar el valor de UMIN

	//Overflow en unidades de minuto (10 minutos)
	CPI		CONTADOR, 10							//ovf
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

	//Overflow de unidades de hora para decenas 0-1
	LDS		CONTADOR, UHOR								//Se vuelve a cargar las unidades para comparar
	CPI		CONTADOR, 10
	BRNE	RETORN1
	LDI		CONTADOR, 0x00								//reiniciar el contador de unidades
	STS		UHOR, CONTADOR

	//Incrementar el contador de decenas de horas
	LDS		CONTADOR, DHOR
	INC		CONTADOR
	STS		DHOR, CONTADOR
	RJMP	RETORN1

//OVF de unidades para decenas de 2
OVERF_2:
	LDS		CONTADOR, UHOR								//se cargan las unidades para comparar
	CPI		CONTADOR, 4									//Esta vez el limite es 4
	BRNE	RETORN1

	//Reiniciar los contadores de unidades y decenas de hora
	LDI		CONTADOR, 0x00								//reiniciar contadores de unidades y decenas de horas
	STS		UHOR, CONTADOR
	STS		DHOR, CONTADOR

	//Encender bandera que incrementa DIAS
	LDI		R16, 0x01									//LDI	R16, (1<<OVFD)
	EOR		FLAGS_MP, R16								
RETORN1:
	RET
/***************Logica de CLK**********************/

/***************Logica para ovf de modo fecha***************/
LOGICF:
	//Resetear la bandera CLK
	LDI		R16, 0x01									//LDI	R16, (1<<OVFD)
	EOR		FLAGS_MP, R16

	//Ver que la logica a usar dependende si estamos antes de agosto o despues
	LDS		R16, UMES
	CPI		R16, 8										//Si es igual a 7 ir LOVF2
	BRNE	LOVF1										//mientra no sea igual a 7 ir LOVF1
LOVF2:
	/*De Agosto (0x07) a diciembre (0x0B) los meses de 31 dias terminan en 0
	Los de 30 terminan en 1*/
	LDI		R25, 31										//Se cambia la lógica
	LDI		R26, 32
LOVF1:
	//De enero (0x01) a Julio (0x07) los meses de 31 dias terminan en 1
	//Los de 30 terminan en 0 excepto febrero.
	SBRC	R16, 0										//Revisar si el mes termina en 0 o en 1
	MOV		LIMIT_OVF, R25								// 31
	SBRS	R16, 0
	MOV		LIMIT_OVF, R26								// 30
	CPI		R16, 2										//Mientras no sea febrero usar 30 o 31 como limite
	BRNE	INCREMENTAR_FECHA
	LDI		LIMIT_OVF, 29								// 1C 0001 1100

	//Incrementar dias
INCREMENTAR_FECHA:										
	INC		DIAS										//Incrementar dias
	CP		DIAS, LIMIT_OVF								//Comparar con el limite para el ovf
	BREQ	RESET_UD										//Si es distinto al limite saltar


INC_UD:
	//Incrementar unidades de dias
	LDS		R16, UDIAS			
	INC		R16											//Incrementar las unidades de dias
	STS		UDIAS, R16
	CPI		R16, 10										//Si es distinto a 10 saltar
	BRNE	RETORNF		
									
	//Se ejecuta unicamente cuando hay OVF en unidades de dias
	//Reiniciar las unidades e incrementar las decenas
	LDI		R16, 0x00									//Reiniciar contador de unidades dias
	STS		UDIAS, R16									//Guardar el contador de unidades dias

	//Incrementar decenas de dias
	LDS		R16, DDIAS
	INC		R16									
	STS		DDIAS, R16	
	RJMP	RETORNF
	
RESET_UD:
	//Reiniciar los dias, unidades y decenas de dias
	LDI		DIAS, 8
	STS		UDIAS, DIAS
	LDI		DIAS, 2
	STS		DDIAS, DIAS
	LDI		DIAS, 28
	
	//Incrementar mes, unidades y decenas de mes
	LDS		R16, DMES
	CPI		R16, 1										//Si es igual a 1
	BRNE	OVFUM										// No salta

	//Incrementar unidades de mes cuando decenas es 1
	LDS		R16, UMES
	INC		R16
	STS		UMES, R16
	CPI		R16, 3										//El overflow ocurre en 2
	BRNE	RETORNF

	//Aca pasaron todos lo meses del año.
	//Resetear unidades y decenas de mes
	LDI		R16, 0x00
	STS		UMES, R16
	STS		DMES, R16

	//Se reestablece la logica a la inicial
	LDI		R25, 32
	LDI		R26, 31	
OVFUM:
	//Incrementar unidades de mes cuando decenas es 0
	LDS		R16, UMES
	INC		R16
	STS		UMES, R16
	CPI		R16, 10
	BRNE	RETORNF										//Mientras no se igual a 10 salta
	
	//Resetear unidades y aumentar decenas de mes
	LDI		R16, 0x00
	STS		UMES, R16
	LDS		R16, DMES
	INC		R16
	STS		DMES, R16							
RETORNF:
	RET
/***************Logica para ovf de modo fecha***************/

/***************Logica para incrementar configuración***************/
INCREMENTAR: 
	//Limpiar la bandera de incremento
	LDI		R16, 0x02									//LDI	R16, (1<<Incrementar)
	EOR		FLAGS_MP, R16

	SBRC	FLAGS_MP, 3									//UNIDEC ---> 1
	LDI		R16, 0x00									//Trabajar con minutos/mes
	SBRS	FLAGS_MP, 3									//UNIDEC --> 0
	LDI		R16, 0x01									//Trabajar con horas/dias
	CPI		R16, 0x00
	BRNE	MINMES										//Si es diferente salta a MINMES
	
	//Trabajar horas y dias
	SBRC	FLAGS_MP, 6									//Si HORA --> 1 se trabajan con horas
	CALL	INCHOUR
	SBRC	FLAGS_MP, 7									//Si Fecha -->1 se trabaja con dias
	CALL	INCDAYS
	RET
MINMES:
	//Trabajar con minutos/mes
	//Trabajar minitos y mese
	SBRC	FLAGS_MP, 6									//Si HORA --> 1 se trabajan con min
	CALL	INCMINS
	SBRC	FLAGS_MP, 7									//Si Fecha -->1 se trabaja con meses
	CALL	INCMES
	RET

/**Logica para incrementar horas/mins**/
INCHOUR:
	LDI		R16, 10										//Limite es 10
	LDS		CONTADOR, DHOR
	//DE 1/0 OVFUD hasta 10 y cuando es 2 OVFUD hasta 4
	CPI		CONTADOR, 2
	BRNE	INCUHOUR
	LDI		R16, 4										//limite es 4
INCUHOUR:
	//Incrementar unidades
	LDS		CONTADOR, UHOR
	INC		CONTADOR
	STS		UHOR, CONTADOR 
	CP		CONTADOR, R16								//ovf de unidades de horas
	BRNE	R_INCH
	//Reiniciar las unidades
	LDI		CONTADOR, 0x00			
	STS		UHOR, CONTADOR
	//Incrementar decenas
	LDS		CONTADOR, DHOR
	INC		CONTADOR
	STS		DHOR, CONTADOR
	CPI		CONTADOR, 3
	BRNE	R_INCH
	//Reiniciar el contador de decenas
	LDI		CONTADOR, 0x00
	STS		DHOR, CONTADOR
R_INCH:
	RET

//logica para incrementar minutos
INCMINS:
	LDS		CONTADOR, UMIN									//Incrementar unidades
	INC		CONTADOR
	STS		UMIN, CONTADOR
	CPI		CONTADOR, 10
	BRNE	R_INCM
	LDI		CONTADOR, 0x00									//Reinicar unidades
	STS		UMIN, CONTADOR
	LDS		CONTADOR, DMIN									//Incrementar decenas
	INC		CONTADOR
	STS		DMIN, CONTADOR
	CPI		CONTADOR, 6
	BRNE	R_INCM
	LDI		CONTADOR, 0x00									//Reiniciar decenas
	STS		DMIN, CONTADOR
R_INCM:
	RET
/**Logica para incrementar horas/mins**/

/**Logica para incrementar meses/dias**/
INCDAYS:
	//Ver que la logica a usar dependende si estamos antes de agosto o despues
	LDS		R16, UMES
	CPI		R16, 8										//Si es igual a 7 ir LOVF2
	BRNE	L0VF1										//mientra no sea igual a 7 ir LOVF1
L0VF2:
	/*De Agosto (0x07) a diciembre (0x0B) los meses de 31 dias terminan en 0
	Los de 30 terminan en 1*/
	LDI		R25, 31										//Se cambia la lógica
	LDI		R26, 32
L0VF1:
	//De enero (0x01) a Julio (0x07) los meses de 31 dias terminan en 1
	//Los de 30 terminan en 0 excepto febrero.
	SBRC	R16, 0										//Revisar si el mes termina en 0 o en 1
	MOV		LIMIT_OVF, R25								// 31
	SBRS	R16, 0
	MOV		LIMIT_OVF, R26								// 30
	CPI		R16, 2										//Mientras no sea febrero usar 30 o 31 como limite
	BRNE	INCUDAYS
	LDI		LIMIT_OVF, 29
INCUDAYS:
	INC		DIAS
	CP		DIAS, LIMIT_OVF
	BREQ	RUD											//Ir a reiniciar contador de dias
	LDS		CONTADOR, UDIAS
	INC		CONTADOR									//Incrementar unidades de dias
	STS		UDIAS, CONTADOR
	CPI		CONTADOR, 10
	BRNE	R_INCD
	LDI		CONTADOR, 0x00								//Reiniciar unidades de dias
	STS		UDIAS, CONTADOR
	LDS		CONTADOR, DDIAS								//Incrementar decenas de dias
	INC		CONTADOR
	STS		DDIAS, CONTADOR	
	RJMP	R_INCD
RUD:
	LDI		DIAS, 0x00
	STS		DDIAS, DIAS
	LDI		DIAS, 0x01
	STS		UDIAS, DIAS
R_INCD:
	RET

INCMES:
	LDS		CONTADOR, DMES
	CPI		CONTADOR, 0x00
	BRNE	INCDM
	LDS		CONTADOR, UMES								//Incrementar unidades 
	INC		CONTADOR
	STS		UMES, CONTADOR
	CPI		CONTADOR, 10
	BRNE	R_INCM
	LDI		CONTADOR, 0x00								//Reinciar las unidades
	STS		UMES, CONTADOR
	LDS		CONTADOR, DMES								//Incrementar las decenas
	INC		CONTADOR
	STS		DMES, CONTADOR	
	RJMP	R_INCM
INCDM:
	LDS		CONTADOR, UMES								//Incrementar unidades 
	INC		CONTADOR
	STS		UMES, CONTADOR
	CPI		CONTADOR,	3								//Ahora el overflow se hace en 2
	BRNE	R_INCME
	LDI		CONTADOR, 0x01								//Resetear unidades
	STS		UMES, CONTADOR
	LDI		CONTADOR, 0x00								//Reinciar las decenas
	STS		DMES, CONTADOR
R_INCME:
	RET

/***************Logica para incrementar***************/

DECREMENTAR:
	//Limpiar la bandera de incremento
	LDI		R16, 0x04									//LDI	R16, (1<<Decrementar)
	EOR		FLAGS_MP, R16

	//Configurar las de horas/dias - minutos/mes
	SBRC	FLAGS_MP, 3									//UNIDEC ---> 1
	LDI		R16, 0x00									//Trabajar con minutos/mes
	SBRS	FLAGS_MP, 3									//UNIDEC --> 0
	LDI		R16, 0x01									//Trabajar con horas/dias
	CPI		R16, 0x00
	BRNE	MINMESD										//Si es diferente salta a MINMES
	
	//Trabajar horas y dias
	SBRC	FLAGS_MP, 6									//Si HORA --> 1 se trabajan con horas
	CALL	DECHOUR
	SBRC	FLAGS_MP, 7									//Si Fecha -->1 se trabaja con dias
	CALL	DECDAYS
	RET
MINMESD:
	//Trabajar con minutos/mes
	SBRC	FLAGS_MP, 6									//Si HORA --> 1 se trabajan con min
	CALL	DECMINS
	SBRC	FLAGS_MP, 7									//Si Fecha -->1 se trabaja con meses
	CALL	DECMES
	RET

//Subrutinas de decremento
DECHOUR:
	LDS		CONTADOR, DHOR								//Comparar si las decenas son 0
	CPI		CONTADOR, 0
	BRNE	UNDFUH										//Mientras se diferente a 0 el undf de la unidades es en 9
	
	//Decrementar unidades de hora
	LDS		CONTADOR, UHOR
	CPI		CONTADOR, 0									//El underflow lo hara a 4 si llega a cero
	BRNE	UNDFUH
	//UNDERFLOW DE DIA
	LDI		CONTADOR, 4
	STS		UHOR, CONTADOR
	LDI		CONTADOR, 2
	STS		DHOR, CONTADOR
	RET
UNDFUH:
	//Decrementar unidades de hora
	LDS		CONTADOR, UHOR
	CPI		CONTADOR, 0									//El underflow lo hara a 9 si llega a cero
	BRNE	UNDFUDH

	//Decrementar las unidades horas
	DEC		CONTADOR
	STS		UHOR, CONTADOR
	RET
UNDFUDH:
	LDI		CONTADOR, 9
	STS		UHOR, CONTADOR
	//Decrementar decenas de horas
	LDS		CONTADOR, DHOR
	DEC		CONTADOR
	STS		DHOR, CONTADOR	
R_DH:
	RET

DECMINS:
	RET

DECDAYS:
	RET

DECMES:
	RET

//********Subrutinas**********

// Tabla de conversion hexadecimal a 7 segmentos
TABLA:
    .DB 0xF3, 0x81, 0xEA, 0xE9, 0x99, 0x79, 0x7B, 0xC1, 0xFB, 0xF9

TABLA2:
	.DB 0xF3, 0x81, 0xE6, 0xE5, 0x95, 0x75