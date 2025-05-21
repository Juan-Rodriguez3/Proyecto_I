// Universidad Del Valle De Guatemala
// IE2023: Programaci?n de Microcontroladores
// Autor: Juan Rodr?guez
// Carn?: 221593
// Proyecto: Brazo rob?tico
// Hardware: Atmega238p
// Creado: 08/05/2025

//Librer?as y definiciones
#define F_CPU 16000000UL
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdint.h>
#include "PWM1/PWM1.h"
#include "PWM2/PWM2.h"
#include "ADC_init/ADC_init.h"
#include "UART_init/USARTinit.h"
#include "RW_EEPRROM/Function_EEPROM.h" 
#define  Vref_5V 5
#define ON 1
#define OFF 0
#define prescaler_PWM 8
#define prescaler_ADC 128
#define mode_PWM1 14
#define mode_PWM2 3
#define periodo 39999 
#define comparador 2



//****Prototipo de funciones****
void setup();
void SaveinEEPROM_Position(unsigned int direction0,unsigned int direction1,unsigned int direction2,unsigned int direction3); //Funcion que guarda la posicion de los 4 servos
void ExcuteEEPROM_Position(unsigned int direction0,unsigned int direction1,unsigned int direction2,unsigned int direction3); //Funcion que ejecuta la posicion guardada

//****Variables globales****
volatile uint8_t modo=0;
volatile uint8_t canal_ADC=4;	// =0 --> D10/OC1B - !=0 --> D9/OC1A
volatile uint8_t valorADC = 0;	//Lectura del adc
volatile uint16_t DTC1 = 0;	//Duty_cycle de los Servos del timer1
volatile uint16_t DTC2 = 0;	//Duty_cycle de los Servos
volatile uint16_t DTC3 = 0;	//Duty_cycle de los Servos del timer1
volatile uint16_t DTC4 = 0;	//Duty_cycle de los Servos
volatile uint8_t DUT_UART=0;
volatile uint8_t canal_UART=0;
volatile uint8_t Save_Position=1;
volatile uint8_t Execute_Position=1;

volatile uint8_t valorADC1= 0;
volatile uint8_t valorADC2 =0;


/*********main*********/
int main(void)
{
    setup();
    while (1) 
    {
		 _delay_ms(1);  // Peque?o retardo para estabilidad
		 
		 switch (modo){
			 case 0:	//modo manual
			 PORTD &= ~((1<<PORTD4)|(1<<PORTD5));	//LEDs de estado apagadas
			 
			 if (Save_Position>1){
				 PORTD |= (1<<PORTD6);
				 _delay_ms(100);
				 PORTD &= ~(1<<PORTD6);
				 Save_Position=0;
			 }
			 break;
			 
			 case 1:	//Modo eprom
			 PORTD &= ~((1<<PORTD5));			//LED azul encendida -->EEPROM
			 PORTD |= (1<<PORTD4);
			 
			 if (Execute_Position>1){
				 PORTD |= (1<<PORTD6);
				 _delay_ms(100);
				 PORTD &= ~(1<<PORTD6);
				 Execute_Position=0;
			 }
			 
			 break;
			 
			 case 2:	//Modo UART
			 PORTD &= ~(1<<PORTD4);				////LED amarilla encendida -->Adafruit
			 PORTD |= (1<<PORTD5); 
			 break;
			 
			 default:
			 break;
		 }
    }
}



/*********Subrutinas NON Interrupts*********/
void setup(void){
	cli();
	
	
	//Configuraci?n de pinC
	//Puerto C como entrada y pullup deshabilitado.
	//CLKPR |= (1<< CLKPCE);
	//CLKPR |= (1<<CLKPS2);	//Configurar prescaler principal a 16 para frecuencia de 1Mhz
	
	DDRC=0x00;
	PORTC=0;
	PORTC |= (1<<PORTC0)|(1<<PORTC1)|(1<<PORTC2)|(1<<PORTC3);
	
	//COnfiguraci?n del puertoB		
	DDRB = 0;
	DDRB |= (1 << DDB3)|(1 << DDB2)|(1 << DDB1); //Configurar el puerto de Led
	PORTB=0;
	PORTB |= (1<<PORTB4); //Habilitar pullup en PB5
	
	//COnfiguraci?n del puerto D
	DDRD=0;
	DDRD|= (1<<PORTD1)|(1<<PORTD3)|(1<<PORTD4)|(1<<PORTD5)|(1<<PORTD6);
	PORTD=0;
	
	//Interrupciones de pin change
	PCICR =0;
	PCICR |= (1<<PCIE0)|(1<<PCIE1); //Pin change habilitado en Puerto B y Puerto C
	
	PCMSK1=0;
	PCMSK0=0;
	PCMSK0 |= (1<<PCINT4); //Pinchange en pin PINB5
	PCMSK1 |= (1<<PCINT8)|(1<<PCINT9)|(1<<PCINT10)|(1<<PCINT11);
	
	initPWM1(comparador, OFF, mode_PWM1, prescaler_PWM, periodo);	//Servos de los brazos
	initPWM2(comparador,OFF, mode_PWM2, 1024); //Servo de la garra
	ADC_init(ON, Vref_5V,canal_ADC,ON,prescaler_ADC);
	initUSART_9600();
	
	sei();
}

//Funcion para guardar la posicion de los servos
void SaveinEEPROM_Position(unsigned int direction0,unsigned int direction1,unsigned int direction2,unsigned int direction3) {
	write_EEPROM(direction0, valorADC1);
	write_EEPROM(direction1, valorADC2);
	write_EEPROM(direction2, OCR2A);
	write_EEPROM(direction3, OCR2B);
}

//Funci?n para ejecutar una posicion guardada
void ExcuteEEPROM_Position(unsigned int direction0,unsigned int direction1,unsigned int direction2,unsigned int direction3) {
	OCR1A = DutyCycle1(read_EEPROM(direction0));
	OCR1B = DutyCycle1(read_EEPROM(direction1));
	OCR2A  =read_EEPROM(direction2);
	OCR2B  =read_EEPROM(direction3);
}



/**************Subrutinas de interrupcion*************/
//Controla el estado
ISR(PCINT0_vect){
	//Antirebote
	if ((PINB&(1<<PINB4))==0){
		//_delay_ms(50);
		//if ((PINB&(1<<PINB4)) ==0){
			//Boton presionado
			modo++;
		//}
	}
	
	//Overflow de modo
	if (modo==3){
		modo=0;
	}
}

//Estos botones tienen diferentes funciones dependiendo del estado

/*
Modo Manual guardan la posici?n de los servos:
bot?n 1 --> posici?n 1
bot?n 2 --> posici?n 2
bot?n 3 --> posici?n 3
bot?n 4 --> posici?n 4
Modo Eprom  ejecutan la posici?n guardada
bot?n 1 --> posici?n 1
bot?n 2 --> posici?n 2
bot?n 3 --> posici?n 3
bot?n 4 --> posici?n 4
 */

ISR(PCINT1_vect){
	switch(modo){
		case 0:		//Modo manual guardar el Dutycycle de los 4 servos
		if (Save_Position==0){
			if ((PINC&(0x0F))==0x0F){
				Save_Position=1;
			}
		}
		else if (Save_Position==1){
			//Parpadeo que confirma que se guardo la posici?n
			if (((PINC&(1<<PINC0))==0) && ((PINC&((1<<PINC1)|(1<<PINC2)|(1<<PINC3)))== 0x0E)){
				Save_Position =2;
				//Escribir en la eprom la nueva posici?n 1
				SaveinEEPROM_Position(0,1,2,3);
			}
			else if (((PINC&(1<<PINC1))==0) && ((PINC&((1<<PINC0)|(1<<PINC2)|(1<<PINC3)))== 0x0D)){
				Save_Position =3;
				//Escribir en la eprom la nueva posici?n 2
				SaveinEEPROM_Position(4,5,6,7);
			}
			else if (((PINC&(1<<PINC2))==0) && ((PINC&((1<<PINC0)|(1<<PINC1)|(1<<PINC3)))== 0x0B)){
				Save_Position =4;
				//Escribir en la eprom la nueva posici?n 3
				SaveinEEPROM_Position(8,9,10,11);
			}
			else if (((PINC&(1<<PINC3))==0) && ((PINC&((1<<PINC0)|(1<<PINC1)|(1<<PINC2)))== 0x07)){
				Save_Position =5;
				//Escribir en la eprom la nueva posici?n 4
				SaveinEEPROM_Position(12,13,14,15);
			}
		}
		break;
		
		case 1:
		if (Execute_Position==0){
			if ((PINC&(0x0F))==0x0F){
				Execute_Position=1;
				
			}
		}
		else if (Execute_Position==1){
			//Parpadeo que confirma que se guardo la posici?n
			if (((PINC&(1<<PINC0))==0) && ((PINC&((1<<PINC1)|(1<<PINC2)|(1<<PINC3)))== 0x0E)){
				Execute_Position =2;
				//Escribir en la eprom la nueva posici?n 1
				ExcuteEEPROM_Position(0,1,2,3);
			}
			else if (((PINC&(1<<PINC1))==0) && ((PINC&((1<<PINC0)|(1<<PINC2)|(1<<PINC3)))== 0x0D)){
				Execute_Position =3;
				//Escribir en la eprom la nueva posici?n 2
				ExcuteEEPROM_Position(4,5,6,7);
			}
			else if (((PINC&(1<<PINC2))==0) && ((PINC&((1<<PINC0)|(1<<PINC1)|(1<<PINC3)))== 0x0B)){
				Execute_Position =4;
				//Escribir en la eprom la nueva posici?n 3
				ExcuteEEPROM_Position(8,9,10,11);
			}
			else if (((PINC&(1<<PINC3))==0) && ((PINC&((1<<PINC0)|(1<<PINC1)|(1<<PINC2)))== 0x07)){
				Execute_Position =5;
				//Escribir en la eprom la nueva posici?n 4
				ExcuteEEPROM_Position(12,13,14,15);
			}
		}
		break;
		
		default:
		break;
	}
	
}


ISR(USART_RX_vect){
	if (modo==2){
		
		
		
		switch(canal_UART){
			case 0:
			OCR1A = DUT_UART;            // Actualizamos el duty cycle
			break;
			case 1:
			OCR1B = DUT_UART;			// Actualizamos el duty cycle
			break;
			
			default:
			break;
		}
	}
}


ISR(ADC_vect){
	if (modo==0){
		//Actualizamos el valor del Dutty cycle
		valorADC = ADCH;        // Leemos solo ADCH por justificaci?n izquierda
		DTC1 = DutyCycle1(valorADC);	//rotor
		DTC2= DutyCycle2(valorADC);		//codo
		DTC3= DutyCycle3(valorADC);		//mu?eca
		DTC4= DutyCycle4(valorADC);		//Garra
		
		
		
		
		//Actualizamos el DutyCycle dependiendo de que canal se haya leido
		switch(canal_ADC){
			case 4:
			OCR1A = DTC1;			// Actualizamos el duty cycle del rotor
			valorADC1= valorADC;	//Este valor sirve para guardarlo en la EEPROM
			break;
			
			case 5:
			OCR1B = DTC2;			// Actualizamos el duty cycle //codo
			valorADC2= valorADC;	//Este valor sirve para guardarlo en la EEPROM
			break;
				
			case 6:
			OCR2A = DTC3;			// Actualizamos el duty cycle de muñeca
			break;
			
			case 7:
			OCR2B = DTC4;			// Actualizamos el duty cycle de garra
			break;
			
			default:
			break;
		}
		

		//Multiplexeo de canales de ADC para la proxuma lectura.
		if (canal_ADC>=7){
			canal_ADC=4;
		}
		else {
			canal_ADC++;	//pasamos al siguiente canal
		}
	}
	
	ADC_init(ON, Vref_5V,canal_ADC,ON,prescaler_ADC);
}

