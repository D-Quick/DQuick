module dquick.renderer2D.openGL.borderRectangleVertices;

import dquick.renderer3D.openGL.renderer;
import dquick.renderer3D.openGL.texture;
import dquick.renderer3D.openGL.shader;
import dquick.renderer3D.openGL.shaderProgram;
import dquick.renderer3D.openGL.VBO;
import dquick.renderer3D.openGL.util;
import dquick.renderer3D.openGL.renderer;
import dquick.renderer3D.openGL.mesh;

import dquick.maths.color;
import dquick.maths.vector2s32;
import dquick.maths.vector2f32;

import derelict.opengl3.gl;

import std.stdio;
import std.variant;
import std.math;

/// Implementation based on multiplication of vertices for repeat and round TileMode

// TODO Add the possibility to update colors and texcoords
// TODO Implement TileMode switch
// TODO use triangle strip

struct BorderRectangleVertices
{
public:
	enum	TileMode
	{
		Stretch,
		Repeat,
		Round,
	}

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

	@property void	borderLeft(int value)
	{
		mLeftBorder = value;
		updateMesh();
	}
	@property int	borderLeft() {return mLeftBorder;}

	@property void	borderRight(int value)
	{
		mRightBorder = value;
		updateMesh();
	}
	@property int	borderRight() {return mRightBorder;}

	@property void	borderTop(int value)
	{
		mTopBorder = value;
		updateMesh();
	}
	@property int	borderTop() {return mTopBorder;}

	@property void	borderBottom(int value)
	{
		mBottomBorder = value;
		updateMesh();
	}
	@property int	borderBottom() {return mBottomBorder;}

	// TODO
	@property void	horizontalTileMode(TileMode mode)
	{
		mHorizontalTileMode = mode;
		updateMesh();
	}
	@property void	verticalTileMode(TileMode mode)
	{
		mVerticalTileMode = mode;
		updateMesh();
	}

	void	draw()
	{
		mMesh.draw();
	}

private:
	void	create()	// Safe to call it if mesh is already created
	{
		if (mMesh)
			return;

		Variant[] options;

		options ~= Variant(import("rectangle.vert"));
		options ~= Variant(import("rectangle.frag"));
		mMesh = new Mesh();
		mShader = dquick.renderer3D.openGL.renderer.resourceManager.getResource!Shader("rectangle", options);
		mShaderProgram.program = mShader.getProgram();
		mMesh.setShader(mShader);
		mMesh.setShaderProgram(mShaderProgram);

		mMesh.indexes.setArray(indexesArray(), cast(GLenum)GL_ELEMENT_ARRAY_BUFFER, cast(GLenum)GL_DYNAMIC_DRAW);
		mMesh.vertices.setArray(verticesArray(), cast(GLenum)GL_ARRAY_BUFFER, cast(GLenum)GL_DYNAMIC_DRAW);
		mMesh.texCoords.setArray(texCoordArray(), cast(GLenum)GL_ARRAY_BUFFER, cast(GLenum)GL_DYNAMIC_DRAW);
		mMesh.colors.setArray(colorsArray(), cast(GLenum)GL_ARRAY_BUFFER, cast(GLenum)GL_DYNAMIC_DRAW);
	}

	void	updateMesh()
	{
		create();

		mMesh.vertices.updateArray(verticesArray());
		mMesh.texCoords.updateArray(texCoordArray());
	}

private:
	Vector2s32	quadNumbers()
	{
		Vector2s32	result;

		final switch (mHorizontalTileMode)
		{
		case TileMode.Stretch:
			result.x = 1;
			break;
		case TileMode.Repeat:
			result.x = cast(int)ceil(cast(float)(mSize.x - mLeftBorder - mRightBorder) / cast(float)(mMesh.texture().size().x  - mLeftBorder - mRightBorder));
			break;
		case TileMode.Round:
			result.x = cast(int)floor(cast(float)(mSize.x - mLeftBorder - mRightBorder) / cast(float)(mMesh.texture().size().x  - mLeftBorder - mRightBorder));
			break;
		}

		final switch (mVerticalTileMode)
		{
		case TileMode.Stretch:
			result.x = 1;
			break;
		case TileMode.Repeat:
			result.y = cast(int)ceil(cast(float)(mSize.y - mTopBorder - mBottomBorder) / cast(float)(mMesh.texture().size().y  - mTopBorder - mBottomBorder));
			break;
		case TileMode.Round:
			result.y = cast(int)floor(cast(float)(mSize.y - mTopBorder - mBottomBorder) / cast(float)(mMesh.texture().size().y  - mTopBorder - mBottomBorder));
			break;
		}

		return result;
	}

	Vector2f32	quadSizes()
	{
		Vector2f32	result;

		return result;
	}

	GLuint[]	indexesArray()
	{
		return cast(GLuint[])[
			0,	1,	4,	1,	5,	4,	// TopLeft quad
			1,	2,	5,	2,	6,	5,
			2,	3,	6,	3,	7,	6,
			4,	5,	8,	5,	9,	8,
			5,	6,	9,	6,	10,	9,
			6,	7,	10,	7,	11,	10,
			8,	9,	12,	9,	13,	12,
			9,	10,	13,	10,	14,	13,
			10,	11,	14,	11,	15,	14];
	}

	GLfloat[]	verticesArray()
	{
		GLfloat	rows[4];
		GLfloat	columns[4];

		rows[0] = 0.0f;
		rows[1] = rows[0] + mTopBorder;
		rows[3] = mSize.y;
		rows[2] = rows[3] - mBottomBorder;

		columns[0] = 0.0f;
		columns[1] = columns[0] + mLeftBorder;
		columns[3] = mSize.x;
		columns[2] = columns[3] - mRightBorder;

		return cast(GLfloat[])[
			columns[0], rows[0], 0.0f,
			columns[1], rows[0], 0.0f,
			columns[2], rows[0], 0.0f,
			columns[3], rows[0], 0.0f,

			columns[0], rows[1], 0.0f,
			columns[1], rows[1], 0.0f,
			columns[2], rows[1], 0.0f,
			columns[3], rows[1], 0.0f,

			columns[0], rows[2], 0.0f,
			columns[1], rows[2], 0.0f,
			columns[2], rows[2], 0.0f,
			columns[3], rows[2], 0.0f,

			columns[0], rows[3], 0.0f,
			columns[1], rows[3], 0.0f,
			columns[2], rows[3], 0.0f,
			columns[3], rows[3], 0.0f];
	}

	GLfloat[]	texCoordArray()
	{
		GLfloat	rows[4];
		GLfloat	columns[4];

		GLfloat	texWidth = 0.0f;
		GLfloat	texHeight = 0.0f;

		if (mMesh.texture())
		{
			texWidth = mMesh.texture().size().x;
			texHeight = mMesh.texture().size().y;
		}

		rows[0] = 0.0f;
		rows[1] = rows[0] + mTopBorder / texHeight;
		rows[3] = 1.0f;
		rows[2] = rows[3] - mBottomBorder / texHeight;

		columns[0] = 0.0f;
		columns[1] = columns[0] + mLeftBorder / texWidth;
		columns[3] = 1.0f;
		columns[2] = columns[3] - mRightBorder / texWidth;

		return cast(GLfloat[])[
			columns[0], rows[0],
			columns[1], rows[0],
			columns[2], rows[0],
			columns[3], rows[0],

			columns[0], rows[1],
			columns[1], rows[1],
			columns[2], rows[1],
			columns[3], rows[1],

			columns[0], rows[2],
			columns[1], rows[2],
			columns[2], rows[2],
			columns[3], rows[2],

			columns[0], rows[3],
			columns[1], rows[3],
			columns[2], rows[3],
			columns[3], rows[3]];
	}

	GLfloat[]	colorsArray()
	{
		GLfloat[]	array;

//		return array;
		return cast(GLfloat[])[
			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f,

			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f,

			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f,

			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f];
	}

	bool			mUserSize;
	Vector2f32		mSize = Vector2f32(0.0f, 0.0f);
	Mesh			mMesh;
	Shader			mShader;
	ShaderProgram	mShaderProgram;

	TileMode		mHorizontalTileMode = TileMode.Repeat;
	TileMode		mVerticalTileMode = TileMode.Repeat;
	int				mLeftBorder = 0;
	int				mRightBorder = 0;
	int				mTopBorder = 0;
	int				mBottomBorder = 0;
}
