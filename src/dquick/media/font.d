module dquick.renderer_2d.opengl.font;

import derelict.freetype.ft;

import dquick.algorithms.atlas;
import dquick.media.image;

import dquick.maths.vector2s32;

import std.string;
import std.typecons;
import std.c.string;	// for memcpy

/**
* One Font per size
* kerning requested at runtime
*
*
**/

// TODO The font manager have to find fonts files in system folders
// The function FT_Open_Face may help to discover mFaces types (regular, italic, bold,...) registered in a font file
// http://www.freetype.org/freetype2/docs/reference/ft2-base_intermFace.html#FT_Open_Face

// TODO migrate FT_Library to FontManager (if it share memory)

class FontManager
{
public:
	ref Font	getFont(string name, int size)
	{
		string	fontKey;
		Font*	font;

		fontKey = format("%s-%d", name.toStringz(), size);
		font = (fontKey in mFonts);
		if (font !is null)
			return *font;

		Font	newFont;

		newFont.load(name, size);
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

private:
	ref Atlas	lastAtlas()
	{
		if (mAtlases.length)
			return mAtlases[$ - 1];
		return newAtlas;
	}

	ref Atlas	newAtlas()
	{
		mAtlases.length = mAtlases.length + 1;

		mAtlases[$ - 1].create(mAtlasSize);

		return mAtlases[$ - 1];
	}

	Atlas[]			mAtlases;
	Font[string]	mFonts;
	Vector2s32		mAtlasSize = Vector2s32(512, 512);
}

FontManager	fontManager;

struct Font
{
public:
	~this()
	{
//		FT_Done_Face(mFace);
//		FT_Done_FreeType(mLibrary);
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
        int				ft_bitmap_width = 0;
        int				ft_bitmap_rows = 0;
        int				ft_bitmap_pitch = 0;
        int				ft_glyph_top = 0;
        int				ft_glyph_left = 0;
		FT_Glyph		ft_glyph;
		FT_GlyphSlot	slot;
		FT_Bitmap		ft_bitmap;
		FT_UInt			glyph_index;
		size_t			i, x, y, width, height, depth, w, h;	// TODO replace x,y and width,height per Vector2s32
		Atlas.Region	region;
		size_t			missed = 0;
		Atlas			imageAtlas = fontManager.lastAtlas();

		width  = imageAtlas.size().x;
		height = imageAtlas.size().y;
		depth  = 3;	// TODO do something better

		glyph_index = FT_Get_Char_Index(mFace, charCode);
		// WARNING: We use texture-atlas depth to guess if user wants
		//          LCD subpixel rendering

		if (outline_type > 0)
			flags |= FT_LOAD_NO_BITMAP;
		else
			flags |= FT_LOAD_RENDER;

		if (!hinting)
			flags |= FT_LOAD_NO_HINTING | FT_LOAD_NO_AUTOHINT;
		else
			flags |= FT_LOAD_FORCE_AUTOHINT;

		if (depth == 3)
		{
			FT_Library_SetLcdFilter(mLibrary, FT_LcdFilter.FT_LCD_FILTER_LIGHT);
			flags |= FT_LOAD_TARGET_LCD;
			if (filtering)
				FT_Library_SetLcdFilterWeights(mLibrary, lcd_weights.ptr);
		}
		error = FT_Load_Glyph(mFace, glyph_index, flags);
		if (error)
			throw new Exception(format("Failed to load glyph. Error : %d", error));

		if (outline_type == 0)
		{
			slot            = mFace.glyph;
			ft_bitmap       = slot.bitmap;
			ft_bitmap_width = slot.bitmap.width;
			ft_bitmap_rows  = slot.bitmap.rows;
			ft_bitmap_pitch = slot.bitmap.pitch;
			ft_glyph_top    = slot.bitmap_top;
			ft_glyph_left   = slot.bitmap_left;
		}
		else
		{
			FT_Stroker		stroker;
			FT_BitmapGlyph	ft_bitmap_glyph;
			error = FT_Stroker_New(mLibrary, &stroker);
			if (error)
				throw new Exception(format("Failed to create stroker. Error : %d", error));
			scope(exit) FT_Stroker_Done(stroker);
			FT_Stroker_Set(stroker,
						   cast(int)(outline_thickness *64),
						   FT_Stroker_LineCap.FT_STROKER_LINECAP_ROUND,
						   FT_Stroker_LineJoin.FT_STROKER_LINEJOIN_ROUND,
						   0);
			error = FT_Get_Glyph(mFace.glyph, &ft_glyph);
			if (error)
				throw new Exception(format("Failed to get glyph. Error : %d", error));

			if (outline_type == 1)
				error = FT_Glyph_Stroke(&ft_glyph, stroker, 1);
			else if (outline_type == 2)
				error = FT_Glyph_StrokeBorder(&ft_glyph, stroker, 0, 1);
			else if (outline_type == 3)
				error = FT_Glyph_StrokeBorder(&ft_glyph, stroker, 1, 1);
			if (error)
				throw new Exception(format("Failed to use stroker. Error : %d", error));

			if (depth == 1)
			{
				error = FT_Glyph_To_Bitmap(&ft_glyph, FT_Render_Mode.FT_RENDER_MODE_NORMAL, null, 1);
				if (error)
					throw new Exception(format("Failed to convert glyph as bitmap. Error : %d", error));
			}
			else
			{
				error = FT_Glyph_To_Bitmap(&ft_glyph, FT_Render_Mode.FT_RENDER_MODE_LCD, null, 1);
				if (error)
					throw new Exception(format("Failed to convert glyph as bitmap. Error : %d", error));
			}
			ft_bitmap_glyph = cast(FT_BitmapGlyph) ft_glyph;
			ft_bitmap       = ft_bitmap_glyph.bitmap;
			ft_bitmap_width = ft_bitmap.width;
			ft_bitmap_rows  = ft_bitmap.rows;
			ft_bitmap_pitch = ft_bitmap.pitch;
			ft_glyph_top    = ft_bitmap_glyph.top;
			ft_glyph_left   = ft_bitmap_glyph.left;
		}


		// We want each glyph to be separated by at least one black pixel
		// (for example for shader used in demo-subpixel.c)
		w = ft_bitmap_width / depth + 1;
		h = ft_bitmap_rows + 1;
		region = imageAtlas.allocateRegion(w, h);
		if (region.x < 0)
		{
			missed++;
			throw new Exception("Texture atlas is full. Instanciate a new one isn't supported yet");	// TODO
			//			continue;
		}
		w = w - 1;
		h = h - 1;
		x = region.x;
		y = region.y;

		mGlyphs[charCode] = Glyph();
		glyph = (charCode in mGlyphs);


		with (*glyph)
		{
			glyph.width			= w;
			glyph.height		= h;
			outline_type		= outline_type;
			outline_thickness	= outline_thickness;
			offset_x			= ft_glyph_left;
			offset_y			= ft_glyph_top;
			/*		s0					= x / cast(float)width;
			t0					= y / cast(float)height;
			s1					= (x + glyph.width) / cast(float)width;
			t1					= (y + glyph.height) / cast(float)height;*/
		}

		// Discard hinting to get advance
		FT_Load_Glyph(mFace, glyph_index, FT_LOAD_RENDER | FT_LOAD_NO_HINTING);
		slot = mFace.glyph;
		glyph.advance_x = slot.advance.x / 64.0;
		glyph.advance_y = slot.advance.y / 64.0;

		if (outline_type > 0)
			FT_Done_Glyph(ft_glyph);
		
		blitGlyph(ft_bitmap, *glyph);

		return tuple(*glyph, false);
	}

private:
	void	load(string filePath, int size)
	{
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
			throw new Exception(format("Failed to load mFace. Error : %d", error));

		error = FT_Select_Charmap(mFace, FT_Encoding.FT_ENCODING_UNICODE);
		if (error)
			throw new Exception(format("Failed to select charmap. Error : %d", error));

//		error = FT_Set_Char_Size(mFace, size * 64, 0, 72 * hres, 72);
		error = FT_Set_Pixel_Sizes(mFace, 0, size);
		if (error)
			throw new Exception(format("Failed to select charmap. Error : %d", error));

//		FT_Set_Transform(mFace, &matrix, null);
	}

	void	blitGlyph(const ref FT_Bitmap ft_bitmap, ref Glyph glyph)
	{
		/*		texture_atlas_set_region(atlas, x, y, w, h,
		ft_bitmap.buffer, ft_bitmap.pitch);
		*/
		glyph.image = new Image;
		glyph.image.create("", glyph.width, glyph.height, 3);	// TODO do something cleaner for depth (bytes per pixels)

		size_t i;
		size_t depth;
		uint	x = 0;
		uint	y = 0;

		depth = glyph.image.nbBytesPerPixel;
		for (i = 0; i < ft_bitmap.rows; i++)
		{
			memcpy(glyph.image.pixels + ((y + i) * glyph.width + x) * depth, 
				   ft_bitmap.buffer + (i * ft_bitmap.pitch), ft_bitmap.width * depth);
		}
	}

	Glyph[uint]	mGlyphs;

	FT_Library	mLibrary;
	FT_Face		mFace;

    string	filename;

    float	size;
    int		hinting;
    int		outline_type;	// (0 = None, 1 = line, 2 = inner, 3 = outer)
    float	outline_thickness;
    int		filtering;
    ubyte	lcd_weights[5];

    float	height;
    float	linegap;
    float	ascender;
    float	descender;
    float	underline_position;
    float	underline_thickness;
}

// http://www.freetype.org/freetype2/docs/tutorial/step2.html
struct Glyph
{
//    uint	charcode;
    uint	width;
    uint	height;
    int		offset_x;
    int		offset_y;
    float	advance_x;
    float	advance_y;
    int		outline_type;
    float	outline_thickness;

	size_t			atlasIndex;
	Atlas.Region	atlasRegion;	// TODO check redundancy with width and height
	Image			image;
}

shared static this()
{
	fontManager = new FontManager;

	DerelictFT.load();
}

shared static ~this()
{
	DerelictFT.unload();
}

unittest
{
/*	Font	font;
	string	text;

	Image[]	images;

	font = fontManager.getFont("../data/samples/fonts/Vera.ttf", 12);
	text = "Iñtërnâtiônàlizætiøn";

	foreach(dchar charCode; text)
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
									 3);
			}

			// Write glyph in image
			images[glyph.atlasIndex].blit(glyph.image,
										  Vector2s32(0, 0),
										  Vector2s32(glyph.width, glyph.height),
										  Vector2s32(glyph.atlasRegion.x, glyph.atlasRegion.y));
		}
	}

	images[0].save("../data/FontTestResult.bmp");*/
}
