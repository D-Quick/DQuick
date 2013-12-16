module dquick.media.font;

import derelict.freetype.ft;

import dquick.algorithms.atlas;
import dquick.media.image;

import dquick.maths.vector2s32;
import dquick.maths.vector2f32;
import dquick.maths.rect2s32;
import dquick.maths.color;

import std.stdio;
import std.string;
import std.typecons;
import std.c.string;	// for memcpy
import std.math;

import dquick.system.fontconfig.fontconfig;
import std.conv;

/**
* One Font per size and style
* kerning requested at runtime
* Notice that all glyph bitmap contains an extra border of 1 pixel large to avoid issue with filtering
**/

// TODO The font manager have to find fonts files in system folders
// The function FT_Open_Face may help to discover mFaces types (regular, italic, bold,...) registered in a font file
// http://www.freetype.org/freetype2/docs/reference/ft2-base_intermFace.html#FT_Open_Face
// http://forum.dlang.org/thread/kcqstrprmrzluvfoylqb@forum.dlang.org#post-fbojhpvgewysrrapfapw:40forum.dlang.org
// registry DB : HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft \Windows NT\CurrentVersion\Fonts

// TODO migrate FT_Library to FontManager (if it share memory)
// TODO check kerning computation it doesn't seems working fine
// TODO check glyph rendering quality

// It can be good to chech how gtk manage fontconfig under windows to do something more reliable

// http://www.freedesktop.org/software/fontconfig/fontconfig-user.html

class FontManager
{
public:
	ref Font	getFont(in string family, in Font.Style style, in int size)
	{
		string	fontKey;
		Font*	font;

		fontKey = format("%s-%d", family, size);
		font = (fontKey in mFonts);
		if (font !is null)
			return *font;

		Font	newFont = new Font;

		newFont.load(fontPathFromFamily(family, style), style, size);
		mFonts[fontKey] = newFont;
		return *(fontKey in mFonts);
	}

	/// Use with caution, only next atlas creation will take the new size
	void	setAtlasSize(Vector2s32 size)
	{
		mAtlasSize = size;
	}

	Vector2s32	atlasSize()
	{
		return mAtlasSize;
	}

	Atlas	getAtlas(size_t index)
	{
		return mAtlases[index];
	}

	size_t	getAtlasCount()
	{
		return mAtlases.length;
	}

private:
	void	clear()	// used by unnitest to avoid conflict with applications
	{
		mAtlases.length = 0;
		mFonts.clear();
	}

	Atlas	lastAtlas()
	{
		if (mAtlases.length)
			return mAtlases[$ - 1];
		return newAtlas();
	}

	Atlas	newAtlas()
	{
		mAtlases.length = mAtlases.length + 1;

		mAtlases[$ - 1] = new Atlas;
		mAtlases[$ - 1].create(mAtlasSize);

		return mAtlases[$ - 1];
	}

	Atlas[]			mAtlases;
	Font[string]	mFonts;
	Vector2s32		mAtlasSize = Vector2s32(512, 512);
}

FontManager	fontManager;

class Font
{
public:
	enum Style
	{
		Regular = 0x00,	// 0 because Regular is the implicit style and couldn't be combined with others
		Bold = 0x01,
		Italic = 0x02
	}

	~this()
	{
		FT_Done_Face(mFace);
		FT_Done_FreeType(mLibrary);
	}

	Tuple!(Glyph, bool)	loadGlyph(uint charCode)
	{
		Glyph*	glyph;

		glyph = (charCode in mGlyphs);
		if (glyph !is null)
			return tuple(*glyph, true);

		// Load glyphs
		FT_Error		error;
		FT_Int32		flags = 0;
		FT_Glyph		ftGlyph;
		FT_GlyphSlot	ftGlyphSlot;
		FT_Bitmap		ftBitmap;
		FT_UInt			glyphIndex;
		size_t			depth;	// TODO replace x,y and width,height per Vector2s32
		Rect2s32		region;
		Atlas			imageAtlas = fontManager.lastAtlas();

		depth  = 1;	// TODO do something better (because it impact the quality of rendering)

		glyphIndex = FT_Get_Char_Index(mFace, charCode);
		// WARNING: We use texture-atlas depth to guess if user wants
		//          LCD subpixel rendering

		if (mOutlineType > 0)
			flags |= FT_LOAD_NO_BITMAP;
		else
			flags |= FT_LOAD_RENDER;

		if (!mHinting)
			flags |= FT_LOAD_NO_HINTING | FT_LOAD_NO_AUTOHINT;
		else
			flags |= FT_LOAD_FORCE_AUTOHINT;

		if (depth == 3)
		{
			FT_Library_SetLcdFilter(mLibrary, FT_LcdFilter.FT_LCD_FILTER_LIGHT);
			flags |= FT_LOAD_TARGET_LCD;
			if (mFiltering)
				FT_Library_SetLcdFilterWeights(mLibrary, mLcdWeights.ptr);
		}
		error = FT_Load_Glyph(mFace, glyphIndex, flags);
		if (error)
			throw new Exception(format("Failed to load glyph. Error : %d", error));

		if (mOutlineType == 0)
		{
			ftGlyphSlot = mFace.glyph;
			ftBitmap = ftGlyphSlot.bitmap;
		}
		else
		{
			FT_Stroker		stroker;
			FT_BitmapGlyph	ftBitmapGlyph;

			error = FT_Stroker_New(mLibrary, &stroker);
			if (error)
				throw new Exception(format("Failed to create stroker. Error : %d", error));
			scope(exit) FT_Stroker_Done(stroker);
			FT_Stroker_Set(stroker,
						   cast(int)(mOutlineThickness * 64),
						   FT_Stroker_LineCap.FT_STROKER_LINECAP_ROUND,
						   FT_Stroker_LineJoin.FT_STROKER_LINEJOIN_ROUND,
						   0);
			error = FT_Get_Glyph(mFace.glyph, &ftGlyph);
			if (error)
				throw new Exception(format("Failed to get glyph. Error : %d", error));

			if (mOutlineType == 1)
				error = FT_Glyph_Stroke(&ftGlyph, stroker, 1);
			else if (mOutlineType == 2)
				error = FT_Glyph_StrokeBorder(&ftGlyph, stroker, 0, 1);
			else if (mOutlineType == 3)
				error = FT_Glyph_StrokeBorder(&ftGlyph, stroker, 1, 1);
			if (error)
				throw new Exception(format("Failed to use stroker. Error : %d", error));

			if (depth == 1)
			{
				error = FT_Glyph_To_Bitmap(&ftGlyph, FT_Render_Mode.FT_RENDER_MODE_NORMAL, null, 1);
				if (error)
					throw new Exception(format("Failed to convert glyph as bitmap. Error : %d", error));
			}
			else
			{
				error = FT_Glyph_To_Bitmap(&ftGlyph, FT_Render_Mode.FT_RENDER_MODE_LCD, null, 1);
				if (error)
					throw new Exception(format("Failed to convert glyph as bitmap. Error : %d", error));
			}
			ftBitmapGlyph = cast(FT_BitmapGlyph)ftGlyph;
			ftBitmap = ftBitmapGlyph.bitmap;
		}

		region = imageAtlas.allocateRegion(ftBitmap.width + 2, ftBitmap.rows + 2);
		if (region.x < 0)
		{
			throw new Exception("Texture atlas is full. Instanciate a new one isn't supported yet");	// TODO
			//			continue;
		}

		mGlyphs[charCode] = Glyph();
		glyph = (charCode in mGlyphs);

		with (*glyph)
		{
			atlasRegion			= region;
			outlineType			= mOutlineType;
			outlineThickness	= mOutlineThickness;
			offset.x			= mFace.glyph.bitmap_left;
			offset.y			= mFace.glyph.bitmap_top;
		}

		// Discard hinting to get advance
		FT_Load_Glyph(mFace, glyphIndex, FT_LOAD_RENDER | FT_LOAD_NO_HINTING);
		ftGlyphSlot = mFace.glyph;
		glyph.advance = Vector2f32(ftGlyphSlot.advance.x >> 6, ftGlyphSlot.advance.y >> 6);

		FT_Done_Glyph(ftGlyph);

		blitGlyph(ftBitmap, *glyph);

		return tuple(*glyph, false);
	}

	float	height()
	{
		return mHeight;
	}

	float	linegap()
	{
		return mLinegap;
	}

	string	filePath()
	{
		return mFilePath;
	}

	/// it's a negative value
	float	underLinePosition()
	{
		return mUnderlinePosition;
	}

	float	underLineThickness()
	{
		return mUnderlineThickness;
	}

	string	family()
	{
		return mFamily;
	}

	Vector2f32	kerning(uint previousCharacter, uint currentCharacter)
	{
		FT_Error	error;
		FT_Vector	kerning;

		if (mFace == null)
			Vector2f32(0.0f, 0.0f);

		error = FT_Get_Kerning(mFace, previousCharacter, currentCharacter, FT_Kerning_Mode.FT_KERNING_DEFAULT, &kerning);
		if (error > 0)
			throw new Exception("Failed to retrieve kerning.");
		return	Vector2f32(kerning.x >> 6, kerning.y >> 6);
	}

private:
	void	load(in string filePath, in Font.Style style, in int size)
	{
		mFilePath = filePath;
		mSize = size;

		FT_Error		error;
		size_t			hres = 64;
/*		FT_Matrix		matrix = {cast(int)((1.0 / hres) * 0x10000L),
		cast(int)((0.0) * 0x10000L),
		cast(int)((0.0) * 0x10000L),
		cast(int)((1.0) * 0x10000L)};*/

		error = FT_Init_FreeType(&mLibrary);
		if (error)
			throw new Exception(format("Failed to initialize FreeType mLibrary. Error : %d", error));

		error = FT_New_Face(mLibrary, filePath.toStringz(), 0, &mFace);
		if (error)
			throw new Exception(format("Failed to load face \"%s\". Error : %d", filePath, error));

		error = FT_Select_Charmap(mFace, FT_Encoding.FT_ENCODING_UNICODE);
		if (error)
			throw new Exception(format("Failed to select charmap. Error : %d", error));

//		error = FT_Set_Char_Size(mFace, size * 64, 0, 72 * hres, 72);
		error = FT_Set_Pixel_Sizes(mFace, 0, size);
		if (error)
			throw new Exception(format("Failed to select charmap. Error : %d", error));

//		FT_Set_Transform(mFace, &matrix, null);

		mUnderlinePosition = mFace.underline_position / cast(float)mSize;
		mUnderlinePosition = round(mUnderlinePosition);
		if (mUnderlinePosition > -2)
			mUnderlinePosition = -2.0;

		mUnderlineThickness = mFace.underline_thickness / cast(float)mSize;
		mUnderlineThickness = round(mUnderlineThickness);
		if (mUnderlineThickness < 1)
			mUnderlineThickness = 1.0;

		mAscender = mFace.size.metrics.ascender >> 6;
		mDescender = mFace.size.metrics.descender >> 6;
		mHeight = mFace.size.metrics.height >> 6;
		mLinegap = mHeight /* - mAscender + mDescender*/;
	}

	void	blitGlyph(const ref FT_Bitmap ftBitmap, ref Glyph glyph)
	{
		glyph.image = new Image;
		glyph.image.create("", glyph.atlasRegion.width, glyph.atlasRegion.height, Image.Format.RGBA);

		glyph.image.fill(Color(1.0f, 1.0f, 1.0f, 0.0f), Vector2s32(0, 0), Vector2s32(glyph.atlasRegion.width, glyph.atlasRegion.height));

		assert(glyph.atlasRegion.width == ftBitmap.width + 2);
		assert(glyph.atlasRegion.height == ftBitmap.rows + 2);

		size_t	depth;
		uint	x = 1;
		uint	y = 1;

		depth = glyph.image.nbBytesPerPixel;
		for (size_t i = 0; i < ftBitmap.width; i++)
			for (size_t j = 0; j < ftBitmap.rows; j++)
			{
				ubyte	color[4];

				color[0] = 0;
				color[1] = 0;
				color[2] = 0;
				color[3] = ftBitmap.buffer[j * ftBitmap.pitch + i];
				memcpy(glyph.image.pixels + ((y + j) * (ftBitmap.width + 2) + (x + i)) * depth,
					   color.ptr,
					   color.sizeof);
			}
	}

	Glyph[uint]	mGlyphs;

	FT_Library		mLibrary;
	FT_Face			mFace;

    string	mFilePath;
	string	mFamily;	// TODO Set it

    float	mSize;
    int		mHinting;
    int		mOutlineType;	// (0 = None, 1 = line, 2 = inner, 3 = outer)
    float	mOutlineThickness;
    int		mFiltering;
    ubyte	mLcdWeights[5];

    float	mHeight;
    float	mLinegap;
    float	mAscender;
    float	mDescender;
    float	mUnderlinePosition;
    float	mUnderlineThickness;
}

// http://www.freetype.org/freetype2/docs/tutorial/step2.html
struct Glyph
{
    Vector2f32	offset;
    Vector2f32	advance;
    int			outlineType;
    float		outlineThickness;

	size_t		atlasIndex;
	Rect2s32	atlasRegion;	// TODO check redundancy with width and height
	Image		image;
}

private FcConfig*	config;

shared static this()
{
	writeln("dquick.media.font : shared static this()");
/*	version (Windows)	// Set environment variables FONTCONFIG_FILE and FONTCONFIG_PATH, without fontconfig won't be able to locate default configuration
	{	// Doesn't work
		import std.process;

		environment["FONTCONFIG_FILE"] = "dquick/fontconfig/fonts.conf";
		environment["FONTCONFIG_PATH"] = "dquick/fontconfig";
	}*/

	DerelictFontConfig.load();
	if (FcInit() == FcFalse)
		throw new Exception("[FontManager] Unable to initialiaze fontconfig library.");
	version (Windows)
	{
		//FcConfigParseAndLoad(config, "dquick/fontconfig/fonts.conf", FcTrue);	// TODO See why it doesn't work (an absolute path doesn't help)
		if (FcConfigAppFontAddDir(null, getFontFolder().toStringz()) == FcFalse)
			throw new Exception("[FontManager] Fontconfig failed to scan fonts directory.");
	}
	else
		config = FcInitLoadConfigAndFonts();

	DerelictFT.load();

	fontManager = new FontManager;
}

shared static ~this()
{
	writeln("dquick.media.font : shared static ~this()");
	DerelictFT.unload();
	FcFini();
	DerelictFontConfig.unload();
}

/// Return the default font folder
version(Windows)
{
	import std.windows.registry;

	string	getFontFolder()
	{
		string	fontPath;

		Key		key;

		// http://msdn.microsoft.com/en-us/library/windows/desktop/bb762188%28v=vs.85%29.aspx
		/*		PWSTR	fontPathBuffer;
		scope(exit) CoTaskMemFree(fontPathBuffer);
		if (SHGetKnownFolderPath(FOLDERID_Fonts, 0, NULL, &fontPathBuffer) != S_OK)
		throw new Exception("Unable to determine the font folder.");
		fontPath = ;
		*/

		// TODO use SHGetKnownFolderPath with FOLDERID_Fonts in place of direct registry access
		key = Registry.currentUser().getKey("Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders");
		fontPath = key.getValue("Fonts").value_EXPAND_SZ();
		return fontPath;
	}
}

string	fontPathFromFamily(in string family, in Font.Style style = Font.Style.Regular)
{
	string	fontPath;
	string	fontFileName;
	string	pattern;

	pattern = family;
	if (style & Font.Style.Bold)
		pattern ~= ":bold";
	if (style & Font.Style.Italic)
		pattern ~= ":italic";

	// configure the search pattern, 
	// assume "family" is a std::string with the desired font family in it
	FcPattern*	pat = FcNameParse(pattern.toStringz());

	scope(exit) FcPatternDestroy(pat);

	FcConfigSubstitute(config, pat, FcMatchKind.FcMatchPattern);
	FcDefaultSubstitute(pat);

	// find the font
	FcResult	result;
	FcPattern*	font = FcFontMatch(config, pat, &result);

	scope(exit) FcPatternDestroy(font);
	if (font)
	{
		FcChar8*	file = null;
		if (FcPatternGetString(font, FC_FILE, 0, &file) == FcResult.FcResultMatch)
		{
			// save the file to another std::string
			fontPath = to!string(file);
		}
	}
	return fontPath;
}

/// Return all font families available
string[]	getSystemFonts()
{
	string[string]	fontFiles;

	FcPattern*		pat = FcPatternCreate();
	FcObjectSet*	os = FcObjectSetBuild (FC_FAMILY, FC_STYLE, FC_LANG, FC_FILE, null);
	FcFontSet*		fs = FcFontList(config, pat, os);

//	writefln("Total matching fonts: %d\n", fs.nfont);
	for (int i = 0; fs && i < fs.nfont; i++)
	{
		FcPattern*	font = fs.fonts[i];
		FcChar8*	file, style, family;

		if (FcPatternGetString(font, FC_FILE, 0, &file) == FcResult.FcResultMatch &&
			FcPatternGetString(font, FC_FAMILY, 0, &family) == FcResult.FcResultMatch &&
			FcPatternGetString(font, FC_STYLE, 0, &style) == FcResult.FcResultMatch)
		{
			fontFiles[to!string(family)] = to!string(file);
//			writefln("Filename: %s (family %s, style %s)", to!string(file), to!string(family), to!string(style));
		}
	}
	if (fs)
		FcFontSetDestroy(fs);

	return fontFiles.keys();
}

private string	remove(in string source, in string str)
{
	ptrdiff_t	pos;
	if ((pos = source.indexOf(str)) != -1)
		return strip(source[0..pos] ~ source[pos + str.length..$]);
	return source;
}

unittest
{
	version(Windows)
	{
		assert(icmp(fontPathFromFamily("Arial"), "C:/Windows/Fonts/arial.ttf") == 0 || icmp(fontPathFromFamily("Arial"), "C:/Windows/Fonts/Arialtbg.ttf") == 0);
		assert(icmp(fontPathFromFamily("arial"), "C:/Windows/Fonts/arial.ttf") == 0 || icmp(fontPathFromFamily("arial"), "C:/Windows/Fonts/Arialtbg.ttf") == 0);	// Test with wrong case
		assert(fontPathFromFamily("Arial", Font.Style.Bold | Font.Style.Italic) == "C:/Windows/Fonts/arialbi.ttf");
		assert(fontPathFromFamily("Andalus", Font.Style.Bold) == "C:/Windows/Fonts/andlso.ttf");	// There is no bold file for this font, so the same file as for regular must be returned (because it can contains bold layout)
	}
	writeln(getSystemFonts());
	writeln(getSystemFonts().length);
}

// TODO make unnittest using resource manager to share image atlas between us and applications (throw TextItem)
// it's certainly better than the call of fontManager.clear()
unittest
{
	Font	font;
	string	text;

	Image[]	images;

	font = fontManager.getFont("Times New Roman", Font.Style.Regular, 36);
	text = "Iñtërnâtiônàlizætiøn";

	Image		textImage;
	Vector2f32	cursor;

	cursor.x = 0;
	cursor.y = /*cast(int)font.linegap*/ 36;
	textImage = new Image;
	textImage.create("", 500, 100, Image.Format.RGBA);
	textImage.fill(Color(1.0f, 1.0f, 1.0f, 0.0f), Vector2s32(0, 0), textImage.size());

	foreach (dchar charCode; text)
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
									 Image.Format.RGBA);
				images[$ - 1].fill(Color(1.0f, 1.0f, 1.0f, 1.0f), Vector2s32(0, 0), images[$ - 1].size());
			}

			// Write glyph in image
			images[glyph.atlasIndex].blit(glyph.image,
										  Vector2s32(0, 0),
										  Vector2s32(glyph.atlasRegion.width, glyph.atlasRegion.height),
										  Vector2s32(glyph.atlasRegion.x, glyph.atlasRegion.y));
		}

		Vector2f32	pos;

		pos.x = glyph.offset.x;
		pos.y = -glyph.offset.y;
		textImage.blit(glyph.image,
					   Vector2s32(0, 0),
					   Vector2s32(glyph.atlasRegion.width, glyph.atlasRegion.height),
					   Vector2s32(cast(int)round(cursor.x + pos.x), cast(int)round(cursor.y + pos.y)));
		cursor.x = cursor.x + glyph.advance.x;
	}

	textImage.save("../data/FontTestText.png");

	fontManager.clear();
}
