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

char[] itoa(long, uint);

void newThread() {
	Console.putString("Hey we made it back");
	
	for(;;){}	
}

void main(char[][] argv) {
	MinFS.initialize();
	File f = MinFS.open("/binaries/xomb", AccessMode.Executable);
	
	XombThread* t = XombThread.threadCreate(&newThread, 0);
	t.schedule();
	
	Syscall.swap(f.ptr);
}
