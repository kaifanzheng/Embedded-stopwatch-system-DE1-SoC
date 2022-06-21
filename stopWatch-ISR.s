.section .vectors, "ax"
B _start            // reset vector
B SERVICE_UND       // undefined instruction vector
B SERVICE_SVC       // software interrupt vector
B SERVICE_ABT_INST  // aborted prefetch vector
B SERVICE_ABT_DATA  // aborted data vector
.word 0             // unused vector
B SERVICE_IRQ       // IRQ interrupt vector
B SERVICE_FIQ       // FIQ interrupt vector

.text
.global _start
.equ hex_Address1, 0xFF200020
.equ hex_Address2,  0xFF200030
.equ pushButton,  0xFF200050
.equ edgeCatpture, 0xFF20005C
.equ pushButtonInterrupt, 0xFF200058
.equ switches_Address, 0xFF200040
.equ led_Address, 0xFF200000
//timer
.equ load, 0xFFFEC600
.equ control, 0xFFFEC608
.equ interrupt, 0xFFFEC60C
Hex_Deci: .word 0x3F,0x06, 0x5B, 0x4F, 0x66, 0x6D,0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7c, 0x39, 0x5E, 0x79, 0x71
PB_int_flag: .word 0x0
tim_int_flag: .word 0x0
_start:
    /* Set up stack pointers for IRQ and SVC processor modes */
    MOV R1, #0b11010010      // interrupts masked, MODE = IRQ
    MSR CPSR_c, R1           // change to IRQ mode
    LDR SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 onchip memory
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV R1, #0b11010011      // interrupts masked, MODE = SVC
    MSR CPSR, R1             // change to supervisor mode
    LDR SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
    BL  CONFIG_GIC               // configure the ARM GIC
    // To DO: write to the pushbutton KEY interrupt mask register
    // Or, you can call enable_PB_INT_ASM subroutine from previous task
    // to enable interrupt for ARM A9 private timer, use ARM_TIM_config_ASM subroutine
	bl enable_PB_INT_ASM
	ldr r0,=#20000000
	mov r1,#7
	bl ARM_TIM_config_ASM
	
    LDR R0, =0xFF200050      // pushbutton KEY base address
    MOV R1, #0xF             // set interrupt mask bits
    STR R1, [R0, #0x8]       // interrupt mask register (base + 8)
    // enable IRQ interrupts in the processor
    MOV R0, #0b01010011      // IRQ unmasked, MODE = SVC
    MSR CPSR_c, R0
IDLE:
	bl voidMainPartTwo
    B IDLE // This is where you write your objective task
	
/*--- Undefined instructions --------------------------------------*/
SERVICE_UND:
    B SERVICE_UND
/*--- Software interrupts ----------------------------------------*/
SERVICE_SVC:
    B SERVICE_SVC
/*--- Aborted data reads ------------------------------------------*/
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
/*--- Aborted instruction fetch -----------------------------------*/
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
/*--- IRQ ---------------------------------------------------------*/
SERVICE_IRQ:
    PUSH {R0-R7, LR}
/* Read the ICCIAR from the CPU Interface */
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C] // read from ICCIAR
/* To Do: Check which interrupt has occurred (check interrupt IDs)
   Then call the corresponding ISR
   If the ID is not recognized, branch to UNEXPECTED
   See the assembly example provided in the De1-SoC Computer_Manual on page 46 */
   //menue push botton check
Pushbutton_check:
    CMP R5, #73
	bne timerCheck
	bl KEY_ISR
	b EXIT_IRQ
timerCheck:
	CMP r5, #29
	bne UNEXPECTED
	bl Time_ISR
	b EXIT_IRQ
UNEXPECTED:
    BNE UNEXPECTED      // if not recognized, stop here
    BL KEY_ISR
EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
SUBS PC, LR, #4
/*--- FIQ ---------------------------------------------------------*/
SERVICE_FIQ:
    B SERVICE_FIQ

CONFIG_GIC:
    PUSH {LR}
/* To configure the FPGA KEYS interrupt (ID 73):
* 1. set the target to cpu0 in the ICDIPTRn register
* 2. enable the interrupt in the ICDISERn register */
/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
/* To Do: you can configure different interrupts
   by passing their IDs to R0 and repeating the next 3 lines */
    MOV R0, #73            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT
	
	MOV R0, #29            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT

/* configure the GIC CPU Interface */
    LDR R0, =0xFFFEC100    // base address of CPU Interface
/* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF        // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
/* Set the enable bit in the CPU Interface Control Register (ICCICR).
* This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
/* Set the enable bit in the Distributor Control Register (ICDDCR).
* This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}

/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
* values are used for other registers in the GIC
* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
/* Configure Interrupt Set-Enable Registers (ICDISERn).
* reg_offset = (integer_div(N / 32) * 4
* value = 1 << (N mod 32) */
    LSR R4, R0, #3    // calculate reg_offset
    BIC R4, R4, #3    // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4    // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1        // enable
    LSL R2, R5, R2    // R2 = value
/* Using the register address in R4 and the value in R2 set the
* correct bit in the GIC register */
    LDR R3, [R4]      // read current register value
    ORR R3, R3, R2    // set the enable bit
    STR R3, [R4]      // store the new register value
/* Configure Interrupt Processor Targets Register (ICDIPTRn)
* reg_offset = integer_div(N / 4) * 4
* index = N mod 4 */
    BIC R4, R0, #3    // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4    // R4 = word address of ICDIPTR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPTR
/* Using register address in R4 and the value in R2 write to
* (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}
	
KEY_ISR:
	ldr r3,=PB_int_flag
	
    LDR R0, =0xFF200050    // base address of pushbutton KEY port
    LDR R1, [R0, #0xC]     // read edge capture register
	str r1,[r3]
    MOV R2, #0xF
    STR R2, [R0, #0xC]     // clear the interrupt
    LDR R0, =0xFF200020    // based address of HEX display
CHECK_KEY0:
    MOV R3, #0x1
    ANDS R3, R3, R1        // check for KEY0
    BEQ CHECK_KEY1
    MOV R2, #0b00111111
    STR R2, [R0]           // display "0"
    B END_KEY_ISR
CHECK_KEY1:
    MOV R3, #0x2
    ANDS R3, R3, R1        // check for KEY1
    BEQ CHECK_KEY2
    MOV R2, #0b00000110
    STR R2, [R0]           // display "1"
    B END_KEY_ISR
CHECK_KEY2:
    MOV R3, #0x4
    ANDS R3, R3, R1        // check for KEY2
    BEQ IS_KEY3
    MOV R2, #0b01011011
    STR R2, [R0]           // display "2"
    B END_KEY_ISR
IS_KEY3:
    MOV R2, #0b01001111
    STR R2, [R0]           // display "3"
END_KEY_ISR:
    BX LR
	
Time_ISR:
	push {r0-r3}
	LDR R0, =load
	LDR R1, [R0, #0xC]
	LDR r3, =tim_int_flag
	STR r1, [r3]
	MOV R2, #0x1
    STR R2, [R0, #0xC]     // clear the interrupt
	pop {r0-r3}
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
			ldr r0,=tim_int_flag
			ldr r0,[r0]
			cmp r0,#1
			beq makeOneCount
			ldr r0,=PB_int_flag
			ldr r0,[r0]
			cmp r0,#1
			bne makeOneCount
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
	
	
end: 
	b end