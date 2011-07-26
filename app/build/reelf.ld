OUTPUT_FORMAT("elf64-x86-64")
ENTRY(_start)
kernel_VMA = 0xffff800000000000;
kernel_LMA = 0x100000;
SECTIONS{
	/* link from LMA */
	. = kernel_LMA;

	_kernelLMA = .;
	. = kernel_VMA;
	_kernelVMA = .;

	_text = .;
	_trampoline = .;
	_etrampoline = .;
	_stack = .;
	_estack = .;
	_kernel = .;
	.text : {
			*(.pretext);
			*(.text)
			*(.rodata)
			. = ALIGN(4096);
	}
	/* _etext defined */
	_etext = .; PROVIDE(etext = .);

	/* data section */
	.data :	
	{
		_data = .;

		data = .;
		*(.data)

		/* constructors and deconstructors
		(if needed, doesn't hurt) */

		start_ctors = .;
		*(.ctor*)
		end_ctors = .;

		start_dtors = .;
		*(.dtor*)
		end_dtors = .;

		. = ALIGN(4096);
	}

	/* _edata defined */
	_edata = .; PROVIDE (edata = .);


	/* static code */
	.bss :
	{
		_bss = .;
		sbss = .;
		*(.bss)
		. = ALIGN(4096);
	}

	_ebss = .;
	ebss = .;

	/*  */
	.ehframe :
	{
		ehframe = .;
		*(.ehframe)
		. = ALIGN(4096);
	}


	/* _end defined (for posterity and tradition) */
	_end = .; PROVIDE (end = .);

	_ekernel = .;
}