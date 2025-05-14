/*
 * funtion_EEPROM.c
 *
 * Created: 5/13/2025 10:48:10 AM
 *  Author: juana
 */ 

#define F_CPU 16000000UL

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdint.h>

unsigned char read_EEPROM(unsigned int uiAddress) {
	// Esperar la finalizaci?n de la escritura anterior
	while (EECR & (1 << EEPE));
	
	// Configurar el registro de direcci?n
	EEAR = uiAddress;
	
	// Iniciar la lectura de la EEPROM escribiendo EERE
	EECR |= (1 << EERE);
	
	// Devolver los datos del registro de datos
	return EEDR;
}

void write_EEPROM(unsigned int uiAddress, unsigned char ucData) {
	// Esperar la finalizaci?n de la escritura anterior
	while (EECR & (1 << EEPE));
	
	// Configurar los registros de direcci?n y datos
	EEAR = uiAddress;
	EEDR = ucData;
	
	// Escribir un uno l?gico en EEMPE
	EECR |= (1 << EEMPE);
	
	// Iniciar la escritura de la EEPROM estableciendo EEPE
	EECR |= (1 << EEPE);
}
