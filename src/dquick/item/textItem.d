module dquick.item.textItem;

import dquick.item.graphicItem;
import dquick.media.font;
import dquick.media.image;
import dquick.renderer3D.openGL.mesh;
import dquick.renderer3D.openGL.texture;
import dquick.renderer3D.openGL.shader;
import dquick.renderer3D.openGL.shaderProgram;
import dquick.maths.vector2s32;
import dquick.maths.color;

import std.stdio;
import std.variant;
import std.typecons;
import std.string;
import std.math;
import std.uni;

// TODO Support pixel perfect render (check the matrix)
// TODO Optimize the generated mesh (strip it)
// TODO Add a markup system (merge meshes by texture, but limit their size for a good support of occluders)
// TODO Fix first character position when a line wrapping occurs just before (it seems there is a little residual offset coming from removed spaces)

// TODO Make Font a property (fontStyle, fontSize,... have to be in a struct)
// TODO Check vocabulary (family, bold,...)

// TODO Check how wrapping (WrapAnywhere and Wrap) works when there is no space for a character on a ligne (item width around 0)

class TextItem : GraphicItem
{
public:
	alias Font.Style	FontStyle;

	enum WrapMode
	{
		NoWrap,			/// (default) No wrapping will be performed. If the text contains insufficient newlines, then contentWidth will exceed a set width.
		WordWrap,		/// Wrapping is done on word boundaries only. If a word is too long, contentWidth will exceed a set width.
		WrapAnywhere,	/// Wrapping is done at any point on a line, even if it occurs in the middle of a word.
		Wrap			/// If possible, wrapping occurs at a word boundary; otherwise it will occur at the appropriate point on the line, even in the middle of a word.
	}

	this(DeclarativeItem parent = null)
	{
		super(parent);
		
		Variant[] options;

		options ~= Variant(import("rectangle.vert"));
		options ~= Variant(import("rectangle.frag"));
		mShaderProgram = new ShaderProgram();
		mShader = dquick.renderer3D.openGL.renderer.resourceManager.getResource!Shader("rectangle", options);
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
	@property void	family(string family)
 	{
		if (family.length)
			mFamily = family;
 		else
			mFamily = defaultFont;
 		mNeedRebuild = true;
		onFamilyChanged.emit(family);
 	}
	@property string	family() {return mFamily;}
	mixin Signal!(string) onFamilyChanged;
	
	@property void	fontSize(int size)
	{
		mFamilySize = size;
		mNeedRebuild = true;
		onFontSizeChanged.emit(size);
	}
	@property int	fontSize() {return mFamilySize;}
	mixin Signal!(int) onFontSizeChanged;
	
	@property void	fontStyle(FontStyle family)
	{
		mFamilyStyle = family;
		mNeedRebuild = true;
		onFontStyleChanged.emit(family);
	}
	@property FontStyle	fontStyle() {return mFamilyStyle;}
	mixin Signal!(FontStyle) onFontStyleChanged;

	@property void	wrapMode(WrapMode mode)
	{
		mWrapMode = mode;
		mNeedRebuild = true;
		onWrapModeChanged.emit(mode);
	}
	@property WrapMode	wrapMode() {return mWrapMode;}
	mixin Signal!(WrapMode) onWrapModeChanged;

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
			if (mWrapMode != WrapMode.NoWrap)
				mNeedRebuild = true;
		}

		@property void	width(float width)
		{
			GraphicItem.width = width;
			if (mWrapMode != WrapMode.NoWrap)
				mNeedRebuild = true;
		}
		@property float	width() {return GraphicItem.width;}
		@property void	height(float height)
		{
			GraphicItem.height = height;
			if (mWrapMode != WrapMode.NoWrap)
				mNeedRebuild = true;
		}
		@property float	height() {return GraphicItem.height;}

		@property float	implicitWidth() {return mImplicitSize.x;}

		@property float	implicitHeight() {return mImplicitSize.y;}
	}

private:
	struct Line
	{
		Vector2f32		size = Vector2f32(0.0f, 0.0f);
		Glyph[]			glyphes;
		Vector2f32[]	offsets;	// Offsets of glyphes, y need to be added to the verticalCursor value
		float			verticalCursor = 0.0f;	// Global vertical offset for the line
		float			maxHeightUnderOrigin = 0.0f;	// Used to compute implicitHeight
	}

	// TODO Use resource manager to update texture atlas, textures have to be shared between all TextItems
	void	rebuildMesh()
	{
		mNeedRebuild = false;
		clear(mMesh);
		if (!mText.length)
			return;

		Line[]	lines;
		mImplicitSize = Vector2f32(0.0f, 0.0f);

		bool	updateTexture = false;	// True if a new glyph is loaded (this is a little optimization)

		try
		{
			string[]	words = splitToConservativesWords(mText);

			Font	font;

			font = fontManager.getFont(mFamily, mFamilyStyle, mFamilySize);

			Vector2f32	cursor;
			bool		newLineStarted = true;
			dchar		prevCharCode;
			Vector2f32	pos;

			void	startNewLine(size_t wordIndex)
			{
				cursor.x = 0.0f;
				cursor.y = cursor.y + cast(int)font.linegap();
				newLineStarted = true;
				lines ~= Line();
				pos.x = 0.0f;
			}

			Glyph	getGlyph(dchar charCode)
			{
				Tuple!(Glyph, bool)	glyphTuple;
				Glyph				glyph;
				bool				alreadyLoaded;

				glyphTuple = font.loadGlyph(charCode);
				glyph = glyphTuple[0];
				alreadyLoaded = glyphTuple[1];

				if (glyph.atlasRegion.width == 0 || glyph.atlasRegion.height == 0)
					return glyph;

				if (!alreadyLoaded)
				{
					updateTexture = true;
					// Allocate image if need
					while (glyph.atlasIndex >= mImages.length)
					{
						mImages ~= new Image;
						mImages[$ - 1].create(format("ImageAtlas-%d", mImages.length),
											  fontManager.getAtlas(mImages.length - 1).size().x,
											  fontManager.getAtlas(mImages.length - 1).size().y,
											  Image.Format.RGBA);
						mImages[$ - 1].fill(Color(1.0f, 1.0f, 1.0f, 1.0f), Vector2s32(0, 0), mImages[$ - 1].size());
					}

					// Write glyph in image
					mImages[glyph.atlasIndex].blit(glyph.image,
												   Vector2s32(0, 0),
												   Vector2s32(glyph.atlasRegion.width, glyph.atlasRegion.height),
												   Vector2s32(glyph.atlasRegion.x, glyph.atlasRegion.y));
				}
				return glyph;
			}

			cursor.x = 0;
			cursor.y = cast(int)font.linegap /*mFamilySize*/;

			lines ~= Line();
			size_t	previousWordIndex = -1;
			foreach (size_t wordIndex, word; words)
			{
				foreach (dchar charCode; word)
				{
					Glyph	glyph;

					if (charCode == '\r')
					{
					}
					else if (charCode == '\n')
						startNewLine(wordIndex);
					else
					{
						if (cursor.x == 0.0f && isWhite(charCode)
							&& !(word[0] == '\r' || word[0] == '\n' || wordIndex == 0))	// We let starting spaces if it comes from the user
							break;

						glyph = getGlyph(charCode);

						pos.x = 0.0f;
						pos.y = -glyph.offset.y;

						if (!newLineStarted)
						{
							pos.x = glyph.offset.x;
							if (mKerning)
								pos.x = pos.x + font.kerning(prevCharCode, charCode).x;
						}

						final switch (mWrapMode)
						{
							case WrapMode.NoWrap:		// (default) No wrapping will be performed. If the text contains insufficient newlines, then contentWidth will exceed a set width.
								break;
							case WrapMode.Wrap:			// If possible, wrapping occurs at a word boundary; otherwise it will occur at the appropriate point on the line, even in the middle of a word.
								{
									float	advance = 0.0f;
									foreach (dchar charCode; word)
										advance += getGlyph(charCode).advance.x;
									if (advance > mSize.x && lines[$ - 1].size.x + pos.x + glyph.advance.x > mSize.x)	// word is longuer than item width, so we cut it (works if a word need to be written on multiple line)
										startNewLine(wordIndex);
								}
								goto case WrapMode.WordWrap;	// At this point we are compatible with the WordWrap mode (that why break isn't necessary)
							case WrapMode.WordWrap:		// Wrapping is done on word boundaries only. If a word is too long, contentWidth will exceed a set width.
								if (wordIndex != previousWordIndex)
								{
									float	advance = 0.0f;
									foreach (dchar charCode; word)
										advance += getGlyph(charCode).advance.x;
									if (lines[$ - 1].size.x + pos.x + advance > mSize.x)
										startNewLine(wordIndex);
									previousWordIndex = wordIndex;
								}
								break;
							case WrapMode.WrapAnywhere:	// Wrapping is done at any point on a line, even if it occurs in the middle of a word.
								if (lines[$ - 1].size.x + pos.x + glyph.advance.x > mSize.x)
									startNewLine(wordIndex);
								break;
						}

						// Update Line struct data
						if (!isWhite(charCode))
						{
							lines[$ - 1].glyphes ~= glyph;
							lines[$ - 1].offsets ~= Vector2f32(cursor.x + pos.x, pos.y);
							if (lines[$ - 1].verticalCursor < cursor.y)
								lines[$ - 1].verticalCursor = cursor.y;
						}

						lines[$ - 1].size.x = cursor.x + pos.x + glyph.advance.x;
						if (lines[$ - 1].size.y < font.linegap())
							lines[$ - 1].size.y = font.linegap();
						// --

						float	heightUnderOrigin = -font.underLinePosition() + font.underLineThickness();

						if (lines[$ - 1].size.x > mImplicitSize.x)
							mImplicitSize.x = lines[$ - 1].size.x;
						if (heightUnderOrigin > lines[$ - 1].maxHeightUnderOrigin)
							lines[$ - 1].maxHeightUnderOrigin = heightUnderOrigin;

						if (!(newLineStarted && isWhite(charCode)))
							cursor.x = cursor.x + glyph.advance.x;
						newLineStarted = false;
						prevCharCode = charCode;
					}
				}
			}

			if (lines.length)
				mImplicitSize.y = lines[$ - 1].verticalCursor + lines[$ - 1].maxHeightUnderOrigin;	// TODO clean that, it's not really exact (a little margin is necessary for character that can be draw under the cursor like 'g')

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
			else if (updateTexture)	// We can only do an update
			{
				mTextures[0].update(mImages[0]);
			}
			// --

			mMesh.setTexture(mTextures[0]);
			
			onImplicitWidthChanged.emit(mImplicitSize.x);
			onImplicitHeightChanged.emit(mImplicitSize.y);		
		}
		catch (Exception e)
		{
			writeln(e.toString());
			clear(mMesh);
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
			tX,				1.0f - tY,
			tX + tWidth,	1.0f - tY,
			tX,				1.0f - (tY + tHeight),
			tX + tWidth,	1.0f - (tY + tHeight)];
		colors~= cast(GLfloat[])[
			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f,
			1.0f, 1.0f, 1.0f, 1.0f];
	}

	static const string	defaultFont = "Verdana";
	static const int	tabSize = 4;

	Vector2f32		mImplicitSize = Vector2f32(0.0f, 0.0f);

	bool			mNeedRebuild = true;
	Mesh			mMesh;
	Shader			mShader;
	ShaderProgram	mShaderProgram;
	string			mText;
	string			mFamily = defaultFont;
	int				mFamilySize = 24;
	FontStyle		mFamilyStyle = FontStyle.Regular;
	bool			mKerning = true;
	WrapMode		mWrapMode = WrapMode.NoWrap;

	static Image[]		mImages;
	static Texture[]	mTextures;
}

/// This function return an array of string that contains words (array of alphanumerical characters or white characters)
/// Notice that '\t' characters are transformed into spaces, number is depending on TextItem.spaceSize
string[]	splitToConservativesWords(in string text)
{
	string[]	textAsWords;
	bool		previousCharIsSpace = false;

	foreach (dchar charCode; text)
	{
		if (textAsWords.length == 0 || previousCharIsSpace != isWhite(charCode))	// Need to start a new word
			textAsWords ~= "";
		if (charCode == '\t')
			for (int i = 0; i < TextItem.tabSize; i++)
				textAsWords[$ - 1] ~= " ";
		else
			textAsWords[$ - 1] ~= charCode;

		previousCharIsSpace = isWhite(charCode);
	}
	return textAsWords;
}

unittest
{
	string[]	words;

	words = splitToConservativesWords("Un test  relativement\n\tsimple.");
	assert(words[0] == "Un");
	assert(words[1] == " ");
	assert(words[2] == "test");
	assert(words[3] == "  ");
	assert(words[4] == "relativement");
	assert(words[5] == "\n    ");
	assert(words[6] == "simple.");
}
