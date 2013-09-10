module dquick.item.text_item;

import dquick.item.graphic_item;
import dquick.media.font;
import dquick.media.image;
import dquick.renderer_3d.opengl.mesh;
import dquick.renderer_3d.opengl.shader;
import dquick.renderer_3d.opengl.shader_program;
import dquick.maths.vector2s32;
import dquick.maths.color;

import std.stdio;
import std.typecons;
import std.string;
import std.math;

// TODO Support pixel perfect render (check the matrix)
// TODO Support multiline
// TODO Optimize the generated mesh
// TODO Add a markup system (merge meshes by texture, but limit their size for a good support of occluders)
// TODO Find font by name and family

class TextItem : GraphicItem
{
public:
	alias Font.Family	FontFamily;

	this()
	{
		mShaderProgram = new ShaderProgram();
		mShader = dquick.renderer_3d.opengl.renderer.resourceManager.getResource!Shader("dquick/shaders/rectangle");
		mShaderProgram.setProgram(mShader.getProgram());
	}

	@property void	text(string text)
	{
		mText = text;
		mNeedRebuild = true;
		onTextChanged.emit(text);
	}
	@property string	text() {return mText;}
	mixin Signal!(string) onTextChanged;

	/// Giving an empty string will reset the default font
	@property void	font(string font)
	{
		if (font.length)
			mFont = font;
		else
			mFont = defaultFont;
		mNeedRebuild = true;
		onFontChanged.emit(font);
	}
	@property string	font() {return mFont;}
	mixin Signal!(string) onFontChanged;
	
	@property void	fontSize(int size)
	{
		mFontSize = size;
		mNeedRebuild = true;
		onFontSizeChanged.emit(size);
	}
	@property int	fontSize() {return mFontSize;}
	mixin Signal!(int) onFontSizeChanged;
	
	@property void	fontFamily(FontFamily family)
	{
		mFontFamily = family;
		mNeedRebuild = true;
		onFontFamilyChanged.emit(family);
	}
	@property FontFamily	fontFamily() {return mFontFamily;}
	mixin Signal!(FontFamily) onFontFamilyChanged;

	override
	void	paint(bool transformationUpdated)
	{
		startPaint(transformationUpdated);
		if (mNeedRebuild)
			rebuildMesh();
		if (mMesh !is null)
			mMesh.draw();
		paintChildren();
		endPaint();
	}

	override
	{
		void	setSize(Vector2f32 size)
		{
			GraphicItem.setSize(size);
		}

		@property void	width(float width) {GraphicItem.width = width;}
		@property float	width() {return GraphicItem.width;}
		@property void	height(float height) {GraphicItem.height = height;}
		@property float	height() {return GraphicItem.height;}
	}

private:
	// TODO Use resource manager to update texture atlas, textures have to be shared between all TextItems
	void	rebuildMesh()
	{
		mNeedRebuild = false;
		mMesh = null;
		if (!mText.length)
			return;

		try
		{
			Font	font;

			font = fontManager.getFont(mFont, mFontSize);

			mMesh = new Mesh();
			mMesh.setShader(mShader);
			mMesh.setShaderProgram(mShaderProgram);

			GLuint[]	indexes;
			GLfloat[]	vertices;
			GLfloat[]	texCoords;
			GLfloat[]	colors;

			Image[]	images;

			Vector2f32	cursor;
			bool		newLineStarted = true;
			size_t		glyphIndex;
			dchar		prevCharCode;

			cursor.x = 0;
			cursor.y = /*cast(int)font.linegap*/ mFontSize;

			foreach (dchar charCode; mText)
			{
				if (charCode == '\r')
				{
				}
				else if (charCode == '\n')
				{
					cursor.x = 0;
					cursor.y = cursor.y + cast(int)font.linegap();
					newLineStarted = true;
				}
				else
				{
					Tuple!(Glyph, bool)	glyphTuple;
					Glyph				glyph;
					bool				alreadyLoaded;

					glyphTuple = font.loadGlyph(charCode);
					glyph = glyphTuple[0];
					alreadyLoaded = glyphTuple[1];

					if (!alreadyLoaded)
					{
						// Allocate image if need
						while (glyph.atlasIndex >= images.length)
						{
							images ~= new Image;
							images[$ - 1].create(format("ImageAtlas-%d", images.length),
													fontManager.getAtlas(images.length - 1).size().x,
													fontManager.getAtlas(images.length - 1).size().y,
													4);
							images[$ - 1].fill(Color(1.0f, 1.0f, 1.0f, 1.0f), Vector2s32(0, 0), images[$ - 1].size());
						}

						// Write glyph in image
						images[glyph.atlasIndex].blit(glyph.image,
														Vector2s32(0, 0),
														Vector2s32(glyph.atlasRegion.width, glyph.atlasRegion.height),
														Vector2s32(glyph.atlasRegion.x, glyph.atlasRegion.y));
					}

					Vector2f32	pos;

					if (!newLineStarted)
						pos.x = glyph.offset.x + font.kerning(prevCharCode, charCode).x;
					else
						pos.x = 0.0f;
					pos.y = -glyph.offset.y;

					writeln(format("cursor %f %f", cursor.x, cursor.y));
					addGlyphToMesh(indexes, vertices, texCoords, colors,
								   Vector2s32(cast(int)round(cursor.x + pos.x), cast(int)round(cursor.y + pos.y)),
								   glyph, glyphIndex, images[glyph.atlasIndex]);

					cursor.x = cursor.x + glyph.advance.x;
					newLineStarted = false;
					prevCharCode = charCode;
					glyphIndex++;
				}
			}

			mMesh.indexes.setArray(indexes, cast(GLenum)GL_ELEMENT_ARRAY_BUFFER, cast(GLenum)GL_STATIC_DRAW);
			mMesh.vertices.setArray(vertices, cast(GLenum)GL_ARRAY_BUFFER, cast(GLenum)GL_STATIC_DRAW);
			mMesh.texCoords.setArray(texCoords, cast(GLenum)GL_ARRAY_BUFFER, cast(GLenum)GL_STATIC_DRAW);
			mMesh.colors.setArray(colors, cast(GLenum)GL_ARRAY_BUFFER, cast(GLenum)GL_STATIC_DRAW);
			mMesh.setTexture(images[0]);
		}
		catch (Exception e)
		{
			writeln(e.toString());
			mMesh = null;
		}
	}

	void	addGlyphToMesh(ref GLuint[] indexes, ref GLfloat[] vertices, ref GLfloat[] texCoords, ref GLfloat[] colors, Vector2s32 origin, Glyph glyph, size_t glyphIndex, ref Image atlas)
	{
		float	x, y, width, height;
		float	tX, tY, tWidth, tHeight;

		x = origin.x;
		y = origin.y;
		width = glyph.atlasRegion.width;
		height = glyph.atlasRegion.height;

		tX = cast(float)glyph.atlasRegion.x / cast(float)atlas.size().x;
		tY = cast(float)(atlas.size().y - glyph.atlasRegion.y) / cast(float)atlas.size().y;
		tWidth = cast(float)width / cast(float)atlas.size().x;
		tHeight = cast(float)height / cast(float)atlas.size().y;

		indexes ~= cast(GLuint[])[glyphIndex * 4 + 0, glyphIndex * 4 + 1, glyphIndex * 4 + 2, glyphIndex * 4 + 1, glyphIndex * 4 + 3, glyphIndex * 4 + 2];
		vertices ~= cast(GLfloat[])[
			x,			y,			0.0f,
			x + width,	y,			0.0f,
			x,			y + height,	0.0f,
			x + width,	y + height,	0.0f];
		texCoords ~= cast(GLfloat[])[
			tX,				tY,
			tX + tWidth,	tY,
			tX,				tY + tHeight,
			tX + tWidth,	tY + tHeight];
		colors~= cast(GLfloat[])[
			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f];
	}

	static const string	defaultFont = "Verdana";

	bool			mNeedRebuild = true;
	Mesh			mMesh;
	Shader			mShader;
	ShaderProgram	mShaderProgram;
	string			mText;
	string			mFont = defaultFont;
	int				mFontSize = 24;
	FontFamily		mFontFamily = FontFamily.Regular;
}