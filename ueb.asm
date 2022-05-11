format MZ
entry CSEG:main

stack 0ffh

segment DSEG
dispPointer         DD 0B8000000h
displayVarGlobal    DW 0
LOOP_CHAR           EQU '.'
CHAR_I              EQU 'I'
CHARNUM             EQU 1400
INITIAL_INTERRUPT_8 DD ?
INTERRUPT_PRINT_INT DD INTERUPT:printI
ADDR_INTCTRL		EQU 020h
ICW1				EQU 00010001b
ICW2				EQU 8
ICW3				EQU 00000100b
ICW4				EQU 00000001b
ADDR_TIMER			EQU 040h
TIMER0_MODE			EQU 00110110b
TIMER0_MSB			EQU 00h
TIMER0_LSB			EQU 04h
TIMER0_MODE_BIOS 	EQU 00110110b
TIMER0_MSB_BIOS		EQU 00h
TIMER0_LSB_BIOS		EQU 00h
segment CSEG
main:
	; LOAD DSEG
	MOV AX, DSEG
	MOV DS, AX

getInterupt:
    MOV AX, 3508h           ; AH = 35h; AL = 8 -> get vector (of interrupt 8) -> output in ES:BX
	int 21h                 ; function request
	; Little Endian write of Vector ES:BX
	MOV word [INITIAL_INTERRUPT_8+0], BX
	MOV word [INITIAL_INTERRUPT_8+2], ES

setCustomInterrupt:
	PUSH DS
    MOV AX, 2508h           ; AH = 25h; AL = 8 -> set interrupt vector (of interrupt 8) -> uses DS:DX as vector
	LDS DX, [INTERRUPT_PRINT_INT]
	int 21h
    POP DS

	; SET Video MODE
	; MOV AX, 0002h; AH = 00, AL = 07
	; int 10h

initTimer:
	IN AL, ADDR_INTCTRL+1
	AND AL, 11111110b
	OUT ADDR_INTCTRL+1, AL

	; Init Timer
	MOV AL, TIMER0_MODE
	out ADDR_TIMER+11b, AL
	MOV AL, TIMER0_LSB
	OUT ADDR_TIMER+00b, AL
	MOV AL, TIMER0_MSB
	OUT ADDR_TIMER+00b, AL

	IN AL, ADDR_INTCTRL+1
	OR AL, 01b
	OUT ADDR_INTCTRL+1, AL

initInterupt:
	MOV AL, ICW1
	OUT ADDR_INTCTRL, AL
	MOV AL, ICW2
	OUT ADDR_INTCTRL+1, AL
	MOV AL, ICW3
	OUT ADDR_INTCTRL+1, AL
    MOV AL, ICW4
	OUT ADDR_INTCTRL+1, AL

clear:
	MOV AX, 0700h 			; AH = 07h, AL = 00 ; scroll page down
	XOR CX, CX 				; CX = 0 ; upper left 00, 00
	MOV DX, 184Fh 			; lower right 24, 79
    MOV BH, 07h 			; attribute 07h
	int 10h					; video bios interrupt
    
setCursor:
    MOV AH, 02h
    MOV DX, 1600h
    MOV BH, 0
    int 10h

charLoopInit:
	MOV CX, 500
	CLI
waitOnInit:
	CALL FUNCTIONSEG:waitFunction
	LOOP waitOnInit
	STI
	MOV AL, LOOP_CHAR
	MOV CX, CHARNUM
CHARLoop:
	CALL FUNCTIONSEG:waitFunction
	CALL FUNCTIONSEG:displayLetter
    LOOP CHARLoop

terminate:
    ; Reset BIOS interupt Vector from beginnning of Program
	LDS DX, [INITIAL_INTERRUPT_8]
	MOV AX, 2508h
	int 21h
	; Reset Timer
	MOV AL, TIMER0_MODE_BIOS
	out ADDR_TIMER+11b, AL
	MOV AL, TIMER0_LSB_BIOS
	OUT ADDR_TIMER+00b, AL
	MOV AL, TIMER0_MSB_BIOS
	OUT ADDR_TIMER+00b, AL



	mov ax, 4c00h			; terminate with code 0
	int 21h

segment FUNCTIONSEG
displayLetter:
    PUSHF                           ; push flags
	CLI								; Clear Interupt Flag (supress Interupts)
	PUSH DI							; Store Chaged Registers
	PUSH ES
	PUSH BX
	PUSH DS
	
	MOV BX, DSEG					; load data segment
	MOV DS, BX

	LES DI, [dispPointer]			; load DisplayPointer ; es and di
	ADD DI, [displayVarGlobal]		; Add DisplayOffset
	MOV [ES:DI], AL					; Print char out of AL
	INC DI							; Increment DIsplay Offset
	INC DI
	MOV [displayVarGlobal], DI

	POP DS
	POP BX
	POP ES
	POP DI
	POPF                            ; pop flags -> don't need to do STI, because OPTIMIZATION
	RETF

waitFunction:
    PUSH CX
    MOV CX, 0007h
waitLoop1:
    PUSH CX
    MOV CX, 0FFFFh
waitLoop2:
    NOP
    LOOP waitLoop2

    POP CX
    LOOP waitLoop1

    POP CX
	RETF

segment INTERUPT
default:
	PUSHF
    push ax
    mov al, 00100000b ; OCW2 Non Specific EOI
    out ADDR_INTCTRL,al
    pop ax
	POPF
    iret

printI:
    PUSHF
	push AX
	MOV AL, CHAR_I
	CALL FUNCTIONSEG:displayLetter
    mov al, 00100000b ; OCW2 Non Specific EOI
    out ADDR_INTCTRL, al
    pop ax
	POPF
    iret
