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
