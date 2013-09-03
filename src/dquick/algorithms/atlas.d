module dquick.algorithms.atlas;

import dquick.maths.vector2s32;

import gl3n.linalg;

// TODO migrate mNodes on a container http://dlang.org/phobos/std_container.html

/**
* An atlas that will optimize memory usage.
* It's a skyline implementation (bottom-left) without rotation
* http://clb.demon.fi/files/RectangleBinPack.pdf
* 
* Original sources
* http://clb.demon.fi/files/RectangleBinPack/SkylineBinPack.h
* http://clb.demon.fi/files/RectangleBinPack/SkylineBinPack.cpp
**/
struct Atlas
{
public:
	struct Region
	{
		int	x;
		int y;
		int width;
		int height;
	}

	void	create(Vector2s32 size)
	{
		mSize = size;
		clear();
	}

	Vector2s32	size()
	{
		return mSize;
	}

	/// Return -1 in all Region properties when not enough space found
	Region	allocateRegion(uint width, uint height)
	{
		int y;
		int	bestHeight;
		int	bestWidth;
		int	bestIndex;

		Region	region;
		size_t	i;

		region.x = 0;
		region.y = 0;
		region.width = width;
		region.height = height;

		bestHeight = int.max;
		bestIndex  = -1;
		// Used to break ties if there are nodes at the same level. Then pick the narrowest one.
		bestWidth = int.max;
		for (i = 0; i < mNodes.length; i++)
		{
			y = rectangleFits(i, width, height);
			if (y >= 0)
			{
				if (y + height < bestHeight || (y + height == bestHeight && mNodes[i].width < bestWidth))
				{
					bestHeight = y + height;
					bestIndex = i;
					bestWidth = mNodes[i].width;
					region.x = mNodes[i].x;
					region.y = y;
					region.width = width;
					region.height = height;
				}
			}
		}

		if (bestIndex == -1)
			return Region(-1, -1, -1, -1);

		addSkylineLevel(bestIndex, region);

		return region;
	}

	void	clear()
	{
		mNodes.length = 1;
		mNodes[0].x = 0;
		mNodes[0].y = 0;
		mNodes[0].width = mSize.x;
	}

private:
	struct Skyline
	{
		/// The starting x-coordinate (leftmost).
		uint x;

		/// The y-coordinate of the skyline level line.
		uint y;

		/// The line width. The ending coordinate (inclusive) will be x+width-1.
		uint width;
	}

	int	rectangleFits(uint index, uint width, uint height)
	{
		int	x = mNodes[index].x;

		if (x + width > mSize.x)
			return -1;

		int		y = mNodes[index].y;
		size_t	i = index;
		int		widthLeft = width;

		while (widthLeft > 0)
		{
			y = max(y, mNodes[i].y);
			if (y + height > mSize.y)
				return -1;
			widthLeft -= mNodes[i].width;
			++i;
			assert(i < mNodes.length || widthLeft <= 0);
		}
		assert(y >= 0);
		return y;
	}

	void	addSkylineLevel(int index, Region region)
	{		
		Skyline	node;

		node.x = region.x;
		node.y = region.y + region.height;
		node.width = region.width;

		mNodes = mNodes[0..index] ~ node ~ mNodes[index..$];	// insert node at index

		assert(node.x + node.width <= mSize.x);
		assert(node.y <= mSize.y);

		for (size_t i = index + 1; i < mNodes.length; i++)
		{
			assert(mNodes[i - 1].x <= mNodes[i].x);

			if (mNodes[i].x < mNodes[i - 1].x + mNodes[i - 1].width)
			{
				int	shrink = mNodes[i - 1].x + mNodes[i - 1].width - mNodes[i].x;

				mNodes[i].x += shrink;
				mNodes[i].width -= shrink;
				if (mNodes[i].width <= 0)
				{
					mNodes = mNodes[0..i] ~ mNodes[i + 1..$];	// remove i node
					i--;
				}
				else
					break;
			}
			else
				break;
		}
		mergeSkylines();
	}

	void	mergeSkylines()
	{
		size_t	i;

		for (i = 0; i < mNodes.length - 1; i++)
		{
			if (mNodes[i].y == mNodes[i + 1].y)
			{
				mNodes[i].width += mNodes[i + 1].width;
				mNodes = mNodes[0..i + 1] ~ mNodes[i + 2..$];	// remove i + 1 node
				--i;
			}
		}
	}

	Skyline[]	mNodes;
	Vector2s32	mSize;
}

import derelict.sdl2.sdl;
import derelict.sdl2.image;

import dquick.maths.color;
import dquick.media.image;

import std.stdio;
import std.c.string;

/// This test will use images to simplify the debugging
unittest
{
	void	fillAtlas(ref Atlas atlas, Image imageAtlas, Vector2s32 size, Color color)
	{
		Atlas.Region	region;
		Image			subImage = new Image;

		subImage.create("subImage", size.x, size.y, 3);
		subImage.fill(color, Vector2s32(0, 0), subImage.size());
		region = atlas.allocateRegion(subImage.width, subImage.height);
		if (region.x >= 0)
		{
			assert(subImage.width == region.width);
			assert(subImage.height == region.height);

			imageAtlas.fill(color, Vector2s32(region.x, region.y), Vector2s32(region.width, region.height));

			// Uncomment it to generate the code of the result Image
			/*			writeln(format("\texpectedResult.fill(Color(%0.1f, %0.1f, %0.1f), Vector2s32(%3d, %3d), Vector2s32(%3d, %3d));",
			color.x, color.y, color.z,
			region.x, region.y,
			size.x, size.y));*/
		}
	}

	Atlas	atlas;
	Image	imageAtlas = new Image;
	Image	expectedResult = new Image;

	atlas.create(Vector2s32(128, 128));

	imageAtlas.create("imageAtlas", atlas.size.x, atlas.size.y, 3);
	expectedResult.create("result", imageAtlas.width, imageAtlas.height, imageAtlas.nbBytesPerPixel);

	fillAtlas(atlas, imageAtlas, Vector2s32( 20,  30), Color(1.0, 0.0, 0.0));
	fillAtlas(atlas, imageAtlas, Vector2s32(100,  10), Color(0.0, 1.0, 0.0));
	fillAtlas(atlas, imageAtlas, Vector2s32( 10, 100), Color(0.0, 0.0, 1.0));
	fillAtlas(atlas, imageAtlas, Vector2s32( 10,  60), Color(1.0, 1.0, 0.0));
	fillAtlas(atlas, imageAtlas, Vector2s32( 30,  30), Color(0.0, 1.0, 1.0));
	fillAtlas(atlas, imageAtlas, Vector2s32( 45,  70), Color(1.0, 0.0, 1.0));
	fillAtlas(atlas, imageAtlas, Vector2s32( 15,   5), Color(1.0, 1.0, 1.0));

	// ============================================================================

	fillAtlas(atlas, imageAtlas, Vector2s32( 20,  30), Color(0.5, 0.0, 0.0));
	fillAtlas(atlas, imageAtlas, Vector2s32( 10,  10), Color(0.0, 0.5, 0.0));
	fillAtlas(atlas, imageAtlas, Vector2s32( 25,  12), Color(0.0, 0.0, 0.5));
	fillAtlas(atlas, imageAtlas, Vector2s32( 10,  70), Color(0.5, 0.5, 0.0));
	fillAtlas(atlas, imageAtlas, Vector2s32( 30,  30), Color(0.0, 0.5, 0.5));
	fillAtlas(atlas, imageAtlas, Vector2s32( 45,  20), Color(0.5, 0.0, 0.5));
	fillAtlas(atlas, imageAtlas, Vector2s32( 15,   5), Color(0.5, 0.5, 0.));

	// ============================================================================

	fillAtlas(atlas, imageAtlas, Vector2s32(126,   1), Color(1.0, 0.0, 0.0));
	fillAtlas(atlas, imageAtlas, Vector2s32(127,   1), Color(0.0, 1.0, 0.0));
	fillAtlas(atlas, imageAtlas, Vector2s32(128,   1), Color(0.0, 0.0, 1.0));

	// ============================================================================

	fillAtlas(atlas, imageAtlas, Vector2s32(  1, 126), Color(1.0, 0.0, 0.0));
	fillAtlas(atlas, imageAtlas, Vector2s32(  1, 127), Color(0.0, 1.0, 0.0));
	fillAtlas(atlas, imageAtlas, Vector2s32(  1, 128), Color(0.0, 0.0, 1.0));

	imageAtlas.save("../data/ImageAtlasTest.bmp");

	expectedResult.fill(Color(1.0, 0.0, 0.0), Vector2s32(  0,   0), Vector2s32( 20,  30));
	expectedResult.fill(Color(0.0, 1.0, 0.0), Vector2s32( 20,   0), Vector2s32(100,  10));
	expectedResult.fill(Color(0.0, 0.0, 1.0), Vector2s32( 20,  10), Vector2s32( 10, 100));
	expectedResult.fill(Color(1.0, 1.0, 0.0), Vector2s32( 30,  10), Vector2s32( 10,  60));
	expectedResult.fill(Color(0.0, 1.0, 1.0), Vector2s32( 40,  10), Vector2s32( 30,  30));
	expectedResult.fill(Color(1.0, 0.0, 1.0), Vector2s32( 70,  10), Vector2s32( 45,  70));
	expectedResult.fill(Color(1.0, 1.0, 1.0), Vector2s32(  0,  30), Vector2s32( 15,   5));
	expectedResult.fill(Color(0.5, 0.0, 0.0), Vector2s32(  0,  35), Vector2s32( 20,  30));
	expectedResult.fill(Color(0.0, 0.5, 0.0), Vector2s32(115,  10), Vector2s32( 10,  10));
	expectedResult.fill(Color(0.0, 0.0, 0.5), Vector2s32( 40,  40), Vector2s32( 25,  12));
	expectedResult.fill(Color(0.5, 0.5, 0.0), Vector2s32(115,  20), Vector2s32( 10,  70));
	expectedResult.fill(Color(0.0, 0.5, 0.5), Vector2s32( 40,  52), Vector2s32( 30,  30));
	expectedResult.fill(Color(0.5, 0.0, 0.5), Vector2s32( 65,  80), Vector2s32( 45,  20));
	expectedResult.fill(Color(0.5, 0.5, 0.0), Vector2s32(  0,  65), Vector2s32( 15,   5));
	expectedResult.fill(Color(1.0, 0.0, 0.0), Vector2s32(  0, 110), Vector2s32(126,   1));
	expectedResult.fill(Color(0.0, 1.0, 0.0), Vector2s32(  0, 111), Vector2s32(127,   1));
	expectedResult.fill(Color(0.0, 0.0, 1.0), Vector2s32(  0, 112), Vector2s32(128,   1));
	expectedResult.fill(Color(1.0, 0.0, 0.0), Vector2s32(120,   0), Vector2s32(  1, 126));
	expectedResult.fill(Color(0.0, 1.0, 0.0), Vector2s32(121,   0), Vector2s32(  1, 127));
	expectedResult.fill(Color(0.0, 0.0, 1.0), Vector2s32(122,   0), Vector2s32(  1, 128));

	expectedResult.save("../data/AtlasTestResult.bmp");

	assert(0 == memcmp(expectedResult.pixels, imageAtlas.pixels, imageAtlas.width * imageAtlas.height * imageAtlas.nbBytesPerPixel));
}
