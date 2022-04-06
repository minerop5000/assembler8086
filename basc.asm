format MZ
entry CSEG:main

stack 050h

segment DSEG
dispPointer DD 0B8000000h
char DB '8086 Assembler-Programmier-Uebung'

; Single-Char-Hex-String (with color information) "8086 Assembler-Programmier-Uebung" 
copyString DW 0738h, 0730h, 0738h, 0736h, 0720h, 0741h, 0773h, 0773h, 0765h, 076Dh, 0762h, 076Ch, 0765h, 0772h, 072Dh, 0750h, 0772h, 076Fh, 076Fh, 0772h, 0772h, 076Dh, 076Dh, 0769h, 0765h, 0772h, 072Dh, 0755h, 0765h, 0762h, 0775h, 076Eh, 0767h

displayVarGlobal DW 160*4

bcdA DW 5555h
bcdB DW 3157h
charOUT DB 0, 0, 0, 0

bcdStore DW 0


segment CSEG
main:
	; LOAD DSEG
	MOV AX, DSEG
	MOV DS, AX
	;JMP extraCredit

	; SET Video MODE
	; MOV AX, 0002h; AH = 00, AL = 07
	; int 10h
	
	; clear
	MOV AX, 0700h 			; AH = 07h, AL = 00 ; scroll page down
	XOR CX, CX 				; CX = 0 ; upper left 00, 00
	MOV DX, 184Fh 			; lower right 24, 79
    MOV BH, 07h 			; attribute 07h
	int 10h					; video bios interrupt



firstDisplayInit:
	LES DI, [dispPointer]	; load DisplayPointer
	ADD DI, 160				; 2. row
	MOV CX, 33				; init loop counter
	XOR SI, SI				; SI = 0 ; SourceIndex

firstDisplayLoop:
	MOV AL, [char+SI]		; load current Char
	MOV [ES:DI], AL			; display current Char
	INC DI					; DI += 2
	INC DI
	INC SI					; SI++ ; next Char
    LOOP firstDisplayLoop
	

	
secondDisplayInit:
	LES DI, [dispPointer]	; load DisplayPointer
	MOV CX, 33				; init loop counter
	XOR SI, SI				; SI = 0 ; SourceIndex
	XOR BX, BX				; BX = 0 
	
secondDisplayLoop:
    ; color
	XOR BX, 1				; flip 2^0 bit of BX
	;MOV AL, 07h
	;MOV [ES:DI+BX+320], AL
	MOV [ES:DI+BX+320], CL

	; char
	XOR BX, 1				; flip 2^0 bit of BX
	MOV AL, [char+SI]		; load current Char
	MOV [ES:DI+BX+320], AL
    
    ; loop 
	INC DI					; DI += 2
	INC DI
	INC SI					; SI++ ; next Char

	LOOP secondDisplayLoop



thirdDisplayInit:
	LES DI, [dispPointer]	; load DisplayPointer
	ADD DI, 480
	MOV CX, 33				; init loop counter
	MOV SI, copyString		; high-word in DS, low-word in SI

thirdDisplayLoop:
	REP MOVSW               ; Rep: loop until cx = 0 with cx-- ; MOVSW: move SI to DI wordwise



fourthDisplayInit:
	MOV CX, 33				; init loop counter
	XOR SI, SI				; SI = 0 

fourthDisplayLoop:
	; display char
	MOV AL, [char + SI]		
	CALL FUNCTIONSEG:displayLetter

	; iterate
	INC SI					
	LOOP fourthDisplayLoop

extraCredit:
	; load new data segment pointer into DS
	MOV AX, DSEG			
	MOV DS, AX
	
	; load BCDs
	MOV AX, [bcdA]
	MOV DX, [bcdB]
	
	ADD AL, DL				; Low Byte Addition
	DAA
	PUSHF					; Safe Flag bits to adjust for Carry after BCD adjustment
	MOV BL, AL				; store low-byte result
	
	POP CX
	AND CL, 1				; Bitmask Carry Flag

	MOV AL, AH				; Carry Flag Addition
	ADD AL, CL
	DAA
	
	ADD AL, DH				; High Byte Addition
	DAA

	MOV BH, AL  			; store high-Byte result
	MOV [bcdStore+0], BX	; store combined result to memory



printFirstInit:
	MOV DX, 160*5			; 6. row
	MOV [displayVarGlobal], DX

	MOV DX, [bcdA]
	CALL FUNCTIONSEG:BCDtoString
	MOV CX, 4
	XOR SI, SI
	
printFirstLoop:
	MOV AL, [charOUT + SI]
	CALL FUNCTIONSEG:displayLetter
	INC SI
	LOOP printFirstLoop



	MOV AL, ' '
	CALL FUNCTIONSEG:displayLetter
	MOV AL, '+'
	CALL FUNCTIONSEG:displayLetter
	MOV AL, ' '
	CALL FUNCTIONSEG:displayLetter



printSecondInit:
	MOV DX, [bcdB]
	CALL FUNCTIONSEG:BCDtoString
	MOV CX, 4
	XOR SI, SI

printSecondLoop:
	MOV AL, [charOUT + SI]
	CALL FUNCTIONSEG:displayLetter
	INC SI
	LOOP printSecondLoop



	MOV AL, ' '
	CALL FUNCTIONSEG:displayLetter
	MOV AL, '='
	CALL FUNCTIONSEG:displayLetter
	MOV AL, ' '
	CALL FUNCTIONSEG:displayLetter



printBCDResultInit:
	MOV DX, [bcdStore]
	CALL FUNCTIONSEG:BCDtoString
	MOV CX, 4
	XOR SI, SI

printBCDResultLoop:
	MOV AL, [charOUT + SI]
	CALL FUNCTIONSEG:displayLetter
	INC SI
	LOOP printBCDResultLoop
	

terminate:
	; End
	mov ax, 4c00h			; terminate with code 0
	int 21h
	
segment FUNCTIONSEG
displayLetter:
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
	RETF

BCDtoString:		; DX is BCD
	PUSH DS							; Store Chaged Registers
	PUSH AX
	MOV AX, DSEG
	MOV DS, AX
	
	MOV AL, DH						; 0010 1001
	SAR AL, 4						; xxxx 0010
	AND AL, 0Fh						; 0000 0010
	ADD AL, '0'
	MOV [charOUT], AL

	MOV AL, DH
	AND AL, 0Fh
	ADD AL, '0'
	MOV [charOUT+1], AL

	MOV AL, DL
	SAR AL, 4
	AND AL, 0Fh
	ADD AL, '0'
	MOV [charOUT+2], AL

	MOV AL, DL
	AND AL, 0Fh
	ADD AL, '0'
	MOV [charOUT+3], AL

	POP AX
	POP DS
	RETF
	
	