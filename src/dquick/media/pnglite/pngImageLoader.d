module dquick.media.pnglite.pngImageLoader;

import dquick.media.imageData;
import dquick.media.pnglite.pnglite;
import std.stdio;
import std.string;
import std.conv;

class PngImageLoader : ImageLoader
{
	string name() const
	{
		return "PNG";
	}
	
	bool checkFormat(in string fileName)
	{
		const ubyte[8] sigRef = [ 0x89, 0x50, 0x4E, 0x47, 0xD, 0x0A, 0x1A, 0x0A ];
		ubyte[8] sig;
		
		try
		{
			mFile.open(fileName, "rb");
			mFile.rawRead(sig);
			if(sig != sigRef)
			{
				png_close_file(&mPng);
				return false;
			}
		}
		catch(Exception exc)
		{
			png_close_file(&mPng);
			return false;
		}
		
		return true;
	}
	
	bool load(in string fileName, ref ImageData data)
	{
		scope(exit) mFile.close();
		
		data.format = ImageData.Format.Invalid;
		data.width = data.height = 0;
		data.pixels = null;
		
		mFile.rewind();
		int err = png_open_read(&mPng, &litepngRead, cast(void*)&mFile);
		if(err != PNG_NO_ERROR)
		{
			writeln(fileName, ", png_open: ", to!string(png_error_string(err)));
			return false;
		}
		
		switch(mPng.color_type)
		{
		case PNG_GREYSCALE:
			data.format = ImageData.Format.Gr;
			break;
		case PNG_GREYSCALE_ALPHA:
			data.format = ImageData.Format.GrA;
			break;
		case PNG_TRUECOLOR:
			data.format = ImageData.Format.RGB;
			break;
		case PNG_TRUECOLOR_ALPHA:
			data.format = ImageData.Format.RGBA;
			break;
		default:
			return false;
		}
		
		if(mPng.bpp != data.format)
		{
			writeln(fileName, ", bpp=", mPng.bpp, ", format=", data.format);
			data.format = ImageData.Format.Invalid;
			return false;
		}
		
		data.width = mPng.width;
		data.height = mPng.height;
		data.pixels = new ubyte[data.width*data.height*data.format];		
		
		err = png_get_data(&mPng, data.pixels.ptr);
		if(err != PNG_NO_ERROR)
		{
			writeln(fileName, ", png_get_data: ", to!string(png_error_string(err)));
			data.format = ImageData.Format.Invalid;
			data.width = data.height = 0;
			data.pixels = null;
			return false;
		}
		
		return true;
	}
	
	private
	{
		png_t mPng;
		File mFile;
		
		static this()
		{
			png_init(null, null);
		}
	}
}

private
{
	extern(C) uint litepngRead(void* output, size_t size, size_t numel, void* user_pointer)
	{
		File* file = cast(File*)user_pointer;
		if(!output)
		{
			file.seek(size*numel, SEEK_CUR);
			return cast(uint)(size*numel);
		}
		else
		{		
			ubyte* ptr = cast(ubyte*)output;
			return cast(uint)file.rawRead(ptr[0..size*numel]).length;
		}
	}
}
