module dquick.media.image;

import std.string;
import std.stdio;
import std.conv;

import derelict.sdl2.image;
import derelict.sdl2.sdl;

import dquick.maths.color;
import dquick.maths.vector2s32;

//import dquick.system.dynamic_library;

import dquick.utils.resource_manager;

ResourceManager	resourceManager;

static this()
{
	resourceManager = new ResourceManager();
	resourceManager.maximumWeight(50 * 1000 * 1024);
}

static ~this()
{
}

class Image : IResource
{
	mixin ResourceBase;

public:
	~this()
	{
		unload();
	}

	void	load(string filePath, Variant[] options = null)
	{
		assert(options == null);
		unload();

		if ((mSurface = IMG_Load(filePath.toStringz)) != null)
		{
			mWeight = width * height * nbBytesPerPixel;
			mFilePath = filePath;
		}
		else
			throw new Exception(format("Unable to load image \"%s\"", filePath));
	}

	void	save(string filePath)
	{
		if (SDL_SaveBMP(mSurface, filePath.toStringz) != 0)
			throw new Exception(format("Unable to save image \"%s\", error : \"%s\"", filePath, to!string(SDL_GetError())));
	}

	void	create(string filePath, uint width, uint height, ubyte nbBytesPerPixel)
	{
		unload();

		version(BigEndian)
		{
			uint rmask = 0xff000000;
			uint gmask = 0x00ff0000;
			uint bmask = 0x0000ff00;
			uint amask = 0x000000ff;
		}
		else
		{
			uint rmask = 0x000000ff;
			uint gmask = 0x0000ff00;
			uint bmask = 0x00ff0000;
			uint amask = 0xff000000;
		}

		if ((mSurface = SDL_CreateRGBSurface(0, width, height, nbBytesPerPixel * 8, rmask, gmask, bmask, amask)) != null)
		{
			mWeight = width * height * nbBytesPerPixel;
			mFilePath = filePath;
		}
		else
			throw new Exception(format("Unable to create image \"%s\", error : \"%s\"", filePath, to!string(SDL_GetError())));
	}

	void	fill(Color color, Vector2s32 position, Vector2s32 size)
	{
		assert(mSurface);

		SDL_Rect	rect;
		Uint32		colorCode;

		rect.x = position.x;
		rect.y = position.y;
		rect.w = size.x;
		rect.h = size.y;

		colorCode = SDL_MapRGBA(mSurface.format, cast(ubyte)(color.z * 255.0), cast(ubyte)(color.y * 255.0), cast(ubyte)(color.x * 255.0), cast(ubyte)(color.w * 255.0));
		if (SDL_FillRect(mSurface, &rect, colorCode) != 0)
			throw new Exception(format("Unable to fill image, error : \"%s\"", to!string(SDL_GetError())));
	}

	void	blit(Image image, Vector2s32 destPosition, Vector2s32 sourcePosition, Vector2s32 sourceSize)
	{
		throw new Exception("Not implemented!");
	}

	void	unload()
	{
		if (mSurface != null)
		{
			SDL_FreeSurface(mSurface);
			mSurface = null;
		}
	}

	uint	width()
	{
		if (mSurface)
			return mSurface.w;
		return 0;
	}

	uint	height()
	{
		if (mSurface)
			return mSurface.h;
		return 0;
	}

	Vector2s32	size()
	{
		return Vector2s32(width, height);
	}

	ubyte*	pixels()
	{
		if (mSurface)
			return cast(ubyte*)mSurface.pixels;
		return null;
	}

	ubyte	nbBytesPerPixel()
	{
		if (mSurface)
			return mSurface.format.BytesPerPixel;
		return 0;
	}

	// TODO find why ImageAtlas that derived Image can't acces mSurface member directly (check method setRegion and parameter subImage)
	SDL_Surface*	getSurface() {return mSurface;}

protected:
	SDL_Surface*	mSurface = null;
}
