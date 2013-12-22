module dquick.media.devil.devilLoaderWriter;

import dquick.media.imageData;
import derelict.devil.il;

import std.stdio;
import std.string;

class DevilLoaderWriter : ImageLoader, ImageWriter
{	
	@property string name() const{ return "DevIL"; }

	bool load(in string fileName, ref ImageData data) const
	{
		ILuint img;
		ilGenImages(1, &img);
		ilBindImage(img);
		scope(exit) ilDeleteImages(1, &img);
		
		if (!ilLoadImage(fileName.toStringz))
			return false;

		data.width = ilGetInteger(IL_IMAGE_WIDTH);
		data.height = ilGetInteger(IL_IMAGE_HEIGHT); 
		uint fmt = ilGetInteger(IL_IMAGE_FORMAT).swapILFormat;
		data.format = formatFromIL(fmt);
		data.pixels = new ubyte[data.width * data.height * data.format];
		ilCopyPixels(0, 0, 0, data.width, data.height, 1, fmt, IL_UNSIGNED_BYTE, data.pixels.ptr);

		return true;
	}

	bool handlesFormat(in string formatExtension) const
	{
		return true;
	}

	void write(in string filePath, in ImageData data) const
	{
		ILuint img;

		ilGenImages(1, &img);
		ilBindImage(img);
		scope(exit) ilDeleteImages(1, &img);

		final switch (data.format)
		{
			case ImageData.Format.Invalid:
				throw new Exception("Image's format is invalid");
			case ImageData.Format.Gr:
				throw new Exception("Image's format isn't supported for saving file.");
			case ImageData.Format.GrA:
				throw new Exception("Image's format isn't supported for saving file.");
			case ImageData.Format.RGB:
				ilTexImage(data.width, data.height, 1, data.nbBytesPerPixel(), IL_RGB, IL_UNSIGNED_BYTE, cast(void*)data.pixels.ptr);
			   break;
			case ImageData.Format.RGBA:
				ilTexImage(data.width, data.height, 1, data.nbBytesPerPixel(), IL_RGBA, IL_UNSIGNED_BYTE, cast(void*)data.pixels.ptr);
				break;
		}

		if (!ilSaveImage(filePath.toStringz))
			throw new Exception(format("Failed to save image with Devil at : %s", filePath));
	}
}

private
{
	uint swapILFormat(uint fmt)
	{
		if(fmt == IL_BGR)
			return IL_RGB;
		else if(fmt == IL_BGRA)
			return IL_RGBA;
		return fmt;
	}
	
	ImageData.Format formatFromIL(uint fmt)
	{
		switch(fmt)
		{
		case IL_LUMINANCE:
			return ImageData.Format.Gr;
		case IL_LUMINANCE_ALPHA:
			return ImageData.Format.GrA;
		case IL_RGB:
			return ImageData.Format.RGB;
		case IL_RGBA:
			return ImageData.Format.RGBA;
		default:
			return ImageData.Format.Invalid;
		}
	}
}

static this()
{
	writeln("dquick.media.devil.devilLoaderWriter : static this()");
	DerelictIL.load();
	ilInit();
	ilEnable(IL_FILE_OVERWRITE);
}

static ~this()
{
	writeln("dquick.media.devil.devilLoaderWriter : static this()");
	DerelictIL.unload();
}
