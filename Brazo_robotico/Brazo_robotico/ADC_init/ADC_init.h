/*
 * IncFile1.h
 *
 * Created: 4/21/2025 1:13:45 AM
 *  Author: juana
 */ 

//Libreria para configurar el ADC en modo free running --> ADATE=0.
#ifndef ADC_init_H_
#define ADC_init_H_

void ADC_init (uint8_t justi, uint8_t V_ref, uint8_t canal, uint8_t interrupt, uint8_t prescaler);


#endif /*ADC_init_H_*/