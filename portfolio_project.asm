TITLE Program Template     (template.asm)

; Author:					Stuart Allen
; Last Modified:			12/5/21
; OSU email address:		allenstu@oregonstate.edu
; Course number/section:	CS271 Section 400
; Project Number:           6
; Due Date:					12/5/21
; Description:				This project will take in 10 integers from the user, using macros within procedure to parse them,
;							display all the numbers, their sum, and truncated average

INCLUDE Irvine32.inc

;	MACROS

; ---------------------------------------------------------------------------------
; Name:				mGetString
;
;					Displays a prompt, stores a user string into a memory location,
					
;
; Preconditions:	Do not pass registers EAX, ECX or EDX
;
; Receives:			message = array address
;					outputLocation = value address
;					maxInputSize = value
;					bytesRead = value address
;
; returns:			outputLocation = stored user string
;					bytesRead = number of bytes read
; ---------------------------------------------------------------------------------
mGetString	MACRO	message:REQ, outputLocation:REQ, maxInputSize:REQ, bytesRead:REQ
	PUSH	EDX
	PUSH	ECX
	PUSH	EAX

	MOV		EDX, message
	CALL	WriteString

	MOV		ECX, maxInputSize
	MOV		EDX, outputLocation
	CALL	ReadString
	MOV		bytesRead, EAX

	POP		EAX
	POP		ECX
	POP		EDX
ENDM

; ---------------------------------------------------------------------------------
; Name:				mDisplayString
;
;					Displays the string passed
;
; Preconditions:	TODO: Do not pass register EAX
;
; Receives:			inputString = string address
;					
;
; returns:			none
; ---------------------------------------------------------------------------------
mDisplayString	MACRO	inputString:REQ
	MOV		EDX, inputString
	CALL	WriteString
ENDM

;	CONSTANTS
MAXLENGTH = 100
USERNUMBERSTOTAL = 10

.data
	introMsg			BYTE		"Stuart Allen's programming assignment 6",13,10,13,10,"Please input 10 signed decimal integers",0
	numberPrompt		BYTE		"Please Enter a signed decimal integer:  ",0

	tempString			BYTE		MAXLENGTH DUP(?)		;	This will hold the string we are currently evaluating
	numberResult		SDWORD		?
	userNumbers			SDWORD		10 DUP(0)

	invalidInputMsg		BYTE		"What you entered is not a number or is larger than a 32 bit signed integer",13,10,0

	stringToNumber		BYTE		MAXLENGTH DUP(?)

	sum					SDWORD		0
	numberSpacerMsg		BYTE		", ",0
	numberRecallMsg		BYTE		13,10,"You entered the following numbers: ",13,10,0

	sumMessage			BYTE		"The sum of the numbers is: ",0

	average				SDWORD		0
	averageMsg			BYTE		"The truncated average of the numbers is: ",0

	goodbyeMsg			BYTE		"Thanks using the program, bye now!",0

.code
main PROC
	MOV		EDX, OFFSET introMsg
	CALL	WriteString
	CALL	CrLf

	MOV		EDI, OFFSET userNumbers
	MOV		ECX, USERNUMBERSTOTAL

_inputLoop:					;	Get all the user's input
	PUSH	EDI
	PUSH	OFFSET invalidInputMsg
	PUSH	OFFSET tempString
	PUSH	OFFSET numberPrompt
	PUSH	DWORD PTR MAXLENGTH
	CALL	ReadVal
	MOV		EAX, [EDI]
	ADD		sum, EAX

	ADD		EDI, 4
	LOOP	_inputLoop

	MOV		EDX, OFFSET numberRecallMsg
	CALL	WriteString

	MOV		ESI, OFFSET userNumbers
	MOV		ECX, USERNUMBERSTOTAL
	MOV		EDX, OFFSET numberSpacerMsg
_recallAllNumbersLoop:		;	Display all the user's numbers
	PUSH	OFFSET stringToNumber
	PUSH	[ESI]
	CALL	WriteVal
	CMP		ECX, 1
	JE		_noComma
	CALL	WriteString

_noComma:
	ADD		ESI, 4
	LOOP	_recallAllNumbersLoop

	CALL	CrLf
	MOV		EDX, OFFSET sumMessage	;	Dipslay the sum
	CALL	WriteString

	PUSH	OFFSET stringToNumber
	PUSH	SDWORD PTR sum
	CALL	WriteVal

	CALL	CrLf
	MOV		EDX, OFFSET averageMsg	;	Display the average
	CALL	WriteString

	MOV		EAX, sum
	MOV		EBX, USERNUMBERSTOTAL
	CDQ
	IDIV	EBX
	PUSH	OFFSET stringToNumber
	PUSH	EAX
	CALL	WriteVal

	CALL	CrLf
	CALL	CrLf
	MOV		EDX, OFFSET goodByeMsg
	CALL	WriteString

	Invoke ExitProcess,0	; exit to operating system
main ENDP

;	PROCEDURES

; ---------------------------------------------------------------------------------
; Name:				ReadVal
;
;					Gets a string value and validates that it is a signed 32 bit
;					integer
;
; Preconditions:	None
;
; Postconditions:	A signed 32 bit integer is stored in the output value
;
; Receives:			A value location, and a maximum buffer size
;
; Returns:			A signed 32 bit integer
; ---------------------------------------------------------------------------------
ReadVal	PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	EBX
	PUSH	ESI
	PUSH	ECX
	PUSH	EDX
	PUSH	EAX

_getNewValue:

	;	+8 is the max length
	;	+12 is the message
	;	+16 is tempString
	;	+20 is the invalid input msg
	;	+24 is where to store the result
	;	EBX is the number of bytes read
	mGetString [EBP + 12], [EBP + 16], [EBP + 8], EBX

	MOV		ESI, [EBP + 16]
	;	Add the number of bytes read to start at the end
	ADD		ESI, EBX
	;	Decrement one to skip the null terminator
	DEC		ESI
	MOV		ECX, 0
	STD

	;	If EBX is greater than 11 it is definitely larger than 32 bits
	CMP		EBX, 11
	JG		_invalidInput

	MOV		EAX, [EBP + 24]
	MOV		[EAX], SDWORD PTR 0			;	initialize the returned value

_iterateTempString:
	MOV		EAX, 0						;	Clear EAX

	LODSB

	;	Check if the value has a negative sign
	CMP		AL, 45
	JNE		_hasPosSign
	INC		ECX							;	If it is the leftmost char ECX should be 1 less than EBX here
	CMP		ECX, EBX
	JNE		_invalidInput				;	If - is not the leftmost char it is invalid
	DEC		ECX

	PUSH	ECX
	MOV		ECX, [EBP + 24]
	MOV		EAX, [ECX]
	MOV		EDX, -1
	IMUL	EDX
	MOV		[ECX], EAX
	POP		ECX
	JMP		_finished

_hasPosSign:
	CMP		AL, 43
	JNE		_noSign
	INC		ECX
	CMP		ECX, EBX
	JNE		_invalidInput
	DEC		ECX

	JMP		_finished

_noSign:
	CMP		ECX, 9				;	If ECX is 9 the power may overflow
	JNE		_noExpOverflow
	CMP		AL, 50
	JG		_invalidInput	;	If the power is 9 and AL is greater than 2 it will surely overflow

_noExpOverflow:
	;	Check if the value is a number
	CMP		AL, 48
	JL		_invalidInput

	CMP		AL, 57
	JG		_invalidInput

	SUB		AL, 48				;	AL/EAX is now the number value

	PUSH	ECX

_power:
	CMP		ECX, 0
	JLE		_powerApplied

	MOV		EDX, 10
	MUL		EDX
	LOOP	_power

_powerApplied:
	POP		ECX

	PUSH	ECX

	MOV		ECX, [EBP + 24]
	ADD		EAX, [ECX]
	JO		_checkOverflow
	MOV		[ECX], EAX

	POP		ECX

	INC		ECX
	CMP		ECX, EBX
	JL		_iterateTempString

	JMP		_finished

_checkOverflow:
	POP		ECX						;	If we get here ECX is still on the stack
	CMP		EAX, -2147483648		;	This is the only negative number that
									;	doesn't have a + equivalent in a SDWORD
	JNE		_invalidInput
	MOV		DL, [ESI]				;	DL is the lower 8 bits of EDX
	CMP		DL, 45					;	It can only be this value if it's supposed to
									;	be negative
	JNE		_invalidInput
	ADD		ECX, 2					;	ECX is on the second from the end character
	CMP		ECX, EBX
	JNE		_invalidInput			;	If it has a - it must be the last character

	MOV		EAX, [EBP + 24]
	MOV		[EAX], SDWORD PTR -2147483648
	JMP		_finished				;	Otherwise it's fine

_invalidInput:
	MOV		EAX, [EBP + 24]
	MOV		[EAX], SDWORD PTR 0		;	Reset the value
	MOV		EDX, [EBP + 20]
	CALL	WriteString
	JMP		_getNewValue

_finished:

	POP		EAX
	POP		EDX
	POP		ECX
	POP		ESI
	POP		EBX
	POP		EBP

	RET		20
ReadVal	ENDP

; ---------------------------------------------------------------------------------
; Name:				WriteVal
;
;					Converts an SDWORD to a string and displays it
;
; Preconditions:	Passed a 32-bit signed integer by value
;
; Postconditions:	Value has been printed
;
; Receives:			SDWORD by value
;
; Returns:			None
; ---------------------------------------------------------------------------------
WriteVal	PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	PUSH	EDX
	PUSH	EDI

	MOV		EDI, [EBP + 12]	;	EDI has the address of our string

	MOV		EAX, [EBP + 8]	;	EAX is now our value
	
	MOV		EBX, 0					;	EBX will represent the sign

	CMP		EAX, 0
	JNE		_nonZero
		
	MOV		[EDI], BYTE PTR 48		;	Put 0 in there
	INC		EDI
	MOV		[EDI], BYTE PTR 0		;	Add a null terminator
	DEC		EDI						;	Reset to beginning
	mDisplayString	EDI
	JMP		_finish

_nonZero:
	CMP		EAX, 0
	JG		_absolutedValue
	MOV		EDX, -1
	IMUL	EDX						;	EAX is now positive
	MOV		[EDI], BYTE PTR 45		;	Put a - sign
	INC		EDI						;	Increase EDI to start of numbers
	MOV		EBX, 1					

_absolutedValue:	
	PUSH	EBX						;	We will push the sign

	MOV		EBX, 10

	MOV		ECX, 0					;	We will use ECX to keep track of how many #s are on the stack
_divideLoop:
	MOV		EDX, 0
	DIV		EBX
	PUSH	EDX
	INC		ECX
	CMP		EAX, 0
	JE		_resultOnStack
	JMP		_divideLoop
	
_resultOnStack:
	CLD
	MOV		EDX, ECX				;	EDX will hold the length of our string for now

_unstackLoop:
	POP		EAX						;	Only 32 bits are valid here but the value will never
									;	exceed 9
	ADD		AL, 48
	STOSB
	LOOP	_unstackLoop

	MOV		[EDI], BYTE PTR 0		;	Add a null terminator

	SUB		EDI, EDX
	
	POP		EBX
	CMP		EBX, 1
	JNE		_displayNonZero
	DEC		EDI

_displayNonZero:
	mDisplayString	EDI

_finish:

	POP		EDI
	POP		EDX
	POP		ECX
	POP		EBX
	POP		EAX
	POP		EBP
	RET		8
WriteVal	ENDP

END main
