module dquick.media.devil.devilLoader;

import dquick.media.imageData;
import derelict.devil.il;
import std.string;

class DevILImageLoader : ImageLoader
{	
	this()
	{
		DerelictIL.load();
		ilInit();
	}
	
	~this()
	{
		DerelictIL.unload();
	}
	
	@property string name() const{ return "DevIL"; }

	bool load(in string fileName, ref ImageData data)
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
