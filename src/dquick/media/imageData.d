module dquick.media.imageData;

import dquick.media.devil.devilLoaderWriter;

import std.stdio;

struct ImageData
{
	enum Format
	{
		Invalid,
		Gr,
		GrA,
		RGB,
		RGBA
	}

	Format	format;
	uint	width;
	uint	height;

	@property
	ubyte	nbBytesPerPixel() const {return formats[format];}

	ubyte[]	pixels;

private:
	static enum ubyte[Format] formats = [
		Format.Invalid :	0,
		Format.Gr :			1,
		Format.GrA :		2,
		Format.RGB :		3,
		Format.RGBA:		4];
}

interface ImageLoader
{
	@property string name() const;
	bool load(in string fileName, ref ImageData data);
	
	static
	{
		int opApply(int delegate(ImageLoader) dlg)
		{
			int result;
			for (size_t i = 0; i < msLoaders.length; ++i)
			{
				result = dlg(msLoaders[i]);
				if(result)
					break;
			}
			return result;
		}
		
		void addLoader(ImageLoader loader)
		{
			msLoaders ~= loader;
		}
		
		private ImageLoader[] msLoaders;
	}
}

interface ImageWriter
{
	@property
	string name() const;
	bool handlesFormat(in string formatExtension) const;
	void write(in string filePath, in ImageData data);
	
	static
	{
		void addWriter(ImageWriter writer)
		{
			msWriters ~= writer;
		}
		
		int opApply(int delegate(ImageWriter) dlg)
		{
			int result;
			for(uint i = 0; i < msWriters.length; ++i)
			{
				result = dlg(msWriters[i]);
				if(result)
					break;
			}
			return result;
		}
		
		private ImageWriter[] msWriters;
	}
}
private
{
	shared static this()
	{
		writeln("dquick.media.imageData : shared static this()");
		DevilLoaderWriter devilLoaderWriter = new DevilLoaderWriter();

		ImageLoader.addLoader(devilLoaderWriter);
		ImageWriter.addWriter(devilLoaderWriter);
	}
}
