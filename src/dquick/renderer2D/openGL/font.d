module dquick.renderer_2d.opengl.font;

struct Font
{
public:
	static Font*	create(string filePath, int size);

	/**
	* This function creates a new texture font from given filename and size.  The
	* texture atlas is used to store glyph on demand. Note the depth of the atlas
	* will determine if the font is rendered as alpha channel only (depth = 1) or
	* RGB (depth = 3) that correspond to subpixel rendering (if available on your
	* freetype implementation).
	*
	* @param atlas     A texture atlas
	* @param filename  A font filename
	* @param size      Size of font to be created (in points)
	*
	* @return A new empty font (no glyph inside yet)
	*
	*/
//	texture_font_t *texture_font_new( texture_atlas_t * atlas, const char * filename, const float size );


	/**
	* Delete a texture font. Note that this does not delete the glyph from the
	* texture atlas.
	*
	* @param self a valid texture font
	*/
//	void texture_font_delete( texture_font_t * self );


	/**
	* Request a new glyph from the font. If it has not been created yet, it will
	* be. 
	*
	* @param self     A valid texture font
	* @param charcode Character codepoint to be loaded.
	*
	* @return A pointer on the new glyph or 0 if the texture atlas is not big
	*         enough
	*
	*/
//	texture_glyph_t *texture_font_get_glyph( texture_font_t * self, wchar_t charcode );


	/**
	* Request the loading of several glyphs at once.
	*
	* @param self     A valid texture font
	* @param charcode Character codepoints to be loaded.
	*
	* @return Number of missed glyph if the texture is not big enough to hold
	*         every glyphs.
	*/
//	size_t texture_font_load_glyphs( texture_font_t * self, const wchar_t * charcodes );

	/**
	* Get the kerning between two horizontal glyphs.
	*
	* @param self      a valid texture glyph
	* @param charcode  codepoint of the peceding glyph
	* 
	* @return x kerning value
	*/
//	float texture_glyph_get_kerning( const texture_glyph_t * self, const wchar_t charcode );


private:
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
    wchar charcode;

    /**
	* Kerning value (in fractional pixels).
	*/
    float kerning;

}

/**
*
* A structure that describe a glyph.
*
*
* Glyph metrics:
* --------------
*
*                       xmin                     xmax
*                        |                         |
*                        |<-------- width -------->|
*                        |                         |    
*              |         +-------------------------+----------------- ymax
*              |         |    ggggggggg   ggggg    |     ^        ^
*              |         |   g:::::::::ggg::::g    |     |        | 
*              |         |  g:::::::::::::::::g    |     |        | 
*              |         | g::::::ggggg::::::gg    |     |        | 
*              |         | g:::::g     g:::::g     |     |        | 
*    offset_x -|-------->| g:::::g     g:::::g     |  offset_y    | 
*              |         | g:::::g     g:::::g     |     |        | 
*              |         | g::::::g    g:::::g     |     |        | 
*              |         | g:::::::ggggg:::::g     |     |        |  
*              |         |  g::::::::::::::::g     |     |      height
*              |         |   gg::::::::::::::g     |     |        | 
*  baseline ---*---------|---- gggggggg::::::g-----*--------      |
*            / |         |             g:::::g     |              | 
*     origin   |         | gggggg      g:::::g     |              | 
*              |         | g:::::gg   gg:::::g     |              | 
*              |         |  g::::::ggg:::::::g     |              | 
*              |         |   gg:::::::::::::g      |              | 
*              |         |     ggg::::::ggg        |              | 
*              |         |         gggggg          |              v
*              |         +-------------------------+----------------- ymin
*              |                                   |
*              |------------- advance_x ---------->|
*/
private struct Glyph
{
    /**
	* Wide character this glyph represents
	*/
    wchar charcode;

    /**
	* Glyph id (used for display lists)
	*/
    uint id;

    /**
	* Glyph's width in pixels.
	*/
    size_t width;

    /**
	* Glyph's height in pixels.
	*/
    size_t height;

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
	* First normalized texture coordinate (x) of top-left corner
	*/
    float s0;

    /**
	* Second normalized texture coordinate (y) of top-left corner
	*/
    float t0;

    /**
	* First normalized texture coordinate (x) of bottom-right corner
	*/
    float s1;

    /**
	* Second normalized texture coordinate (y) of bottom-right corner
	*/
    float t1;

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
