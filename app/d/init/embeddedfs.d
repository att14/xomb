module embeddedfs;

import mindrt.util;
import libos.elf.loader;
import libos.fs.minfs;

struct EmbeddedFS{
	static:
	void makeFS(){
		MinFS.format();
		
		// binaries
		xsh = makeFile!("binaries/xsh", true)();
		makeFile!("binaries/hello", true)();
		makeFile!("binaries/simplymm", true)();

		//makeFile!("binaries/chel", true)();
		//makeFile!("binaries/fhel", true)();
		makeFile!("binaries/posix", true)();
		makeFile!("binaries/test", true)();

		// symlinks
		MinFS.link("/binaries/posix", "/binaries/cat");
		MinFS.link("/binaries/posix", "/binaries/cp");
		MinFS.link("/binaries/posix", "/binaries/echo");
		MinFS.link("/binaries/posix", "/binaries/ls");
		MinFS.link("/binaries/posix", "/binaries/ln");
		
		// data
		makeFile!("LICENSE", false)();
	}

	ubyte[] shell(){
		return xsh;
	}

private:
	File xsh;

	template makeFile(char[] filename, bool exe){
		File makeFile(){
			const char[] actualFilename = "/" ~ filename;

			// import file
			ubyte[] data = cast(ubyte[])import(filename);

			// create minFS file
			File f =  MinFS.open(actualFilename, AccessMode.Writable|AccessMode.AllocOnAccess|AccessMode.User|AccessMode.Executable, true);

			// populate
			if(exe){
				Loader.load(data, f);
			}else{
				int spacer = ulong.sizeof;

				memcpy(cast(void*)((f.ptr)[spacer..spacer]).ptr,
							 cast(void*)data.ptr, data.length);

				ulong* size = cast(ulong*)f.ptr;

				*size = data.length;
			}

			return f;
		}
	}
}
