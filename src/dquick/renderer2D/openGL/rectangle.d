module dquick.renderer_2d.opengl.rectangle;

import dquick.renderer_3d.opengl.renderer;
import dquick.renderer_3d.opengl.texture;
import dquick.renderer_3d.opengl.shader;
import dquick.renderer_3d.opengl.shader_program;
import dquick.renderer_3d.opengl.vbo;
import dquick.renderer_3d.opengl.util;
import dquick.renderer_3d.opengl.mesh;

import dquick.maths.color;
import dquick.maths.vector2f32;

import derelict.opengl3.gl;

import std.stdio;
import std.variant;

// TODO Add the possibility to update colors and texcoords

struct Rectangle
{
public:
	bool	setTexture(string filePath)
	{
		create();
		mMesh.setTexture(filePath);

		if (!mUserSize)
			mSize = Vector2f32(mMesh.texture.size().x, mMesh.texture.size().y);
		updateMesh();	// update mesh to the texture size if no user size was specified
		return true;
	}

	void	setSize(Vector2f32 newSize)
	{
		mSize = newSize;
		mUserSize = true;
		updateMesh();
	}

	Vector2f32	size()
	{
		return mSize;
	}

	@property void	width(float width) {setSize(Vector2f32(width, size().y));}
	@property float	width() {return mSize.x;}
	@property void	height(float height) {setSize(Vector2f32(size().x, height));}
	@property float	height() {return mSize.y;}

	void	draw()
	{
		mMesh.draw();
	}

private:
	void	create()	// Safe to call it if mesh is already created
	{
		if (mMesh)
			return;

		mMesh = new Mesh();
		mShaderProgram = new ShaderProgram();

		mShader = dquick.renderer_3d.opengl.renderer.resourceManager.getResource!Shader("dquick/shaders/rectangle");
		mShaderProgram.setProgram(mShader.getProgram());
		mMesh.setShader(mShader);
		mMesh.setShaderProgram(mShaderProgram);

		mMesh.indexes.setArray(cast(GLuint[])[0, 1, 2, 1, 3, 2],
							   cast(GLenum)GL_ELEMENT_ARRAY_BUFFER, cast(GLenum)GL_STATIC_DRAW);

		mMesh.vertices.setArray(cast(GLfloat[])[
								-mSize.x / 2.0f,	-mSize.y / 2.0f,	0.0f,
								 mSize.x / 2.0f,	-mSize.y / 2.0f,	0.0f,
								-mSize.x / 2.0f,	 mSize.y / 2.0f,	0.0f,
								 mSize.x / 2.0f,	 mSize.y / 2.0f,	0.0f],
								cast(GLenum)GL_ARRAY_BUFFER, cast(GLenum)GL_DYNAMIC_DRAW);


		mMesh.texCoords.setArray(cast(GLfloat[])[
								 0.0f, 0.0f,
								 1.0f, 0.0f,
								 0.0f, 1.0f,
								 1.0f, 1.0f],
								 cast(GLenum)GL_ARRAY_BUFFER, cast(GLenum)GL_DYNAMIC_DRAW);

		mMesh.colors.setArray(cast(GLfloat[])[
							  1.0f, 1.0f, 1.0f, 1.0f,
							  1.0f, 1.0f, 1.0f, 1.0f,
							  1.0f, 1.0f, 1.0f, 1.0f,
							  1.0f, 1.0f, 1.0f, 1.0f],
							  cast(GLenum)GL_ARRAY_BUFFER, cast(GLenum)GL_DYNAMIC_DRAW);
	}

	void	updateMesh()
	{
		create();

		mMesh.vertices.updateArray(cast(GLfloat[])[
								   -mSize.x / 2.0f,	-mSize.y / 2.0f,	0.0f,
								    mSize.x / 2.0f,	-mSize.y / 2.0f,	0.0f,
								   -mSize.x / 2.0f,	 mSize.y / 2.0f,	0.0f,
								    mSize.x / 2.0f,	 mSize.y / 2.0f,	0.0f]);
	}

	bool			mUserSize;
	Vector2f32		mSize;
	Mesh			mMesh;
	Shader			mShader;
	ShaderProgram	mShaderProgram;
}
