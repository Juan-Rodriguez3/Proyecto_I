/*
 * USARTinit.c
 *
 * Created: 5/9/2025 10:12:12 AM
 *  Author: juana
 */ 
#include "USARTinit.h"

void write(char texto){
	while ((UCSR0A & (1<<UDRIE0))==0);	//Esperamos a que el registro de datos de USART este vac?o
	UDR0= texto;
}

void writeString(char* texto){
	for(uint8_t i = 0; *(texto+i) !='\0'; i++)
	{
		write(*(texto+i));
	}
	
}

uint8_t mapeo_DC(char* dato) {
	uint8_t grados = 0;
	grados = (uint8_t)atoi(dato); // atoi convierte cadena a int
	return grados;
}

void initUSART_9600(){
	//Configurar los pines PD1 Tx y PD0 Rx
	DDRD |= (1<<PORTD1);
	DDRD &= ~(1<<PORTD0);
	UCSR0A = 0;		//No se utiliza doble speed.
	UCSR0B = 0;
	UCSR0B |= (1<<RXCIE0)|(1<<RXEN0)|(1<<TXEN0);  //Habilitamos interrupciones al recibir, habilitar recepci?n y transmisi?n
	UCSR0C = 0;
	UCSR0C |= (1<<UCSZ00)|(1<<UCSZ01);	//Asincrono, deshabilitado el bit de paridad, un stop bit, 8 bits de datos.
	UBRR0=103;	//UBBRR0=103; -> 9600 con frecuencia de 16MHz
}