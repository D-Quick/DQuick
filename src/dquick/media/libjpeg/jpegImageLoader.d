module dquick.media.libjpeg.jpegImageLoader;

import dquick.media.imageLoader;
import dquick.media.libjpeg.jpeglib;
import std.string;
import std.path;
import std.c.stdio;

class JpegImageLoader : ImageLoader
{
	string name() const
	{
		return "JEPG";
	}
	
	bool checkFormat(in string fileName)
	{
		try
		{
			mInfo.err = jpeg_std_error(&mErr);
			mErr.error_exit = &jpegError;
			jpeg_create_decompress(&mInfo);
			
			mFile = fopen(fileName.toStringz, "rb");
			if(mFile is null)
				return false;
			
			jpeg_stdio_src(&mInfo, mFile);
			jpeg_read_header(&mInfo, true);
		}
		catch(Exception exc)
		{
			jpeg_finish_decompress(&mInfo);
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
		}
		catch(Exception exc)
		{
			data.format = ImageData.Format.Invalid;
			data.width = data.height = 0;
			data.pixels = null;
			
			jpeg_finish_decompress(&mInfo);
			fclose(mFile);
			mFile = null;
			return false;
		}
		
		return true;
	}
	
	private
	{
		FILE* mFile;
		jpeg_decompress_struct mInfo;
		jpeg_error_mgr mErr;
	}
}

private
{
	extern(C)
	{
		void jpegError(j_common_ptr info)
		{
			throw new Exception("libjpeg error");
		}
	}
}
