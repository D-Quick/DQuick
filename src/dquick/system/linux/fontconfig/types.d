module dquick.system.linux.fontconfig.types;

bool	FcTrue = true;
bool	FcFalse = false;

/+#define FcTrue		1
#define FcFalse		0

#define FC_FAMILY	    "family"		/* String */
#define FC_STYLE	    "style"		/* String */
#define FC_SLANT	    "slant"		/* Int */
#define FC_WEIGHT	    "weight"		/* Int */
#define FC_SIZE		    "size"		/* Double */
#define FC_ASPECT	    "aspect"		/* Double */
#define FC_PIXEL_SIZE	    "pixelsize"		/* Double */
#define FC_SPACING	    "spacing"		/* Int */
#define FC_FOUNDRY	    "foundry"		/* String */
#define FC_ANTIALIAS	    "antialias"		/* Bool (depends) */
#define FC_HINTING	    "hinting"		/* Bool (true) */
#define FC_HINT_STYLE	    "hintstyle"		/* Int */
#define FC_VERTICAL_LAYOUT  "verticallayout"	/* Bool (false) */
#define FC_AUTOHINT	    "autohint"		/* Bool (false) */
#define FC_GLOBAL_ADVANCE   "globaladvance"	/* Bool (true) */
#define FC_WIDTH	    "width"		/* Int */ +/
const char* FC_FILE =		    "file";		/* String */
/+#define FC_INDEX	    "index"		/* Int */
#define FC_FT_FACE	    "ftface"		/* FT_Face */
#define FC_RASTERIZER	    "rasterizer"	/* String */
#define FC_OUTLINE	    "outline"		/* Bool */
#define FC_SCALABLE	    "scalable"		/* Bool */
#define FC_SCALE	    "scale"		/* double */
#define FC_DPI		    "dpi"		/* double */
#define FC_RGBA		    "rgba"		/* Int */
#define FC_MINSPACE	    "minspace"		/* Bool use minimum line spacing */
#define FC_SOURCE	    "source"		/* String (deprecated) */
#define FC_CHARSET	    "charset"		/* CharSet */
#define FC_LANG		    "lang"		/* String RFC 3066 langs */
#define FC_FONTVERSION	    "fontversion"	/* Int from 'head' table */
#define FC_FULLNAME	    "fullname"		/* String */
#define FC_FAMILYLANG	    "familylang"	/* String RFC 3066 langs */
#define FC_STYLELANG	    "stylelang"		/* String RFC 3066 langs */
#define FC_FULLNAMELANG	    "fullnamelang"	/* String RFC 3066 langs */
#define FC_CAPABILITY       "capability"	/* String */
#define FC_FONTFORMAT	    "fontformat"	/* String */
#define FC_EMBOLDEN	    "embolden"		/* Bool - true if emboldening needed*/
#define FC_EMBEDDED_BITMAP  "embeddedbitmap"	/* Bool - true to enable embedded bitmaps */
#define FC_DECORATIVE	    "decorative"	/* Bool - true if style is a decorative variant */
#define FC_LCD_FILTER	    "lcdfilter"		/* Int */!/ +/


alias bool	FcBool;
alias char	FcChar8;
alias void	FcConfig;
alias void	FcPattern;

enum FcMatchKind
{
	FcMatchPattern,
	FcMatchFont,
	FcMatchScan
};

enum FcResult
{
	FcResultMatch,
	FcResultNoMatch,
	FcResultTypeMismatch,
	FcResultNoId,
	FcResultOutOfMemory
};

struct FcFontSet
{
	int			nfont;
	int			sfont;
	FcPattern**	fonts;
}

struct FcObjectSet
{
	int				nobject;
	int				sobject;
	const char**	objects;
}
