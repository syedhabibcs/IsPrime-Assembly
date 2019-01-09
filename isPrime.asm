
;Register Dictionary
;R0 - for I/O
;R1 - index into array Data
;R2 - element at current array index
;R3 - value of digit in question (0 and 9 for decimal).  In the end R3 contains the result.
;R4 - The number being computed (the number represented by the input). THis will be copied into R3 at the end.
;R5 - scratch register.
 
  .orig x3000


	;print the Banner 
	LEA R0, Banner
	TRAP x22

;read in input and store into Data. Aside aside 4 bytes which is enough.

  LEA R0,StrPrompt  ;print user for input.
  trap x22
  LEA R1,Data
ReadLoop: 

  TRAP x20
   
  ADD R3,R0,#-10    ;R3 will be 0 if user hit <ENTER> (=10)
  BRz DoneRead   
  
  STR R0,R1,#0    ;store character read into array Data
  ADD R1,R1,#1    ;increment array index
  BR ReadLoop  
      
DoneRead 
  AND R0,R0,#0    ;set R0 to 0
  STR R0,R1,#0    ;put null-terminating character onto string read (optional)

  LEA R0,StrEcho    
  Trap x22
  LEA R0,Data     ;echo input string
  TRAP x22  
  LEA R0,StrNewline 
  Trap x22

ProcessInput      ;process the input
  AND R4,R4,#0    ;zero out result  
  LEA R1,Data     ;get start of input string
  ADD R1,R1,#1	  ;IGNORE THE # SIGN IN FRONT

;This handle conversion of decimal numbers.
  LDR R2,R1,#0    ;get first digit (must be between 0 and 9, since it is a decimal digit)

DecCalc
  LD R3,ch0
  ADD R3,R3,R2    ;compute digits value
  ADD R4,R4,R3    ;add digit to result
DecNextChar 
  ADD R1,R1,#1
  LDR R2,R1,#0    ;get new digit
  ADD R2,R2,#0    ;see if value is zero (remember, we null terminated the string)
  BRz Done        ;yes, we are done!
  ADD R5,R4,R4    ;multiply R4 by 10
  ADD R5,R5,R5    ;since we do not have a multiply, we have to use a workaround.
  ADD R5,R5,R5
  ADD R3,R4,R4    ;At this point R3 = 2*R4, R5 = 8*R4.
  ADD R4,R3,R5    ;R4 = R3+R5 which is 10*R4

  BR DecCalc      ;deal with current digit  
Done
  ADD R3,R4,#0    ;copy final result into R3.


	
	

	AND R6,R6,#0	;	stack pointer
	LD R6,STACKBASE	;	initialize stack pointer to 0x4000



	; IS PRIME	(checking if the input is a prime number)

	;REGISTER DIRECTORY 
	;R0 - 	i 
	;R1 - 	isPrime
	;R2 - 	-sqrt(n)
	;R3 -	n
	
	
	AND R0,R0,#0
	ADD R0,R0,#2	;	i=2

	AND R1,R1,#0
	ADD R1,R1,#1	;	R1 = isPrime = true = 1
	
	ADD R4,R3,#0	;	R4=n
	JSR PUSH	;	storing n on stack
	AND R4,R4,#0	
	JSR PUSH	;	empty space for return value
	
	JSR SQRT
	LDR R2,R6,#0	;	R2 = sqrt(n)
	JSR POP
	JSR POP		;	removing return value and argument from stack

	NOT R2,R2
	ADD R2,R2,#1	;	R2 = -sqrt(n)

	
WHILE	;(i<=sqrt(n) and isPrime == true)

	ADD R5,R0,R2	;	i-sqrt(n) <=0
	BRp	WDONE
	ADD R1,R1,#0	;	isPrime ==true?	
	BRz	WDONE


	;calculating n/i
	ADD R4,R3,#0	;	pushing n as argument
	JSR PUSH
	ADD R4,R0,#0	;	pushing i as argument
	JSR PUSH

	AND R4,R4,#0
	JSR PUSH	;	pushing space for return value
	
	JSR DIVISION
	LDR R5,R6,#0	;	R5 = n/i
	JSR POP
	JSR POP
	JSR POP


	;n/i * i
	ADD R4,R5,#0	;	saving n/i(R5) on stack	
	JSR PUSH

	ADD R4,R0,#0	;	pushing i as argument
	JSR PUSH

	
	JSR PUSH	;	pushing space for return value

	JSR MULTIPLY
	LDR R5,R6,#0	;	get return value R5 = n/i * i
	JSR POP
	JSR POP
	JSR POP

	
	NOT R5,R5
	ADD R5,R5,#1	;	R5 = -(n/i*i)

	ADD R5,R5,R3	;	R5+n

	BRnp	ZREM	;	if(n/i * i != n) 

	ADD R1,R1,#-1	;	isPrime = false =0 = R1



ZREM	ADD R0,R0,#1;		i++ (zero remainder)
	BR WHILE

WDONE	 ;while loop done
	LEA R0, Data 
	TRAP x22


	ADD R1,R1,#0	;	if zero is composite
	
	BRp PRIME

	LEA R0, StrComp

	BR FDONE	
	
PRIME	LEA R0, StrPri


FDONE	; finally done
	
        TRAP X22

	LEA R0, ENDPROG	; print	end of processing
	TRAP x22


	HALT

;-------------------------------------------------------------------



;Data section

Data        .blkw   4 ;set aside 4 bytes

StrPrompt   .stringz  "\nEnter a 3 character number:"
StrEcho     .stringz  "\nYou have entered:"

StrNewline  .stringz  "\n"

ch0       .fill   #-48  ;negative of the ASCII code for the '0' character

STACKBASE	.fill	x4000	;Start of stack

ENDPROG	.stringz "End of processing.\n"

StrPri	    .stringz  " is a prime number.\n"

StrComp	    .stringz  " is a composite number.\n"

Banner	.stringz "Syed Habib Ur Rehman, 7763408, Comp2280, Michael Zapp, A4, q1\n"




;----------------------------------
;subroutine PUSH - Pushes the value stored in R4 onto the stack
;Data Dictionary
;R4 - Used for push 
;R6 - Stack Pointer

	
PUSH	
	ADD R6,R6,#-1
	STR R4,R6,#0
	RET

;----------------------------------

;subroutine POP - Pops the value from stack and stores in R4 (only if there is anything on stack)
;Data Dictionary
;R4 - Used to store poped from stack 
;R6 - Stack Pointer


POP	
	LD R4,STACKBASE	;	checking underflow
	NOT R4,R4
	ADD R4,R4,#1	;	getting negative stackbase (complement)
	ADD R4,R6,R4		
	BRn	VALID
	AND R4,R4,#0
	BR RETURN
VALID	LDR R4,R6,#0	;	valid so poping the value
	ADD R6,R6,#1
RETURN	RET


;----------------------------------



;subroutine MULTIPLY - computes multiplication of the two numbers passed on the stack
;Data Dictionary
;R0 - First Parameter
;R1 - Second Paratmeter
;R4 - Used for push and pop as well as for the sum(return value)
;R5 - Frame pointer
;R6 - Stack Pointer

;Stack Contents:
;R5+0 - return value
;R5+1 - Parameter 2
;R5+2 - Parameter 1


MULTIPLY	
	
	ADD R4,R7,#0	; 	pushing R7
	JSR PUSH

	ADD R4,R5,#0	;	pushing R5
	JSR PUSH

	ADD R5,R6,#2	;	setting frame pointer	

	ADD R4,R0,#0	;	pushing R0
	JSR PUSH

	ADD R4,R1,#0	;	pushing R1
	JSR PUSH

	;Load arguments
	AND R4,R4,#0
	LDR R0,R5,#2	;	load first parameter into R0 = A
	LDR R1,R5,#1	;	load 2nd parameter into R1 = B

	;do multiply
	BRz MRET	;	if b=2nd parameter = 0 return 0	
	
	
MLOOP	
	ADD R4,R0,R4	;	the sum
	ADD R1,R1,#-1	;	decrement the loop index
	BRp	MLOOP


MRET	;restore
	STR R4,R5,#0	;	put result into stack
	
	JSR POP		;	restore R1
	ADD R1,R4,#0

	JSR POP		;	restore R0
	ADD R0,R4,#0

	JSR POP		;	restoring R5
	ADD R5,R4,#0	

	JSR POP		;	restoring R7
	ADD R7,R4,#0

	RET

;----------------------------------------

;subroutine DIVISION - computes integer division of the two numbers passed on the stack
;Data Dictionary
;R0 - First parameter.
;R1 - Second paramter
;R2 - Used to store subtraction of R0 and R1 (used in loop condition)
;R4 - Holds the sum to return,also used for pop and push
;R5 - Frame pointer
;R6 - Stack Pointer

;Stack Contents:
;R5+0 - return value
;R5+1 - Parameter 2
;R5+2 - Parameter 1

DIVISION	
	
	ADD R4,R7,#0	; 	pushing R7
	JSR PUSH

	ADD R4,R5,#0	;	pushing R5
	JSR PUSH

	ADD R5,R6,#2	;	setting frame pointer	

	ADD R4,R0,#0	;	pushing R0
	JSR PUSH

	ADD R4,R1,#0	;	pushing R1
	JSR PUSH

	ADD R4,R2,#0	;	pushing R2
	JSR PUSH

	;Load arguments
	AND R4,R4,#0
	LDR R0,R5,#2	;	load first parameter into R0 = A
	LDR R1,R5,#1	;	load 2nd parameter into R1 = B

	;do Integer Division
	NOT R1,R1
	ADD R1,R1,#1	;	-b

	ADD R2,R0,R1	;	a-b >=0

	BRn DRET	;	if a>=b	

	
DLOOP	
	ADD R4,R4,#1	;	the sum D=D+1
	
	ADD R0,R0,R1	;	A = A-B
	
	ADD R2,R0,R1
	BRzp	DLOOP


DRET	;restore
	STR R4,R5,#0	;	put result into stack
	
	JSR POP		;	restore R2
	ADD R2,R4,#0

	JSR POP		;	restore R1
	ADD R1,R4,#0

	JSR POP		;	restore R0
	ADD R0,R4,#0

	JSR POP		;	restoring R5
	ADD R5,R4,#0	

	JSR POP		;	restoring R7
	ADD R7,R4,#0

	RET


;------------------------------------------------

;subroutine SQRT - computes square root of a number passed on the stack
;Data Dictionary
;R0 - First parameter.
;R1 - x (the sum)
;R2 - stores x*x
;R4 - used for pop and push
;R5 - Frame pointer
;R6 - Stack Pointer

;Stack Contents:
;R5+0 - return value
;R5+1 - Parameter 1

SQRT	
	
	ADD R4,R7,#0	; 	pushing R7
	JSR PUSH

	ADD R4,R5,#0	;	pushing R5
	JSR PUSH

	ADD R5,R6,#2	;	setting frame pointer	

	ADD R4,R0,#0	;	pushing R0
	JSR PUSH

	ADD R4,R1,#0	;	pushing R1
	JSR PUSH

	ADD R4,R2,#0	;	pushing R2
	JSR PUSH

	;Load arguments
	AND R4,R4,#0
	LDR R0,R5,#1	;	load first parameter into R0 = n
	NOT R0,R0
	ADD R0,R0,#1	;	getting complement of n (-n)
	
	;do Integer Square root
	
	AND R1,R1,#0	;	R1 = x=0

	
SLOOP	
	ADD R1,R1,#1	;	x=x+1
	ADD R4,R1,#0	;	R4 = x
	JSR PUSH	;	save x
	JSR PUSH	;	save x

	AND R4,R4,#0	;	save space for return value
	JSR PUSH
	
	JSR MULTIPLY
	LDR R2,R6,#0	;	get return value of multiply (x*x)		
	JSR POP		;	pop return value
	JSR POP		;	pop first x
	JSR POP		;	pop second x

	ADD R2,R2,R0	;	x2 - n <=0
	

	BRnz	SLOOP

	ADD R4,R1,#-1	;	return value = x-1	

	;restore
	STR R4,R5,#0	;	put result into stack
	
	JSR POP		;	restore R2
	ADD R2,R4,#0

	JSR POP		;	restore R1
	ADD R1,R4,#0

	JSR POP		;	restore R0
	ADD R0,R4,#0

	JSR POP		;	restoring R5
	ADD R5,R4,#0	

	JSR POP		;	restoring R7
	ADD R7,R4,#0

	RET



    .end