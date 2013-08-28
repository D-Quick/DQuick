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
	}

	void	setRegion(Region region, Image subImage)
	{
		assert(subImage.width == region.width);
		assert(subImage.height == region.height);
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

	atlas.create("toto", 128, 128, 4);
	region = atlas.allocateRegion(20, 20);
	assert(region.x == 1);
	assert(region.y == 1);
	assert(region.width == 20);
	assert(region.height == 20);

	region = atlas.allocateRegion(100, 30);
	assert(region.x == 21);
	assert(region.y == 21);
	assert(region.width == 100);
	assert(region.height == 30);

	region = atlas.allocateRegion(30, 5);
	assert(region.x == 1);
	assert(region.y == 21);
	assert(region.width == 30);
	assert(region.height == 5);
}
