;File Name: lab1_part2.asm
;Authors: Dimitriadis Stathis 8490 - Sahinis Alexandros 8906

.include "m16def.inc"

.cseg
.org 0

.def leds = R16
.def temp = R17
.def index = R18
.def aem_1 = R19
.def aem_2 = R20
.def smaller_aem_first = R21
.def smaller_aem_last = R22
.def bigger_aem_first = R23
.def bigger_aem_last = R24

AEM1: .db "8490"
AEM2: .db "8906"

RESET:
	
	ser temp				 
	out DDRB, temp			;Initialize DDRB as output
	out PORTB, temp			;Initialize leds to be switched off

    ldi temp, 0x00  		;for real life is 0x00
    out DDRD, temp  		;set PORTD as input

	ldi  R16,  low(RAMEND)  ;Initialize stack for function calls
	out  SPL,  R16  		; 				-
	ldi  R16,  high(RAMEND) ; 				-
	out  SPH,  R16  		; 				-

	ldi index, 0			;Index showing the digit being examined
	rcall comp
	rjmp waitpress			;Start the program by comparing AEMs

waitpress:
	in temp, PIND
	cpi temp, 0xFF
	breq waitpress			;If no press occurs, wait 
	mov R18, temp 			;Switch pressed is saved to R18
	rjmp waitrelease

waitrelease:
	in temp, PIND
	cpi temp, 0xFF
	brne waitrelease		;If not released, wait
	rjmp switch				;When released jump to determine switch pressed

switch:
    sbrs R18, 0   
    rjmp switch_0
    sbrs R18, 1   
    rjmp switch_1
    sbrs R18, 2  
    rjmp switch_2
    sbrs R18, 3 
    rjmp switch_3
    sbrs R18, 7
    rjmp switch_7

    rjmp waitpress
	
switch_0:   ;2 last digits of bigger aem
	com bigger_aem_last
    out PORTB, bigger_aem_last
 
    rcall delay10
    rjmp waitpress


switch_1:   ;2 first digits of bigger aem
	com bigger_aem_first
    out PORTB, bigger_aem_first
 
    rcall delay10
    rjmp waitpress

switch_2:   ;2 last digits of smaller aem
	com smaller_aem_last
    out PORTB, smaller_aem_last
 
    rcall delay10
    rjmp waitpress

switch_3:   ;2 first digits of smaller aem
	com smaller_aem_first
    out PORTB, smaller_aem_first
 
    rcall delay10
    rjmp waitpress

switch_7:
    rjmp FINISH

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
	;Prepare the leds for when the SW7 switch is pressed
	
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
	
	;Store aem digits for when SW0-SW3 switches are pressed 
	rjmp aem1_lower 
	
ELSE:
	;Prepare the leds for when the SW7 switch is pressed

	ldi ZL, low((AEM2 << 1) + 3);Load the address to Z
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

	;Store aem digits for when SW0-SW3 switches are pressed
	rjmp aem2_lower
	

aem1_lower:
    ldi ZH, high(AEM1 << 1)
    ldi ZL, low(AEM1 << 1)
    ;read first digit of smaller aem
    rcall store_smaller_aem

    ;now for the bigger aem
    ldi ZH, high(AEM2 << 1)
    ldi ZL, low(AEM2 << 1)
    rcall store_bigger_aem
    ret

aem2_lower:
    ldi ZH, high(AEM2 << 1)
    ldi ZL, low(AEM2 << 1)
    rcall store_smaller_aem
    ;now for the bigger aem
    ldi ZH, high(AEM1 << 1)
    ldi ZL, low(AEM1 << 1)
    rcall store_bigger_aem
    ret

store_smaller_aem:
    lpm
    mov smaller_aem_first, r0
    subi smaller_aem_first, 0x30
    ldi temp, 10
    mul smaller_aem_first, temp
    mov smaller_aem_first, r0
    adiw R30, 1
    ;read second digit of smaller aem
    lpm
    mov temp, r0
    subi temp, 0x30
    add smaller_aem_first, temp

    ;read third digit of smaller aem
    adiw R30, 1
    lpm
    mov smaller_aem_last, r0
    subi smaller_aem_last, 0x30
    ldi temp, 10
    mul smaller_aem_last, temp
    mov smaller_aem_last, r0
    adiw R30, 1
    lpm
    mov temp, r0
    subi temp, 0x30
    add smaller_aem_last, temp
    ret

store_bigger_aem:
    lpm
    mov bigger_aem_first, r0
    subi bigger_aem_first, 0x30
    ldi temp, 10
    mul bigger_aem_first, temp
    mov bigger_aem_first, r0
    adiw R30, 1
    ;read second digit of bigger aem
    lpm
    mov temp, r0
    subi temp, 0x30
    add bigger_aem_first, temp

    ;read third digit of bigger aem
    adiw R30, 1
    lpm
    mov bigger_aem_last, r0
    subi bigger_aem_last, 0x30
    ldi temp, 10
    mul bigger_aem_last, temp
    mov bigger_aem_last, r0
    adiw R30, 1
    lpm
    mov temp, r0
    subi temp, 0x30
    add bigger_aem_last, temp
    ret


delay10:
    ldi  r18, 203
    ldi  r19, 236
    ldi  r20, 133
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
