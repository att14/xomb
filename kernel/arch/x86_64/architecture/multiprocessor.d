/*
 * mp.d
 *
 * This module contains the abstraction for the Multiprocessor module
 *
 */

module architecture.multiprocessor;

import architecture.cpu;

import kernel.arch.x86_64.core.gdt;
import kernel.arch.x86_64.core.tss;
import kernel.arch.x86_64.core.idt;
import kernel.arch.x86_64.core.ioapic;
import kernel.arch.x86_64.core.lapic;
import kernel.arch.x86_64.core.info;
import kernel.arch.x86_64.core.paging;

// MP Spec
import kernel.arch.x86_64.specs.mp;
import kernel.arch.x86_64.specs.acpi;

// Import helpful routines
import kernel.core.error;	// ErrorVal
import kernel.core.log;		// logging

// reinit
import user.environment;
import kernel.core.kprintf; // remove

struct Multiprocessor {
static:
public:

	// This module will conform to the interface
	ErrorVal initialize() {
		// 1. Look for the ACPI tables (preferred method)
		if(ACPI.Tables.findTable() == ErrorVal.Success && ACPI.Tables.readTable() == ErrorVal.Success) {
			// ACPI tables parsed
		}
		else {
			// 2. Fall back on looking for the MP tables

			// 2a. Locate the MP Tables
			if (MP.findTable() == ErrorVal.Fail) {
				// If the MP table is missing, fail.
				return ErrorVal.Fail;
			}

			// 2b. Read MP Table
			if (MP.readTable() != ErrorVal.Success) {
				return ErrorVal.Fail;
			}
		}

		// 3a. Initialize Local APIC
		Log.print("LocalAPIC: initialize()");
		ErrorVal LAPICInitialized = Log.result(LocalAPIC.initialize());
		if (LAPICInitialized != ErrorVal.Success) {
			return ErrorVal.Fail;
		}

		// 3b. Initialize IOAPIC
		Log.print("IOAPIC: initialize()");
		ErrorVal IOAPICInitialized = Log.result(IOAPIC.initialize());
		if (IOAPICInitialized != ErrorVal.Success) {
			return ErrorVal.Fail;
		}

		// Enable Interrupts
		asm {
			sti;
		}

		// If it got this far, it has succeeded
		return ErrorVal.Success;
	}
	
	ErrorVal reinitialize() {
		// Remake Tables
		ubyte* start = findFreeSegment();
		Paging.mapRegion(start, cast(void*) 0x0, cast(ulong) 0x100000);
		ubyte* end = start + 0x100000;
		
		// 1. Look for the ACPI tables (preferred method)
		if(ACPI.Tables.findTable(start, end) != ErrorVal.Success || ACPI.Tables.readTable() != ErrorVal.Success) {
			// 2. Fall back on looking for the MP tables

			// 2a. Locate the MP Tables
			if (MP.findTable(start) == ErrorVal.Fail) {
				// If the MP table is missing, fail.
				kprintfln!("MP.findTable")();
				return ErrorVal.Fail;
			}

			// 2b. Read MP Tabletest
			if (MP.readTable(start) != ErrorVal.Success) {
				kprintfln!("MP.readTable")();
				return ErrorVal.Fail;
			}
		}

		// 3a. Initialize Local APIC
		Log.print("LocalAPIC: initialize()");
		ErrorVal LAPICInitialized = Log.result(LocalAPIC.initialize());
		if (LAPICInitialized != ErrorVal.Success) {
			kprintfln!("LocalAPIC")();
			return ErrorVal.Fail;
		}
		
		// 3b. Initialize IOAPIC
		Log.print("IOAPIC: initialize()");
		ErrorVal IOAPICInitialized = Log.result(IOAPIC.initialize());
		if (IOAPICInitialized != ErrorVal.Success) {
			kprintfln!("IOAPIC")();
			return ErrorVal.Fail;
		}
		
		// Enable Interrupts
		asm {
			sti;
		}
//		enableInterrupts();

		// If it got this far, it has succeeded
		return ErrorVal.Success;
	}

	ulong cpuCount() {
		return Info.numLAPICs;
	}

	ErrorVal bootCores() {
		LocalAPIC.startCores();
		return ErrorVal.Success;
	}

	ErrorVal installCore() {
		// Enable this core's Local APIC
		LocalAPIC.install();

		return ErrorVal.Success;
	}
private:
}
