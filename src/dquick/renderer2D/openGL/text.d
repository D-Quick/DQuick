module dquick.renderer_2d.opengl.text;

import dquick.renderer_2d.opengl.font;

import dquick.renderer_3d.opengl.renderer;
import dquick.renderer_3d.opengl.texture;
import dquick.renderer_3d.opengl.vbo;
import dquick.renderer_3d.opengl.util;
import dquick.renderer_3d.opengl.mesh;

import dquick.maths.color;
import dquick.maths.vector2f32;

struct Text
{
public:
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
}

// TODO create one big mesh internally before splitting it by textures. Cause of ImageAtlas some fonts can be on multiple textures.
// Restrict meshes size to a rectangle of something like 512x512 to be able to support very large texts. This will allow to draw
// smaller meshes when parts of texts are out of the view.
