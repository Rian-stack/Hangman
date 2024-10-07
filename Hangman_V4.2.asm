; Authors: Daniel Flores, Rianne Papa, Ethan Vine, Cody Witty
; Class: CIS123 Assembly Language.
; File Name: Hangman_V3.2.asm
; Creation Date: 10/29/22
; Program Description: Describe with a short paragraph what your
;                      program does and its purpose. Explain in general
;                      terms the expected inputs and output results.

INCLUDE Irvine32.inc			;Use Irvine32 library.

GetUserOption PROTO string1: PTR DWORD, char1: BYTE																;Required to use INVOKE
WriteStrToConsole PROTO string1: PTR DWORD																		;Required to use INVOKE
CheckForMatches PROTO userDefStr: PTR BYTE,  lengthOfStr: DWORD, resultString: PTR BYTE, guessChar: BYTE		;Required to use INVOKE
OverwriteStr PROTO resultString: PTR DWORD, lengthOfStr: DWORD, char: BYTE										;Required to use INVOKE NOTE: Check chapter 8.4, page 317
LoadBuffer PROTO FileName: PTR DWORD
CommaLocation PROTO stringPtr: PTR DWORD
SelectRanStr PROTO bufferStr: PTR DWORD, parsedStr: PTR DWORD, commaPosition: DWORD
MaxBufferSize = 500

.const
	maxAttempts = 6															;Max number of attempts
	maxStringSize = 25														;Max size for user defined string and result string, 26 including NULL BYTE
.data
	CaseTable BYTE '1'														;Lookup value
			  DWORD Multiplayer												;Address for procedure
	EntrySize = ($ - CaseTable)												;Size of 1 entry, 5 BYTES
			  BYTE '2'														;Lookup value
			  DWORD RandomWord												;Address for procedure
			  BYTE '3'														;Lookup value
			  DWORD Exit_P													;Address for procedure
	NumEntries = ($ - CaseTable) / EntrySize								;Number of entries in CaseTable
	menuPrompt BYTE "Please enter an option: 1,2,3", 13, 10,			;Menu prompt
					"1 - Multiplayer", 13, 10,					
					"2 - Guess Randomized Word", 13, 10,
					"3 - Quit" , 13, 10, 0									;End of menu prompt

	CaseTable2 BYTE '1'														;Lookup value
			   DWORD FoodFile												;Address for procedure
			   BYTE '2'														;Lookup value
			   DWORD CompaniesFile											;Address for procedure
			   BYTE '3'														;Lookup value
			   DWORD MASMFile												;Address for procedure
	NumEntries2 = ($ - CaseTable2) / EntrySize
	topicPrompt BYTE "Please select one of the following topics:", 13, 10,	;Topic Prompt
					 "1 - Food", 13, 10,
					 "2 - Companies", 13, 10,
					 "3 - AL Terms", 13, 10, 0								;End of topic prompt

	errorPrompt BYTE "Invalid input, please try again", 13, 10, 0			;Error message, displayed when input is invalid
	currAttempts BYTE 10,"Attempts left: ",0									;String used to display attempts
	gameOver BYTE "---GAME OVER---",0										;String used to display when game is over								
	youWin BYTE "---YOU WIN---",0											;String used to display when user guess word correctly
	youLose BYTE "---YOU LOSE---",10,0										;String used to display when user lost
	entryStr BYTE "Enter a letter:",0										;String used to prompt user to enter a letter
	;userStr BYTE "test", 0													;String that holds user defined word. NOTE: hardcoded to "assembly" for the time being
	userStr BYTE maxStringSize DUP(0),0
	resultStr BYTE maxStringSize DUP('-'),0									;String that holds all correctly guessed characters.
	tempResultStr BYTE maxStringSize DUP('-'),0
	;temp BYTE "-"															;used to remove buffer		
	optionChar BYTE ?														;BYTE that holds the users option to start the game, 'Y' or 'N'
	guessedChar BYTE ?														;BYTE that holds the useres guessed character
	tempCounter DWORD ?														;Used to save counter, ecx.
	buffer BYTE MaxBufferSize DUP(0),0										;User inputed word
	fileFood BYTE "File_Food.txt", 0										;File name for Food Topic
	fileCompanies BYTE "File_Companies.txt", 0								;File name for Companies Topic
	fileAl BYTE "File_Al.txt",0												;File name for MASM terms topic
	fileHandle1 DWORD ?														;File handle
	randomStr BYTE maxStringSize DUP(0),0
	customStr BYTE maxStringSize DUP(0),0
	commaNum DWORD 0
	commaLoc DWORD 1
	numRounds BYTE "How many Rounds do you wanna play: ",0					;String used to prompt user for number of rounds. Used in multiplayer PROC
	player1 BYTE "Player 1 please enter a word:", 0							;String used to prompt P1 to enter a word. Used in multiplayer PROC
	player2 BYTE "Player 2 please enter a word:", 0							;String used to prompt P2 to enter a word. Used in multiplayer PROC
	rounds DWORD ?															;temporary counter used for rounds
	score1 DWORD ?															;stores P1 score
	score2 DWORD ?															;stores P2 score
	multiResult BYTE "Results:",0											;String used to display results
	scorePrompt1 BYTE "P1 Score: ",0										;String used to display P1 score
	scorePrompt2 BYTE "P2 Score: ",0										;String used to display P2 score
	scoreCheck DWORD ?														;score indicator used to check if user guesses correct word
	roundPrompt BYTE "Rounds Remaining: ",0									;String used to display rounds remaining		
	playerPrompt1 BYTE "Player 1's turn",0									;String used to specify turn
	playerPrompt2 BYTE "Player 2's turn",0									;String used to specify turn
	p1wins BYTE "---Player 1 WINS---",0										;String used to display when P1 wins
	p2wins BYTE	"---Player 2 WINS---",0										;String used to display when P2 wins
	tie BYTE "---TIE---",0													;String used to display when P1 and P2 ties


;Strings for the stick figure 
	firstWrong BYTE 10, "   0   ",0
	secondWrong BYTE 10,"   0   ", 13, 10,	                                    
						"   |   ",10,0
	thirdWrong BYTE  10,"  \0   ", 13, 10,
	                    "   |   ",10,0
	fourthWrong BYTE 10,"  \0/  ", 13, 10,
					    "   |   ",10,0
	fifthWrong BYTE  10,"  \0/  ", 13, 10, 
					    "   |   ", 13, 10, 
					    "  /    ",10,0
	sixthWrong BYTE 10,"  \0/  ", 13, 10, 
					   "   |   ", 13, 10, 
					   "  / \  ",10,0
.code
main PROC
WhileLoop:																	;Infinite while loop
L0:																			;Used to ask for a new char if inital char was invalid
	call Randomize
	INVOKE WriteStrToConsole, OFFSET menuPrompt								;Write menuPrompt to console
	call ReadChar															;Read a char from the console
	mov ebx, OFFSET CaseTable												;mov offset of CaseTable to ebx
	mov ecx, NumEntries														;Set loop counter to NumEntries
	call SearchCaseTable													;Search CaseTable for valid entry
	cmp al, 'I'																;Compare al with 'I'
	jne Continue															;Jump to Continue if al == 'I' is false
	INVOKE WriteStrToConsole, ADDR errorPrompt								;Display errorPrompt to console if al == 'I' is true
	jmp L0																	;Jump to L0 to get valid user input
Continue:																	;Label to skip 'true' assignments
	INVOKE OverWriteStr, ADDR userStr, LENGTHOF userStr, 0
	INVOKE WriteStrToConsole, ADDR userStr
	jmp WhileLoop															;Jump back to label
	exit																	;Exit program.
main ENDP

;--------------------------------------------------
;SearchCaseTable: Search through CaseTable to find valid entry and then execute procedure
;Recieves: al  = char to be compared to lookup values
;		   ebx = CaseTable OFFSET
;		   ecx = number of entries in casetable
;Returns: If al matches a lookup value, returns nothing.But procedure tried to value is called.
;No match found, then return al, which is equl to 'I'.'I' represents invalid.
;---------------------------------------------------
SearchCaseTable PROC
Search:																		;Search through all entries in casetable
	cmp al, [ebx]															;compare user inputed char to lookup value in ebx
	jne NextEntry															;If al==[ebx] is false, then jump to NextEntry
	call NEAR PTR [ebx + 1]													;If al==[ebx] is true, then continue. Call procecure tied to lookup value
	jmp Continue															;Jump to continue to skip false assignments
NextEntry:																	;Used to set ebx to next entry lookup value
	add ebx, EntrySize														;Increment ebx by EntrySize
	Loop Search																;Loop to Search
	mov al, 'I'																;Set al to 'I' if no match was found in CaseTable
	ret																		;return
Continue:																	;Lable used to skip false assignments
	ret																		;Return
SearchCaseTable ENDP

;----------------------------------------------------------
;StartGame: Starts hangman game, where user guesses letters
;in a word.
;Recieves: Nothing
;Returns: Nothing
;----------------------------------------------------------
StartGame PROC USES ecx
	mov ecx, maxAttempts													;set counter to 7, max attempts.
	INVOKE OverwriteStr, OFFSET resultStr, LENGTHOF resultStr,'-'		;Overwrites the existing characters of the resultStr.
	GameFunc:
		mov edx, OFFSET currAttempts										;set edx to OFFSET of currAttemtps string
		call WriteString													;Writes currAttemtps string to console
		mov eax, ecx														;Move number of attempts(held in ecx) to eax
		call WriteDec														;Writes number attempts to console
		call crlf															;Newline on console
		call StickFigure                                                    ;Displays current stickfigure

		INVOKE GetUserOption, OFFSET entryStr, guessedChar									;Reads a char from the console. In this case, the guessed char. Char stores in al
		mov guessedChar, al																	;move value in al to guessedChar
		INVOKE CheckForMatches, ADDR userStr, lengthof userStr, ADDR resultStr, guessedChar	;Checks if the guessed char is in the user defined string, then puts the gussed char to the result string if correct
		INVOKE WriteStrToConsole, OFFSET resultStr											;Write result string to console
		INVOKE Str_Copy, ADDR resultStr, ADDR tempResultStr
		INVOKE Str_trim, ADDR resultStr, '-'												;removes buffer
		INVOKE Str_compare,	ADDR resultStr, ADDR userStr									;compares resultStr with userStr
		je Correct																			;jump to Correct if userStr == resultStr	
		INVOKE Str_Copy, ADDR tempResultStr, ADDR resultStr
		dec ecx																;Decrement counter
		jnz GameFunc														;Jump to GameFunc if zero flag is not set. Bypasses the "Loop" directive +/- 128 BYTE jump limit.

		INVOKE WriteStrToConsole, ADDR sixthWrong
		INVOKE WriteStrToConsole, ADDR youLose								;Write youLose string to console
		ret																	;Return in user fails to guess all letters in word
Correct:																	;Prompts user that they won
		inc scoreCheck														;used for multiplayer scoring feature. 
		call crlf															;Newline
		INVOKE WriteStrToConsole, OFFSET youWin								;Write youWin string to console
		call crlf															;Newline
	ret																		;Return
StartGame ENDP

;Use for new features
RandomWord PROC
	INVOKE WriteStrToConsole, ADDR topicPrompt								;Write topic menu to console
	call ReadChar															;Read a char from the console
	mov ebx, OFFSET CaseTable2												;mov offset of CaseTable to ebx
	mov ecx, NumEntries2													;Set loop counter to NumEntries
	call SearchCaseTable													;Search CaseTable for valid entry
	ret
RandomWord ENDP

Exit_P PROC
	INVOKE WriteStrToConsole, ADDR gameOver
	call crlf
	exit
Exit_P ENDP

;--------------------------------------------------------------
;GetUserOption: Prompts user to input a char and reads a char from the console and returns it.
;Recieves: string1: A pointer to string, char1: a single BYTE
;Returns: al = user inputed char
;Requires: string1 must be a DWORD pointer.
;--------------------------------------------------------------
GetUserOption PROC USES edx, string1: PTR DWORD, char1: BYTE	
	INVOKE WriteStrToConsole, string1										;Writes string to console using the string1: PTR DWORD argument
	call ReadChar															;Reads a char from the console, stored in al.														
	ret																		;Return
GetUserOption ENDP

;--------------------------------------------------------------
;WriteStrToConsole: Writes string to console using WriteString irvine32 lib.
;Recieves: string1: A pointer to string
;Returns: Nothing
;Requires: string1 must be a DWORD pointer.
;--------------------------------------------------------------
WriteStrToConsole PROC USES edx, string1: PTR DWORD
	mov edx, string1														;move string pointer to edx
	call WriteString														;Write string to console
	call crlf																;Newline on console
	ret																		;Return
WriteStrToConsole ENDP

;--------------------------------------------------------------
;CheckForMatches: Searches if there are any matching characters in a string given 
;an inputed char. Matching Chars are inputed to a second string.
;Recieves: userDefStr: pointer(BYTE) to first char in string, 
;		   lengthOfStr: length of string to be searched
;		   resultString: pointer(BYTE) to first char in string
;		   guessChar: character, BYTE size.
;Returns:ecx = attempt same(incorrect guess) or increased(correct)
;--------------------------------------------------------------
CheckForMatches PROC USES eax ebx edx esi, userDefStr: PTR BYTE, lengthOfStr: DWORD, resultString: PTR BYTE, guessChar: BYTE
	push ecx																;Save counter to stack, which is the amount fo attempts left
	mov bh, 0																;bh will be a duplicate counter, in case there are 2 repeating chars
	mov esi, userDefStr														;esi is set to a pointer, which could be the loaction of any char in a string.
	mov ecx, lengthOfStr													;set counter to length of string to be checked
	mov edx, resultString													;edx is set to a pointer, which could be the loaction of any char in a string.
	mov ah, guessChar														;Move char to ah
L0:																			;Check loop
	mov al,[esi]															;Set al to value in esi
	inc esi																	;Increment esi, which updates the pointer to the next char
	cmp ah,al																;If ah==al, set zero flag.
	je L1																	;Jump to L1 if zero flag is set
	jmp L2																	;Jump to L2 if zero flag is not set
	L1:																		;Builds result string based on correct chars
		mov [edx], ah														;Set value at location of pointer to ah.
		inc edx																;Increment edx, which updates the pointer to the next char
		mov tempCounter, ecx												;Save Check loop counter to tempCounter
		pop ecx																;Put attempt counter to ecx
		.if bh < 1															;Checks to see if attempt counter has already been increased
			inc ecx															;Increment ecx
			inc bh															;Increment bh to prevent double increments
		.ENDIF																;Ends if statement
		push ecx															;Save attempt counter to stack
		mov ecx, tempCounter												;Restore Check loop counter
		loop L0																;Loop to L0, repeat the process for the next char.
	L2:																		;Executes if chars are not matching
		inc edx																;Increment edx, which updates the pointer to the next char
		loop L0																;Loop to L0, repeat the process for the next char.
		pop ecx																;Restore attempt counter.
	ret																		;Return
CheckForMatches ENDP

;--------------------------------------------------------------
;OverwriteStr: changes every char in a string to '-', except NULL char.
;Recieves: resultString: pointer to string
;		   lengthOfStr: length of the string being overwrited
;Returns: nothing
;--------------------------------------------------------------
OverwriteStr PROC USES ecx edx, resultString: PTR DWORD, lengthOfStr: DWORD, char1: BYTE
	mov al, char1
	mov edx, resultString													;Move pointer of string to edx
	mov ecx, lengthOfStr													;Set counter to length of string
L0:																			;Overwriting loop
	cmp BYTE PTR[edx], 0													;Override pointer to BYTE(to point to a char) and check if value in pointer == 0 (Null BYTE), set zero flag if equal.
	jne L1																	;Jump to L1 if zero flag is not set
	jmp L2																	;Jump to L2 if zero flag is set
	L1:																		;Inserting '-' 
		mov BYTE PTR[edx], al											;Set value in edx to '-'
		inc edx																;Increment edx, which updates the pointer to the next char
	loop L0
	L2:																		;Inserting NULL BYTE 
		mov BYTE PTR[edx], 0												;Set value in edx to 0
	ret																		;Return		
OverwriteStr ENDP

;--------------------------------------------------------------
;Following 3 procedures are used for casetable for picking categories
;--------------------------------------------------------------
FoodFile PROC
	INVOKE LoadBuffer, ADDR fileFood
	call GenRandomNum
	INVOKE CommaLocation, ADDR buffer
	INVOKE SelectRanStr, ADDR buffer, ADDR randomStr, commaloc
	INVOKE Str_Copy, ADDR randomStr, ADDR userStr
	INVOKE WriteStrToConsole, ADDR userStr
	call StartGame
	ret
FoodFile ENDP

CompaniesFile PROC
	INVOKE LoadBuffer, ADDR fileCompanies
	call GenRandomNum
	INVOKE CommaLocation, ADDR buffer
	INVOKE SelectRanStr, ADDR buffer, ADDR randomStr, commaloc
	INVOKE Str_Copy, ADDR randomStr, ADDR userStr
	INVOKE WriteStrToConsole, ADDR userStr
	call StartGame
	ret
CompaniesFile ENDP

MASMFile PROC
	INVOKE LoadBuffer, ADDR fileAl
	call GenRandomNum
	INVOKE CommaLocation, ADDR buffer
	INVOKE SelectRanStr, ADDR buffer, ADDR randomStr, commaloc
	INVOKE Str_Copy, ADDR randomStr, ADDR userStr
	INVOKE WriteStrToConsole, ADDR userStr
	call StartGame
	ret
MASMFile ENDP

;--------------------------------------------------------------
;Multiplayer
;User Inputs a string, second player guesses
;Recieves: scoreCheck (from startGame): Indicator for scoring
;Returns: Nothing
;--------------------------------------------------------------
Multiplayer PROC
	mov scoreCheck, 0							;resets score indicator	
	mov score1,0								;resets P1 score
	mov score2,0								;resets P2 score

	call clrscr									
	INVOKE WriteStrToConsole, ADDR numRounds
	call readInt								;saves number of rounds into eax register
	call clrscr									
	mov rounds, eax								;moves eax value into temporary counter
	mov ecx, rounds								;moves temporary counter into ecx register
L1:
	mov edx, OFFSET roundPrompt			
	call writestring
	mov eax, rounds						
	call writedec								;displays remaining rounds
	call crlf

  P1:
	INVOKE WriteStrToConsole, ADDR player1
	mov  edx,OFFSET customStr
    mov  ecx,MaxBufferSize   
    call ReadString
	call clrscr
	INVOKE Str_Copy, ADDR customStr, ADDR userStr
	INVOKE WriteStrToConsole, ADDR playerPrompt2
	call StartGame
;updates P2 score
	cmp scoreCheck, 1							;checks if user guesses correct word
	je Update2									;if scoreCheck=1, jump to 'Update2'
	jmp P2										;else, jump to P2
Update2:
	inc score2									;increments P2 score
	dec scoreCheck								;decrements scoreCheck back to 0

  P2:
	INVOKE WriteStrToConsole, ADDR player2
	mov  edx,OFFSET customStr
    mov  ecx,MaxBufferSize   
    call ReadString
	call clrscr
	INVOKE Str_Copy, ADDR customStr, ADDR userStr
	;INVOKE WriteStrToConsole, ADDR userStr
	INVOKE WriteStrToConsole, ADDR playerPrompt1
	call StartGame
;updates P1 score
	cmp scoreCheck, 1							;checks if user got correct word
	je Update1									;if scoreCheck=1, jump to 'Update1'
	jmp outputScore								;else, jump to outputScore
Update1:
	inc score1									;increments P1 score
	dec scoreCheck								;decrements scoreCheck back to 0

outputScore:
    call clrscr
	INVOKE WriteStrToConsole, ADDR multiResult
	mov edx, OFFSET scorePrompt1
	call writestring
	mov eax, score1
	call writedec								;displays P1 score
	call crlf
	mov edx, OFFSET scorePrompt2
	call writestring
	mov eax, score2
	call writedec								;displays P2 score
	call crlf
	call crlf
;loop counter
	mov ecx, rounds								;moves temp counter back into ecx
	cmp ecx, 1					
	je quit										;if there is one round remaining, jump to quit
	dec rounds									;decrements temp counter
	jne l1										;else if rounds>1, loop L1
quit:
	mov eax, score2								;moves score2 into eax for cmp instruction
	cmp score1, eax		
	je NoVictor									;jumps if score1=score2
	jl victorP2									;jumps if score1<score2
	jg victorP1									;jumps if score1>score2
	
VictorP1:
	INVOKE WriteStrToConsole, ADDR p1wins
	ret
VictorP2:
	INVOKE WriteStrToConsole, ADDR p2wins
	ret
NoVictor:
	INVOKE WriteStrToConsole, ADDR tie
	ret

Multiplayer ENDP

;----------------------------------------
;LoadBuffer: Used to load buffer(String)
;Recieves: FileName: OFFSET of file name
;Returns: Nothing
;-----------------------------------------
LoadBuffer PROC, FileName: PTR DWORD
	mov edx, FileName														;Move FileName to edx
	call OpenInputFile														;Open text file
	mov fileHandle1, eax													;Store filehandle in eax to fileHandle1 var
	mov edx, OFFSET buffer													;Set edx to the offset of buffer
	mov ecx, MaxBufferSize													;Set ecx to 5000
	call ReadFromFile														;Read from file and stores in buffer
	INVOKE WriteStrToConsole, ADDR buffer									
	mov eax, fileHandle1													;Restore fileHandle to eax, caused errors if not presents
	call CloseFile															;Close input file
	ret																		;return
LoadBuffer ENDP

GenRandomNum PROC
	mov eax, 6
	call RandomRange
	inc eax
	ret
GenRandomNum ENDP

CommaLocation PROC bufferPtr: PTR DWORD
	mov commaNum, 0
	mov commaLoc, 1
	mov edx, bufferPtr
	mov ecx, 100
FindComma: 
	cmp BYTE PTR[edx],','
	jne NextChar
	inc commaNum
	cmp commaNum, eax
	jne NextChar
	ret
NextChar:
	inc edx
	inc commaLoc
	loop FindComma
	ret
CommaLocation ENDP

SelectRanStr PROC bufferStr: PTR DWORD, parsedStr: PTR DWORD, commaPosition: DWORD
	;mov eax, commaPosition
	mov edx, bufferStr
	add edx, commaPosition
	mov esi, parsedStr
	mov ecx, MaxStringSize
BuildStr:
	mov bl, BYTE PTR[edx]
	cmp bl,','
	jne NextChar
	mov BYTE PTR[esi],0
	ret
NextChar:
	mov BYTE PTR[esi],bl
	inc edx
	inc esi
	loop BuildStr
	ret
SelectRanStr ENDP

;--------------------------------------------------------------
;StickFigure
;Views attempts remaining and ouputs a stick figure.
;Recieves: ECX
;Returns: One of the prompts
;--------------------------------------------------------------
StickFigure PROC
	cmp ecx, 6																;Compares attempts remaing to six
	je done																	;if equal skip to done
	cmp ecx, 5																;Compares attempts remaing to five
	jne l2																	;if not equal skip to l2
	  INVOKE WriteStrToConsole, ADDR firstWrong								;display firstWrong stick figure to consle
	  jmp done																;jump to done
	l2:
	  cmp ecx, 4															;Compares attempts remaining to four
	  jne l3																;if not equal skip to l3
	  INVOKE WriteStrToConsole, ADDR secondWrong							;display secondWrong stick figure to consle
	  jmp done																;jump to done
	l3:
	  cmp ecx, 3															;Compares attempts remaing to 3
	  jne l4																;if not equal skip to l4										
	  INVOKE WriteStrToConsole, ADDR thirdWrong								;display thirdWrong stick figure to consle
	  jmp done																;jump to done
	l4:
	  cmp ecx, 2															;Compares attempts remaing to 2
	  jne l5																;if not equal skip to l5
	  INVOKE WriteStrToConsole, ADDR fourthWrong							;display fourthWrong stick figure to consle
	  jmp done																;jump to done
	l5: 
	  INVOKE WriteStrToConsole, ADDR fifthWrong							    ;display fifthWrong stick figure to consle
done:
	ret
StickFigure ENDP

END main
