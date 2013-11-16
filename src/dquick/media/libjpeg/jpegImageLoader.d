module dquick.media.libjpeg.jpegImageLoader;

import dquick.media.imageData;
import dquick.media.libjpeg.jpeglib;
import std.string;
import std.path;
import std.stdio;
import std.c.stdio;

version(Posix)
	import core.sys.posix.setjmp;
else version(Windows)
	import dquick.system.win32.setjmp;
else
	static assert("This platform doesn't have setjmp/longjmp support in D!");

class JpegImageLoader : ImageLoader
{
	this()
	{
		mErr.mgr.error_exit = &jpegError;
	}
	
	string name() const
	{
		return "JEPG";
	}
	
	bool checkFormat(in string fileName)
	{
		if(setjmp(mErr.env) == 0)
		{
			mInfo.err = cast(jpeg_error_mgr*)&mErr;
			jpeg_create_decompress(&mInfo);
			
			mFile = fopen(fileName.toStringz, "rb");
			if(mFile is null)
				return false;
			
			jpeg_stdio_src(&mInfo, mFile);
			jpeg_read_header(&mInfo, true);
		}
		else
		{
			jpeg_destroy_decompress(&mInfo);
			if(mFile)
				fclose(mFile);
			mFile = null;
			return false;
		}
		
		return true;
	}
	
	bool load(in string fileName, ref ImageData data)
	{
		try
		{
			if(setjmp(mErr.env) == 0)
			{	
				jpeg_start_decompress(&mInfo);
				
				data.format = ImageData.formatFromChannels(mInfo.output_components);
				data.width = mInfo.output_width;
				data.height = mInfo.output_height;
				data.pixels = new ubyte[data.width*data.height*data.format];
				
				scope ubyte*[] rows = new ubyte*[data.height];
				for(uint i = 0; i < data.height; ++i)
					rows[i] = data.pixels[i*data.width*data.format..$].ptr;
				jpeg_read_scanlines(&mInfo, rows.ptr, data.height);
				
				jpeg_finish_decompress(&mInfo);
				jpeg_destroy_decompress(&mInfo);
			}
			else
				throw mErr.exception;
		}
		catch(Exception exc)
		{
			data.format = ImageData.Format.Invalid;
			data.width = data.height = 0;
			data.pixels = null;
			
			jpeg_destroy_decompress(&mInfo);
			fclose(mFile);
			mFile = null;
			return false;
		}
		
		return true;
	}
	
	private
	{
		ErrorHandler mErr;
		FILE* mFile;
		jpeg_decompress_struct mInfo;
	}
}

private
{	
	struct ErrorHandler
	{
		jpeg_error_mgr mgr;
		jmp_buf env;
		Exception exception;
	}
	
	extern(C)
	{
		void jpegError(j_common_ptr info)
		{
			ErrorHandler* eh = cast(ErrorHandler*)info.err;
			writeln("libjpeg error");
			longjmp(eh.env, 1);
		}
	}
}
