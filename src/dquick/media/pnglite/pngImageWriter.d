module dquick.media.pnglite.pngImageWriter;

import dquick.media.imageData;
import dquick.media.pnglite.pnglite;
import std.string;
import std.stdio;

class PngImageWriter : ImageWriter
{
	string name() const
	{
		return "PNG";
	}
	
	bool handlesFormat(in string formatExtension) const
	{
		return formatExtension.toLower == ".png";
	}
	
	void write(in string filePath, in ImageData data)
	{
		try
		{
			int formatToCol(ImageData.Format fmt)
			{
				final switch(fmt)
				{
				case ImageData.Format.Invalid:
					return 0;
				case ImageData.Format.Gr:
					return PNG_GREYSCALE;
				case ImageData.Format.GrA:
					return PNG_GREYSCALE_ALPHA;
				case ImageData.Format.RGB:
					return PNG_TRUECOLOR;
				case ImageData.Format.RGBA:
					return PNG_TRUECOLOR_ALPHA;
				}
			}
			
			File file = File(filePath, "wb");
			png_t png;
			png_open_write(&png, &pngliteWrite, cast(void*)&file);
			if(png_set_data(&png, data.width, data.height, 8, formatToCol(data.format), cast(ubyte*)data.pixels.ptr) != PNG_NO_ERROR)
				throw new Exception(filePath ~ ": png_set_data failed!");
		}
		catch(Exception exc)
		{
			writeln(exc.msg);
		}
	}
}

private
{
	extern(C) uint pngliteWrite(void* input, size_t size, size_t numel, void* user_pointer)
	{
		File* file = cast(File*)user_pointer;
		ubyte* ptr = cast(ubyte*)input;
		file.rawWrite(ptr[0..size*numel]);
		return cast(uint)(size*numel);
	}
}
