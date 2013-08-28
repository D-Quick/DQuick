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
		mNodes[0].x = 1;
		mNodes[0].y = 1;
		mNodes[0].z = width - 2;
	}

	Region	allocateRegion(uint width, uint height)
	{
		int y;
		int	best_height;
		int	best_width;
		int	best_index;

		Skyline	node;
		Skyline	prev;
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
				node = mNodes[i];
				if (((y + height) < best_height) || (((y + height) == best_height) && (node.z < best_width)))
				{
					best_height = y + height;
					best_index = i;
					best_width = node.z;
					region.x = node.x;
					region.y = y;
				}
			}
		}

		if (best_index == -1)
		{
			region.x = -1;
			region.y = -1;
			region.width = 0;
			region.height = 0;
			return region;
		}

		node.x = region.x;
		node.y = region.y + height;
		node.z = width;
		mNodes = mNodes[0..best_index] ~ node ~ mNodes[best_index..$];
//		vector_insert( mNodes, best_index, node );

		for (i = best_index + 1; i < mNodes.length; i++)
		{
			node = mNodes[i];
			prev = mNodes[i - 1];

			if (node.x < (prev.x + prev.z))
			{
				int	shrink = prev.x + prev.z - node.x;

				node.x += shrink;
				node.z -= shrink;
				if (node.z <= 0)
				{
					mNodes = mNodes[0..i] ~ mNodes[i + 1..$];
//					vector_erase( mNodes, i );
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
		Skyline	node = mNodes[index];

		int		x = node.x;
		int		y;
		int		width_left = width;
		size_t	i = index;

		if ((x + width) > (Image.width - 1))
		{
			return -1;
		}
		y = node.y;
		while (width_left > 0)
		{
			node = mNodes[i];
			if (node.y > y)
			{
				y = node.y;
			}
			if ((y + height) > (Image.height - 1))
			{
				return -1;
			}
			width_left -= node.z;
			i++;
		}
		return y;
	}

	void	merge()
	{
		Skyline	node;
		Skyline	next;
		size_t	i;

		for (i = 0; i < mNodes.length - 1; i++)
		{
			node = mNodes[i];
			next = mNodes[i + 1];
			if (node.y == next.y)
			{
				node.z += next.z;
				mNodes = mNodes[0..i] ~ mNodes[i + 1..$];
//				vector_erase( self->nodes, i );
				i--;
			}
		}
	}

	size_t			mNbPixelsUsed;
	Skyline[]		mNodes;
}

import derelict.sdl2.sdl;
import derelict.sdl2.image;

// TODO Create a unittest pack some images into a single one, it can write the resulting image on HDD
// Let user specifying margin, for text with clamp it might be not necessary to have a margin.
unittest
{
	ImageAtlas			atlas = new ImageAtlas;
	ImageAtlas.Region	region;
	Image				subImage = new Image;

	atlas.create("toto", 1024, 1024, 4);
	
	subImage.load("E:/Dev/Personal/DQuick/data/images/Qt/text-highscore-new.png");
	region = atlas.allocateRegion(subImage.width, subImage.height);
	atlas.setRegion(region, subImage);
	atlas.save("E:/Dev/Personal/DQuick/data/ImageAtlasTest.bmp");
	assert(region.x == 1);
	assert(region.y == 1);
	assert(region.width == subImage.width);
	assert(region.height == subImage.height);

	subImage.load("E:/Dev/Personal/DQuick/data/images/Qt/text-no-winner.png");
	region = atlas.allocateRegion(subImage.width, subImage.height);
	atlas.setRegion(region, subImage);
	atlas.save("E:/Dev/Personal/DQuick/data/ImageAtlasTest.bmp");
	assert(region.x == 1);
	assert(region.y == 1);
	assert(region.width == subImage.width);
	assert(region.height == subImage.height);

	subImage.load("E:/Dev/Personal/DQuick/data/images/Qt/monkey_on_64x64.png");
	region = atlas.allocateRegion(subImage.width, subImage.height);
	atlas.setRegion(region, subImage);
	atlas.save("E:/Dev/Personal/DQuick/data/ImageAtlasTest.bmp");
	assert(region.x == 1);
	assert(region.y == 1);
	assert(region.width == subImage.width);
	assert(region.height == subImage.height);
}
