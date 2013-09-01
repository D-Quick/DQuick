module dquick.renderer_2d.opengl.font;

import derelict.freetype.ft;

import dquick.algorithms.atlas;
import dquick.media.image;

import dquick.maths.vector2s32;

import std.string;

// TODO The font manager have to find fonts files in system folders
// The function FT_Open_Face may help to discover faces types (regular, italic, bold,...) registered in a font file
// http://www.freetype.org/freetype2/docs/reference/ft2-base_interface.html#FT_Open_Face

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

private:
	struct	ImageAtlas
	{
		Atlas	atlas;
		Image	image;
	}

	ref ImageAtlas	lastAtlas()
	{
		if (mAtlases.length)
			return mAtlases[$];
		return newAtlas;
	}

	ref ImageAtlas	newAtlas()
	{
		mAtlases.length = mAtlases.length + 1;

		mAtlases[$ - 1].atlas.create(Vector2s32(512, 512));
		mAtlases[$ - 1].image = new Image;
		mAtlases[$ - 1].image.create(format("ImageAtlas-%d", mAtlases.length), mAtlases[$ - 1].atlas.size.x, mAtlases[$ - 1].atlas.size.y, 4);

		return mAtlases[$ - 1];
	}

	ImageAtlas[]	mAtlases;
	Font[string]	mFonts;
}

FontManager	fontManager;

struct Font
{
public:


private:
	void	load(string filePath, int size)
	{
		FT_Library		library;
		FT_Error		error;
		FT_Face			face;
		size_t			hres = 64;
/*		FT_Matrix		matrix = {cast(int)((1.0 / hres) * 0x10000L),
		cast(int)((0.0) * 0x10000L),
		cast(int)((0.0) * 0x10000L),
		cast(int)((1.0) * 0x10000L)};*/

		error = FT_Init_FreeType(&library);
		if (error)
			throw new Exception(format("Failed to initialize FreeType library. Error : %d", error));
		scope(exit) FT_Done_FreeType(library);

		error = FT_New_Face(library, filePath.toStringz(), 0, &face);
		if (error)
			throw new Exception(format("Failed to load face. Error : %d", error));
		scope(exit) FT_Done_Face(face);

		error = FT_Select_Charmap(face, FT_Encoding.FT_ENCODING_UNICODE);
		if (error)
			throw new Exception(format("Failed to select charmap. Error : %d", error));

//		error = FT_Set_Char_Size(face, size * 64, 0, 72 * hres, 72);
		error = FT_Set_Pixel_Sizes(face, 0, size);
		if (error)
			throw new Exception(format("Failed to select charmap. Error : %d", error));

//		FT_Set_Transform(face, &matrix, null);

		// Load glyphs
		FT_Glyph				ft_glyph;
		FT_GlyphSlot			slot;
		FT_Bitmap				ft_bitmap;
		FT_UInt					glyph_index;
		size_t					i, x, y, width, height, depth, w, h;	// TODO replace x,y and width,height per Vector2s32
		Glyph					glyph;
		Atlas.Region			region;
		size_t					missed = 0;
		FontManager.ImageAtlas	imageAtlas = fontManager.lastAtlas();

		width  = imageAtlas.image.width;
		height = imageAtlas.image.height;
		depth  = imageAtlas.image.nbBytesPerPixel;

/*		for (i = 0; i < face.num_glyphs; i++)
		{
			FT_Int32	flags = 0;
			int			ft_bitmap_width = 0;
			int			ft_bitmap_rows = 0;
			int			ft_bitmap_pitch = 0;
			int			ft_glyph_top = 0;
			int			ft_glyph_left = 0;

			glyph_index = FT_Get_Char_Index( face, charcodes[i] );
			// WARNING: We use texture-atlas depth to guess if user wants
			//          LCD subpixel rendering

			if( self.outline_type > 0 )
			{
				flags |= FT_LOAD_NO_BITMAP;
			}
			else
			{
				flags |= FT_LOAD_RENDER;
			}

			if( !self.hinting )
			{
				flags |= FT_LOAD_NO_HINTING | FT_LOAD_NO_AUTOHINT;
			}
			else
			{
				flags |= FT_LOAD_FORCE_AUTOHINT;
			}


			if( depth == 3 )
			{
				FT_Library_SetLcdFilter( library, FT_LCD_FILTER_LIGHT );
				flags |= FT_LOAD_TARGET_LCD;
				if( self.filtering )
				{
					FT_Library_SetLcdFilterWeights( library, self.lcd_weights );
				}
			}
			error = FT_Load_Glyph( face, glyph_index, flags );
			if( error )
			{
				fprintf( stderr, "FT_Error (line %d, code 0x%02x) : %s\n",
						__LINE__, FT_Errors[error].code, FT_Errors[error].message );
				FT_Done_Face( face );
				FT_Done_FreeType( library );
				return wcslen(charcodes)-i;
			}


			if( self.outline_type == 0 )
			{
				slot            = face.glyph;
				ft_bitmap       = slot.bitmap;
				ft_bitmap_width = slot.bitmap.width;
				ft_bitmap_rows  = slot.bitmap.rows;
				ft_bitmap_pitch = slot.bitmap.pitch;
				ft_glyph_top    = slot.bitmap_top;
				ft_glyph_left   = slot.bitmap_left;
			}
			else
			{
				FT_Stroker stroker;
				FT_BitmapGlyph ft_bitmap_glyph;
				error = FT_Stroker_New( library, &stroker );
				if( error )
				{
					fprintf(stderr, "FT_Error (0x%02x) : %s\n",
							FT_Errors[error].code, FT_Errors[error].message);
					FT_Done_Face( face );
					FT_Stroker_Done( stroker );
					FT_Done_FreeType( library );
					return 0;
				}
				FT_Stroker_Set( stroker,
							   cast(int)(self.outline_thickness *64),
							   FT_STROKER_LINECAP_ROUND,
							   FT_STROKER_LINEJOIN_ROUND,
							   0);
				error = FT_Get_Glyph( face.glyph, &ft_glyph);
				if( error )
				{
					fprintf(stderr, "FT_Error (0x%02x) : %s\n",
							FT_Errors[error].code, FT_Errors[error].message);
					FT_Done_Face( face );
					FT_Stroker_Done( stroker );
					FT_Done_FreeType( library );
					return 0;
				}

				if( self.outline_type == 1 )
				{
					error = FT_Glyph_Stroke( &ft_glyph, stroker, 1 );
				}
				else if ( self.outline_type == 2 )
				{
					error = FT_Glyph_StrokeBorder( &ft_glyph, stroker, 0, 1 );
				}
				else if ( self.outline_type == 3 )
				{
					error = FT_Glyph_StrokeBorder( &ft_glyph, stroker, 1, 1 );
				}
				if( error )
				{
					fprintf(stderr, "FT_Error (0x%02x) : %s\n",
							FT_Errors[error].code, FT_Errors[error].message);
					FT_Done_Face( face );
					FT_Stroker_Done( stroker );
					FT_Done_FreeType( library );
					return 0;
				}

				if( depth == 1)
				{
					error = FT_Glyph_To_Bitmap( &ft_glyph, FT_RENDER_MODE_NORMAL, 0, 1);
					if( error )
					{
						fprintf(stderr, "FT_Error (0x%02x) : %s\n",
								FT_Errors[error].code, FT_Errors[error].message);
						FT_Done_Face( face );
						FT_Stroker_Done( stroker );
						FT_Done_FreeType( library );
						return 0;
					}
				}
				else
				{
					error = FT_Glyph_To_Bitmap( &ft_glyph, FT_RENDER_MODE_LCD, 0, 1);
					if( error )
					{
						fprintf(stderr, "FT_Error (0x%02x) : %s\n",
								FT_Errors[error].code, FT_Errors[error].message);
						FT_Done_Face( face );
						FT_Stroker_Done( stroker );
						FT_Done_FreeType( library );
						return 0;
					}
				}
				ft_bitmap_glyph = cast(FT_BitmapGlyph) ft_glyph;
				ft_bitmap       = ft_bitmap_glyph.bitmap;
				ft_bitmap_width = ft_bitmap.width;
				ft_bitmap_rows  = ft_bitmap.rows;
				ft_bitmap_pitch = ft_bitmap.pitch;
				ft_glyph_top    = ft_bitmap_glyph.top;
				ft_glyph_left   = ft_bitmap_glyph.left;
				FT_Stroker_Done(stroker);
			}


			// We want each glyph to be separated by at least one black pixel
			// (for example for shader used in demo-subpixel.c)
			w = ft_bitmap_width/depth + 1;
			h = ft_bitmap_rows + 1;
			region = texture_atlas_get_region( self.atlas, w, h );
			if ( region.x < 0 )
			{
				missed++;
				fprintf( stderr, "Texture atlas is full (line %d)\n",  __LINE__ );
				continue;
			}
			w = w - 1;
			h = h - 1;
			x = region.x;
			y = region.y;
			texture_atlas_set_region( self.atlas, x, y, w, h,
									 ft_bitmap.buffer, ft_bitmap.pitch );

			glyph = texture_glyph_new( );
			glyph.charcode = charcodes[i];
			glyph.width    = w;
			glyph.height   = h;
			glyph.outline_type = self.outline_type;
			glyph.outline_thickness = self.outline_thickness;
			glyph.offset_x = ft_glyph_left;
			glyph.offset_y = ft_glyph_top;
			glyph.s0       = x/cast(float)width;
			glyph.t0       = y/cast(float)height;
			glyph.s1       = (x + glyph.width)/cast(float)width;
			glyph.t1       = (y + glyph.height)/cast(float)height;

			// Discard hinting to get advance
			FT_Load_Glyph( face, glyph_index, FT_LOAD_RENDER | FT_LOAD_NO_HINTING);
			slot = face.glyph;
			glyph.advance_x = slot.advance.x/64.0;
			glyph.advance_y = slot.advance.y/64.0;

			vector_push_back( self.glyphs, &glyph );

			if( self.outline_type > 0 )
			{
				FT_Done_Glyph( ft_glyph );
			}
		}
		FT_Done_Face( face );
		FT_Done_FreeType( library );
		texture_atlas_upload( self.atlas );
		texture_font_generate_kerning( self );
		return missed;*/
	}

	/**
	* Vector of glyphs contained in this font.
	*/
//    vector_t * glyphs;

    /**
	* Atlas structure to store glyphs data.
	*/
//    texture_atlas_t * atlas;

    /**
	* Font filename
	*/
//    char * filename;

    /**
	* Font size
	*/
//    float size;

    /**
	* Whether to use autohint when rendering font
	*/
//    int hinting;

    /**
	* Outline type (0 = None, 1 = line, 2 = inner, 3 = outer)
	*/
//    int outline_type;

    /**
	* Outline thickness
	*/
//    float outline_thickness;

    /** 
	* Whether to use our own lcd filter.
	*/
//    int filtering;

    /**
	* LCD filter weights
	*/
//    unsigned char lcd_weights[5];

    /**
	* This field is simply used to compute a default line spacing (i.e., the
	* baseline-to-baseline distance) when writing text with this font. Note
	* that it usually is larger than the sum of the ascender and descender
	* taken as absolute values. There is also no guarantee that no glyphs
	* extend above or below subsequent baselines when using this distance.
	*/
//    float height;

    /**
	* This field is the distance that must be placed between two lines of
	* text. The baseline-to-baseline distance should be computed as:
	* ascender - descender + linegap
	*/
//    float linegap;

    /**
	* The ascender is the vertical distance from the horizontal baseline to
	* the highest 'character' coordinate in a font face. Unfortunately, font
	* formats define the ascender differently. For some, it represents the
	* ascent of all capital latin characters (without accents), for others it
	* is the ascent of the highest accented character, and finally, other
	* formats define it as being equal to bbox.yMax.
	*/
//    float ascender;

    /**
	* The descender is the vertical distance from the horizontal baseline to
	* the lowest 'character' coordinate in a font face. Unfortunately, font
	* formats define the descender differently. For some, it represents the
	* descent of all capital latin characters (without accents), for others it
	* is the ascent of the lowest accented character, and finally, other
	* formats define it as being equal to bbox.yMin. This field is negative
	* for values below the baseline.
	*/
//    float descender;

    /**
	* The position of the underline line for this face. It is the center of
	* the underlining stem. Only relevant for scalable formats.
	*/
//    float underline_position;

    /**
	* The thickness of the underline for this face. Only relevant for scalable
	* formats.
	*/
//    float underline_thickness;
}

private struct Kerning
{
    /**
	* Left character code in the kern pair.
	*/
    uint charcode;

    /**
	* Kerning value (in fractional pixels).
	*/
    float kerning;

}

// http://www.freetype.org/freetype2/docs/tutorial/step2.html
struct Glyph
{
    /**
	* Wide character this glyph represents
	*/
    uint charcode;

    /**
	* Glyph's width in pixels.
	*/
    ushort width;

    /**
	* Glyph's height in pixels.
	*/
    ushort height;

    /**
	* Glyph's left bearing expressed in integer pixels.
	*/
    int offset_x;

    /**
	* Glyphs's top bearing expressed in integer pixels.
	*
	* Remember that this is the distance from the baseline to the top-most
	* glyph scanline, upwards y coordinates being positive.
	*/
    int offset_y;

    /**
	* For horizontal text layouts, this is the horizontal distance (in
	* fractional pixels) used to increment the pen position when the glyph is
	* drawn as part of a string of text.
	*/
    float advance_x;

    /**
	* For vertical text layouts, this is the vertical distance (in fractional
	* pixels) used to increment the pen position when the glyph is drawn as
	* part of a string of text.
	*/
    float advance_y;

    /**
	* A vector of kerning pairs relative to this glyph.
	*/
    Kerning kerning[];

    /**
	* Glyph outline type (0 = None, 1 = line, 2 = inner, 3 = outer)
	*/
    int outline_type;

    /**
	* Glyph outline thickness
	*/
    float outline_thickness;

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
	Font	font;

	font = fontManager.getFont("../data/samples/fonts/Vera.ttf", 12);
}
