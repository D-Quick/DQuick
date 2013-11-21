module dquick.media.imageData;

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
		
	Format format;
	uint width, height;
	ubyte[] pixels;
	
	static Format formatFromChannels(uint numChannels)
	{
		static const Format[] formats =
		[
			Format.Invalid,
			Format.Gr,
			Format.GrA,
			Format.RGB,
			Format.RGBA
		];
		
		if(numChannels >= formats.length)
			return Format.Invalid;
		return formats[numChannels];
	}
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
		import std.stdio;
		
		import dquick.media.devil.devilLoaderWriter;

		DevilLoaderWriter devilLoaderWriter = new DevilLoaderWriter();

		//		devilLoaderWriter = new DevilLoaderWriter();
		ImageLoader.addLoader(devilLoaderWriter);
		ImageWriter.addWriter(devilLoaderWriter);
	}
}
