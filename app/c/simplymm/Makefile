CC = x86_64-pc-xomb-gcc
LDFLAGS=-L../../../user/c/lib -L../../../runtimes/mindrt -l:drt0.a -l:syscall.a -l:mindrt.a

all: clean
	$(CC) -O2 -T../../build/elf.ld -o simplymm -static simplymm.c ${LDFLAGS}
	cp simplymm ../../../build/root/binaries/.

clean:
	rm -f simplymm.o simplymm

