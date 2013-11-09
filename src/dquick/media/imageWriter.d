module dquick.media.imageWriter;

public import dquick.media.imageData;

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

private shared static this()
{
	import std.stdio;
	
	try
	{
		// add writers
	} catch(Exception exc){ writeln(exc.msg); }
}
