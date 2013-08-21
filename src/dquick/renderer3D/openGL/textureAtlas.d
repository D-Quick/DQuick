module dquick.renderer_3d.opengl.texture_atlas;

import dquick.renderer_3d.opengl.texture;
import dquick.renderer_3d.opengl.util;
import dquick.media.image;
import dquick.maths.vector2s32;
import dquick.utils.resource_manager;

import std.string;

class TextureAtlas : Texture
{
public:
	override void	load(string filePath, Variant[] options = null)
	{
		throw new Exception("Not supported");
	}
}
