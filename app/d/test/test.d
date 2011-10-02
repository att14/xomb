/* xsh.d

   XOmB Native Shell

*/

module test;

import console;
import Syscall = user.syscall;
//import user.environment;
import libos.keyboard;
import libos.fs.minfs;

import libos.libdeepmajik.threadscheduler;

void main(char[][] argv) {
	ulong s;
	MinFS.initialize();
	File f = MinFS.open("/binaries/xomb", AccessMode.Executable);
	
	asm {
		mov R12, 0x9;	
	}
	
	Syscall._update(f.ptr);
	
	Console.putString("Back to test.d\n");
	
	asm {
		mov R11, R12;
	}
	
	if (s == 9) {
		Console.putString("It worked\n");
	}
}
