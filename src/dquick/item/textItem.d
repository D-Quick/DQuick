module dquick.item.text_item;

import dquick.item.graphic_item;
import dquick.media.font;
import dquick.media.image;
import dquick.renderer_3d.opengl.mesh;
import dquick.renderer_3d.opengl.texture;
import dquick.renderer_3d.opengl.shader;
import dquick.renderer_3d.opengl.shader_program;
import dquick.maths.vector2s32;
import dquick.maths.color;

import std.stdio;
import std.variant;
import std.typecons;
import std.string;
import std.math;
import std.uni;

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

	@property void	kerning(bool flag)
	{
		mKerning = flag;
		mNeedRebuild = true;
		onKerningChanged.emit(flag);
	}
	@property bool	kerning() {return mKerning;}
	mixin Signal!(bool) onKerningChanged;

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
		// TODO put mNeedRebuild at true only when wrapping is activated
		void	setSize(Vector2f32 size)
		{
			GraphicItem.setSize(size);
			mNeedRebuild = true;
		}

		@property void	width(float width) {GraphicItem.width = width; mNeedRebuild = true;}
		@property float	width() {return GraphicItem.width;}
		@property void	height(float height) {GraphicItem.height = height; mNeedRebuild = true;}
		@property float	height() {return GraphicItem.height;}
	}

private:
	struct Line
	{
		Vector2s32		size;
		Glyph[]			glyphes;
		Vector2f32[]	offsets;	// Offsets of glyphes, y need to be added to the verticalCursor value
		float			verticalCursor = 0.0f;	// Global vertical offset for the line
	}

	// TODO Use resource manager to update texture atlas, textures have to be shared between all TextItems
	void	rebuildMesh()
	{
		mNeedRebuild = false;
		mMesh = null;
		if (!mText.length)
			return;

		Line[]	lines;
		mImplicitSize = Vector2f32(0.0f, 0.0f);

		try
		{
			Font	font;

			font = fontManager.getFont(mFont, mFontSize);

			Vector2f32	cursor;
			bool		newLineStarted = true;
			dchar		prevCharCode;

			cursor.x = 0;
			cursor.y = cast(int)font.linegap /*mFontSize*/;

			lines ~= Line();
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
					lines ~= Line();
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
						while (glyph.atlasIndex >= mImages.length)
						{
							mImages ~= new Image;
							mImages[$ - 1].create(format("ImageAtlas-%d", mImages.length),
													fontManager.getAtlas(mImages.length - 1).size().x,
													fontManager.getAtlas(mImages.length - 1).size().y,
													4);
							mImages[$ - 1].fill(Color(1.0f, 1.0f, 1.0f, 1.0f), Vector2s32(0, 0), mImages[$ - 1].size());
						}

						// Write glyph in image
						mImages[glyph.atlasIndex].blit(glyph.image,
														Vector2s32(0, 0),
														Vector2s32(glyph.atlasRegion.width, glyph.atlasRegion.height),
														Vector2s32(glyph.atlasRegion.x, glyph.atlasRegion.y));
					}

					Vector2f32	pos;

					if (!newLineStarted)
					{
						pos.x = glyph.offset.x;
						if (mKerning)
							pos.x = pos.x + font.kerning(prevCharCode, charCode).x;
					}
					else
						pos.x = 0.0f;
					pos.y = -glyph.offset.y;

					// TODO set des data pour le mesh
					if (!isSpace(charCode))
					{
						lines[$ - 1].glyphes ~= glyph;
						lines[$ - 1].offsets ~= Vector2f32(cursor.x + pos.x, pos.y);
						if (lines[$ - 1].verticalCursor < cursor.y)
							lines[$ - 1].verticalCursor = cursor.y;
					}

					if (lines[$ - 1].size.y < font.linegap())
						lines[$ - 1].size.y = cast(int)round(font.linegap());
					// --

					cursor.x = cursor.x + glyph.advance.x;
					newLineStarted = false;
					prevCharCode = charCode;
				}
			}

			// Building the Mesh
			mMesh = new Mesh();
			mMesh.setShader(mShader);
			mMesh.setShaderProgram(mShaderProgram);

			GLuint[]	indexes;
			GLfloat[]	vertices;
			GLfloat[]	texCoords;
			GLfloat[]	colors;

			size_t		glyphIndex = 0;

			foreach (Line line; lines)
			{
				for (size_t i = 0; i < line.glyphes.length; i++)
				{
					addGlyphToMesh(indexes, vertices, texCoords, colors,
								   Vector2s32(cast(int)round(line.offsets[i].x), cast(int)round(line.verticalCursor + line.offsets[i].y)),
								   line.glyphes[i], glyphIndex, mImages[line.glyphes[i].atlasIndex].size());
					glyphIndex++;
				}
			}

			mMesh.indexes.setArray(indexes, cast(GLenum)GL_ELEMENT_ARRAY_BUFFER, cast(GLenum)GL_STATIC_DRAW);
			mMesh.vertices.setArray(vertices, cast(GLenum)GL_ARRAY_BUFFER, cast(GLenum)GL_STATIC_DRAW);
			mMesh.texCoords.setArray(texCoords, cast(GLenum)GL_ARRAY_BUFFER, cast(GLenum)GL_STATIC_DRAW);
			mMesh.colors.setArray(colors, cast(GLenum)GL_ARRAY_BUFFER, cast(GLenum)GL_STATIC_DRAW);

			// Update texture at the last moment
			if (mTextures.length < 0 + 1)	// Check if the textures array already contains the current atlas
			{
				Variant[]	options;
				options ~= Variant(mImages[0]);

				mTextures ~= new Texture();	// TODO do a loop to insert as many texture as needed
				mTextures[0].load(mImages[0].filePath(), options);
			}
			else	// We can only do an update
			{
				mTextures[0].update(mImages[0]);
			}
			// --

			mMesh.setTexture(mTextures[0]);
		}
		catch (Exception e)
		{
			writeln(e.toString());
			mMesh = null;
		}
	}

	void	addGlyphToMesh(ref GLuint[] indexes, ref GLfloat[] vertices, ref GLfloat[] texCoords, ref GLfloat[] colors, Vector2s32 origin, Glyph glyph, size_t glyphIndex, Vector2s32 atlasSize)
	{
		float	x, y, width, height;
		float	tX, tY, tWidth, tHeight;

		x = origin.x;
		y = origin.y;
		width = glyph.atlasRegion.width;
		height = glyph.atlasRegion.height;

		tX = cast(float)glyph.atlasRegion.x / cast(float)atlasSize.x;
		tY = cast(float)glyph.atlasRegion.y / cast(float)atlasSize.y;
		tWidth = cast(float)width / cast(float)atlasSize.x;
		tHeight = cast(float)height / cast(float)atlasSize.y;

		indexes ~= cast(GLuint[])[glyphIndex * 4 + 0, glyphIndex * 4 + 1, glyphIndex * 4 + 2, glyphIndex * 4 + 1, glyphIndex * 4 + 3, glyphIndex * 4 + 2];
		vertices ~= cast(GLfloat[])[
			x,			y,			0.0f,
			x + width,	y,			0.0f,
			x,			y + height,	0.0f,
			x + width,	y + height,	0.0f];
		texCoords ~= cast(GLfloat[])[// Don't forget opengl is down to top oriented (left-top corner = 0,1 coords)
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

	Vector2f32		mImplicitSize;

	bool			mNeedRebuild = true;
	Mesh			mMesh;
	Shader			mShader;
	ShaderProgram	mShaderProgram;
	string			mText;
	string			mFont = defaultFont;
	int				mFontSize = 24;
	FontFamily		mFontFamily = FontFamily.Regular;
	bool			mKerning = true;

	static Image[]		mImages;
	static Texture[]	mTextures;
}
