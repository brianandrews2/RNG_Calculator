TITLE Project Five Arrays, Addressing and Stack-Passed Parameters    (Proj5_andrebri.asm)

; Author:  Brian Andrews
; Last Modified:  05/22/2021
; OSU email address: andrebri@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:   5              Due Date:  05/23/2021
; Description: A program that generates 200 random numbers in the range [10,29], then does the following:
;				It first displays the original list, then sorts the list, displays the median value of the list,
;				displays the list sorted in ascending order, then displays the number of instances of each 
;				generated value starting with the number of 10s.

INCLUDE Irvine32.inc

; (insert macro definitions here)

; (insert constant definitions here)
LO = 10
HI = 29
ARRAYSIZE = 200

.data

; (insert variable definitions here)
introductionMessage	BYTE	"Project 5 - Arrays, Addressing and Stack-Passed Parameters   Author:  Brian Andrews",13,10,13,10,0
explanationMessage	BYTE	"A program that generates 200 random numbers in the range [10,29], then does the following:",13,10,
							"It first displays the original list, then sorts the list, displays the median value of the list,",13,10,
							"displays the list sorted in ascending order, then displays the number of instances of each",13,10,
							"generated value starting with the number of 10s.",13,10,13,10,0
unsortedTitle		BYTE	"Unsorted List:",13,10,0
sortedTitle			BYTE	"Sorted List:",13,10,0
countTitle			BYTE	"Count List:",13,10,0
medianTitle			BYTE	"Median value of array: ",0
randArray			DWORD	ARRAYSIZE dup(?)			; randomly generated array with values between LO and HI and length ARRAYSIZE
countArray			DWORD	ARRAYSIZE dup(0)			; array that counts quantity of each number in randArray
countArrayLen		DWORD	?							; length of countArray (will equal HI - LO)
space				BYTE	" ",0
median				DWORD	?							; median value of sorted randArray using 'Round Half Up' rounding
farewellMessage		BYTE	"Goodbye.",13,10,0


.code
main PROC

	call	Randomize

	; Introduction
	push	OFFSET	introductionMessage
	call	introduction

	; Explanation
	push	OFFSET	explanationMessage
	call	explanation

	; Populate randArray
	push	TYPE randArray
	push	HI
	push	LO
	push	ARRAYSIZE
	push	OFFSET	randArray
	call	fillArray

	; Display randArray
	push	OFFSET	space
	push	TYPE randArray
	push	ARRAYSIZE
	push	OFFSET	unsortedTitle
	push	OFFSET	randArray
	call	displayList

	; Sort randArray
	push	TYPE randArray
	push	ARRAYSIZE
	push	OFFSET	randArray
	call	sortList

	; Display median value of randArray
	push	TYPE randArray
	push	SIZEOF randArray
	push	LENGTHOF randArray
	push	OFFSET randArray
	push	OFFSET medianTitle
	call	displayMedian

	; Display sorted randArray
	push	OFFSET	space
	push	TYPE randArray
	push	ARRAYSIZE
	push	OFFSET	sortedTitle
	push	OFFSET	randArray
	call	displayList

	; Calculate quantity of each digit and populate countList array
	push	TYPE	randArray
	push	TYPE	countArray
	push	OFFSET	randArray
	push	ARRAYSIZE
	push	OFFSET	countArray
	push	LO
	push	HI
	call	countList

	; Display countList array
	mov		EAX, HI
	mov		EBX, LO
	sub		EAX, EBX
	mov		countArrayLen, EAX
	push	OFFSET	space
	push	TYPE countArray
	push	countArrayLen
	push	OFFSET	countTitle
	push	OFFSET	countArray
	call	displayList

	; Display farewell message
	push	OFFSET	farewellMessage
	call	farewell

; (insert executable instructions here)

	Invoke ExitProcess,0	; exit to operating system
main ENDP


; Name:  Introduction
; Introduces the program title and author to the user
; Preconditions:  None
; Postconditions: Introduction message displayed.  EDX changed and not restored.
; Receives:  OFFSET to introductionMessage
; Returns:  None
introduction PROC
	push	EBP
	mov		EBP, ESP
	mov		EDX, [EBP + 8]
	call	WriteString
	pop		EBP
	ret		4
introduction ENDP


; Name:  Explanation
; Explains the program to the user
; Preconditions:  None
; Postcontitions: Explanation message displayed.  EDX changed and not restored
; Receives:  OFFSET to explanationMessage
; Returns:  None
explanation PROC
	push	EBP
	mov		EBP, ESP
	mov		EDX, [EBP + 8]
	call	WriteString
	pop		EBP
	ret		4
explanation ENDP


; Name:  fillArray
; Randomly generates numbers to fill ARRAYSIZE length array with 20 numbers per line, containing values between LO to HI
; Preconditions:  None
; Postconditions:  EAX, EBX, ECX, EDI changed and not restored
; Receives:  TYPE randArray, HI, LO, ARRAYSIZE, and OFFSET randArray
; Returns:  randArray updated in memory with random numbers
fillArray PROC USES EBP
	mov		EBP, ESP
	mov		ECX, [EBP + 12]	; ARRAYSIZE
	mov		EBX, [EBP + 16]	; LO
	mov		EDI, [EBP + 8] ; array offset
_fillArrayLoop:
	mov		EAX, [EBP + 20]	; HI
	call	RandomRange
	cmp		EAX, LO
	jb		_fillArrayLoop ; skip random numbers below min
	mov		[EDI], EAX
	add		EDI, [EBP + 24] ; TYPE
	mov		EAX, [EBP + 20]
	LOOP	_fillArrayLoop
	ret		20
fillArray ENDP


; Name:  sortList
; Sorts the randArray in ascending order
; Preconditions:  None
; Postconditions:  EAX, EBX, ECX, EDX changed and not restored
; Receives:  TYPE randarray, ARRAYSIZE, OFFSET randArray
; Returns:  Values in memory at randArray updated in sorted order
sortList PROC USES EBP
	mov		EBP, ESP
	mov		EDX, [EBP + 8]		; first array index 'i'
	mov		ECX, [EBP + 12]		; ARRAYSIZE # of elements in array
	dec		ECX
_OuterSortLoop:
	push	EDX
	push	ECX
	mov		EBX, EDX
	add		EBX, [EBP + 16]		; add TYPE to obtain second array index 'j'
_InnerSortLoop:
	mov		EAX, [EBX]			; j
	cmp		[EDX], EAX			; cmp i, j
	ja		_Exchange
_ContinueInnerSortLoop:
	add		EDX, [EBP + 16]
	add		EBX, [EBP + 16]
	LOOP	_InnerSortLoop
	pop		ECX
	pop		EDX
	LOOP	_OuterSortLoop
	jmp		_Finish

_Exchange:
	; Sets up the call to the exchangeElements procedure with i and j variables
	push	EDX	; i
	push	EBX	; j
	push	[EDX]
	push	[EBX]
	call	exchangeElements
	jmp		_ContinueInnerSortLoop

_Finish:
	ret 12
sortList ENDP


; exchangeElements
; Exchanges elements at index i and j provided as parameters from sortList procedure
; Preconditions:  None
; Postconditions:  EAX changed and not restored
; Receives:  i index offset, j index offset, i value and j value
; Returns:  i and j element values swapped in memory in the randArray array
exchangeElements PROC USES EBP EDX
	mov		EBP, ESP
	mov		EDX, [EBP + 24] ; i ref
	mov		EAX, [EBP + 12] ; j
	mov		[EDX], EAX

	mov		EDX, [EBP + 20] ; j ref
	mov		EAX, [EBP + 16] ; i
	mov		[EDX], EAX
	ret		16
exchangeElements ENDP


; Name:  displayList
; Prints any array in rows of length 20
; Preconditions:  None
; Postconditions:  Array is displayed in rows of length 20.  EAX, EBX, ECX, EDX changed and not restored.
; Receives:  OFFSET space string, TYPE of array, ARRAYSIZE, OFFSET array title, OFFSET array
; Returns:  None
displayList PROC USES EBP
	mov		EBP, ESP
	mov		ECX, [EBP + 16] ; length of array
	mov		EDX, [EBP + 8]	; offset array
	mov		EBX, 0			; row counter

	push	EDX
	mov		EDX, [EBP + 12] ; list title
	call	WriteString
	pop		EDX

_displayList:
	; Loop that prints each array value with 1 space between them
	mov		EAX, [EDX]
	add		EDX, [EBP + 20] ; TYPE
	call	WriteDec
	inc		EBX
	cmp		EBX, 20
	je		_printNewLine
	push	EDX
	mov		EDX, [EBP + 24] ; OFFSET space
	call	WriteString
	pop		EDX
_returnToDisplayLoop:
	LOOP	_displayList
	cmp		EBX, 0
	jne		_PrintOneMoreLine
	jmp		_finish

_printNewLine:
	; if 20 values are printed this prints a new line and then returns to the loop
	call	CrLf
	mov		EBX, 0
	jmp		_returnToDisplayLoop

_PrintOneMoreLine:
	; prints one more line if displayList stops before filling a complete row of 20
	call	CrLf
	jmp		_finish

_finish:
	call	CrLf
	ret		20
displayList ENDP


; Name:  displayMedian
; Calculates and displays the median of the array
; Preconditions:  None
; Postconditions:  Displays median value of array.  EAX, EBX, ECX, EDX changed and not restored
; Receives:  TYPE of array, SIZEOF array, LENGTHOF array, OFFSET array, and OFFSET array title
; Returns:  median data variable updated in memory with calculated median
displayMedian PROC USES EBP
	mov		EBP, ESP
	mov		EDX, [EBP + 8]	; medianTitle
	call	WriteString
	mov		EAX, [EBP + 16] ; length of randArray
	mov		EDX, 0
	mov		EBX, 2
	div		EBX
	cmp		EDX, 0
	jne		_OddQuantity

	; calculate median if even numbers in array
	mov		EBX, [EBP + 12] ; start of array
	mov		EAX, [EBP + 20] ; size of randArray
	mov		EDX, 0
	mov		ECX, 2
	div		ECX				; find middle-right value of array
	add		EBX, EAX
	mov		EAX, [EBX]		; middle-right number
	push	EAX
	sub		EBX, [EBP + 24] ; decrement index by TYPE of randArray
	mov		EAX, [EBX]		; middle-left number
	pop		EBX
	add		EAX, EBX
	mov		EDX, 0
	mov		EBX, 2
	div		EBX				; average of middle-left and middle-right numbers of array
	push	EAX
	cmp		EDX, 0
	je		_Finish
	jmp		_CalculateDecimal

_CalculateDecimal:
	; Calculates decimal to determine if median is rounded up or down using Round Half Up rounding
	mov		EAX, EDX
	mov		EDX, 10
	mul		EDX
	mov		EDX, 0
	mov		EBX, 2
	div		EBX
	cmp		EAX, 5
	jae		_RoundUp
	jmp		_Finish

_RoundUp:
	; Rounds the median up
	pop		EAX
	inc		EAX
	push	EAX
	jmp		_Finish

_OddQuantity:
	; Calculates the median if array has an odd number of values
	mov		EBX, [EBP + 12] ; start of array
	mov		EAX, [EBP + 20] ; size of array
	sub		EAX, [EBP + 24] ; decrement index by type of array
	mov		EDX, 0
	mov		ECX, 2
	div		ECX
	add		EBX, EAX
	mov		EAX, [EBX]
	push	EAX
	jmp		_Finish

_Finish:
	pop		EAX
	call	WriteDec
	call	CrLf
	call	CrLf
	ret		8
displayMedian ENDP


; Name:  countList
; Prints an array displaying the number of times each value in the randArray was present
; Preconditions:  None
; Postconditions:  Displays countList array.  EAX, EBX, ECX, EDX changed and not restored.
; Receives:  TYPE randArray, TYPE countArray, OFFSET randArray, ARRAYSIZE, OFFSET countArray, LO, HI
; Returns: countList array updated in memory with calculated values at each index
countList PROC USES EBP
	mov		EBP, ESP
	mov		ECX, [EBP + 20] ; ARRAYSIZE
	mov		EBX, [EBP + 16] ; countArray offset
	mov		EDX, [EBP + 24] ; randArray offset
	mov		EAX, [EBP + 12] ; LO
_CountLoop:
	cmp		[EDX], EAX
	je		_IncrementCount
	add		EBX, [EBP + 28] ; countArray TYPE
	;add		EDX, [EBP + 32] ; randArray TYPE
	inc		EAX
	jmp		_CountLoop
	jmp		_Finish

_IncrementCount:
	; increments the current value in countArray
	add		EDX, [EBP + 32] ; randArray TYPE	
	inc		DWORD PTR [EBX]
	LOOP	_CountLoop

_Finish:
	ret		28
countList ENDP


; Name:  farewell
; Says farewell to user
; Preconditions:  None
; Postconditions:  EDX changed and not restored
; Receives:  OFFSET to farewellMessage pushed to stack
; Returns:  None
farewell PROC USES EBP
	mov		EBP, ESP
	mov		EDX, [EBP + 8]
	call	WriteString
	ret
farewell ENDP


END main
