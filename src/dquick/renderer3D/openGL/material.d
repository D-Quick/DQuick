module dquick.renderer_3d.opengl.material;

import dquick.renderer_3d.opengl.renderer;
import dquick.renderer_3d.opengl.texture;
import dquick.renderer_3d.opengl.shader;
import dquick.renderer_3d.opengl.util;
import dquick.renderer_3d.opengl.renderer;

import dquick.maths.color;

import derelict.opengl3.gl;

import std.stdio;

/// It's not considered like a resource, it's not necessary as texture are already shared
/// Using a structure allow customization
struct Material
{
public:
	~this()
	{
		destroy();
	}

	bool	setTexture(string filePath)
	{
		mTexture = dquick.renderer_3d.opengl.renderer.resourceManager.getResource!Texture(filePath);
		return true;
	}

private:
	void	destroy()
	{
		dquick.renderer_3d.opengl.renderer.resourceManager.releaseResource(mTexture);
		mTexture = null;
		.destroy(mShader);
	}

	static const GLuint		mBadId = 0;

	Texture					mTexture;
	Shader					mShader;
	GLint					mColorAttribute;
	GLint					mTexcoordAttribute;
}
