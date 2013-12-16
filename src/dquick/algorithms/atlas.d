module dquick.algorithms.atlas;

import dquick.maths.vector2s32;
import dquick.maths.rect2s32;

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
class Atlas
{
public:
	bool	allowRotation = false;

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
	Rect2s32	allocateRegion(uint width, uint height)	// TODO use a Vector2s32
	{
		int			bestHeight;
		int			bestWidth;
		int			bestIndex;
		Rect2s32	newNode = findPositionForNewNodeBottomLeft(width, height, bestHeight, bestWidth, bestIndex);

		if (bestIndex != -1)
		{
			// Perform the actual packing.
			addSkylineLevel(bestIndex, newNode);
		}
		else
			return Rect2s32(-1, -1, -1, -1);
		return newNode;
	}

	void	clear()
	{
		mSkyLine.length = 0;

		SkylineNode	node;
		node.x = 0;
		node.y = 0;
		node.width = mSize.x;
		mSkyLine ~= node;
	}

private:
	Rect2s32	findPositionForNewNodeBottomLeft(int width, int height, ref int bestHeight, ref int bestWidth, ref int bestIndex) const
	{
		Rect2s32	newNode;

		bestHeight = int.max;
		bestIndex = -1;
		// Used to break ties if there are nodes at the same level. Then pick the narrowest one.
		bestWidth = int.max;
		for (int i = 0; i < mSkyLine.length; ++i)
		{
			int y;
			if (rectangleFits(i, width, height, y))
			{
				if (y + height < bestHeight || (y + height == bestHeight && mSkyLine[i].width < bestWidth))
				{
					bestHeight = y + height;
					bestIndex = i;
					bestWidth = mSkyLine[i].width;
					newNode.x = mSkyLine[i].x;
					newNode.y = y;
					newNode.width = width;
					newNode.height = height;
				}
			}
			// Try to find something best with a 90 degres rotation
			if (allowRotation && rectangleFits(i, height, width, y))
			{
				if (y + width < bestHeight || (y + width == bestHeight && mSkyLine[i].width < bestWidth))
				{
					bestHeight = y + width;
					bestIndex = i;
					bestWidth = mSkyLine[i].width;
					newNode.x = mSkyLine[i].x;
					newNode.y = y;
					newNode.width = height;
					newNode.height = width;
				}
			}
		}

		return newNode;
	}

	bool	rectangleFits(int skylineNodeIndex, int width, int height, ref int y) const
	{
		int x = mSkyLine[skylineNodeIndex].x;
		if (x + width > mSize.x)
			return false;
		int widthLeft = width;
		int i = skylineNodeIndex;
		y = mSkyLine[skylineNodeIndex].y;
		while (widthLeft > 0)
		{
			y = max(y, mSkyLine[i].y);
			if (y + height > mSize.y)
				return false;
			widthLeft -= mSkyLine[i].width;
			++i;
			assert(i < mSkyLine.length || widthLeft <= 0);
		}
		return true;
	}

	void	addSkylineLevel(int skylineNodeIndex, const ref Rect2s32 rect)
	{
		SkylineNode newNode;
		newNode.x = rect.x;
		newNode.y = rect.y + rect.height;
		newNode.width = rect.width;
//		mSkyLine.insert(mSkyLine.begin() + skylineNodeIndex, newNode);
		mSkyLine = mSkyLine[0..skylineNodeIndex] ~ newNode ~ mSkyLine[skylineNodeIndex..$];	// insert node at skylineNodeIndex

		assert(newNode.x + newNode.width <= mSize.x);
		assert(newNode.y <= mSize.y);

		for (size_t i = skylineNodeIndex+1; i < mSkyLine.length; ++i)
		{
			assert(mSkyLine[i-1].x <= mSkyLine[i].x);

			if (mSkyLine[i].x < mSkyLine[i-1].x + mSkyLine[i-1].width)
			{
				int shrink = mSkyLine[i-1].x + mSkyLine[i-1].width - mSkyLine[i].x;

				mSkyLine[i].x += shrink;
				mSkyLine[i].width -= shrink;

				if (mSkyLine[i].width <= 0)
				{
//					mSkyLine.erase(mSkyLine.begin() + i);
					mSkyLine = mSkyLine[0..i] ~ mSkyLine[i + 1..$];	// remove i node
					--i;
				}
				else
					break;
			}
			else
				break;
		}
		mergeSkylines();
	}

	/// Merges all skyline nodes that are at the same level.
	void	mergeSkylines()
	{
		for (size_t i = 0; i < mSkyLine.length-1; ++i)
			if (mSkyLine[i].y == mSkyLine[i+1].y)
			{
				mSkyLine[i].width += mSkyLine[i+1].width;
//				mSkyLine.erase(mSkyLine.begin() + (i+1));
				mSkyLine = mSkyLine[0..i + 1] ~ mSkyLine[i + 2..$];	// remove i + 1 node
				--i;
			}
	}

	/// Represents a single level (a horizontal line) of the skyline/horizon/envelope.
	struct	SkylineNode
	{
		/// The starting x-coordinate (leftmost).
		int	x;

		/// The y-coordinate of the skyline level line.
		int	y;

		/// The line width. The ending coordinate (inclusive) will be x+width-1.
		int	width;
	};

	Vector2s32		mSize;
	SkylineNode[]	mSkyLine;
}

import dquick.maths.color;
import dquick.media.image;

import std.stdio;
import std.c.string;

/// This test will use images to simplify the debugging
unittest
{
	import std.file;
	import std.path;
	chdir(dirName(thisExePath()));

	void	fillAtlas(ref Atlas atlas, Image imageAtlas, Vector2s32 size, Color color)
	{
		Rect2s32	region;
		Image		subImage = new Image;

		subImage.create("subImage", size.x, size.y, Image.Format.RGB);
		subImage.fill(color, Vector2s32(0, 0), subImage.size());
		region = atlas.allocateRegion(subImage.width(), subImage.height());
		if (region.x >= 0)
		{
			assert(subImage.width() == region.width);
			assert(subImage.height() == region.height);

			imageAtlas.fill(color, Vector2s32(region.x, region.y), Vector2s32(region.width, region.height));

			// Uncomment it to generate the code of the result Image
/*			writefln("\texpectedResult.fill(Color(%0.1f, %0.1f, %0.1f), Vector2s32(%3d, %3d), Vector2s32(%3d, %3d));",
						   color.x, color.y, color.z,
						   region.x, region.y,
						   size.x, size.y);*/
		}
	}

	Atlas	atlas = new Atlas;
	Image	imageAtlas = new Image;
	Image	expectedResult = new Image;

	atlas.create(Vector2s32(128, 128));

	imageAtlas.create("imageAtlas", atlas.size().x, atlas.size().y, Image.Format.RGB);
	expectedResult.create("result", imageAtlas.width(), imageAtlas.height(), imageAtlas.format());

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

	imageAtlas.save("../data/ImageAtlasTest.png");

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
	expectedResult.fill(Color(0.5, 0.0, 0.5), Vector2s32( 70,  80), Vector2s32( 45,  20));
	expectedResult.fill(Color(0.5, 0.5, 0.0), Vector2s32(  0,  65), Vector2s32( 15,   5));
	expectedResult.fill(Color(1.0, 0.0, 0.0), Vector2s32(  0, 110), Vector2s32(126,   1));
	expectedResult.fill(Color(0.0, 1.0, 0.0), Vector2s32(  0, 111), Vector2s32(127,   1));
	expectedResult.fill(Color(0.0, 0.0, 1.0), Vector2s32(  0, 112), Vector2s32(128,   1));

	expectedResult.save("../data/AtlasTestResult.png");

	assert(0 == memcmp(expectedResult.pixels(), imageAtlas.pixels(), imageAtlas.width() * imageAtlas.height() * imageAtlas.nbBytesPerPixel()));
}
