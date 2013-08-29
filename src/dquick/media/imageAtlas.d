module dquick.media.image_atlas;

import dquick.media.image;
import dquick.maths.vector2s32;
import dquick.utils.resource_manager;

import gl3n.linalg;

import std.string;

// TODO migrate mNodes on a container http://dlang.org/phobos/std_container.html

/**
 * An image atlas that will optimize memory usage.
 * It's a skyline implementation, which is great for font glyphes.
 * http://clb.demon.fi/files/RectangleBinPack.pdf
 *
 * Because ImageAtlas is made to be used as texture we add a 1 pixel margin
 * to avoid filtering issues. This margin is fill with the #00000000 color.
**/
class ImageAtlas : Image
{
public:
	struct Region
	{
		int	x;
		int y;
		int width;
		int height;
	}

	override void	load(string filePath, Variant[] options = null)
	{
		throw new Exception("Not supported");
	}

	override void	create(string filePath, uint width, uint height, ubyte nbBytesPerPixel)
	{
		Image.create(filePath, width, height, nbBytesPerPixel);

		mNodes.length = 1;
		mNodes[0].x = 0;
		mNodes[0].y = 0;
		mNodes[0].z = width;
	}

	/// Return -1 in all Region properties when not enough space found
	Region	allocateRegion(uint width, uint height)
	{
		int y;
		int	best_height;
		int	best_width;
		int	best_index;

		Region	region;
		size_t	i;

		region.x = 0;
		region.y = 0;
		region.width = width;
		region.height = height;

		best_index  = -1;
		best_height = int.max;
		best_width = int.max;
		for (i = 0; i < mNodes.length; i++)
		{
			y = fit(i, width, height);
			if (y >= 0)
			{
				if (((y + height) < best_height) || (((y + height) == best_height) && (mNodes[i].z < best_width)))
				{
					best_height = y + height;
					best_width = mNodes[i].z;
					best_index = i;
					region.x = mNodes[i].x;
					region.y = y;
				}
			}
		}

		if (best_index == -1)
		{
			return Region(-1, -1, -1, -1);
		}

		Skyline	node;

		node.x = region.x;
		node.y = region.y + height;
		node.z = width;
		mNodes = mNodes[0..best_index] ~ node ~ mNodes[best_index..$];

		for (i = best_index + 1; i < mNodes.length; i++)
		{
			if (mNodes[i].x < (mNodes[i - 1].x + mNodes[i - 1].z))
			{
				int	shrink = mNodes[i - 1].x + mNodes[i - 1].z - mNodes[i].x;

				mNodes[i].x += shrink;
				mNodes[i].z -= shrink;
				if (mNodes[i].z <= 0)
				{
					mNodes = mNodes[0..i] ~ mNodes[i + 1..$];
					i--;
				}
				else
				{
					break;
				}
			}
			else
			{
				break;
			}
		}
		merge();
		mNbPixelsUsed += width * height;
		return region;
	}

	void	freeAllRegions()
	{
		throw new Exception("Not implemented!");
	}

	void	setRegion(Region region, Image subImage)
	{
		assert(subImage.width == region.width);
		assert(subImage.height == region.height);

		SDL_Rect	rect;
		rect.x = region.x;
		rect.y = region.y;
		rect.w = region.width;
		rect.h = region.height;
		if (SDL_BlitSurface(subImage.getSurface(), null, mSurface, &rect) != 0)
			throw new Exception(format("Failed to set region : \"%s\"", to!string(SDL_GetError())));
	}

private:
	struct Skyline
	{
		uint x;
		uint y;
		uint z;
	}

	int	fit(uint index, uint width, uint height)
	{
		int		x = mNodes[index].x;
		int		y = mNodes[index].y;
		int		width_left = width;
		size_t	i = index;

		if ((x + width) > Image.width)
		{
			return -1;
		}
		y = mNodes[index].y;
		while (width_left > 0)
		{
			if (mNodes[i].y > y)
			{
				y = mNodes[i].y;
			}
			if ((y + height) > Image.height)
			{
				return -1;
			}
			width_left -= mNodes[i].z;
			i++;
		}
		return y;
	}

	void	merge()
	{
		size_t	i;

		for (i = 0; i < mNodes.length - 1; i++)
		{
			if (mNodes[i].y == mNodes[i + 1].y)
			{
				mNodes[i].z += mNodes[i + 1].z;
				mNodes = mNodes[0..i] ~ mNodes[i + 1..$];
				i--;
			}
		}
	}

	size_t			mNbPixelsUsed;
	Skyline[]		mNodes;
}

import derelict.sdl2.sdl;
import derelict.sdl2.image;

import dquick.maths.color;

unittest
{
	ImageAtlas			atlas = new ImageAtlas;
	ImageAtlas.Region	region;
	Image				subImage = new Image;
	Image				expectedResult = new ImageAtlas;

	atlas.create("toto", 128, 128, 3);

	subImage.create("subImage", 20, 30, 3);
	subImage.fill(Color(1.0, 0.0, 0.0), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	subImage.create("subImage", 100, 10, 3);
	subImage.fill(Color(0.0, 1.0, 0.0), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	subImage.create("subImage", 10, 100, 3);
	subImage.fill(Color(0.0, 0.0, 1.0), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	subImage.create("subImage", 10, 60, 3);
	subImage.fill(Color(1.0, 1.0, 0.0), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	subImage.create("subImage", 30, 30, 3);
	subImage.fill(Color(0.0, 1.0, 1.0), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	subImage.create("subImage", 45, 70, 3);
	subImage.fill(Color(1.0, 0.0, 1.0), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	subImage.create("subImage", 15, 5, 3);
	subImage.fill(Color(1.0, 1.0, 1.0), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	// ============================================================================

	subImage.create("subImage", 20, 30, 3);
	subImage.fill(Color(0.5, 0.0, 0.0), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	subImage.create("subImage", 10, 10, 3);
	subImage.fill(Color(0.0, 0.5, 0.0), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	subImage.create("subImage", 25, 12, 3);
	subImage.fill(Color(0.0, 0.0, 0.5), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	subImage.create("subImage", 10, 70, 3);
	subImage.fill(Color(0.5, 0.5, 0.0), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	subImage.create("subImage", 30, 30, 3);
	subImage.fill(Color(0.0, 0.5, 0.5), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	subImage.create("subImage", 45, 20, 3);
	subImage.fill(Color(0.5, 0.0, 0.5), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	subImage.create("subImage", 15, 5, 3);
	subImage.fill(Color(0.5, 0.5, 0.5), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	// ============================================================================

	subImage.create("subImage", 126, 1, 3);
	subImage.fill(Color(1.0, 0.0, 0.0), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	subImage.create("subImage", 127, 1, 3);
	subImage.fill(Color(0.0, 1.0, 0.0), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	subImage.create("subImage", 128, 1, 3);
	subImage.fill(Color(0.0, 0.0, 1.0), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	// ============================================================================

	subImage.create("subImage", 1, 126, 3);
	subImage.fill(Color(1.0, 0.0, 0.0), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	subImage.create("subImage", 1, 127, 3);
	subImage.fill(Color(0.0, 1.0, 0.0), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	subImage.create("subImage", 1, 128, 3);
	subImage.fill(Color(0.0, 0.0, 1.0), Vector2s32(0, 0), subImage.size());
	region = atlas.allocateRegion(subImage.width, subImage.height);
	if (region.x >= 0)
		atlas.setRegion(region, subImage);

	atlas.save("../data/ImageAtlasTest.bmp");
}
