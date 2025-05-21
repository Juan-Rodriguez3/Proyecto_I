/*
 * PWM2.c
 *
 * Created: 5/8/2025 11:44:37 PM
 *  Author: juana
 */ 
#define F_CPU 16000000UL

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdint.h>

	uint8_t DutyCycle3( uint8_t valor_ADC){ //muñeca
		return (5UL+(valor_ADC*50UL)/255);
	}

	uint8_t DutyCycle4( uint8_t valor_ADC){
		return (6UL+(valor_ADC*8UL)/255);
		/*Servo de la garra
		
		*/
	}

	void initPWM2(uint8_t compare, uint8_t inv, uint8_t mode, uint16_t prescaler) {
		TCCR2A = 0;
		TCCR2B = 0;
		
		//OCR2B
		if (compare==0){
			if (inv==0) {
				TCCR2A |= (1<<COM2B1);	//No invertido
			}
			else {
				TCCR2A |= (1<<COM2B1) | (1<<COM2B0);
			}
		}
		//OCR2A
		else if (compare==1) {
			if (inv==0) {
				TCCR2A |= (1<<COM2A1); //No invertido
			}
			else {
				TCCR2A |= (1<<COM2A1) | (1<<COM2A0);
			}
		}
		//Esta es util para inicializar el timer1 con las dos señales PWM
		else if (compare==2){
			if (inv==0) {
				TCCR2A |= (1<<COM2A1)|(1<<COM2B1); //No invertido
			}
			else {
				TCCR2A |= (1<<COM2A1) | (1<<COM2A0)|(1<<COM2B1) | (1<<COM2B0);
			}
		}
		
		switch (mode)
		{
			case 1:	 //PWM Phase correct
			TCCR2A |= (1<<WGM20);
			break;
			
			case 2:	//CTC
			TCCR2A |= (1<<WGM21);
			break;
			
			case 3:	//PWM FAST 
			TCCR2A |= (1<<WGM21) | (1<<WGM20);
			break;
			
			case 5: //PWM phase correct TOP - OCRA en este caso OCR2A
			TCCR2A |= (1<<WGM20);
			TCCR2B |= (1<<WGM22);
			break;
			
			case 7:	//PWM FAST top - OCRA
			TCCR2B |= (1<<WGM22);
			TCCR2A |= (1<<WGM20)|(1<<WGM21);
			break;

			default:	//normal
			TCCR2B &= ~(1<<WGM22);
			TCCR2A &= ~((1<<WGM21) | (1<<WGM20));
			break;
		}
		
		switch (prescaler){
			case 1:
			TCCR2B |= (1<<CS20);
			break;
			case 8:
			TCCR2B |= (1<<CS21);
			break;
			case 32:
			TCCR2B |= (1<<CS20)|(1<<CS21);
			break;
			case 64:
			TCCR2B |= (1<<CS22);
			break;
			case 128:
			TCCR2B |= (1<<CS22)|(1<<CS20);
			break;
			case 256:
			TCCR2B |= (1<<CS22)|(1<<CS21);
			break;
			case 1024:
			TCCR2B |= (1<<CS20)|(1<<CS22)|(1<<CS21);
			break;
			default:
			TCCR2B &= ~((1<<CS20)|(1<<CS22)|(1<<CS21));
			break;
		}
}
		