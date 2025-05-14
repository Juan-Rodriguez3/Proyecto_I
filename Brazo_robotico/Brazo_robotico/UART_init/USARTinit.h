/*
 * USARTinit.h
 *
 * Created: 5/9/2025 10:12:23 AM
 *  Author: juana
 */ 


#ifndef USARTINIT_H_
#define USARTINIT_H_

#include <stdlib.h>  
#define F_CPU 16000000UL
#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdio.h>

void writeString(char* texto);
void initUSART_9600(void);
uint8_t mapeo_DC(char* dato);
void write(char texto);


#endif /* USARTINIT_H_ */