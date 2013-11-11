module dquick.system.linux.fontconfig.types;

// Based on fontconfig.h version 2.10.2

import std.string;

alias char		FcChar8;
alias ushort	FcChar16;
alias uint		FcChar32;
alias int		FcBool;

/*
* Current Fontconfig version number.  This same number
* must appear in the fontconfig configure.in file. Yes,
* it'a a pain to synchronize version numbers like this.
*/

const int FC_MAJOR =	2;
const int FC_MINOR =	10;
const int FC_REVISION =	2;

const int FC_VERSION =	((FC_MAJOR * 10000) + (FC_MINOR * 100) + (FC_REVISION));

/*
* Current font cache file format version
* This is appended to the cache files so that multiple
* versions of the library will peacefully coexist
*
* Change this value whenever the disk format for the cache file
* changes in any non-compatible way.  Try to avoid such changes as
* it means multiple copies of the font information.
*/

const string FC_CACHE_VERSION =    "3";

FcBool FcTrue =			1;
FcBool FcFalse =		0;

const FcChar8* FC_FAMILY =			"family";			/* String */
const FcChar8* FC_STYLE =			"style";			/* String */
const FcChar8* FC_SLANT =			"slant";			/* Int */
const FcChar8* FC_WEIGHT =			"weight";			/* Int */
const FcChar8* FC_SIZE =			"size";				/* Double */
const FcChar8* FC_ASPECT =			"aspect";			/* Double */
const FcChar8* FC_PIXEL_SIZE =		"pixelsize";		/* Double */
const FcChar8* FC_SPACING =			"spacing";			/* Int */
const FcChar8* FC_FOUNDRY =			"foundry";			/* String */
const FcChar8* FC_ANTIALIAS =		"antialias";		/* Bool (depends) */
const FcChar8* FC_HINTING =			"hinting";			/* Bool (true) */
const FcChar8* FC_HINT_STYLE =		"hintstyle";		/* Int */
const FcChar8* FC_VERTICAL_LAYOUT =	"verticallayout";	/* Bool (false) */
const FcChar8* FC_AUTOHINT =		"autohint";			/* Bool (false) */
/* FC_GLOBAL_ADVANCE is deprecated. this is simply ignored on freetype 2.4.5 or later */
const FcChar8* FC_GLOBAL_ADVANCE =	"globaladvance";	/* Bool (true) */
const FcChar8* FC_WIDTH =			"width";			/* Int */
const FcChar8* FC_FILE =			"file";				/* String */
const FcChar8* FC_INDEX =			"index";			/* Int */
const FcChar8* FC_FT_FACE =			"ftface";			/* FT_Face */
const FcChar8* FC_RASTERIZER =		"rasterizer";		/* String */
const FcChar8* FC_OUTLINE =			"outline";			/* Bool */
const FcChar8* FC_SCALABLE =		"scalable";			/* Bool */
const FcChar8* FC_SCALE =			"scale";			/* double */
const FcChar8* FC_DPI =				"dpi";				/* double */
const FcChar8* FC_RGBA =			"rgba";				/* Int */
const FcChar8* FC_MINSPACE =		"minspace";			/* Bool use minimum line spacing */
const FcChar8* FC_SOURCE =			"source";			/* String (deprecated) */
const FcChar8* FC_CHARSET =			"charset";			/* CharSet */
const FcChar8* FC_LANG =			"lang";				/* String RFC 3066 langs */
const FcChar8* FC_FONTVERSION =		"fontversion";		/* Int from 'head' table */
const FcChar8* FC_FULLNAME =		"fullname";			/* String */
const FcChar8* FC_FAMILYLANG =		"familylang";		/* String RFC 3066 langs */
const FcChar8* FC_STYLELANG =		"stylelang";		/* String RFC 3066 langs */
const FcChar8* FC_FULLNAMELANG =	"fullnamelang";		/* String RFC 3066 langs */
const FcChar8* FC_CAPABILITY =		"capability";		/* String */
const FcChar8* FC_FONTFORMAT =		"fontformat";		/* String */
const FcChar8* FC_EMBOLDEN =		"embolden";			/* Bool - true if emboldening needed*/
const FcChar8* FC_EMBEDDED_BITMAP =	"embeddedbitmap";	/* Bool - true to enable embedded bitmaps */
const FcChar8* FC_DECORATIVE =		"decorative";		/* Bool - true if style is a decorative variant */
const FcChar8* FC_LCD_FILTER =		"lcdfilter";		/* Int */
const FcChar8* FC_NAMELANG =		"namelang";			/* String RFC 3866 langs */

string FC_CACHE_SUFFIX =			".cache-" ~ FC_CACHE_VERSION;
string FC_DIR_CACHE_FILE =			"fonts.cache-" ~ FC_CACHE_VERSION;
string FC_USER_CACHE_FILE =			".fonts.cache-" ~ FC_CACHE_VERSION;

/* Adjust outline rasterizer */
const FcChar8* FC_CHAR_WIDTH =		"charwidth";	/* Int */
const FcChar8* FC_CHAR_HEIGHT =		"charheight";	/* Int */
const FcChar8* FC_MATRIX =			"matrix";		/* FcMatrix */

const int FC_WEIGHT_THIN =		    0;
const int FC_WEIGHT_EXTRALIGHT =	40;
const int FC_WEIGHT_ULTRALIGHT =	FC_WEIGHT_EXTRALIGHT;
const int FC_WEIGHT_LIGHT =		    50;
const int FC_WEIGHT_BOOK =		    75;
const int FC_WEIGHT_REGULAR =	    80;
const int FC_WEIGHT_NORMAL =	    FC_WEIGHT_REGULAR;
const int FC_WEIGHT_MEDIUM =	    100;
const int FC_WEIGHT_DEMIBOLD =	    180;
const int FC_WEIGHT_SEMIBOLD =	    FC_WEIGHT_DEMIBOLD;
const int FC_WEIGHT_BOLD =		    200;
const int FC_WEIGHT_EXTRABOLD =	    205;
const int FC_WEIGHT_ULTRABOLD =	    FC_WEIGHT_EXTRABOLD;
const int FC_WEIGHT_BLACK =		    210;
const int FC_WEIGHT_HEAVY =		    FC_WEIGHT_BLACK;
const int FC_WEIGHT_EXTRABLACK =	215;
const int FC_WEIGHT_ULTRABLACK =	FC_WEIGHT_EXTRABLACK;

const int FC_SLANT_ROMAN =		    0;
const int FC_SLANT_ITALIC =		    100;
const int FC_SLANT_OBLIQUE =	    110;

const int FC_WIDTH_ULTRACONDENSED =	50;
const int FC_WIDTH_EXTRACONDENSED =	63;
const int FC_WIDTH_CONDENSED =	    75;
const int FC_WIDTH_SEMICONDENSED =	87;
const int FC_WIDTH_NORMAL =		    100;
const int FC_WIDTH_SEMIEXPANDED =	113;
const int FC_WIDTH_EXPANDED =	    125;
const int FC_WIDTH_EXTRAEXPANDED =	150;
const int FC_WIDTH_ULTRAEXPANDED =	200;

const int FC_PROPORTIONAL =		    0;
const int FC_DUAL =					90;
const int FC_MONO =					100;
const int FC_CHARCELL =				110;

/* sub-pixel order */
const int FC_RGBA_UNKNOWN =			0;
const int FC_RGBA_RGB =				1;
const int FC_RGBA_BGR =				2;
const int FC_RGBA_VRGB =			3;
const int FC_RGBA_VBGR =			4;
const int FC_RGBA_NONE =			5;

/* hinting style */
const int FC_HINT_NONE =			0;
const int FC_HINT_SLIGHT =			1;
const int FC_HINT_MEDIUM =			2;
const int FC_HINT_FULL =			3;

/* LCD filter */
const int FC_LCD_NONE =				0;
const int FC_LCD_DEFAULT =			1;
const int FC_LCD_LIGHT =			2;
const int FC_LCD_LEGACY =			3;

enum FcType {
    FcTypeVoid, 
	FcTypeInteger, 
	FcTypeDouble, 
	FcTypeString, 
	FcTypeBool,
	FcTypeMatrix,
	FcTypeCharSet,
	FcTypeFTFace,
	FcTypeLangSet
}

struct FcMatrix {
    double xx;
	double xy;
	double yx;
	double yy;
}

void	FcMatrixInit(ref FcMatrix m)
{
	m.xx = 1;
	m.yy = 1;
	m.xy = 0;
	m.yx = 0;
}

/*
* A data structure to represent the available glyphs in a font.
* This is represented as a sparse boolean btree.
*/
alias void	FcCharSet;

struct FcObjectType {
    const char*	object;
    FcType		type;
}

struct FcConstant {
    const FcChar8*	name;
    const char*		object;
    int				value;
}

enum FcResult {
    FcResultMatch,
	FcResultNoMatch,
	FcResultTypeMismatch,
	FcResultNoId,
	FcResultOutOfMemory
}

alias void	FcPattern;

alias void	FcLangSet;

struct FcValue {
    FcType	type;
    union u{
		const FcChar8*		s;
		int					i;
		FcBool				b;
		double				d;
		const FcMatrix*		m;
		const FcCharSet*	c;
		void*				f;
		const FcLangSet*	l;
    }
}

struct FcFontSet {
    int			nfont;
    int			sfont;
    FcPattern**	fonts;
}

struct FcObjectSet {
    int				nobject;
    int				sobject;
    const char**	objects;
}

enum FcMatchKind {
    FcMatchPattern,
	FcMatchFont,
	FcMatchScan
}

enum FcLangResult {
    FcLangEqual = 0,
	FcLangDifferentCountry = 1,
	FcLangDifferentTerritory = 1,
	FcLangDifferentLang = 2
}

enum FcSetName {
    FcSetSystem = 0,
	FcSetApplication = 1
}

alias void	FcAtomic;

enum FcEndian {
	FcEndianBig,
	FcEndianLittle
}

alias void	FcConfig;

alias void	FcFileCache;

alias void	FcBlanks;

alias void	FcStrList;

alias void	FcStrSet;

alias void	FcCache;
