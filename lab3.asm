;File Name: lab3.asm
;Authors: Dimitriadis Stathis 8490 - Sahinis Alexandros 8906

.include "m16def.inc"

.cseg
.org 0

.def temp = R16
.def program_stored = R17
.def leds = R18
.def delay_counter = R19
.def secondary_counter = R20
.def duration_counter = R22
.def violation_input = R23


RESET:
	
	ser temp				 
	out DDRB, temp			;initialize DDRB as output
	out PORTB, temp			;initialize LEDs to be switched off
	
    ldi temp, 0x00  		;for real life is 0x00	
    out DDRD, temp  		;set PORTD as input

	ldi  R16,  low(RAMEND)  ;initialize stack for function calls
	out  SPL,  R16  		; 				-
	ldi  R16,  high(RAMEND) ; 				-
	out  SPH,  R16  		; 				-

START:
	
	clr leds
	out PORTB, leds			;initialize LEDs to be switched on
	rcall SW6_wait			;wait for press & release of SW6
	ser leds				
	out PORTB, leds			;turn off LEDs
	ser program_stored		;initialize program_stored
	ldi delay_counter, 50 	;initialize delay_counter 
	;100ms delay so for 5s we need 50 repetitions
	rjmp initial_loop		
	
initial_loop:
	rcall delay_100ms
	dec delay_counter
	breq machine_start
	
	in temp, PIND			;read the input
	cpi temp, 0xFF			
	breq initial_loop		;if no SW pressed, repeat the loop
	and program_stored, temp;else, store the input
	rjmp initial_loop		;and continue with the loop

machine_start:
	
	ori program_stored, 0b11000011  ;clear possible miss-clicks
	rcall SW6_wait					;wait for press & release of SW6
	ldi leds, 0b11111101	
	out PORTB, leds					;enable LED1
	
	ldi delay_counter, 50			;initialize delay_counter for use in the overload loop
	rjmp overload_loop				;jump to the overload check

overload_loop:
	ldi secondary_counter, 10
	rcall delay_100ms
	dec delay_counter
	breq machine_wash
	
	sbic PIND, 1					;if SW1 pressed, blink LED1 until it is pressed again
	rjmp overload_loop				;else, continue with the loop
	rcall waitrelease
	rcall LED1_blink				;start blinking LED1 
	
	rjmp machine_wash

machine_wash:
	;starts the washing sequence
	sbrs program_stored, 2	;Check if prewash was selected
	rjmp setup_prewash
	rjmp setup_washing

setup_prewash:
	;prepares for the 4s prewash
	ldi duration_counter, 40
	ldi leds, 0b11111011
	out PORTB, leds
	rjmp prewash

prewash:
	;Will be executed for 4sec and then the program will jump to setup_washing
	dec duration_counter
	breq setup_washing
	rcall delay_100ms
	;check if one of the emulating switches was pressed
	rcall check_violations
	rjmp prewash

check_violations:
	;check for emulated modes
	in violation_input, PIND
	cpi violation_input, 0xFF
	breq return
	rcall waitrelease
	;initialize secondary_counter for the LED toggling
    ldi secondary_counter, 10
	;check which switch was pressed and jump to the respective label
	sbrs violation_input, 1
	rjmp overload
	sbrs violation_input, 0
	rjmp door_open
	sbrs violation_input, 7
	rjmp water_supply_interrupt
	;If no valid switch was pressed return to the caller
	return:
		ret

overload:
	rcall LED1_blink
	ret

water_supply_interrupt:
	;Toggle LED6 every 1s until SWITCH7 is pressed
	rcall delay_100ms
	sbic PIND, 7
	rjmp blink_continue_water
	rcall waitrelease
	;Turn off LED6
	ori leds, 0b01000000
    out PORTB, leds
	;Return to the current stage of the washing sequence (e.g. wringing routine)
	;This is possible because we called check_violations but jumped here
	ret
	
	blink_continue_water:
		dec secondary_counter
		brne water_supply_interrupt		;if 1s hasn't completed, continue with the loop
		rcall LED6_toggle				;else, toggle the LED
		rjmp water_supply_interrupt

door_open:
	;Toggle LED0 every 1s until SWITCH0 is pressed
	rcall delay_100ms
	
	sbic PIND, 0 ;If SW0 is not pressed continue with the loop 		
	rjmp blink_continue_door		
	rcall waitrelease
	ori leds, 0b00000001	;Turn off LED0
    out PORTB, leds
	;Return to the current stage of the washing sequence (e.g. wringing routine)
	;This is possible because we called check_violations but jumped here
	ret

	blink_continue_door:
		dec secondary_counter
		brne door_open					;if 1s hasn't completed, continue with the loop
		rcall LED0_toggle				;else, toggle the LED
		rjmp door_open

setup_washing:
	;We are at stage 2
	ldi leds, 0b11110111
	out PORTB, leds
	mov temp, program_stored
	clr duration_counter
	;We now need to calculate the duration of the washing process 
	;We will set both SW5 and SW2 to 1 for easier comparisons
	ori temp, 0b11100111 ;set the prewash and wringing bits to one
	;We will add 40 cycles to the duration counter and check if the corresponding button combination was pressed
	;We will do it 3 at most times (so we will have either the 4s, 8s and 12s program)
	;Then we will add 60 cycles and start the washing process
	ldi R24, 40
	adc duration_counter,R24
	cpi temp, 0b11100111 ;SW3 and SW4 were pressed
	breq washing
	adc duration_counter, R24
	cpi temp, 0b11101111; SW4 was pressed
	breq washing
    adc duration_counter, R24
	cpi temp, 0b11110111; SW3 was pressed
	breq washing
	;If the program reaches this point then it means than no switch was pressed
	;So we will add 6s to our duration for a total of 18s of washing
	ldi R24, 60
	adc duration_counter, R24
	
	rjmp washing
	
washing:
	;It will loop until duration_counter reaches 0 and then branch to setup_rinsing
	dec duration_counter
	breq setup_rinsing
	rcall delay_100ms
	rcall check_violations
	rjmp washing
	
setup_rinsing:
	;Rinsing lasts for 1s so we load 10 to the duration counter
	ldi duration_counter, 10
	;We light LED4 to denote that the program has reached the rinsing stage
	ldi leds, 0b11101111
	out PORTB, leds
	rjmp rinsing

rinsing:
	;Loop for one second and then proceed to setup_wringing
	dec duration_counter
	breq setup_wringing
	rcall delay_100ms
	;Chech if one of SW0,1,7 was pressed
	rcall check_violations
	rjmp rinsing

setup_wringing:
	;Checks if wringing was selected 
	sbrc program_stored, 5
	;If not jump to setup_terminate
	rjmp setup_terminate
	;Else load 20 to duration_counter for a duration of 2s
	ldi duration_counter, 20
	;Light LED5 to denote that we are at the wringing stadium
	ldi leds, 0b11011111
	out PORTB, leds
	rjmp wringing

wringing:
	;Loop for 2s and then branch to setup_terminate
	dec duration_counter
	breq setup_terminate
	rcall delay_100ms
	;Chech if one of SW0,1,7 was pressed
	rcall check_violations
	rjmp wringing

LED1_blink:
	
	rcall delay_100ms
	
	sbic PIND, 1					;if SW1 pressed, blink LED1 until it is pressed again
	rjmp LED1_blink_continue		;else, continue with the loop
	rcall waitrelease
	ori leds, 0b00000010
    out PORTB, leds
	ret
	
	LED1_blink_continue:
		dec secondary_counter
		brne LED1_blink					;if 1s hasn't completed, continue with the loop
		rcall LED1_toggle				;else, toggle the LED
		rjmp LED1_blink
		
	
LED1_toggle:
	ldi secondary_counter, 10
	ldi temp, 0b00000010
	eor leds, temp
	out PORTB, leds
	ret

LED0_toggle:
	ldi secondary_counter, 10
	ldi temp, 0b00000001
	eor leds, temp
	out PORTB, leds
	ret

LED6_toggle:
	ldi secondary_counter, 10
	ldi temp, 0b01000000
	eor leds, temp
	out PORTB, leds
	ret

SW6_wait:						;wait for SW6 press and release
	sbic PIND, 6
	rjmp SW6_wait
	rcall waitrelease
	ret

waitrelease:
	in temp, PIND
	cpi temp, 0xFF
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

setup_terminate:
	;Load 50 for a 5s duration
	ldi secondary_counter, 50
	;Light LED7
	ldi leds, 0b01111111
	out PORTB, leds
	rjmp termination_led

termination_led:
	;Keep LED7 on for 5s
	dec secondary_counter
	breq terminate
	rcall delay_100ms
	rjmp termination_led

terminate:
	;Turn off all LEDs
	ldi leds, 0xff
	out PORTB, leds
	rjmp PC
