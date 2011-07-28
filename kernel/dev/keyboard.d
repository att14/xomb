module kernel.dev.keyboard;

// Import the architecture specific keyboard driver
import architecture.keyboard;
import architecture.vm;
import user.environment;

import kernel.core.error;

import kernel.config;

import user.keycodes;

import kernel.dev.console;

class Keyboard {
	static:

	ErrorVal initialize() {
		address = VirtualMemory.findFreeSegment();
		_buffer = cast(short[])VirtualMemory.createSegment(address, 2*1024*1024, AccessMode.DefaultKernel);

		_writeOffset = cast(ushort*)_buffer.ptr;
		*_writeOffset = 0;
		_readOffset = &((cast(ushort*)_buffer)[1]);
		*_readOffset = 0;
		
		((cast(ushort*)_buffer)[2]) = cast(ushort)(3 * VirtualMemory.pagesize());
		_maxOffset = ((3 * VirtualMemory.pagesize()) / 2) - 3;

		_buffer = _buffer[3..	_maxOffset];
		ErrorVal ret = KeyboardImplementation.initialize(&putKey, true);
		return ret;
	}
	
	ErrorVal reinitialize(short* buffer) {
		// Instead of creating new buffer, use old values
		_writeOffset = cast(ushort*) buffer - 3;
		_readOffset = cast(ushort*) buffer - 2;
		_maxOffset = (*(cast(ushort*) buffer - 1) / 2) - 3;
		
		_buffer = buffer[0.. _maxOffset];
		
		// Trying to clear buffer
		//*_writeOffset = *_readOffset;
		
		ErrorVal ret = KeyboardImplementation.initialize(&putKey, false);
		return ret;
	}
	
	short* getKeyboardBuffer() {
		return _buffer.ptr;
	}
	
	ubyte* address;
private:

	void putKey(Key nextKey, bool released) {
		if (released) {
			nextKey = -nextKey;
		}

		if ((((*_writeOffset)+1) == *_readOffset) || ((*_writeOffset + 1) >= _maxOffset && (*_readOffset == 0))) {
			// lose this key
			return;
		}

		// put in the buffer at the write pointer position
		_buffer[*_writeOffset] = cast(short)nextKey;
		if ((*_writeOffset + 1) >= _maxOffset) {
			*_writeOffset = 0;
		}
		else {
			*_writeOffset = (*_writeOffset) + 1;
		}
	}

	short[] _buffer;
	ushort* _writeOffset;
	ushort* _readOffset;
	ushort _maxOffset;
}
