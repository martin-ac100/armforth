fIP .req r4
fW .req  r5
fTOS .req r6
fY .req r7
fRSP .req r8
fX .req r10


.macro NEXT
	ldr fW, [fIP], #4
	bx fW
	.endm

.macro PUSHR reg
	str \reg, [fRSP, #-4]!
	.endm

.macro POPR reg
	ldr \reg, [fRSP], #4
	.endm

.macro DOCOL
	PUSHR fIP
	add fIP, fW, #docol_len
	NEXT
	.endm

	.text
	.arm
	.balign 4
	.global _start


.set	F_IMMED, 0x80000000
.set	F_HIDDEN, 0x40000000
.set	F_LENMASK, 0xFF

.set	link, 0

.macro defcode name, label, flags=0
	.text
        .balign 4
        .global name_\label
	name_\label:
		.int link               // link
		.set link, name_\label
		.int 2f - 1f + \flags
	1:
		.ascii "\name"          // the name
	2:
		.balign 4                // padding to next 4 byte boundary
		.global \label
	\label :
        .endm

.macro defword name, label, flags=0
	defcode "\name", \label, \flags
	DOCOL
	.endm

.macro defvar name, label, initial=0
        defcode \name, \label, 0
	push {fTOS}
	ldr fTOS,#link_\name
	NEXT
	link_\name:
	.int var_\name
        .data
        .balign 4
var_\name:
        .int \initial
        .endm

.macro defconst name, label, value
	defcode \name, \label, 0
	push {fTOS}
	ldr fTOS,1f
	NEXT
1:
	.int \value
	.endm

.balign 4

docol:
	DOCOL
	.balign 4
	.set docol_len,(. - docol)
next:
	NEXT
	.set next_len, (. - next)

defcode "DROP",DROP,0
	pop {fTOS}                // drop top of stack
	NEXT

defcode "SWAP",SWAP,0
	mov fX, fTOS
	pop {fTOS}
	push {fX}
	NEXT

defcode "DUP",DUP,0
	push {fTOS}
	NEXT

defcode "OVER",OVER,0
	push {fTOS}
	ldr fTOS,[sp,#4]
	NEXT

defcode "ROT",ROT,0 // 1 2 3 -- 2 3 1
	mov fX, fTOS
	pop {fTOS}
	pop {fW}
	push {fX}
	push {fW}
	NEXT

defcode "-ROT",NROT,0 // 1 2 3 -- 3 1 2
	pop {fX}
	pop {fW}
	push {fX}
	push {fTOS}
	mov fTOS, fW
	NEXT

defcode "1+",INCR,0
	add fTOS, fTOS, #1
        NEXT

defcode "1-",DECR,0
	sub fTOS, fTOS, #1
        NEXT

defcode "CELLS",CELLS,0
	mov fTOS,fTOS,ASL #2
	NEXT

defcode "+CELL",ADD_CELL,0
	add fTOS, fTOS, #4
        NEXT

defcode "-CELL",SUB_CELL,0
	sub fTOS, fTOS, #4
        NEXT


defcode "+",ADD,0
	pop {fX}
	add fTOS, fTOS, fX
        NEXT

defcode "-",SUB,0
	pop {fX}
	sub fTOS, fX, fTOS
        NEXT

defcode "*",MUL,0
	pop {fX}
	mov fW,fTOS
	mul fTOS, fW, fX
        NEXT

defcode "=",EQU,0
	pop {fX}
	cmp fTOS, fX
	moveq fTOS, #1
	movne fTOS, #0
	NEXT

defcode ">",GT,0
	pop {fW}
	cmp fTOS,fW
	movgt fTOS,#1
	movle fTOS, #0
	NEXT

defcode ">=",GE,0
	pop {fW}
	cmp fTOS,fW
	movge fTOS,#1
	movlt fTOS, #0
	NEXT

defcode "<",LT,0
	pop {fW}
	cmp fTOS,fW
	movlt fTOS,#1
	movge fTOS, #0
	NEXT

defcode "<=",LE,0
	pop {fW}
	cmp fTOS,fW
	movle fTOS,#1
	movgt fTOS, #0
	NEXT

defcode ">0",GTZ,0
	cmp fTOS,#0
	movgt fTOS,#1
	movle fTOS, #0
	NEXT

defcode ">=0",GEZ,0
	cmp fTOS,#0
	movge fTOS,#1
	movlt fTOS, #0
	NEXT

defcode "<0",LTZ,0
	cmp fTOS,#0
	movlt fTOS, #1
	movge fTOS, #0
	NEXT

defcode "<=0",LEZ,0
	cmp fTOS,#0
	movle fTOS,#1
	movgt fTOS,#0
	NEXT

defcode "0=",EQZ,0
	cmp fTOS,#0
	mov fTOS,#0
	moveq fTOS, #1
	NEXT

defcode "~",INV,0
	mvn fTOS,fTOS
	NEXT
	
defcode "&",AND,0
	pop {fX}
	and fTOS,fTOS,fX
	NEXT

defcode "|",OR,0
	pop {fX}
	orr fTOS,fTOS,fX
	NEXT

defcode "^",XOR,0
	pop {fX}
	eor fTOS,fTOS,fX
	NEXT

defcode "EXIT",EXIT,0
	POPR fIP
	NEXT

defcode "LIT",LIT,0
	push {fTOS}
	ldr fTOS,[fIP],#4
	NEXT

defcode "!",STORE,0
	pop {fX}
	str fX,[fTOS]
	pop {fTOS}
	NEXT

defcode "@",FETCH,0
	ldr fTOS,[fTOS]
	NEXT

defcode "@!",COPY,0 // ( src dst -- src+4 dst+4 )
	ldr fX,[fTOS]
	ldr fW,[sp]
	str fX,[fW],#4
	add fTOS,fTOS,#4
	str fW,[sp]
	NEXT

defcode "+!",ADDSTORE,0
	pop {fX}
	ldr fW,[fTOS]
	add fW,fW,fX
	str fW,[fTOS]
	pop {fTOS}
	NEXT

defcode "-!",SUBSTORE,0
	pop {fX}
	ldr fW,[fTOS]
	sub fW,fW,fX
	str fW,[fTOS]
	NEXT

defcode "C!",STOREBYTE,0
	pop {fX}
	strb fX,[fTOS]
	pop {fTOS}
	NEXT

defcode "C@",FETCHBYTE,0
	ldrb fTOS,[fTOS]
	NEXT

defcode "C@C!",CCOPY,0 // ( src dst -- src+1 dst+1 )
	ldr fW,[sp] //dst to fW
	ldrb fX,[fTOS],#1
	strb fX,[fW],#1
	str fW,[sp]
	NEXT

defcode "STRCPY",STRCPY,0 // ( len, src, dst -- )
	ldr fX,[sp] //src to fX
	ldr fY,[sp,#4] //dst to fY
1:	
	ldrb fW,[fX],#1
	strb fW,[fY],#1
	subs fTOS,#1
	bgt 1b
	ldr fTOS,[sp,#8]!

	NEXT

defcode "DOCOL>",DOCOLCPY,0 // ( dst -- )
	ldr fX,=docol
	ldr fW,[fX],#4
	str fW,[fTOS],#4
	ldr fW,[fX],#4
	str fW,[fTOS],#4
	ldr fW,[fX],#4
	str fW,[fTOS],#4
	ldr fW,[fX],#4
	str fW,[fTOS],#4
	ldr fTOS,[sp,#4]!
	NEXT

defcode "STRCMP",STRCMP,0 // ( len, addr1, addr2 -- result )
1:
	ldr fX,[sp]
	ldr fY,[sp,#4]
	ldrb fW,[fX],#1
	str fX,[sp]
	ldrb fX,[fY],#1
	str fY,[sp,#4]
	cmp fW,fX
	bne 2f //not equal
	subs fTOS,#1
	bgt 1b
	mov fTOS,#1 //strings are equal

2:	add sp,#8
	movne fTOS,#0 //strings are not equal
	NEXT


defcode ">R",TOR,0
	PUSHR fTOS
	pop {fTOS}
	NEXT

defcode "R>",FROMR,0
	push {fTOS}
	POPR fTOS
	NEXT

defcode "RDROP",RDROP,0
	add fRSP,fRSP,#4
	NEXT

defcode "RDUP",RDUP,0
	push {fTOS}
	ldr fTOS,[fRSP]
	NEXT

defcode "EXE",EXE,0
	mov fW,fTOS
	pop {fTOS}
	bx fW

.macro go l
	.int \l 
	.endm

defcode "BRANCH",BRANCH,0
	ldr fIP,[fIP]
	NEXT

defcode "BZ",BZ,0
	cmp fTOS,#0
	pop {fTOS}
	beq BRANCH
	add fIP,#4
	NEXT

defcode "BNZ",BNZ,0
	cmp fTOS,#0
	pop {fTOS}
	bne BRANCH
	add fIP,#4
	NEXT

defcode "C_CALL",C_CALL,0
	pop {fW}
	ldr fX,=c_call_0
	sub fX,fX, fW, LSL #2
	bx fX
		pop {r3}
		pop {r2}
		pop {r1}
		pop {r0}
	c_call_0:
		blx fTOS
		pop {fTOS}
	NEXT

defcode "SYS_CALL",SYS_CALL,0
	pop {fW}
	ldr fX,=sys_call_0
	sub fX,fX, fW, LSL #2
	bx fX
		pop {r3}
		pop {r2}
		pop {r1}
		pop {r0}
	sys_call_0:
		svc 0
		mov fTOS,r0
	NEXT

defcode "EMIT",EMIT,0
	mov r0,#1
	mov r2,fTOS
	pop {r1}
	mov r7,#4
	svc 0
	pop {fTOS}
	NEXT

defcode "KEY",KEY,0
_KEY:
	ldr fW,=currkey
	ldr fW,[fW]
	ldr fX,=bufftop
	ldr fX,[fX]
	cmp fW,fX
	bge 1f
	push {fTOS}
	ldrb fTOS,[fW],#1
	ldr fX,=currkey
	str fW,[fX]
	NEXT
1:
	push {fTOS}
	mov r0,#0
	ldr r1,=buffer
	mov r2,#buffer_size
	mov r7,#3
	svc 0
	pop {fTOS}
	cmp r0,#0
	ble 2f
	ldr fX,=currkey
	str r1,[fX]
	add r1,r1,r0
	ldr fX,=bufftop
	str r1,[fX]
	b _KEY
2:	
	mov r0,#0
	mov r7,#1
	svc 0

defcode "CACHEFLUSH",CACHEFLUSH,F_HIDDEN
	ldr r0,=dict_addr
	ldr r0,[r0]
	ldr r1,=var_HERE
	ldr r1,[r1]
	mov r2,#0
	ldr r7,=syscall_cacheflush
	ldr r7,[r7] //syscall cacheflush
	svc 0
	NEXT
.align 2
syscall_cacheflush: .int 0x0f0002 

	.data
	.align 4
currkey:
	.int buffer
bufftop:
	.int buffer
wordbuffer:
	.space 32


defword "ISBLANK",ISBLANK,F_HIDDEN
	.int LIT,' ',OVER,LE,EXIT

defword "WORD",WORD,0 // (  -- len addr )
	.int LIT,wordbuffer
	.int DUP,DUP
	1:
	.int DROP,KEY,ISBLANK,BNZ //( tmp, addr -- key, addr)
		go 1b //skip white spaces
	2:
	.int OVER,STOREBYTE,INCR  //( key, addr -- addr+1) 
	.int KEY,ISBLANK,BZ // is it non-blank char? 
		go 2b // repeat to next char

	.int DROP,LIT,wordbuffer,SUB
	
	.int EXIT

PARSE_DIG:
	DOCOL
	.int LIT,digits
	.int BASE,FETCH,ADD //addr of the highest digit for the given base
	1: //stack: digit_to_find, addr
	.int OVER,OVER,FETCHBYTE,EQU,BNZ
	go 2f
	.int DECR,DUP,FETCHBYTE,LIT,' ',EQU,BZ
	go 1b
	.int LIT,-1,EXIT
	2:
	.int SWAP,DROP,DECR,LIT,digits,SUB,EXIT
	digits:
		.ascii " 0123456789ABCDEF"

defword "NUMBER",NUMBER,0 // ( len addr -- isvalid result ),
	//stack: word_len,addr
	.int LIT,1,TOR,LIT,0,TOR //rstack: value,sign
	1:
	.int OVER,FETCHBYTE,LIT,'-',EQU,BZ // is the first char other then "minus" sign?
		go 2f
	.int FROMR,RDROP,LIT,-1,TOR,TOR,DECR,SWAP,INCR,SWAP // rstack: 0, -1  ( len addr -- len-1 addr+1 )
	2: //stack: word_len, addr
	.int DUP,BNZ // if len>0
		go 3f
	.int DROP,DROP,FROMR,FROMR,MUL,LIT,0,EXIT //valid number stack: ( 0 addr -- 0 result )
	3:
	.int OVER,FETCHBYTE,PARSE_DIG,DUP,LTZ,BNZ // ( len addr -- digit len addr)
		go 4f // if digit <0 -> invalid digit conversion
	.int FROMR,BASE,FETCH,MUL,ADD,TOR,DECR,SWAP,INCR,SWAP,BRANCH // ( dig len addr -- len-1 addr+1)
	go 2b
	4:
	.int RDROP,RDROP,SWAP,DROP,EXIT //invalid number stack: ( -1 len addr -- -1 addr )

defword "FIND",FIND,0 //( len waddr - daddr ),
	.int LATEST,FETCH
	1://next word
	.int DUP,TOR,ADD_CELL,FETCH,LIT,F_LENMASK,LIT,F_HIDDEN,OR,AND,OVER,EQU,BNZ // compare LEN
		go 2f
	.int FROMR,FETCH,DUP,BZ // link=0 -> not found
		go 3f
	.int BRANCH //no match, next word
		go 1b
	2:
	//length is equal, so compare char to char (stack: word_len,word_addr, rstack: dict_word_addr)
	.int OVER,OVER,RDUP,ADD_CELL,ADD_CELL,ROT,STRCMP,FROMR,SWAP,BNZ
		go 3f //dictword match
	.int FETCH, BRANCH //try next word
		go 1b
	3: 
	.int ROT,DROP,DROP,EXIT

defword ">XT",TOXT,0
	.int ADD_CELL,DUP,FETCH,LIT,F_LENMASK,AND,ADD,LIT,7,ADD,LIT,3,INV,AND,EXIT

defword ",",COMMA,0
	.int HERE,FETCH,STORE,LIT,4,HERE,ADDSTORE,EXIT

defword "CREATE",CREATE,0
	//s: len,word
	.int HERE,FETCH //s: here,len,wordbuffer
	.int LATEST,FETCH,COMMA,LATEST,STORE //s:len,wordbuffer
	.int DUP,COMMA
	.int SWAP,OVER //s: len,word,len
	.int HERE,FETCH,ROT //s: len,word,here,len
	.int STRCPY //s: len
	.int HERE,FETCH,ADD,LIT,3,ADD,LIT,3,INV,AND,HERE,STORE,CACHEFLUSH,EXIT

defword "[",LBRAC,F_IMMED
	.int LIT,0,STATE,STORE,EXIT

defword "]",RBRAC,F_IMMED
	.int LIT,1,STATE,STORE,EXIT
		
defword ":",COLON,0
	.int WORD
	.int CREATE
	.int HERE,FETCH,DOCOLCPY
	.int LIT,docol_len,HERE,ADDSTORE
	.int LATEST,FETCH,HIDDEN
	.int RBRAC
	.int EXIT

defword ";",SEMICOLON,F_IMMED
	.int LIT,EXIT,COMMA
	.int LATEST,FETCH,HIDDEN
	.int LBRAC
	.int CACHEFLUSH
	.int EXIT

defword "IMMEDIATE",IMMEDIATE,F_IMMED
	.int LATEST,FETCH,ADD_CELL,DUP,FETCH,LIT,F_IMMED,XOR,SWAP,STORE,EXIT

defword "HIDDEN",HIDDEN,F_IMMED
	.int ADD_CELL,DUP,FETCH,LIT,F_HIDDEN,XOR,SWAP,STORE,EXIT

defword "'",TICK,F_IMMED
	.int WORD,FIND,TOXT,EXIT

defword "TELL",TELL,0 //s: LEN,ADDR
	.int LIT,1,ROT,LIT,3,LIT,4,SYS_CALL,EXIT

defword ".",DOT,0
	.int LIT,prf,SWAP,LIT,2,LIT,printf,C_CALL,EXIT
prf:	.asciz "%d\n"

defword "REPL",REPL,0

	.int RDROP,LIT,GO,TOR
	.int WORD,OVER,OVER,FIND,DUP,BZ
		go 2f //not found in dictionary - maybe literal?
	.int ROT,DROP,DROP
	.int STATE,FETCH,BZ
		go 1f //interpreting now, so execute
	.int DUP,ADD_CELL,FETCH,LIT,F_IMMED,AND,BNZ
		go 1f //compiling now, but immediate word, so execute
	.int TOXT,COMMA,EXIT //compile
1:
	.int TOXT,EXE,EXIT
2:	
	.int DROP,NUMBER,BNZ
		go 4f //invalid literal
	.int STATE,FETCH,BNZ
		go 3f //compile it
	.int EXIT
3:
	.int LIT,LIT,COMMA,COMMA,EXIT
4:
	.int LIT,ERR,LIT,ERR_LEN,TELL
	.int EXIT

ERR:
	.ascii "Not a word.\n"
	.set ERR_LEN, ( . - ERR )

defword "BRK",BRK,F_IMMED
	.int EXIT
		


defvar "STATE",STATE
defvar "HERE",HERE
defvar "LATEST",LATEST,name_BASE // must be last in built-in dictionary
defvar "BASE",BASE,10

	.text
	.align 4
_start:

	push {r4,r5,r6,r7,r8,r10}	
	mov r0,#0
	mov r7,#45
	ldr fX,=var_HERE
	svc 0
	str r0,[fX]
	add r0,r0,#16384
	svc 0
	ldr r0,[fX]
	mov r1,#16384
	mov r2,#7 // #7 = RWX memory
	mov r7,#125 //mprotect syscall (void *addr, size_t len, int prot)
	svc 0

	ldr r0,[fX]
	ldr fX,=dict_addr //stores address of allocated user dict into dist_addr
	str r0,[fX]

	ldr fRSP,=return_stack_top
	ldr fIP,=GO
	NEXT
GO:	.int REPL

.bss
	.align 4
dict_addr:
	.int 0;
return_stack:
	.space 256
return_stack_top:
	.space 256
	
	.set buffer_size,4096
	.align 4
buffer:
	.space buffer_size
buffer_top:
