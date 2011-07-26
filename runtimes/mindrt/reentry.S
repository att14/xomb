extern UVTbase
				[SECTION .pretext]

header:	
				dq 0x0
				dq 0xdeadbeefcafe
				
extern rekmain

global _start
_start:
				jmp rekmain