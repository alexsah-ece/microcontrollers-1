;File Name: lab2.asm
;Authors: Dimitriadis Stathis 8490 - Sahinis Alexandros 8906

.include "m16def.inc"

.cseg
.org 0

.def temp = R16
.def password_stored = R17	;system's password
.def delay_counter = R18	;to help us count 50 * 100ms = 5 sec delays
.def try_counter = R19		;how many times has the user failed to insert the correct password
.def temp2 = R20
.def password_inserted = R21;switches that the user has pressed until now
.def secondary_counter = R22;helper for toggling the leds every 1s
.def leds = R24


RESET:
	
	ser temp				 
	out DDRB, temp			;initialize DDRB as output
	out PORTB, temp			;initialize leds to be switched off

    ldi temp, 0x00  		;for real life is 0x00
    out DDRD, temp  		;set PORTD as input

	ldi  R16,  low(RAMEND)  ;initialize stack for function calls
	out  SPL,  R16  		; 				-
	ldi  R16,  high(RAMEND) ; 				-
	out  SPH,  R16  		; 				-

	ser leds
	rjmp switch7_waitpress	;start password storage mode


switch7_waitpress: 			;wait until switch7 is pressed
    sbis PIND, 7
    rjmp switch7_waitrelease
    rjmp switch7_waitpress

store_password:
	in password_stored, PIND		;when the switch 7 is pressed, store the password
	rjmp switch0_waitpress

switch7_waitrelease:   				;wait until switch7 is released
    sbic PIND , 7
    rjmp store_password
    rjmp switch7_waitrelease

switch0_waitpress:					;wait until switch0 is pressed
	sbis PIND, 0
    rjmp switch0_waitrelease
    rjmp switch0_waitpress
   
switch0_waitrelease:				;wait until switch0 is released
    sbic PIND, 0	
    rjmp normal_operation_activated
    rjmp switch0_waitrelease

normal_operation_activated:
	ldi leds, 0b11111110  			 ;light LED0
    out PORTB, leds	  			 	 ;	   -
	ldi delay_counter, 50 			 ;initialize the loop counter
	ldi	try_counter, 0	  			 ;initialize try_counter to 0
	ldi password_inserted, 0xFF 	 ;clear password_inserted with ones
	ldi secondary_counter, 10
    rjmp loop_five_second

loop_five_second:
	;if switch 0 is pressed, we are heading towards the beginning
	sbis PIND, 0
	rcall delay_100ms
	;depending on number of tries we jump to a different location
	cpi try_counter, 0
	breq continue
	cpi try_counter, 1
	breq second_try
	cpi try_counter, 2
	breq last_try
		
	second_try:					;one wrong insertion, toggle the leds, if necessary and jump to continue
		dec secondary_counter
		brne continue
		rcall toggle_led
		rjmp continue
		
	last_try:					;two wrong insertions, toggle the leds, if necessary and loop until SW0 is pressed 
		dec secondary_counter
		brne loop_five_second
		rcall toggle_leds
		rjmp loop_five_second
	
	continue:					;normal procedure of checking user's input
		dec delay_counter
		breq wrong_input		;if time (5s) is up, we jump to the wrong_input location
		in temp, PIND			;check PIND
	    cpi temp, 0xFF			;check if no switch is pressed
	    breq loop_five_second	;if not, continue with the loop
		cpi temp, 0xFE			;if switch 0 is pressed, we are jumping to the start waiting for SW3
		breq switch0_waitrelease
		rcall waitrelease		;
		rjmp check_invalid		;if yes, check if the input is a security breach
		
		invalid_false:			;if there isn't a security breach, continue with the checks
			mov temp2, temp
			and temp2, password_stored	
			cp temp2, password_stored		;check if the switch pressed exists in the password
			brne wrong_input				;if not, then the password is wrong
			
			and password_inserted, temp		;else, the switch pressed exists and we check the overall currently inserted password
			cp password_inserted, password_stored
			brne loop_five_second			;if the currently inserted password doesn't match, continue with the loop
			
			andi leds, 0b11111100			;else, password is correct
			out PORTB, leds					;light LED1 & LED0
			ldi delay_counter, 50 			;initialize the loop counter
			ldi	try_counter, 0	  			;initialize try_counter to 0
			ldi password_inserted, 0xFF 	;clear password_inserted with ones
			ldi secondary_counter, 10
			rjmp switch0_waitpress			;restart the loop
		
		wrong_input:						;handles the wrong password situation
			rcall init_final				;initialize the leds for toggling
			inc try_counter					;increment try counter
			ldi delay_counter, 50			;make the necessary initializations
			ldi password_inserted, 0xFF		;				-
			ldi secondary_counter, 10		;				-
			rjmp loop_five_second			;jump to the start of the loop

init_final:
	ldi leds, 0xFF
	out PORTB, leds
	ret

check_invalid:				;checking invalid inputs to enable security breach messages
	mov temp2, temp
	com temp2
	cpi temp2, 16			;check if one of s4, s5, s6, s7 was pressed
	brsh s4_s5_s6_s7
	
	cpi temp2, 4			;check if s2 was pressed
	breq s2
	rjmp invalid_false		;if not, return to the  loop
	
	s4_s5_s6_s7:
		sbrc password_inserted, 3 	;check if s3 already pressed
		rjmp check_invalid_end							
		rjmp invalid_false			;if yes, no problem, so return to the loop
	s2:
		sbrc password_inserted, 1	;check if s1 already pressed
		rjmp check_invalid_end							
		rjmp invalid_false			;if yes, no problem, so return to the loop
	
	check_invalid_end:
		com temp2
		and leds, temp2			;light the corresponding LED
		andi leds, 0b11111011	;light LED2
		out PORTB, leds
		rjmp switch0_waitpress

waitrelease:					;wait for the release of the switches
	in temp2, PIND
	cpi temp2, 0xFF
	brne waitrelease
	ret

delay_100ms:					;100ms delay - calculator generated 
        ldi  r25, 3
        ldi  r26, 8
        ldi  r27, 120
    L1: dec  r27
        brne L1
        dec  r26
        brne L1
        dec  r25
        brne L1
    ret

toggle_led:						;toggle LED0
	ldi secondary_counter, 10
    ldi temp, 0x01
    eor leds, temp
    out PORTB, leds
    ret

toggle_leds:					;toggle all LEDs
	ldi secondary_counter, 10
	ldi temp, 0xFF
	eor leds, temp
	out PORTB, leds
	ret

