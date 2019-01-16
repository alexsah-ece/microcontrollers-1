;File Name: lab1_part1.asm
;Authors: Dimitriadis Stathis 8490 - Sahinis Alexandros 8906

.include "m16def.inc"

.cseg
.org 0

.def leds = R16
.def temp = R17
.def index = R18
.def aem_1 = R19
.def aem_2 = R20

AEM1: .db "8490"
AEM2: .db "8906"

RESET:
	
	ser temp				 
	out DDRB, temp			;Initialize DDRB as output
	out PORTB, temp			;Initialize leds to be switched off
	
	ldi  R16,  low(RAMEND)  ;Initialize stack for function calls
	out  SPL,  R16  		; 				-
	ldi  R16,  high(RAMEND) ; 				-
	out  SPH,  R16  		; 				-

	ldi index, 0			;Index showing the digit being examined
	
	rjmp comp				;Start the program by comparing AEMs
	
led:
	;LEDs 7-4
	lpm leds, Z+
	subi leds, 0x30
	
	lsl leds
	lsl leds
	lsl leds
	lsl leds 

	;LEDs 3-0
	lpm temp, Z
	subi temp, 0x30

	add leds, temp
	com leds
	out PORTB, leds
	rcall delay3
	ret

comp:
	;AEM1 [index] digit
	ldi ZL, low(AEM1 << 1)  ;Load the address to Z
	ldi ZH, high(AEM1 << 1)	;Load the address to Z
	add ZL, index			
	lpm aem_1, Z
	subi aem_1, 0x30

	;AEM2 [index] digit
	ldi ZL, low(AEM2 << 1)	;Load the address to Z
	ldi ZH, high(AEM2 << 1)	;Load the address to Z
	add ZL, index
	lpm aem_2, Z
	subi aem_2, 0x30

	inc index				;Increment the index to check the next digit
	cp aem_1, aem_2			;Compare the two digits
	breq comp				;If equal, compare the next ones
	
	brlo IF 				;aem_1 < aem_2	

	rjmp ELSE 				;aem_2 < aem_1

IF:
	ldi ZL, low((AEM1 << 1) + 2) ;Load the address to Z
	ldi ZH, high((AEM1 << 1) + 2);Load the address to Z
	
	rcall led					 ;Power the LEDs
	
	ldi ZL, low((AEM1 << 1) + 3) ;Load the address to Z
	ldi ZH, high((AEM1 << 1) + 3);Load the address to Z	
	lpm leds, Z
	andi leds, 1				 ;LED0
	
	ldi ZL, low((AEM2 << 1) + 3) ;Load the address to Z
	ldi ZH, high((AEM2 << 1) + 3);Load the address to Z	
	lpm temp, Z
	andi temp, 1
	com temp					
	lsl temp					 ;LED1
	add leds, temp
	
	rjmp FINISH
	
ELSE:
	
	ldi ZL, low((AEM2 << 1) + 3) ;Load the address to Z
	ldi ZH, high((AEM2 << 1) + 3)	
	rcall led
	
	ldi ZL, low((AEM2 << 1) + 3) ;Load the address to Z
	ldi ZH, high((AEM2 << 1) + 3)	
	lpm leds, Z
	andi leds, 1				 ;LED0
	
	ldi ZL, low((AEM1 << 1) + 3) ;Load the address to Z
	ldi ZH, high((AEM1 << 1) + 3)	
	lpm temp, Z
	andi temp, 1
	com temp
	lsl temp
	add leds, temp				 ;LED1
	
	out PORTB, leds

delay3:
	    ldi  r18, 61
	    ldi  r19, 225
	    ldi  r20, 62
	L1: dec  r20
	    brne L1
	    dec  r19
	    brne L1
	    dec  r18
	    brne L1
	    nop
	ret

FINISH:
		
	out PORTB, leds
	rjmp PC
