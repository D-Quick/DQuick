module dquick.media.image;

import std.string;
import std.stdio;
import std.conv;
import std.path;
import std.c.string;

import dquick.media.imageData;
import dquick.maths.color;
import dquick.maths.vector2s32;
import dquick.utils.resourceManager;

ResourceManager	resourceManager;

// TODO check potential issue with unload and the resources management (it's certainly possible to get a corrupted image)

static this()
{
	writeln("dquick.media.image : shared static this()");
	resourceManager = new ResourceManager();
	resourceManager.maximumWeight(10 * 1024 * 1024 * 4);	// 10 RGBA images of 1024x1024
	// Images are transformed to textures, only fonts will stay in RAM
}

static ~this()
{
	writeln("dquick.media.image : shared static ~this()");
	resourceManager.destroy();
	resourceManager = null;
}

class Image : IResource
{
	mixin ResourceBase;

public:
	alias ImageData.Format	Format;

	~this()
	{
		assert(mData.pixels == null, "unload method wasn't called.");
	}

	void	load(string filePath, Variant[] options = null)
	{
		assert(options == null);
		unload();
		mFilePath = filePath;
		
		foreach (loader; ImageLoader)
		{
			if (loader.load(filePath, mData))
				return;
		}
		
		throw new Exception("Unable to load an image from '" ~ filePath ~ "': file does not exist, or format is unsupported!");
	}

	void	save(string filePath)
	{
		string ext = filePath.extension;
		foreach(writer; ImageWriter)
		{
			if (writer.handlesFormat(ext))
			{
				writer.write(filePath, mData);
				return;
			}
		}
		
		throw new Exception("There is no plugin that handle image format of '" ~ filePath ~ "'!");
	}

	void	create(string filePath, uint width, uint height, ImageData.Format format)
	{
		unload();
		
		mFilePath = filePath;
		mData.format = format;
		mData.width = width;
		mData.height = height;
		mData.pixels = new ubyte[width * height * mData.nbBytesPerPixel];
	}

	void	fill(Color color, Vector2s32 position, Vector2s32 size)
	{		
		scope ubyte[]	pixel = new ubyte[mData.format];

		final switch(mData.format)
		{
		case ImageData.Format.Invalid:
			return;
		case ImageData.Format.Gr:
			pixel[0] = cast(ubyte)(color.toGrey * 255.0f);
			break;
		case ImageData.Format.GrA:
			pixel[0] = cast(ubyte)(color.toGrey * 255.0f);
			pixel[1] = cast(ubyte)(color.w * 255.0f);
			break;
		case ImageData.Format.RGB:
			pixel[0] = cast(ubyte)(color.x * 255.0f);
			pixel[1] = cast(ubyte)(color.y * 255.0f);
			pixel[2] = cast(ubyte)(color.z * 255.0f);
			break;
		case ImageData.Format.RGBA:
			pixel[0] = cast(ubyte)(color.x * 255.0f);
			pixel[1] = cast(ubyte)(color.y * 255.0f);
			pixel[2] = cast(ubyte)(color.z * 255.0f);
			pixel[3] = cast(ubyte)(color.w * 255.0f);
			break;
		}
		
		uint minX = max!int(position.x, 0);
		uint maxX = min!int(position.x + size.x, mData.width);
		uint minY = max!int(position.y, 0);
		uint maxY = min!int(position.y + size.y, mData.height);

		for (uint y = minY; y < maxY; ++y)
			for (uint x = minX; x < maxX; ++x)
				memcpy(mData.pixels[((mData.height - y - 1) * mData.width + x) * mData.format..$].ptr, pixel.ptr, pixel.length);
	}

	void	blend(Image sourceImage, Vector2s32 sourcePosition, Vector2s32 sourceSize, Vector2s32 destPosition)
	in
	{
		assert(mData.format != ImageData.Format.Invalid);
		assert(sourcePosition.x >= 0 && sourcePosition.y >= 0);
		assert(sourcePosition.x < sourceImage.mData.width && sourcePosition.y < sourceImage.mData.height);
		assert(sourceSize.x >= 0 && sourceSize.y >= 0);
		assert(destPosition.x >= 0 && destPosition.y >= 0);
		assert(destPosition.x < mData.width && destPosition.y < mData.height);
	}
	body
	{
		void function(ref ubyte[] dst, in ubyte[] src) blendFn = pixelBlendFn[mData.format][sourceImage.mData.format];
		
		ImageData.Format srcFmt = sourceImage.mData.format;
		
		uint maxX = min!int(sourceSize.x, mData.width - destPosition.x);
		uint maxY = min!int(sourceSize.y, mData.height - destPosition.y);
		
		for (uint x = 0; x < maxX; ++x)
		{
			for (uint y = 0; y < maxY; ++y)
			{
				uint ix = x + destPosition.x;
				uint iy = y + destPosition.y;
				uint si = ((mData.height - iy - 1) * mData.width + ix) * mData.format;
				ubyte[] dstPixel = mData.pixels[si..si + mData.format];
				
				ix = x + sourcePosition.x;
				iy = y + sourcePosition.y;
				si = (iy * sourceImage.mData.width + ix) * srcFmt;
				blendFn(dstPixel, sourceImage.mData.pixels[si..si + srcFmt]);
			}
		}
	}
	
	void	blit(Image sourceImage, Vector2s32 sourcePosition, Vector2s32 sourceSize, Vector2s32 destPosition)
	in
	{
		assert(mData.format != ImageData.Format.Invalid);
		assert(sourcePosition.x >= 0 && sourcePosition.y >= 0);
		assert(sourcePosition.x < sourceImage.mData.width && sourcePosition.y < sourceImage.mData.height);
		assert(sourceSize.x >= 0 && sourceSize.y >= 0);
		assert(destPosition.x >= 0 && destPosition.y >= 0);
		assert(destPosition.x < mData.width && destPosition.y < mData.height);
	}
	body
	{
		ImageData.Format srcFmt = sourceImage.mData.format;

		ubyte* dstPixels = mData.pixels.ptr;
		const ubyte* srcPixels = sourceImage.mData.pixels.ptr;
		
		uint width = min!uint(sourceSize.x, destPosition.x + mData.width);
		uint height = min!uint(sourceSize.y, destPosition.y + mData.height);
		
		uint dstWidth = mData.width;
		uint dstHeight = mData.height;
		uint srcWidth = sourceImage.mData.width;
		uint srcHeight = sourceImage.mData.height;
		
		uint minDstX = destPosition.x;
		uint minDstY = destPosition.y;
		
		uint minSrcX = sourcePosition.x;
		uint minSrcY = sourcePosition.y;
		
		if (mData.format == ImageData.Format.Gr)
		{
			if (sourceImage.mData.format == ImageData.Format.Gr)
			{ mixin(blitPixels!(1, 1)); }
			else if (sourceImage.mData.format == ImageData.Format.GrA)
			{ mixin(blitPixels!(1, 2)); }
			else if (sourceImage.mData.format == ImageData.Format.RGB)
			{ mixin(blitPixels!(1, 3)); }
			else if (sourceImage.mData.format == ImageData.Format.RGBA)
			{ mixin(blitPixels!(1, 4)); }
		}
		else if (mData.format == ImageData.Format.GrA)
		{
			if (sourceImage.mData.format == ImageData.Format.Gr)
			{ mixin(blitPixels!(2, 1)); }
			else if (sourceImage.mData.format == ImageData.Format.GrA)
			{ mixin(blitPixels!(2, 2)); }
			else if (sourceImage.mData.format == ImageData.Format.RGB)
			{ mixin(blitPixels!(2, 3)); }
			else if (sourceImage.mData.format == ImageData.Format.RGBA)
			{ mixin(blitPixels!(2, 4)); }
		}
		else if (mData.format == ImageData.Format.RGB)
		{
			if (sourceImage.mData.format == ImageData.Format.Gr)
			{ mixin(blitPixels!(3, 1)); }
			else if (sourceImage.mData.format == ImageData.Format.GrA)
			{ mixin(blitPixels!(3, 2)); }
			else if (sourceImage.mData.format == ImageData.Format.RGB)
			{ mixin(blitPixels!(3, 3)); }
			else if (sourceImage.mData.format == ImageData.Format.RGBA)
			{ mixin(blitPixels!(3, 4)); }
		}
		else if (mData.format == ImageData.Format.RGBA)
		{
			if (sourceImage.mData.format == ImageData.Format.Gr)
			{ mixin(blitPixels!(4, 1)); }
			else if (sourceImage.mData.format == ImageData.Format.GrA)
			{ mixin(blitPixels!(4, 2)); }
			else if (sourceImage.mData.format == ImageData.Format.RGB)
			{ mixin(blitPixels!(4, 3)); }
			else if (sourceImage.mData.format == ImageData.Format.RGBA)
			{ mixin(blitPixels!(4, 4)); }
		}
	}

	void	unload()
	{
		mData.format = ImageData.Format.Invalid;
		mData.width = mData.height = 0;
		mData.pixels = null;
	}

	uint	width() const
	{
		return mData.width;
	}

	uint	height() const
	{
		return mData.height;
	}

	Vector2s32	size() const
	{
		return Vector2s32(width, height);
	}

	ubyte*	pixels()
	{
		return mData.pixels.ptr;
	}

	const(ubyte*)	pixels() const
	{
		return mData.pixels.ptr;
	}

	Format	format() const
	{
		return mData.format;
	}

	ubyte	nbBytesPerPixel() const
	{
		return mData.nbBytesPerPixel;
	}

protected:
	ImageData mData;
}


private
{
	auto min(T)(T a, T b){ return a < b ? a : b; }
	auto max(T)(T a, T b){ return a > b ? a : b; }
	
	template blitPixel(uint nd, uint ns)
	{
		static if (nd == 1)
		{
			static if (ns == 1)
				enum blitPixel = "dst[0] = src[0];";
			else static if (ns == 2)	   
				enum blitPixel = "dst[0] = src[0];";
			else static if (ns == 3)	   
				enum blitPixel = "dst[0] = cast(ubyte)(src[0] * 0.21f + src[1] * 0.71f + src[2] * 0.07f);";
			else static if (ns == 4)	   
				enum blitPixel = "dst[0] = cast(ubyte)(src[0] * 0.21f + src[1] * 0.71f + src[2] * 0.07f);";
		}
		else static if (nd == 2)
		{
			static if (ns == 1)
				enum blitPixel = "dst[0] = src[0]; dst[1] = 255;";
			else static if (ns == 2)	   				    
				enum blitPixel = "dst[0] = src[0]; dst[1] = src[1];";
			else static if (ns == 3)	   
				enum blitPixel = "dst[0] = cast(ubyte)(src[0] * 0.21f + src[1] * 0.71f + src[2] * 0.07f); dst[1] = 255;";
			else static if (ns == 4)	   
				enum blitPixel = "dst[0] = cast(ubyte)(src[0] * 0.21f + src[1] * 0.71f + src[2] * 0.07f); dst[1] = dst[3];";
		}
		else static if (nd == 3)
		{
			static if (ns == 1)
				enum blitPixel = "dst[0] = src[0]; dst[1] = src[0]; dst[2] = src[0];";
			else static if (ns == 2)	   				    			   	 
				enum blitPixel = "dst[0] = src[0]; dst[1] = src[0]; dst[2] = src[0];";
			else static if (ns == 3)	   				    			   	 
				enum blitPixel = "dst[0] = src[0]; dst[1] = src[1]; dst[2] = src[2];";
			else static if (ns == 4)	   				    			   	 
				enum blitPixel = "dst[0] = src[0]; dst[1] = src[1]; dst[2] = src[2];";
		}
		else static if (nd == 4)
		{
			static if (ns == 1)
				enum blitPixel = "dst[0] = src[0]; dst[1] = src[0]; dst[2] = src[0]; dst[3] = 255;";
			else static if (ns == 2)	   				    			   	 			      
				enum blitPixel = "dst[0] = src[0]; dst[1] = src[0]; dst[2] = src[0]; dst[3] = src[1];";
			else static if (ns == 3)	   				    			   	 			      
				enum blitPixel = "dst[0] = src[0]; dst[1] = src[1]; dst[2] = src[2]; dst[3] = 255;";
			else static if (ns == 4)	   				    			   	 			      
				enum blitPixel = "dst[0] = src[0]; dst[1] = src[1]; dst[2] = src[2]; dst[3] = src[3];";
		}
	}
	
	template nStr(uint n)
	{
		enum nStr = ["0", "1", "2", "3", "4"][n];
	}
	
	template blitPixels(uint nd, uint ns)
	{
		enum blitPixels = r"
			for (uint y = 0; y < height; ++y)
			{
				for (uint x = 0; x < width; ++x)
				{
					ubyte*			dst = &dstPixels[((mData.height - (y + minDstY) - 1) * dstWidth + (x + minDstX)) * " ~ nStr!nd ~ r"];
					const ubyte*	src = &srcPixels[((y + minSrcY) * srcWidth + (x + minSrcX)) * " ~ nStr!ns ~ r"];
					" ~ blitPixel!(nd, ns) ~ r"
				}
			}";
	}

	immutable void function(ref ubyte[], in ubyte[])[ImageData.Format.max + 1][ImageData.Format.max + 1] pixelBlendFn =
	[
		// dst.length == 0
		[
			function void(ref ubyte[], in ubyte[]){},
			function void(ref ubyte[], in ubyte[]){},
			function void(ref ubyte[], in ubyte[]){},
			function void(ref ubyte[], in ubyte[]){},
			function void(ref ubyte[], in ubyte[]){}
		],
		
		// dst.length == 1
		[
			// src.length == 0
			function void(ref ubyte[] dst, in ubyte[] src){
				dst[0] = 0;
			},
			// src.length == 1
			function void(ref ubyte[] dst, in ubyte[] src){
				blender!(1, false, false, ubyte).go(dst.ptr, src[0]);
			},
			// src.length == 2
			function void(ref ubyte[] dst, in ubyte[] src){
				blender!(1, false, true, ubyte, ubyte).go(dst.ptr, src[0], src[1]);
			},
			// src.length == 3
			function void(ref ubyte[] dst, in ubyte[] src){
				blender!(1, false, false, ubyte).go(dst.ptr, (src[0] + src[1] + src[2]) / 3);
			},
			// src.length == 4
			function void(ref ubyte[] dst, in ubyte[] src){
				blender!(1, false, true, ubyte, ubyte).go(dst.ptr, (src[0] + src[1] + src[2]) / 3, src[3]);
			}
		],
		
		// dst.length == 2
		[
			// src.length == 0
			function void(ref ubyte[] dst, in ubyte[] src){
				dst[0] = 0; dst[1] = 0;
			},
			// src.length == 1
			function void(ref ubyte[] dst, in ubyte[] src){
				blender!(2, true, false, ubyte).go(dst.ptr, src[0]);
			},
			// src.length == 2
			function void(ref ubyte[] dst, in ubyte[] src){
				blender!(2, true, true, ubyte, ubyte).go(dst.ptr, src[0], src[1]);
			},
			// src.length == 3
			function void(ref ubyte[] dst, in ubyte[] src){
				blender!(2, true, false, ubyte).go(dst.ptr, (src[0] + src[1] + src[2]) / 3);
			},
			// src.length == 4
			function void(ref ubyte[] dst, in ubyte[] src){
				blender!(2, true, true, ubyte, ubyte).go(dst.ptr, (src[0] + src[1] + src[2]) / 3, src[3]);
			}
		],
		
		// dst.length == 3
		[
			// src.length == 0
			function void(ref ubyte[] dst, in ubyte[] src){
				dst[0] = dst[1] = dst[2] = 0;
			},
			// src.length == 1
			function void(ref ubyte[] dst, in ubyte[] src){
				blender!(3, false, false, ubyte, ubyte, ubyte).go(dst.ptr, src[0], src[0], src[0]);
			},
			// src.length == 2
			function void(ref ubyte[] dst, in ubyte[] src){
				blender!(3, false, true, ubyte, ubyte, ubyte, ubyte).go(dst.ptr, src[0], src[0], src[0], src[1]);
			},
			// src.length == 3
			function void(ref ubyte[] dst, in ubyte[] src){
				blender!(3, false, false, ubyte, ubyte, ubyte).go(dst.ptr, src[0], src[1], src[2]);
			},
			// src.length == 4
			function void(ref ubyte[] dst, in ubyte[] src){
				blender!(3, false, true, ubyte, ubyte, ubyte, ubyte).go(dst.ptr, src[0], src[1], src[2], src[3]);
			}
		],
		
		// dst.length == 4
		[
			// src.length == 0
			function void(ref ubyte[] dst, in ubyte[] src){
				dst[0] = dst[1] = dst[2] = dst[3] = 0;
			},
			// src.length == 1
			function void(ref ubyte[] dst, in ubyte[] src){
				blender!(4, true, false, ubyte, ubyte, ubyte).go(dst.ptr, src[0], src[0], src[0]);
			},
			// src.length == 2
			function void(ref ubyte[] dst, in ubyte[] src){
				blender!(4, true, true, ubyte, ubyte, ubyte, ubyte).go(dst.ptr, src[0], src[0], src[0], src[1]);
			},
			// src.length == 3
			function void(ref ubyte[] dst, in ubyte[] src){
				blender!(4, true, false, ubyte, ubyte, ubyte).go(dst.ptr, src[0], src[3], src[2]);
			},
			// src.length == 4
			function void(ref ubyte[] dst, in ubyte[] src){
				blender!(4, true, true, ubyte, ubyte, ubyte, ubyte).go(dst.ptr, src[0], src[1], src[2], src[3]);
			}
		]
	];
	
	template blender(uint numCh, bool dstAlpha, bool srcAlpha, Src...)
	{
		void go(ubyte* dst, Src src)
		{
			static if (dstAlpha && srcAlpha)
			{
				uint tmp;
				float sa = (cast(float)src[$-1])/255.0f;
				float da = 1.0f - sa;
				mixin(repeat!(0, numCh - 1, "i", q{
					tmp = cast(uint)(dst[i] * da + src[i] * sa);
					dst[i] = cast(ubyte)min(tmp, 255u);
				}));
				dst[numCh - 1] = cast(ubyte)min(cast(uint)(src[$ - 1] * sa + dst[numCh - 1] * dst[numCh - 1] / 255.0f), 255u);
			}
			else static if (dstAlpha)
			{
				mixin(repeat!(0, numCh - 1, "i", q{
					dst[i] = src[i];
				}));
				dst[numCh - 1] = 255;
			}
			else static if (srcAlpha)
			{
				uint tmp;
				float sa = (cast(float)src[$ - 1]) / 255.0f;
				float da = 1.0f - sa;
				mixin(repeat!(0, numCh, "i", q{
					tmp = cast(uint)(dst[i] * da + src[i] * sa);
					dst[i] = cast(ubyte)min(tmp, 255u);
				}));
			}
			else
			{
				foreach(s; src)
					(*dst++) = s;
			}
		}
	}
	
	template repeat(uint i, uint max, string indexName, string code)
	{
		static if (i < max - 1)
			enum repeat = "{ enum " ~ indexName ~ "=" ~ to!string(i) ~ "; " ~ code ~ " } " ~ repeat!(i + 1, max, indexName, code);
		else
			enum repeat = "{ enum " ~ indexName ~ "=" ~ to!string(i) ~ "; " ~ code ~ " } ";
	}
}
