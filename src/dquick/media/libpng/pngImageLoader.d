module dquick.media.libpng.pngImageLoader;

import dquick.media.imageData;
import dquick.media.libpng.png;
import std.stdio;
import std.string;
import std.c.string;
import std.c.stdio;

version(Posix)
{
	import core.sys.posix.setjmp;
}
else
{
	static assert("This platform doesn't have setjmp/longjmp support in D!");
}

class PngImageLoader : ImageLoader
{
	string name() const
	{
		return "PNG";
	}
	
	bool checkFormat(in string fileName)
	{
		if(m_file)
			fclose(m_file);
		
		m_file = fopen(fileName.toStringz, "rb");
		if(!m_file)
			return false;
		
		ubyte[SigLength] sig;
		fread(sig.ptr, sig.length, 1, m_file);
		
		return !png_sig_cmp(sig.ptr, 0, sig.length);
	}
	
	bool load(in string fileName, ref ImageData data)
	{
		png_struct* png;
		png_info* info;
		
		scope(exit)
		{
			if(png !is null) png_destroy_read_struct(&png, (info is null) ? null : &info, null);
			fclose(m_file);
			m_file = null;
		}
		
		try
		{
			const char* libpngVer = png_get_libpng_ver(null);
			debug
			{
				if(strcmp(libpngVer, PNG_LIBPNG_VER_STRING) != 0)
					writeln("[Warning] Compiled with libpng ", PNG_LIBPNG_VER_STRING, ", using ", cstr(png_get_libpng_ver(null)));
			}
			png = png_create_read_struct(libpngVer, null, null, null);
			if(!png) return false;
			info = png_create_info_struct(png);
			if(!info) return false;
			
			ErrorInfo ei;
			if(setjmp(ei.env) == 0)
			{
				png_set_error_fn(png, cast(void*)&ei, &errorFn, &warningFn);
				
				png_init_io(png, m_file);
				png_set_sig_bytes(png, SigLength);
				
				uint xf = PNG_TRANSFORM_STRIP_16 | PNG_TRANSFORM_PACKING | PNG_TRANSFORM_PACKSWAP;
				png_read_png(png, info, xf, null);
				
				data.width = png_get_image_width(png, info);
				data.height = png_get_image_height(png, info);
				uint numChannels = png_get_channels(png, info);
				data.format = ImageData.formatFromChannels(numChannels);
				
				data.pixels = new ubyte[data.width*data.height*numChannels];
				png_byte** rows = png_get_rows(png, info);
				uint stride = data.width*numChannels;
				for(uint y = 0; y < data.height; ++y)
					memcpy(data.pixels[y*stride..(y+1)*stride].ptr, rows[y], stride);
			}
			else
				throw ei.exception;
		}
		catch(Exception exc)
		{
			return false;
		}
		
		return true;
	}
	
	private enum SigLength = 8;
	private FILE* m_file;
}

private struct ErrorInfo
{
	jmp_buf env;
	Exception exception;
}

private extern(C) void warningFn(png_struct* png, const(char)* msg)
{
	ulong len = strlen(msg);
	writeln(msg[0..len]);
}

private extern(C) void errorFn(png_struct* png, const(char)* msg)
{
	writeln("libpng error: ", msg[0..msg.strlen]);
	ErrorInfo* ei = cast(ErrorInfo*)png_get_error_ptr(png);
	ei.exception = new Exception("libpng error");
	longjmp(ei.env, 1);
}

private string cstr(const char* cs)
{
	return cs[0..cs.strlen].idup;
}
