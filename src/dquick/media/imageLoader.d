module dquick.media.imageLoader;

public import dquick.media.imageData;

interface ImageLoader
{
	@property
	string name() const;
	bool checkFormat(in string fileName);
	bool load(in string fileName, ref ImageData data);
	
	static
	{
		int opApply(int delegate(ImageLoader) dlg)
		{
			int result;
			for(ulong i = 0; i < msLoaders.length; ++i)
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

private shared static this()
{
	import std.stdio;
	import dquick.media.libpng.pngImageLoader;
	import dquick.media.libjpeg.jpegImageLoader;
	try
	{
		ImageLoader.addLoader(new PngImageLoader());
		ImageLoader.addLoader(new JpegImageLoader());
	} catch(Exception exc){ writeln(exc.msg); }
}
