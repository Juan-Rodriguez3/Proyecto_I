/*
 * CFile1.c
 *
 * Created: 4/21/2025 1:14:02 AM
 *  Author: juana
 */ 

#define F_CPU 16000000

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdint.h>

void ADC_init(uint8_t justi, uint8_t V_ref, uint8_t canal, uint8_t interrupt, uint8_t prescaler){
	ADMUX = 0;
	if (!justi){
		ADMUX &= ~(1<<ADLAR);
	}
	else {
		ADMUX |= (1<<ADLAR);
	}
	
	switch (V_ref){
		case 1:
		ADMUX |= (1<<REFS0)|(1<<REFS1);
		break;
		case 5:
		ADMUX |= (1<<REFS0);
		default:
		break;
	}
	
	switch(canal){
		case 0:
		break;
		case 1:
		ADMUX |= (1<<MUX0);
		break;
		case 2:
		ADMUX |= (1<<MUX1);
		break;
		case 3:
		ADMUX |= (1<<MUX0)|(1<<MUX1);
		break;
		case 4:
		ADMUX |= (1<<MUX2);
		break;
		case 5:
		ADMUX |= (1<<MUX0)|(1<<MUX2);
		break;
		case 6:
		ADMUX |= (1<<MUX2)|(1<<MUX1);
		break;
		case 7:
		ADMUX |= (1<<MUX0)|(1<<MUX1)|(1<<MUX2);
		break;
		default:
		ADMUX |= (1<<MUX2)|(1<<MUX1);
		break;
	}
	
	ADCSRA = 0;
	if (!interrupt){
		ADCSRA &= ~(1<<ADIE);
	}
	else {
		ADCSRA |= (1<<ADIE);	//	Habilitar interrupciones
	}
	
	switch (prescaler){
		case 2:
		break;
		case 4:
		ADCSRA |= (1<<ADPS1);
		break;
		case 8:
		ADCSRA |= (1<<ADPS1)|(1<<ADPS0);
		break;
		case 16:
		ADCSRA |= (1<<ADPS2);
		break;
		case 32:
		ADCSRA |= (1<<ADPS2)| (1<<ADPS0);
		break;
		case 64:
		ADCSRA |= (1<<ADPS1) |(1<<ADPS2);
		break;
		case 128:
		ADCSRA |= (1<<ADPS1)|(1<<ADPS0)|(1<<ADPS2);
		break;
		default:
		ADCSRA |= (1<<ADPS1)|(1<<ADPS0)|(1<<ADPS2);
		break;
	}
	
	
	//ADCSRA |= (1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0); //Interrupciones - Prescaler 128
	ADCSRA |= (1<<ADEN)|(1<<ADSC); //Habilitar ADC e iniciar conversión
}