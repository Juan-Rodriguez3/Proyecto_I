/*
 * PWM2.h
 *
 * Created: 5/13/2025 11:10:17 PM
 *  Author: juana
 */ 


#ifndef PWM2_H_
#define PWM2_H_

uint8_t DutyCycle3( uint8_t valor_ADC);
uint8_t DutyCycle4( uint8_t valor_ADC);

void initPWM2(uint8_t compare, uint8_t inv, uint8_t mode, uint16_t prescaler);

#endif /* PWM2_H_ */