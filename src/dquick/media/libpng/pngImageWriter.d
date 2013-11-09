module dquick.media.libpng.pngImageWriter;

import dquick.media.imageData;
import std.string;
import std.stdio;
import std.c.stdio;
import std.c.string;
import dquick.media.libpng.png;

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
	in
	{
		assert(data.format != ImageData.Format.Invalid);
		assert(data.width > 0 && data.height > 0);
	}
	body
	{
		FILE* file;
		png_struct* png;
		png_info* info;
		
		scope(exit)
		{
			if(png)
				png_destroy_write_struct(&png, info is null ? null : &info);
			if(file)
				fclose(file);
		}
		
		file = fopen(filePath.toStringz, "wb");
		if(!file)
			throw new Exception("Cannot write PNG file to '" ~ filePath ~ "' - cannot open output file!");
		
		const char* libpngVer = png_get_libpng_ver(null);
		debug
		{
			if(strcmp(libpngVer, PNG_LIBPNG_VER_STRING) != 0)
				writeln("[Warning] Compiled with libpng ", PNG_LIBPNG_VER_STRING, ", using ", cstr(png_get_libpng_ver(null)));
		}
		
		png = png_create_write_struct(libpngVer, null, &writer_errorFn, &writer_warningFn);
		if(png is null)
			throw new Exception("Cannot write PNG file to '" ~ filePath ~ "' (png_create_write_struct)");
		info = png_create_info_struct(png);
		if(!info)
			throw new Exception("Cannot write PNG file to '" ~ filePath ~ "' (png_create_info_struct)");
		png_init_io(png, file);
		
		uint pngColorType()
		{
			final switch(data.format)
			{
			case ImageData.Format.Gr:
				return PNG_COLOR_TYPE_GRAY;
			case ImageData.Format.GrA:
				return PNG_COLOR_TYPE_GRAY_ALPHA;
			case ImageData.Format.RGB:
				return PNG_COLOR_TYPE_RGB;
			case ImageData.Format.RGBA:
				return PNG_COLOR_TYPE_RGBA;
			case ImageData.Format.Invalid:
				throw new Exception("Cannot write PNG file to '" ~ filePath ~ "' image's format is not set!");
			}
		}
		
		png_set_IHDR(png, info, data.width, data.height, 8, pngColorType, PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
		
		scope ubyte*[] rows = new ubyte*[data.height];
		for(uint i = 0; i < data.height; ++i)
			rows[i] = cast(ubyte*)data.pixels[i*data.width*data.format..$].ptr;
		
		png_set_rows(png, info, rows.ptr);
		png_write_png(png, info, PNG_TRANSFORM_IDENTITY, null);		
	}
}

private extern(C) void writer_warningFn(png_struct* png, const(char)* msg)
{
	ulong len = strlen(msg);
	writeln(msg[0..len]);
}

private extern(C) void writer_errorFn(png_struct* png, const(char)* msg)
{
	writeln(msg[0..msg.strlen]);
	throw new Exception("libpng error");
}

private string cstr(const char* cs)
{
	return cs[0..cs.strlen].idup;
}
