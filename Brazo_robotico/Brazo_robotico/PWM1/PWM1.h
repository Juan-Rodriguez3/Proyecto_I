/*
 * PWM1.h
 *
 * Created: 4/11/2025 4:14:38 PM
 *  Author: juana
 */ 


#ifndef PWM1_H_
#define PWM1_H_

void initPWM1(uint8_t compare, uint8_t inv, uint8_t mode, uint16_t prescaler, uint16_t periodo);
uint16_t DutyCycle1(uint8_t lec_ADC);
uint16_t DutyCycle2(uint8_t lec_ADC);


#endif /* PWM1_H_ */