//This is in charge of the HPET timer device
module kernel.arch.x86_64.hpet;

import kernel.core.error;
import kernel.core.util;
import kernel.arch.x86_64.vmem;
import kernel.core.regions;
import kernel.dev.vga;
import kernel.arch.x86_64.ioapic;
import kernel.arch.x86_64.lapic;
import kernel.arch.x86_64.mp;

// Make mpInformation 


template Tmaker(uint ID)
{
	const char[] Tmaker = ", \"T" ~ ID.stringof[0..$-1] ~ "_INT_STS\", 1";
}

//Maps to the memory that holds the configuration data for HPET
align(1) struct hpetConfig {
	ulong capabilitiesAndID;
	ulong reserved1;
	ulong configuration;
	ulong reserved2;
	ulong interruptStatus;
	ulong reserved3;
	ulong mainCounterValue;
	ulong reserved4;

	mixin(Bitfield!(capabilitiesAndID, "REV_ID", 8, "NUM_TIM_CAP", 5, "COUNT_SIZE_CAP", 1, "ReservedCap", 1, "LEG_RT_CAP", 1, "VENDOR_ID", 16,
	"COUNTER_CLOCK_PERIOD", 32));
	mixin(Bitfield!(configuration, "ENABLE_CNF", 1, "LEG_RT_CNF", 1, "Reserved1", 6, "ReservedNonOS", 8, "Reserved2", 48));
	mixin("mixin(Bitfield!(interruptStatus" ~ Reduce!(Cat, Map!(Tmaker, Range!(32))) ~ ", \"ReservedStatus\", 32));");
}

//Maps to the individual timers
align(1) struct timerInfo {
	ulong configurationAndCap;
	ulong comparatorValue;
	ulong FSBInterrruptRoute;
	ulong reserved;
	
	mixin(Bitfield!(configurationAndCap, "Reserved1", 1, "INT_TYPE_CNF", 1, "INT_ENB_CNF", 1, "TYPE_CNF", 1, "PER_INT_CAP", 1, "SIZE_CAP", 1, "VAL_SET_CNF", 1, "Reserved2", 1, "MODE_CNF", 1, "INT_ROUTE_CNF", 5, "FSB_EN_CNF", 1, "FSB_INT_DEL_CAP", 1, "Reserved3", 16, "INT_ROUTE_CAP", 32));
}

//Brings everything together for HPET
struct hpetDev {
	hpetConfig* config;
	timerInfo[] timers;
	ubyte* physHPETAddress = cast(ubyte*)0xFED00000;
}

private hpetDev hpetDevice;

struct HPET
{
	static:

	//initialize out HPET timer
	ErrorVal init()
	{
		// get the virtual address of the HPET within the BIOS device map region
		ubyte* virtHPETAddy = global_mem_regions.device_maps.virtual_start + (hpetDevice.physHPETAddress - global_mem_regions.device_maps.physical_start);
		if(virtHPETAddy > (global_mem_regions.device_maps.virtual_start + global_mem_regions.device_maps.length))
		{
			// map in the region then
			if (vMem.mapRange(hpetDevice.physHPETAddress, hpetConfig.sizeof + (32 * timerInfo.sizeof), virtHPETAddy)
					!= ErrorVal.Success)
			{
				return ErrorVal.Fail;
			}
		}
	
		// resolve the address to the configuration table
		hpetDevice.config = cast(hpetConfig*)virtHPETAddy;

		ulong configVal = hpetDevice.config.configuration;
		
		//kprintfln!("NUM_TIM_CAP = {}")(hpetDevice.config.NUM_TIM_CAP);

		// initialize the configuration to allow standard IOAPIC interrupts
		//hpetDevice.config.LEG_RT_CNF = 0;
		//hpetDevice.config.ENABLE_CNF = 0;
		configVal &= ~(0x3);

		hpetDevice.config.mainCounterValue = 0;

		// resolve the array of timers
		hpetDevice.timers = (cast(timerInfo*)virtHPETAddy+hpetConfig.sizeof)[0..hpetDevice.config.NUM_TIM_CAP];
	
		//printStruct(hpetDevice);

		initTimer(0, 1000000);

		kprintfln!("timer counter: {}")(hpetDevice.config.mainCounterValue);

		//hpetDevice.config.ENABLE_CNF = 1;
		//hpetDevice.config |= 1;
		configVal |= 1;
		hpetDevice.config.configuration = configVal;
	
		for(;;)
		{
			kprintfln!("timer counter: {}")(hpetDevice.config.mainCounterValue);
		}
	
		return ErrorVal.Success;
	}
	
	// the function to start and equip a non-periodic timer
	void initTimer(uint index, ulong nanoSecondInterval)
	{
		// update to femptoseconds
		nanoSecondInterval *= 1000000;

		ulong timerVal;

		// write 0 to reservei
		//hpetDevice.timers[index].Reserved1 = 0;
		//hpetDevice.timers[index].Reserved2 = 0;
		//hpetDevice.timers[index].Reserved3 = 0;

		// we want a 64-bit timer

		//kprintfln!("POSSIBLE: {x}")(hpetDevice.timers[index].INT_ROUTE_CAP);

		if (hpetDevice.timers[index].SIZE_CAP == 0)
		{
			kprintfln!("Computer does not support 64 bit HPET.")();
		}
		//hpetDevice.timers[index].MODE_CNF = 0;
		//hpetDevice.timers[index].FSB_EN_CNF = 0;

		// we want a non-periodic timer (one-shot!)
		//hpetDevice.timers[index].TYPE_CNF = 0;
		
		// we want edge-triggered interrupts
		// do we?  Brian says no, and set it to level
		//hpetDevice.timers[index].INT_TYPE_CNF = 1;
		timerVal |= (1 << 1);
		
		// we want to route to interrupt 'index + 1'
		//hpetDevice.timers[index].INT_ROUTE_CNF = 1; //index + 1
		timerVal |= (1 << 9);
	
		// TODO: change this to a debug
		//kprintfln!("counter updates by = {} for {}ns")(nanoSecondInterval / hpetDevice.config.COUNTER_CLOCK_PERIOD, nanoSecondInterval / 1000000);

		// tell IOAPIC of our plans
		// So the idea here is that we're going to put 'er in
		// to physical mode here and send the apic ID of the first
		// local apic.  Just to test...  we should probably fix this later.
		//kprintfln!("HPET LocalAPICID Destination Field: {}")(MP.mpInformation.processors[0].localAPICID);
		
		IOAPIC.setRedirectionTableEntry(1, LocalAPIC.getLocalAPICId(),
						IOAPICInterruptType.Unmasked, IOAPICTriggerMode.LevelTriggered, 
						IOAPICInputPinPolarity.HighActive, IOAPICDestinationMode.Physical,
						IOAPICDeliveryMode.Fixed, 35 );

		//IOAPIC.printTableEntry(1);

		// enable timer interrupts
		timerVal |= (1 << 2);
	
		// get the main counter
		ulong curcounter = hpetDevice.config.mainCounterValue;

		// update to the new value
		// overflow of main counter will not matter
		ulong factor = (nanoSecondInterval / hpetDevice.config.COUNTER_CLOCK_PERIOD);
		kprintfln!("factor: {}")(factor);
		curcounter += factor;

		hpetDevice.timers[index].comparatorValue = hpetDevice.config.mainCounterValue + factor;

		// we now want to enable the timer
		hpetDevice.timers[index].configurationAndCap = timerVal;
	}

	// the function to reset a timer that has been initialized when it has already fired
	void resetTimer(uint index, ulong nanoSecondInterval)
	{
		// update to femptoseconds
		nanoSecondInterval *= 1000000;

		// halt timer
		hpetDevice.timers[index].INT_ENB_CNF = 0;
		
		// get the main counter
		ulong curcounter = hpetDevice.config.mainCounterValue;

		// update to the new value
		// overflow of main counter will not matter
		curcounter += (nanoSecondInterval / hpetDevice.config.COUNTER_CLOCK_PERIOD);

		// we now want to enable the timer interrupt
		hpetDevice.timers[index].INT_ENB_CNF = 1;
	}

}
