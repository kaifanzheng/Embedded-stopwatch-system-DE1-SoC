.global _start
.equ hex_Address1, 0xFF200020
.equ hex_Address2,  0xFF200030
.equ pushButton,  0xFF200050
.equ edgeCatpture, 0xFF20005C
.equ pushButtonInterrupt, 0xFF200058
.equ switches_Address, 0xFF200040
.equ led_Address, 0xFF200000
.equ load, 0xFFFEC600
.equ control, 0xFFFEC608
.equ interrupt, 0xFFFEC60C
MaxCount: .word 0xF423F
Hex_Deci: .word 0x3F,0x06, 0x5B, 0x4F, 0x66, 0x6D,0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7c, 0x39, 0x5E, 0x79, 0x71
_start:
//testOne
	//mov r0,#0x00000030
	//bl HEX_flood_ASM
	//mov r0,#0x0000000f
	//bl HEX_clear_ASM
	//mov r0,#1
	//bl HEX_clear_ASM
	//mov A1,#0x00000001
	//mov A2,#7
	//bl HEX_write_ASM
	//mov A1,#0x000000f
	//bl HEX_clear_ASM
	//mov A1,#0x4
//testTwo
//loopStart:
//	bl read_PB_edgecp_ASM
//	cmp r0,#0
//	beq loopStart
//	mov r9,r0
//	bl PB_clear_edgecp_ASM
//	b loopStart

//test for main
	//mov r0,#0x3F
	//bl HEX_clear_ASM
	//mov r0,#234
	//bl write_hex_decimal
	//bl voidMainPartTwo
	//bl voidMainPartOne
	bl voidMainPartOne
	b end
    
read_PB_data_ASM:
	push {v1,lr}
	ldr v1,=pushButton
	ldr r0,[v1]
	pop {v1,lr}
	bx lr
//take A1 as input, 
PB_data_is_pressed_ASM:
	push {v1,v2,lr}
	mov v1,r0
	bl read_PB_data_ASM
	mov v2,r0
	cmp v2,v1
	beq PB_data_is_pressed_ASM_end
	mov r0,#0
	pop {v1,v2,lr}
	bx lr
	
PB_data_is_pressed_ASM_end:
	mov r0,#1
	pop {v1,v2,lr}
	bx lr

read_PB_edgecp_ASM:
	push {v1,lr}
	ldr v1, =edgeCatpture
	ldr v1,[v1]
	mov r0, v1
	pop {v1,lr}
	bx lr
//in put is A1(R0)
PB_edgecp_is_pressed_ASM:
	push {v1,v2,v3,lr}
	mov v1,r0
	bl read_PB_edgecp_ASM
	cmp v1,r0
	beq PB_edgecp_is_pressed_ASM_end
	mov r0,#0
	//bl PB_clear_edgecp_ASM
	pop {v1,v2,v3,lr}
	bx lr
PB_edgecp_is_pressed_ASM_end:
	mov r0, #1
	bl PB_clear_edgecp_ASM
	pop {v1,v2,v3,lr}
	bx lr
PB_clear_edgecp_ASM:
	push {v1,v2,v3,lr}
	ldr v1, =edgeCatpture
	bl read_PB_edgecp_ASM
	mov v3,#1
	str r0,[v1]
	pop {v1,v2,v3,lr}
	bx lr
//take r0 as input
enable_PB_INT_ASM:
	push {v1,v2,v3,lr}
	mov v1,r0
	ldr v2,=pushButtonInterrupt
	ldr v3, [v2]
	orr v3,v3,v1
	str v3,[v2]
	pop {v1,v2,v3,lr}
	bx lr
//take ro as input
disable_PB_INT_ASM: 
	push {v1,v2,v3,v4,v5,lr}
	mov v1,r0
	mov v4,#0xF
	ldr v2,=pushButtonInterrupt
	ldr v3, [v2]
	sub v5,v4,v3//flip the bit of v3
	and v3,v1,v5//and the v3 and flipping bit
	str v3,[v2]
	pop {v1,v2,v3,v4,v5,lr}
	bx lr

//take r0(how many hex) and r1(the number) as input
HEX_write_ASM:
	push {v1,v2,v3,v4,v5,v6,v7,v8,lr}
	mov v2,r0
	lsr r0,r0,#4
	mov v4,r0
	ldr v1,=hex_Address1
	ldr v7,[v1]
	ldr v3,=hex_Address2
	ldr v8,[v3]
	ldr v6,=Hex_Deci
	lsl v5,r1,#2
	ldr r1, [v6,v5]
	bl binary
	orr r0,r0,v8
	str r0,[v3]
	sub r0,v2,v4,lsl#4
	bl binary
	orr r0,r0,v7
	str r0,[v1]
	pop {v1,v2,v3,v4,v5,v6,v7,v8,lr}
	bx lr
	
HEX_clear_ASM:
	push {v1,v2,v3,v4,v5,v6,v7,lr}
	mov v7, #0xFFFFFFFF
	mov v2,r0
	lsr r0,r0,#4
	mov v4,r0
	ldr v1,=hex_Address1
	ldr v5,[v1]
	ldr v3,=hex_Address2
	ldr v6,[v3]
	mov r1,#0x000000FF
	bl binary
	sub r0,v7,r0
	and r0,v6,r0
	str r0,[v3]
	sub r0,v2,v4,lsl#4
	bl binary
	sub r0,v7,r0
	and r0,v5,r0
	str r0,[v1]
	pop {v1,v2,v3,v4,v5,v6,v7,lr}
	bx lr

HEX_flood_ASM:
	push {v1,v2,v3,v4,v5,v6,lr}
	mov v2,r0
	lsr r0,r0,#4
	mov v4,r0
	ldr v1,=hex_Address1
	ldr v5,[v1]
	ldr v3,=hex_Address2
	ldr v6, [v3]
	mov r1, #0x000000FF
	bl binary
	orr r0,r0,v6
	str r0,[v3]
	sub r0,v2,v4,lsl#4
	bl binary
	orr r0,r0,v5
	str r0,[v1]
	pop {v1,v2,v3,v4,v5,v6,lr}
	bx lr
//sub rotine, r0 is the number,r1 is the number r0 return bin one by on
//110011 -> 4F4F004F4F
binary:
	push {v1,v2,v3,v5,v6,lr}
	mov v1, r0//v1 = n
	mov v5,r1
	mov r0, #0
loop_binary:
	lsr v2,v1,#1 //s = n//2
	sub v3, v1,v2,lsl#1//v3 is the binary result
	mul v6, v3, v5
	add r0,r0,v6
	lsl v5,v5,#8
	cmp v2,#0
	beq endBinary
	mov v1,v2
	b loop_binary
endBinary:
	pop {v1,v2,v3,v5,v6,lr}
	bx lr
	
read_slider_switches_ASM:
	ldr r0, =switches_Address
	ldr r0,[r0]
	bx lr
//take r0 as input
write_LEDs_ASM:
	push {v1,lr}
	ldr v1, =led_Address
	str r0,[v1]
	pop {v1,lr}
	bx lr
voidMainPartOne:
	push {v1,v2,v3,v4,v5,v6,v7,lr}
	bl PB_clear_edgecp_ASM
	loopOne:
		bl read_slider_switches_ASM
		mov v1,r0//v1 store the value to slider_switches
		cmp v1, #0x200
		beq clearPartOne
		bl write_LEDs_ASM
		bl read_PB_edgecp_ASM
		mov v2,r0//v2 store the value of PB]
		cmp v2,#0
		beq loopOne
		mov r0,v2
		bl PB_edgecp_is_pressed_ASM
		cmp r0,#0
		beq loopOne
	mov r0,#0x00000030
	bl HEX_flood_ASM
	//mov r0,#0x0000000f
	//bl HEX_clear_ASM
	mov r0,v2
	mov r1,v1
	bl HEX_write_ASM
	b loopOne
	clearPartOne:
		mov r0,#0x0000003F
		bl HEX_clear_ASM
		b loopOne
	pop {v1,v2,v3,v4,v5,v6,v7,lr}
	bx lr
//start partTwo r0 and r1 as input
ARM_TIM_config_ASM:
	push {v1,v2,lr}
	ldr v1, =load
	str r0,[v1]
	ldr v2, =control
	str r1,[v2]
	pop {v1,v2,lr}
	bx lr
//return to r0
ARM_TIM_read_INT_ASM:
	push {v1,lr}
	ldr v1,=interrupt
	ldr r0,[v1]
	pop {v1,lr}
	bx lr
ARM_TIM_clear_INT_ASM:
	push {v1,v2,lr}
	mov v1,#1
	ldr v2,=interrupt
	str v1,[v2]
	pop {v1,v2,lr}
	bx lr
//r0 as input, to display the decimal number/r1 as 10
udiv:
	push {v1,v2,v3,lr}
	mov v1,#-1 //counter
	mov v2,r1
	mov v3,#0
	udiv_loop:
		add v1,v1,#1
		mul v3,v1,v2
		cmp v3,r0
		ble udiv_loop
	sub v1,v1,#1
	mov r0,v1
	pop {v1,v2,v3,lr}
	bx lr
//take r0 as input, display that decimal number in the display
write_hex_decimal:
	push {v1,v2,v3,v4,v5,lr}
	mov v1,r0
	mov v2,#1
	mov v3,#10
	loop_write_hex_decimal:
		mov r0,v1//v1 2333
		mov r1,#10
		bl udiv
		mov v4,r0//v4 233
		mul v5,v4,v3 //v5 2330
		sub r1,v1,v5
		mov r0,v2
		bl HEX_write_ASM
		mov v1,v4
		cmp v1,#0
		lsl v2,v2,#1
		bne loop_write_hex_decimal
		
	pop {v1,v2,v3,v4,v5,lr}
	bx lr
//r0 as input
convertTime:
	push {r2,v1,v2,v3,v4,v5,v6,v7,v8,r12,lr}
	mov r2,r0//v6 = sec
	mov v1,#36
	mov v2,#1000
	mov v3,#10
	mov v4,#6
	mul v5,v1,v2//v5 = 36000
	mov r1,v5
	bl udiv
	mov v6, r0//v6 = (int)sec/36000//v6=hour
	mul v7,v6,v5//v7 = v6*36000
	sub v8,r2,v7//v8 = newsec
	mul v5,v4,v3//
	mul v5,v5,v3//v5 = 60*10*10 = 600
	mov r0,v8
	mov r1,v5
	bl udiv
	mov r12,r0//min
	mul v7,r12,v5
	sub v8,v8,v7//secfinal
	
	mov r0,#0
	mul r12,r12,v2
	mul v3,v3,v2
	mul v3,v3,v2
	mul v6,v6,v5
	add r0,r0,v8
	add r0,r0,r12
	add r0,r0,v6
	pop {r2,v1,v2,v3,v4,v5,v6,v7,v8,r12,lr}
	bx lr
voidMainPartTwo:
	push {v1,v2,v3,v4,v5,v6,v7,v8,r12,lr}
	ldr r0,=#20000000//frequency per milisecond
	mov r1,#7//　A and all in one, to reset the
	mov v6,#6
	mov v7,#100
	mov r12,#10
	bl ARM_TIM_config_ASM
	bl PB_clear_edgecp_ASM
	voidMainPartTwoLoop:
		mov v2,#-1 //counter
		voidMainPartTwoLoopTwo:
			bl ARM_TIM_read_INT_ASM
			cmp r0,#1
			beq makeOneCount
			bl read_PB_edgecp_ASM
			mov v3,r0//v3 store the value of PB
			cmp v3,#1
			bleq PB_clear_edgecp_ASM
			moveq r0,#0x3F
			bleq HEX_clear_ASM
			beq voidMainPartTwoLoop
			cmp v3,#2
			bleq PB_clear_edgecp_ASM
			ldreq r0,=#20000000//frequency per milisecond
			moveq r1,#6//　A and all in one, to reset the 
			bleq ARM_TIM_config_ASM
			cmp v3,#4
			bleq PB_clear_edgecp_ASM
			ldreq r0,=#20000000//frequency per milisecond
			moveq r1,#7//　A and all in one, to reset the 
			bleq ARM_TIM_config_ASM
			b voidMainPartTwoLoopTwo
		makeOneCount:
			add v2,v2,#1
			bl ARM_TIM_clear_INT_ASM
			mov r0,#0x3F
			bl HEX_clear_ASM
			
			
			mov r0,v2 // r0 = sec
			bl convertTime
			bl write_hex_decimal
			//ldr v5,=MaxCount
			//ldr v5,[v5]
			cmp v2,#0xFF000000
			beq voidMainPartTwoLoop
			b voidMainPartTwoLoopTwo
			
	pop {v1,v2,v3,v4,v5,v6,v7,v8,r12,lr}
	bx lr
timer:
	push {v1,v2,v3,v4,v5,lr}
	ldr r0,=#200000000//frequency per second
	mov r1,#7//　A and all in one, to reset the 
	bl ARM_TIM_config_ASM
	bl PB_clear_edgecp_ASM
	timerLoop:
		mov v2,#-1 //counter
		timerLoopTwo:
			bl ARM_TIM_read_INT_ASM
			cmp r0,#1
			beq makeOneCount_timer
			bl read_PB_edgecp_ASM
			mov v3,r0//v3 store the value of PB
			cmp v3,#1
			bleq PB_clear_edgecp_ASM
			moveq r0,#0x3F
			bleq HEX_clear_ASM
			beq timerLoop
			cmp v3,#2
			bleq PB_clear_edgecp_ASM
			ldreq r0,=#200000000//frequency per milisecond
			moveq r1,#6//　A and all in one, to reset the 
			bleq ARM_TIM_config_ASM
			cmp v3,#4
			bleq PB_clear_edgecp_ASM
			ldreq r0,=#200000000//frequency per milisecond
			moveq r1,#7//　A and all in one, to reset the 
			bleq ARM_TIM_config_ASM
			b timerLoopTwo
		makeOneCount_timer:
			add v2,v2,#1
			bl ARM_TIM_clear_INT_ASM
			mov r0,#0x3F
			bl HEX_clear_ASM
			mov A2,v2
			mov a1,#1
			bl HEX_write_ASM
			ldr v5,=MaxCount
			//ldr v5,[v5]
			cmp v2,#0xF
			beq timerLoop
			b timerLoopTwo
			
	pop {v1,v2,v3,v4,v5,lr}
	bx lr
	
	
end: 
	b end