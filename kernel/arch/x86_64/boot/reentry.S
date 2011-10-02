bits 64

section .pretext

header:	
				dq 0x0
				dq 0xdeadbeefcafe
			
extern rekmain
				
global _start
_start:
	jmp rekmain

	;jmp rax

	; we should not get here

haltloop:

	hlt
	jmp haltloop
	nop
	nop
	nop
	