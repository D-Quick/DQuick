module dquick.renderer_3d.opengl.texture;

import dquick.renderer_3d.opengl.util;
import dquick.media.image;
import dquick.maths.vector2s32;
import dquick.utils.resource_manager;

import derelict.opengl3.gl;

import std.string;

class Texture : IResource
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

		Image	image = resourceManager.getResource!Image(filePath);
		scope(exit) resourceManager.releaseResource(image);

		mSize.x = image.width;
		mSize.y = image.height;

		checkgl!glEnable(GL_TEXTURE_2D);
		checkgl!glGenTextures(1, &mId);
		if (mId == mBadId)
			throw new Exception("[Texture] Unable to generate a texture");

		checkgl!glBindTexture(GL_TEXTURE_2D, mId);
		if (image.nbBytesPerPixel() == 3)
			checkgl!glTexImage2D(GL_TEXTURE_2D, 0, image.nbBytesPerPixel(), mSize.x, mSize.y, 0, GL_RGB, GL_UNSIGNED_BYTE, image.pixels());
		else if (image.nbBytesPerPixel() == 4)
			checkgl!glTexImage2D(GL_TEXTURE_2D, 0, image.nbBytesPerPixel(), mSize.x, mSize.y, 0, GL_RGBA, GL_UNSIGNED_BYTE, image.pixels());
		else
			throw new Exception("[Texture] Pixel format unsupported");

		checkgl!glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		checkgl!glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//		checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
//		checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

		mWeight = image.weight;
		mFilePath = filePath;
	}

	void	load(Image image, string filePath, Variant[] options = null)
	{
		assert(options == null);
		unload();
		throw new Exception("Not implemented");
	}

	/// Replace the texture's image by the new one, format need to be the same (width, height, bytes per pixels,...)
	void	update(Image image)
	{
		throw new Exception("Not implemented");
	}

	void	unload()
	{
		if (mId != mBadId)
			checkgl!glDeleteTextures(1, &mId);
		mId = mBadId;
		mSize = Vector2s32(0, 0);
	}

	bool	isLoaded() {return mId != mBadId;}

	Vector2s32	size() {return mSize;}

	GLuint	id() {return mId;}

private:
	static const GLuint	mBadId = 0;	// Useful if on some platforms 0 can be used for a texture id

	GLuint		mId = mBadId;
	Vector2s32	mSize;
}
