;
; MEMR Rasmussen memory test for CP/M2 on Altair.
; Version 2.2
;
; Copyright (C) 1980 Lifeboat Associates
;
; Reconstructed from memory image on April 9, 2020
; by Patrick A Llinstruth (patrick@deltecent.com)
;


MONITOR	EQU	0000H
WBOOT	EQU	0001H
TPA	EQU	0100H

RST2	EQU	0010H
RST5	EQU	0028H
RST7	EQU	0038H

ARGS	EQU	0082H

STACK	EQU	00f0H
ADDRBUF	EQU	00f1H
TADDR	EQU	00f3H
LINECNT	EQU	00f9H
MEMTOP	EQU	00faH
SADDR	EQU	00fcH
EADDR	EQU	00feH

CTRLC	EQU	03H		; Control-C
CR	EQU	0DH		; Carriage return
LF	EQU	0AH		; Line feed
ESC	EQU	1BH		; Escape

LINES	EQU	012H


	ORG	TPA		;START of TPA


; JUMP TABLE - Jumps MUST remain here in same order.
JSTART	JMP	START
JCINIT	JMP	CINIT
JMON	JMP	MONITOR
JCONST	JMP	CONST
JCONIN	JMP	CONIN
JCONOUT	JMP	CONOUT

	DW	TFIRST		; First byte tested

MBANNER:
	DB	CR,LF,CR,LF
	DB	'MEMR Rasmussen Memory Test - Version 2.2',CR,LF
	DB	'Copyright (C) 1980 Lifeboat Associates',0

START:
	LXI	SP,STACK
	CALL	JCINIT
	MVI	A,LINES
	STA	LINECNT
	CALL	CONFIG
	CALL	PSTART
	CALL	PEND
	CALL	PCRLF
	LXI	D,MCONT
	CALL	PSTRING
	CALL	GETCHAR	

TSTLOOP:
	LXI	SP,STACK
	CALL	PCRLF
	LXI	H,PDONE
	PUSH	H
	LDA	ARGS
	CPI	'M'
	JZ	M1ONLY
	CPI	'R'
	JZ	RNTEST
	POP	H
	CALL	RUNALL
PDONE:
	LXI	D,MDONE
	CALL	PSTRING
	JMP	TSTLOOP

RUNALL:
	CALL	FCTEST		;Fast compliment test
	CALL	BSTEST		;Bits stuck high/low test
	CALL	ABTEST		;Adjacent bits stuck test
	CALL	CBTEST		;Checkerboard test
	CALL	WBTEST		;Walking bit left/right test
	CALL	ALTEST		;Address line test
	CALL	RNTEST		;Random number test
	CALL	M1TEST		;M1 cycle test
	RET
CONFIG:
	LXI	D,MBANNER
	CALL	PSTRING
	LXI	D,MBLA
	CALL	PSTRING
	LHLD	WBOOT
	MVI	L,000h
	CALL	PADDR
	LDA	ARGS
	CPI	'T'
	JNZ	CONFIG0
	LXI	D,MTOP
	CALL	PSTRING
	CALL	FINDTOP
	SHLD	MEMTOP
	CALL	PADDR
CONFIG0:
	LXI	D,MKEYS
	CALL	PSTRING
	LXI	D,MDEF
	JMP	PSTRING
PSTART:
	LXI	D,MSTADR	;Starting address
	CALL	PSTRING
GSTART:
	CALL	GETADDR
	JNC	GSTART0
	LXI	H,TFIRST
	PUSH	H
	CALL	PADDR
	POP	H
GSTART0:
	XCHG
	LXI	H,TFIRST
	CALL	SUB16
	XCHG
	SHLD	SADDR
	RNC
	LXI	D,MREST		;Re-enter start address
	CALL	PSTRING
	LXI	H,TFIRST
	CALL	PADDR
	JMP	GSTART
PEND:
	LXI	D,MENDADR
	CALL	PSTRING
GEND:
	CALL	GETADDR
	JNC	GEND0
	LHLD	WBOOT
	LXI	D,0FFFCH
	DAD	D
	PUSH	H
	CALL	PADDR
	POP	H

GEND0:
	XCHG
	LHLD	SADDR
	INX	H
	CALL	SUB16
	JNC	GEND1
	LXI	D,MREND
	CALL	PSTRING
	JMP	GEND

GEND1:
	XCHG
	SHLD	EADDR
	SHLD	00F5H		;025c	22 f5 00 	" . . 
	RET

PBADMEM:
	PUSH	B
	PUSH	D
	PUSH	H
	PUSH	PSW
	CALL	PCRLF
	LXI	D,MLOC
	LDA	LINECNT
	CPI	LINES
	CZ	PSTRING
	CALL	PADDR
	MOV	D,B
	CALL	PBYTED
	MOV	A,B
	CALL	PBINARY
	POP	PSW
	PUSH	PSW
	MOV	D,A
	CALL	PBYTED
	POP	PSW
	CALL	PBINARY
	LDA	LINECNT
	DCR	A
	STA	LINECNT
	JNZ	PBM0
	LXI	D,MCONT
	CALL	PSTRING
	CALL	GETADDR
	MVI	A,LINES
	STA	LINECNT

PBM0:
	POP	H
	POP	D
	POP	B
	RET

SETSE:
	; Set HL=Start Address DE=End Address
	; Check for console character
	CALL	GETC
	LHLD	EADDR
	XCHG	
	LHLD	SADDR
	RET

WRMEM:
	; Write B to memory from start address in HL
	; to ending address in DE
	CALL	SETSE

WRMEM0:
	; Write memory loop
	MOV	M,B
	INX	H
	CALL	SUB16
	JNC	WRMEM0
	RET

RDMEM:
	; Read memory from SADDR to EADDR
	LHLD	SADDR

RDMEMHL:
	; Read memory from HL to EADDR and compare
	; the value to B
	XCHG
	LHLD	EADDR
	XCHG

RDMEM0:
	; Read memory loop
	MOV	A,M
	CMP	B
	CNZ	PBADMEM	
	INX	H
	CALL	SUB16
	JNC	RDMEM0
	RET

FCTEST:
	; FAST COMPLEMENT TEST:
	; This is a test of ALL MEMORY starting at 0 to top of RAM.
	; It loads each byte and tries to store the complement.
	; Tests if properly complemented and restores original byte.
	; This is the only test that can test where MEMR runs
	; in the TPA (from 0 to approx 800H) and the BIOS area
	; which contains the console drivers.

	LDA	ARGS
	CPI	'T'
	RNZ
	LXI	D,MFCTEST
	CALL	PSTRING
	LHLD	MEMTOP
	CALL	PADDR
	LXI	H,0000H
	LXI	D,FCTEST0-1
	CALL	FCTEST0
	LHLD	MEMTOP
	XCHG
	LXI	H,FCTEST1

FCTEST0:
	MOV	A,M
	CMA
	MOV	M,A
	MOV	B,A
	MOV	C,M
	MOV	A,B
	CMA
	MOV	M,A

FCTEST1:
	MOV	A,C
	CMP	B
	CNZ	PBADMEM
	INX	H
	CALL	SUB16
	JNC	FCTEST0
	RET

ABTEST:
	; ADJACENT BIT SHORTED TEST:
	; Sets a single bit in all bytes high.
	; Then checks if a bit is shorted to the
	; ones on each side.
	; The test repeats 8 times, rotating
	; the test bit from LSB to MSB.

	LXI	D,MABTEST
	CALL	PSTRING
	MVI	A,01H

ABT0:
	MOV	B,A
	CALL	ABT1
	JNC	ABT0
	RET

ABT1:
	PUSH	PSW
	CALL	WRMEM
	POP	PSW
	PUSH	PSW
	CALL	RDMEM
	POP	PSW
	RLC
	RET

BSTEST:
	; BIT STUCK TEST:
	; 1. Fills test area with 0FFH and checks for 0FFH.
	; 2. Then fills test area with 0's and tests for 0's.
	; 3. Then re-fills with 0FFH and tests
	;    just in case the bit was originally high in (1.).

	LXI	D,MBSTEST
	CALL	PSTRING
	MVI	B,0FFH
	CALL	WRMEM
	CALL	RDMEM
	MVI	B,00H
	CALL	WRMEM
	CALL	RDMEM
	MVI	B,0FFH
	CALL	WRMEM
	CALL	RDMEM
	RET

CBTEST:
	; CHECKERBOARD TEST:
	; Fill memory with 0AAH, 55H pattern and check.
	; This forms an alternating "checkerboard".
	; Then reverse the pattern and re-check.

	LXI	D,MCBTEST
	CALL	PSTRING
	MVI	B,55H
	CALL	CBT0
	MVI	B,0AAH
	CALL	CBT0
	RET

CBT0:
	CALL	SETSE

CBT1:
	MOV	M,B
	INX	H
	CALL	SUB16
	JC	CBT2
	MOV	A,B
	CMA
	MOV	M,A
	INX	H
	CALL	SUB16
	JNC	CBT1

CBT2:
	CALL	SETSE

CBT3:
	MOV	A,M
	CMP	B
	CNZ	PBADMEM
	INX	H
	CALL	SUB16
	RC
	MOV	A,B
	CMA
	MOV	B,A
	MOV	A,M
	CMP	B
	CNZ	PBADMEM
	MOV	A,B
	CMA
	MOV	B,A
	INX	H
	CALL	SUB16
	JNC	CBT3
	RET

WBTEST:
	; WALKING BIT TEST:
	; Fill memory with one bit set for each byte.
	; The bit rotates at memory increases.
	; For example, byte 1 has bit 1 set, byte 2 bit 2 etc.
	; Then memory is checked for the proper pattern.
	; This is repeated 8 times, rotating the bit each time.
	; Then, the whole procedure is repeated rotating
	; the opposite way.
	; This is a very severe test that frequently detects
	; errors that other tests in the battery do not.
	; Don't be surprised if the walking bit "right" test
	; detects errors that "left" doesn't, or vice versa.
	; Sometimes memory developes strange pattern sensitive
	; errors that are most difficult to find.

	LXI	D,MWLTEST
	CALL	PSTRING
	MVI	B,80H

WBT0:
	CALL	WBT2
	MOV	A,B
	RLC
	MOV	B,A
	CPI	80H
	JNZ	WBT0
	LXI	D,MWRTEST
	CALL	PSTRING
	MVI	B,01H

WBT1:
	CALL	WBT5
	MOV	A,B
	RRC
	MOV	B,A
	CPI	01H
	JNZ	WBT1
	RET

WBT2:
	PUSH	B
	CALL	SETSE

WBT3:
	MOV	A,B
	RLC
	MOV	B,A
	MOV	M,A
	INX	H
	CALL	SUB16
	JNC	WBT3
	CALL	SETSE
	POP	B
	PUSH	B

WBT4:
	MOV	A,B
	RLC
	MOV	B,A
	MOV	A,M
	CMP	B
	CNZ	PBADMEM
	INX	H
	CALL	SUB16
	JNC	WBT4
	POP	B
	RET

WBT5:
	PUSH	B
	CALL	SETSE

WBT6:
	MOV	A,B
	RRC
	MOV	B,A
	MOV	M,A
	INX	H
	CALL	SUB16
	JNC	WBT6
	CALL	SETSE
	POP	B
	PUSH	B

WBT7:
	MOV	A,B
	RRC
	MOV	B,A
	MOV	A,M
	CMP	B
	CNZ	PBADMEM
	INX	H
	CALL	SUB16
	JNC	WBT7
	POP	B
	RET

ALTEST:
	; ADDRESS LINE SHORTED TEST:
	; This test will detect addressing problems in memory boards.
	; It fills all memory with 55H, then writes an 0AAH
	; at the lowest memory location tested.
	; It then rechecks the rest of memory to see if it is still 55H.
	; It then clears the original location of AAH and writes
	; writes the AAH into the next location.
	; Then does same with location 2,4,8,etc setting
	; a new address bit high each time and testing all of memory.
	; If any address bit is shorted to another,
	; the test will find an 0AAH in another location
	; than the place it wrote one.

	LXI	D,MALTEST
	CALL	PSTRING
	MVI	B,55H
	CALL	ALT0
	MVI	B,0AAH

ALT0:
	CALL	WRMEM
	MOV	A,B
	STA	00F8H		;0409	32 f8 00 	2 . . 
	CALL	SETSE
	CMA
	MOV	M,A
	INX	H
	CALL	RDMEMHL
	LXI	B,WBOOT

ALT1:
	LHLD	SADDR
	DAD	B
	RC
	MOV	A,D
	SUB	H
	RC
	JNZ	ALT2
	MOV	A,E
	SUB	L
	RC

ALT2:
	LDA	00F8H
	PUSH	B
	MOV	B,A
	CMA
	MOV	M,A
	INX	H
	CALL	SUB16
	JC	ALT3
	CALL	RDMEMHL
	POP	H
	DAD	H
	RC
	MOV	B,H
	MOV	C,L
	JMP	ALT1

ALT3:
	POP	B
	RET

RNTEST:
	; RANDOM NUMBER TEST:
	; A random number routine generates an 8 bit number
	; pattern and writes it through all test memory.
	; It then re-inserts the same seed to the routine
	; and test reads the memory. A new seed is generated
	; and the exercise is repeated with a new pattern.
	; This test goes thru 8 cycles each time the battery
	; is run.  If "MEMR R" is used, it cycles continuously
	; until terminated with an ESC.

	LXI	D,MRNTEST
	CALL	PSTRING
	MVI	C,'1'

RNT0:
	PUSH	B
	CALL	RNT1
	CALL	PSPACE
	POP	B
	CALL	PCHAR
	INR	C
	MVI	A,'9'
	CMP	C
	JNZ	RNT0
	RET

RNT1:
	LHLD	00F5H		;045c	2a f5 00 	* . . 
	SHLD	TADDR
	CALL	SETSE

RNT2:
	CALL	RNT4
	MOV	M,B
	INX	H
	CALL	SUB16
	JNC	RNT2
	LHLD	TADDR
	SHLD	00F5H		;0473	22 f5 00 	" . . 
	CALL	SETSE

RNT3:
	CALL	RNT4
	MOV	A,M
	CMP	B
	CNZ	PBADMEM
	INX	H
	CALL	SUB16
	JNC	RNT3
	RET

RNT4:
	PUSH	H
	LHLD	00F5H		;048a	2a f5 00 	* . . 
	MOV	A,L
	XRA	H
	MOV	B,A
	RLC
	MOV	L,A
	ADD	H
	MOV	H,A
	SHLD	00F5H		;0494	22 f5 00 	" . . 
	POP	H
	RET

M1TEST:
	; M1 CYCLE TEST
	; This tests the M1 cycle time for executing instructions
	; which is different than the time to simply read memory
	; in the Z-80.  The times are the same in 8080 so the
	; test is not especially useful for them.
	; A small segment of executing code "worms" its way thru
	; memory, reporting the results of its execution at each
	; memory location.  Marginal memory may pass all the other
	; tests but fail to execute properly at a given address.
	; When this happens, the test normally reports the error
	; location in the standard way.  However, the faulty execution
	; may cause the test to "bomb" at this point.
	;
	; By running the M1 test in the form "MEMR M", only this
	; test will run, reporting each address as it executes.
	; If a memory failure causes the test to bomb, the last
	; address displayed on the screen locates the failure address.
	; 
	; Please note that the M1 test (only) uses restart locations
	; 2 and 5 in its operation, and also inserts an error trap
	; at restart location 7, which is the most likely landing
	; place for a program gone wild.  That is, a program gone
	; haywire, jumping randomly all over memory, is likely at some
	; point to land in a location that has no memory which will
	; appear to contain the instruction 0FFH, which is a restart 7,
	; which causes the CPU to immediately jump to 38H, the restart
	; 7 location. We mention this because, it your computer happens
	; to use restarts 2, 5 or 7 for critical operations, this test
	; may not run.  That's why it is last.

	LXI	D,MM1TEST
	CALL	PSTRING
	JMP	M1T0

M1FLAG:
	DB	0

M1B0:
	DB	0

M1B1:
	DB	0

M1ONLY:
	MVI	A,'M'
	JMP	M1T1

M1T0:
	XRA	A

M1T1:
	STA	M1FLAG
	LXI	D,TRAP
	LXI	H,RST7
	CALL	SETRST
	LXI	D,M1T3
	LXI	H,RST5
	CALL	SETRST
	LXI	D,M1T6
	LXI	H,RST2
	CALL	SETRST
	LHLD	SADDR
	MOV	A,H		; A=H of Start Address
	CMA			;
	STA	M1B1		;
	LXI	D,000DH		;
	DAD	D		; HL=Start Address + 13
	LXI	D,ENDCB		; DE=End of code block

M1T2:
	MVI	B,14		; Move 14 bytes
	CALL	M1T7		; from DE to HL in reverse
	INX	H
	INX	H
	PCHL			; Jump to code block at HL

M1T3:
	; Called from RST 5
	; 
	; LHLD	M1B0
	; PUSH	H
	; MVI	A,0FFH
	; POP	D
	; RST	5

	POP	H
	MVI	B,0FFH
	CMP	B
	CNZ	PBADMEM
	LDA	M1B0
	MOV	B,A
	MOV	A,E
	CMP	B
	CNZ	PBADMEM
	LDA	M1B1
	MOV	B,A
	MOV	A,D
	CMP	B
	CNZ	PBADMEM
	LDA	M1FLAG
	CPI	'M'
	JNZ	M1T4
	CALL	PWORD
	CALL	PCRLF
	JMP	M1T5

M1T4:
	MOV	A,H
	ANI	0F0H
	MOV	B,A
	LDA	M1B1
	ANI	0F0H
	CMP	B
	JZ	M1T5
	MOV	A,H
	STA	M1B1
	CALL	PSPACE
	MOV	A,H
	RRC
	RRC
	RRC
	RRC
	CALL	PNIBBLE

M1T5:
	XRA	A
	INX	H
	INX	H
	INX	H
	PCHL

M1T6:
	; Called from RST 2
	LHLD	EADDR
	XCHG
	POP	H
	CALL	SUB16
	RC
	MOV	D,H
	MOV	E,L
	DCX	D
	JMP	M1T2

M1T7:
	LDAX	D
	MOV	M,A
	DCX	D
	DCX	H
	DCR	B
	JNZ	M1T7
	RET

TRAP:
	; Called from RST 7
	LXI	D,MTRAP
	CALL	PSTRING
	POP	H
	DCX	H
	CALL	PWORD
	INX	H
	PCHL

MTRAP:
	DB	CR,LF
	DB	'Trap at ',0

SETRST:
	MVI	M,0C3H		; JMP opcode
	INX	H
	MOV	M,E
	INX	H
	MOV	M,D
	RET
;
; Start of 14 byte code block
;
CODEBLK:
	RST	7		; TRAP
	LHLD	M1B0
	PUSH	H
	MVI	A,0FFH
	POP	D
	RST	5		; M1T3
	RST	7		; TRAP
	RST	7		; TRAP
	RST	7		; TRAP
	NOP			; NOP
ENDCB:
	RST	2
;
; End of 14 byte code block
;

GETBYTE:
	CALL	GETCHAR
	RZ
	CPI	' '
	JZ	JSTART
	CPI	CTRLC
	JZ	RESET
	CPI	ESC
	JZ	JSTART
	CALL	ATOI
	JP	INPERR
	RRC
	RRC
	RRC
	RRC
	MOV	E,A
	PUSH	D
	CALL	GETCHAR
	POP	D
	JZ	INPERR
	CALL	ATOI
	JP	INPERR
	ORA	E
	RET

ATOI:
	; Covert ASCII character in A to decimal and return in A
	; Sign bit is set on error
	CALL	TOUPPER	
	SUI	'0'
	JM	ATOI0	
	CPI	0AH
	RM
	SUI	07H
	CPI	0AH
	JM	ATOI0	
	CPI	10H
	RM

ATOI0:
	XRA	A
	RET

TOUPPER:
	CPI	'`'
	RC
	CPI	'{'
	RNC
	ANI	'_'
	RET

INPERR:
	POP	H
	LXI	D,MIERROR	;Input error
	CALL	PSTRING

GETADDR:
	CALL	GETBYTE
	RC
	MOV	H,A
	SHLD	ADDRBUF
	CALL	GETBYTE
	LHLD	ADDRBUF
	MOV	L,A
	RET

PBINARY:
	MOV	E,A
	MVI	D,02H
	CALL	PSPACES		; Print 2 spaces
	MVI	B,02H

PBIN0:
	MVI	D,04H

PBIN1:
	MOV	A,E
	RAL
	MOV	E,A
	MVI	C,'0'
	JNC	PBIN2
	MVI	C,'1'

PBIN2:
	CALL	PCHAR
	DCR	D
	JNZ	PBIN1
	CALL	PSPACE
	DCR	B
	JNZ	PBIN0
	JMP	PSP4		;Print 4 spaces

PSP4:
	MVI	D,04H

PSPACES:
	; Prints the number of spaces in D
	CALL	PSPACE
	DCR	D
	JNZ	PSPACES
	RET

PSTRING:
	; Print string in D:E
	LDAX	D
	ORA	A
	RZ
	MOV	C,A
	CALL	PCHAR
	INX	D
	JMP	PSTRING
	RET

PADDR:
	; Print 16-bit address in D:E followed by 4 spaces
	CALL	PWORD
	JMP	PSP4		;Print 4 spaces

PWORD:
	; Print 16-bit word in D:E
	MOV	A,H
	CALL	PBYTE
	MOV	A,L
	JMP	PBYTE

PBYTED:
	; Print byte with value in D
	MOV	A,D

PBYTE:
	; Print byte with value in A
	PUSH	PSW
	RRC
	RRC
	RRC
	RRC
	CALL	PNIBBLE
	POP	PSW

PNIBBLE:
	ANI	0FH
	CPI	0AH
	JM	PN0
	ADI	07H

PN0:
	ADI	'0'
	MOV	C,A
	JMP	PCHAR

PCRLF:
	MVI	C,CR
	CALL	PCHAR
	MVI	C,LF
	JMP	PCHAR

PSPACE:
	MVI	C,' '
	JMP	PCHAR

	; ???
	INX	H			;0646
	; ???
SUB16:
	MOV	A,H
	ORA	L
	STC
	RZ
	MOV	A,E
	SUB	L
	MOV	A,D
	SBB	H
	RET

FINDTOP:
	LXI	H,00FFH

FT0:
	INR	H
	JZ	FT1
	MOV	B,M
	MOV	A,M
	CMA
	MOV	M,A
	MOV	C,M
	CMP	C
	MOV	M,B
	JZ	FT0

FT1:
	DCR	H
	RET

MBLA:
	DB	CR,LF			;0663
	DB	CR,LF
	DB	'BIOS located at ',0

MTOP:
	DB	' Top of memory at ',0	;0678

MKEYS:
	DB	CR,LF			;068b
	DB	CR,LF
	DB	'Press ESC or SPACE key to interrupt test'
	DB	CR,LF			;06b7
	DB	'or CONTROL C to reboot CP/M at any time. ',0

MDEF:
	DB	CR,LF			;06e3
	DB	CR,LF
	DB	'Response of "CR" gives default test range'
	DB	CR,LF
	DB	'which starts above this program and ends at BIOS.',0

MCONT:
	DB	CR,LF			;0744
	DB	'"CR" to continue test - "ESC", "SP" or "^C" to stop ',0

MSTADR:
	DB	CR,LF
	DB	CR,LF
	DB	'Starting address (Hex or "CR") ',0

MREST:
	DB	CR,LF			;079f
	DB	'Re-enter, starting address must be at least ',0

MENDADR:
	DB	CR,LF			;07ce
	DB	CR,LF			;07cf
	DB	'Ending address   (Hex or "CR") ',0

MREND:
	DB	CR,LF			;07f2
	DB	'Re-enter, ending address below start ',0

MIERROR:
	DB	CR,LF			;081a
	DB	'Input error - Retype 4 hex digits ',0

MFCTEST:
	DB	CR,LF
	DB	'Fast complement test from 0 to ',0

MBSTEST:
	DB	CR,LF			;0861
	DB	'Bit stuck high or low test ',0

MABTEST:
	DB	CR,LF
	DB	'Adjacent bits shorted test ',0

MCBTEST:
	DB	CR,LF			;089d
	DB	'Checkerboard pattern test ',0

MWLTEST:
	DB	CR,LF			;08ba
	DB	'Walking bit  left test ',0

MWRTEST:
	DB	CR,LF			;08d4
	DB	'Walking bit right test ',0

MALTEST:
	DB	CR,LF			;08ee
	DB	'Address line test ',0

MRNTEST:
	DB	CR,LF			;0903
	DB	'Random number test - Cycle: ',0

MM1TEST:
	DB	CR,LF			;0922
	DB	'M1 cycle test - 4K block: ',0

MDONE:
	DB	CR,LF			;093f
	DB	'Test series complete',0

MLOC:
	DB	'LOCATION  SHOULD BE           WAS',CR,LF,0

GETCHAR:
	PUSH	H
	PUSH	D
	PUSH	B
	CALL	JCONIN
	CPI	CR
	STC
	JZ	GC0
	ORA	A
	PUSH	PSW
	MOV	C,A
	CALL	PCHAR
	POP	PSW

GC0:
	POP	B
	POP	D
	POP	H
	RC
	CALL	CMDCHAR
	ORA	A
	RET

PCHAR:
	PUSH	H
	PUSH	D
	PUSH	B
	CALL	JCONOUT
	POP	B
	POP	D
	POP	H

GETC:
	PUSH	H
	PUSH	D
	PUSH	B
	CALL	JCONST
	ORA	A
	JZ	GETC0
	CALL	JCONIN

GETC0:
	POP	B
	POP	D
	POP	H
	RZ

CMDCHAR:
	CPI	' '
	JZ	START
	CPI	ESC
	JZ	START
	CPI	CTRLC
	JZ	RESET
	ORA	A
	RET

RESET:
	LXI	SP,STACK
	JMP	JMON

CONST:
	JMP	0006H		;09c7	c3 06 00 	. . . 

CONIN:
	JMP	0009H		;09ca	c3 09 00 	. . . 

CONOUT:
	JMP	000CH		;09cd	c3 0c 00 	. . . 

CINIT:
	LDA	WBOOT+1
	STA	CONST+2
	STA	CONIN+2
	STA	CONOUT+2
	RET

TFIRST:
	DB	0,0,0,0,0,0,0,0
	DB	0,0,0,0,0,0,0,0
	DB	0,0,0,0,0,0,0,0
	DB	0,0,0,0,0,0,0,0
	DB	0,0,0
