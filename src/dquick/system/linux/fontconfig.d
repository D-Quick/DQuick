/*
 * fontconfig/fontconfig/fontconfig.h
 *
 * Copyright © 2001 Keith Packard
 *
 * Permission to use, copy, modify, distribute, and sell this software and its
 * documentation for any purpose is hereby granted without fee, provided that
 * the above copyright notice appear in all copies and that both that
 * copyright notice and this permission notice appear in supporting
 * documentation, and that the name of the author(s) not be used in
 * advertising or publicity pertaining to distribution of the software without
 * specific, written prior permission.  The authors make no
 * representations about the suitability of this software for any purpose.  It
 * is provided "as is" without express or implied warranty.
 *
 * THE AUTHOR(S) DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
 * INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO
 * EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY SPECIAL, INDIRECT OR
 * CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
 * DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
 * TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */
 
module dquick.system.linux.fontconfig;

version(linux)
{
	import std.string;
	import std.variant;
	import std.c.string;
	import std.c.linux.linux;
	import core.vararg;
	
	alias FcVariant = Algebraic!(string, int, bool);
		
	string matchFont(FcConfig* conf, FcVariant[string] font)
	{
		FcPattern* pattern = FcPatternCreate();
		foreach(nm, val; font)
		{
			if(val.type == typeid(string))
				FcPatternAddString(pattern, nm.toStringz, val.get!(string)().toStringz);
			else if(val.type == typeid(int))
				FcPatternAddInteger(pattern, nm.toStringz, val.get!(int)());
			else if(val.type == typeid(bool))
				FcPatternAddBool(pattern, nm.toStringz, val.get!(bool)());
		}
		
		FcConfigSubstitute(conf, pattern, FcMatchKind.Pattern);
		
		FcResult result;
		FcPattern* mtPattern = FcFontMatch(conf, pattern, &result);
		string fileName;
		if(mtPattern)
		{
			char* ptr;
			if(FcPatternGetString(mtPattern, FC_FILE, 0, &ptr) == FcResult.Match)
				fileName = ptr[0..ptr.strlen].idup;
			FcPatternDestroy(mtPattern);
		}
		
		FcPatternDestroy(pattern);
		return fileName;
	}
	
	string matchFont(FcVariant[string] font)
	{
		return matchFont(null, font);
	}
	
	alias char FcChar8;
	alias wchar FcChar16;
	alias dchar FcChar32;
	alias int FcBool;

	/*
	 * Current Fontconfig version number.  This same number
	 * must appear in the fontconfig configure.in file. Yes,
	 * it'a a pain to synchronize version numbers like this.
	 */
	 
	enum FC_MAJOR = 2;
	enum FC_MINOR = 2;
	enum FC_REVISION = 2;

	enum FC_VERSION = ((FC_MAJOR * 10000) + (FC_MINOR * 100) + (FC_REVISION));

	/*
	 * Current font cache file format version
	 * This is appended to the cache files so that multiple
	 * versions of the library will peacefully coexist
	 *
	 * Change this value whenever the disk format for the cache file
	 * changes in any non-compatible way.  Try to avoid such changes as
	 * it means multiple copies of the font information.
	 */

	enum FC_CACHE_VERSION = "4";

	enum FcTrue = 1;
	enum FcFalse = 0;

	enum FC_FAMILY = "family";		/* String */
	enum FC_STYLE = "style";		/* String */
	enum FC_SLANT = "slant";		/* Int */
	enum FC_WEIGHT = "weight";		/* Int */
	enum FC_SIZE = "size";		/* Double */
	enum FC_ASPECT = "aspect";		/* Double */
	enum FC_PIXEL_SIZE = "pixelsize";		/* Double */
	enum FC_SPACING = "spacing";		/* Int */
	enum FC_FOUNDRY = "foundry";		/* String */
	enum FC_ANTIALIAS = "antialias";		/* Bool (depends) */
	enum FC_HINTING = "hinting";		/* Bool (true) */
	enum FC_HINT_STYLE = "hintstyle";		/* Int */
	enum FC_VERTICAL_LAYOUT = "verticallayout";	/* Bool (false) */
	enum FC_AUTOHINT = "autohint";		/* Bool (false) */
	/* FC_GLOBAL_ADVANCE is deprecated. this is simply ignored on freetype 2.4.5 or later */
	enum FC_GLOBAL_ADVANCE = "globaladvance";	/* Bool (true) */
	enum FC_WIDTH = "width";		/* Int */
	enum FC_FILE = "file";		/* String */
	enum FC_INDEX = "index";		/* Int */
	enum FC_FT_FACE = "ftface";		/* FT_Face */
	enum FC_RASTERIZER = "rasterizer";	/* String */
	enum FC_OUTLINE = "outline";		/* Bool */
	enum FC_SCALABLE = "scalable";		/* Bool */
	enum FC_SCALE = "scale";		/* double */
	enum FC_DPI = "dpi";		/* double */
	enum FC_RGBA = "rgba";		/* Int */
	enum FC_MINSPACE = "minspace";		/* Bool use minimum line spacing */
	enum FC_SOURCE = "source";		/* String (deprecated) */
	enum FC_CHARSET = "charset";		/* CharSet */
	enum FC_LANG = "lang";		/* String RFC 3066 langs */
	enum FC_FONTVERSION = "fontversion";	/* Int from 'head' table */
	enum FC_FULLNAME = "fullname";		/* String */
	enum FC_FAMILYLANG = "familylang";	/* String RFC 3066 langs */
	enum FC_STYLELANG = "stylelang";		/* String RFC 3066 langs */
	enum FC_FULLNAMELANG = "fullnamelang";	/* String RFC 3066 langs */
	enum FC_CAPABILITY = "capability";	/* String */
	enum FC_FONTFORMAT = "fontformat";	/* String */
	enum FC_EMBOLDEN = "embolden";		/* Bool - true if emboldening needed*/
	enum FC_EMBEDDED_BITMAP = "embeddedbitmap";	/* Bool - true to enable embedded bitmaps */
	enum FC_DECORATIVE = "decorative";	/* Bool - true if style is a decorative variant */
	enum FC_LCD_FILTER = "lcdfilter";		/* Int */
	enum FC_FONT_FEATURES = "fontfeatures";	/* String */
	enum FC_NAMELANG = "namelang";		/* String RFC 3866 langs */
	enum FC_PRGNAME = "prgname";		/* String */
	enum FC_HASH = "hash";		/* String */
	enum FC_POSTSCRIPT_NAME = "postscriptname";	/* String */

	enum FC_CACHE_SUFFIX = ".cache-" ~ FC_CACHE_VERSION;
	enum FC_DIR_CACHE_FILE = "fonts.cache-" ~ FC_CACHE_VERSION;
	enum FC_USER_CACHE_FILE = ".fonts.cache-" ~ FC_CACHE_VERSION;

	/* Adjust outline rasterizer */
	enum FC_CHAR_WIDTH = "charwidth";	/* Int */
	enum FC_CHAR_HEIGHT = "charheight"; /*; Int */
	enum FC_MATRIX = "matrix";    /* FcMatrix */

	enum FC_WEIGHT_THIN = 0;
	enum FC_WEIGHT_EXTRALIGHT = 40;
	enum FC_WEIGHT_ULTRALIGHT = FC_WEIGHT_EXTRALIGHT;
	enum FC_WEIGHT_LIGHT = 50;
	enum FC_WEIGHT_BOOK = 75;
	enum FC_WEIGHT_REGULAR = 80;
	enum FC_WEIGHT_NORMAL = FC_WEIGHT_REGULAR;
	enum FC_WEIGHT_MEDIUM = 100;
	enum FC_WEIGHT_DEMIBOLD = 180;
	enum FC_WEIGHT_SEMIBOLD = FC_WEIGHT_DEMIBOLD;
	enum FC_WEIGHT_BOLD = 200;
	enum FC_WEIGHT_EXTRABOLD = 205;
	enum FC_WEIGHT_ULTRABOLD = FC_WEIGHT_EXTRABOLD;
	enum FC_WEIGHT_BLACK = 210;
	enum FC_WEIGHT_HEAVY = FC_WEIGHT_BLACK;
	enum FC_WEIGHT_EXTRABLACK = 215;
	enum FC_WEIGHT_ULTRABLACK = FC_WEIGHT_EXTRABLACK;

	enum FC_SLANT_ROMAN = 0;
	enum FC_SLANT_ITALIC = 100;
	enum FC_SLANT_OBLIQUE = 110;

	enum FC_WIDTH_ULTRACONDENSED = 50;
	enum FC_WIDTH_EXTRACONDENSED = 63;
	enum FC_WIDTH_CONDENSED = 75;
	enum FC_WIDTH_SEMICONDENSED = 87;
	enum FC_WIDTH_NORMAL = 100;
	enum FC_WIDTH_SEMIEXPANDED = 113;
	enum FC_WIDTH_EXPANDED = 125;
	enum FC_WIDTH_EXTRAEXPANDED = 150;
	enum FC_WIDTH_ULTRAEXPANDED = 200;

	enum FC_PROPORTIONAL = 0;
	enum FC_DUAL = 90;
	enum FC_MONO = 100;
	enum FC_CHARCELL = 110;

	/* sub-pixel order */
	enum FC_RGBA_UNKNOWN = 0;
	enum FC_RGBA_RGB = 1;
	enum FC_RGBA_BGR = 2;
	enum FC_RGBA_VRGB = 3;
	enum FC_RGBA_VBGR = 4;
	enum FC_RGBA_NONE = 5;

	/* hinting style */
	enum FC_HINT_NONE = 0;
	enum FC_HINT_SLIGHT = 1;
	enum FC_HINT_MEDIUM = 2;
	enum FC_HINT_FULL = 3;

	/* LCD filter */
	enum FC_LCD_NONE = 0;
	enum FC_LCD_DEFAULT = 1;
	enum FC_LCD_LIGHT = 2;
	enum FC_LCD_LEGACY = 3;

	enum FcType {
		Void,
		Integer,
		Double,
		String,
		Bool,
		Matrix,
		CharSet,
		FTFace,
		LangSet
	}

	struct FcMatrix {
		double xx, xy, yx, yy;
	}

	void FcMatrixInit(ref FcMatrix m)
	{
		m.xx = m.yy = 1;
		m.xy = m.yx = 0;
	}

	/*
	 * A data structure to represent the available glyphs in a font.
	 * This is represented as a sparse boolean btree.
	 */

	struct FcCharSet;

	struct FcObjectType {
		const char	*object;
		FcType	type;
	}

	struct FcConstant {
		const FcChar8  *name;
		const char	*object;
		int		value;
	}

	enum FcResult {
		Match,
		NoMatch,
		TypeMismatch,
		NoId,
		OutOfMemory
	}

	struct FcPattern;

	struct FcLangSet;

	struct FcValue {
		union _U{
			const FcChar8	*s;
			int		i;
			FcBool		b;
			double		d;
			const FcMatrix	*m;
			const FcCharSet	*c;
			void		*f;
			const FcLangSet	*l;
		}
		
		FcType	type;
		_U u;
	}

	struct FcFontSet {
		int		nfont;
		int		sfont;
		FcPattern	**fonts;
	}

	struct FcObjectSet {
		int		nobject;
		int		sobject;
		const char	**objects;
	}
		
	enum FcMatchKind {
		Pattern,
		Font,
		Scan
	}

	enum FcLangResult {
		Equal = 0,
		DifferentCountry = 1,
		DifferentTerritory = 1,
		DifferentLang = 2
	}

	enum FcSetName {
		System = 0,
		Application = 1
	}

	struct FcAtomic;

	enum FcEndian {
		Big,
		Little
	}

	struct FcConfig;

	struct FcFileCache;

	struct FcBlanks;

	struct FcStrList;

	struct FcStrSet;

	struct FcCache;

	extern(C) {

		/* fcblanks.c */
		FcBlanks *
		FcBlanksCreate ();

		void
		FcBlanksDestroy (FcBlanks *b);

		FcBool
		FcBlanksAdd (FcBlanks *b, FcChar32 ucs4);

		FcBool
		FcBlanksIsMember (FcBlanks *b, FcChar32 ucs4);

		/* fccache.c */

		const FcChar8 *
		FcCacheDir(const FcCache *c);

		FcFontSet *
		FcCacheCopySet(const FcCache *c);

		const FcChar8 *
		FcCacheSubdir (const FcCache *c, int i);

		int
		FcCacheNumSubdir (const FcCache *c);

		int
		FcCacheNumFont (const FcCache *c);

		FcBool
		FcDirCacheUnlink (const FcChar8 *dir, FcConfig *config);

		FcBool
		FcDirCacheValid (const FcChar8 *cache_file);

		FcBool
		FcDirCacheClean (const FcChar8 *cache_dir, FcBool verbose);

		void
		FcCacheCreateTagFile (const FcConfig *config);

		/* fccfg.c */
		FcChar8 *
		FcConfigHome ();

		FcBool
		FcConfigEnableHome (FcBool enable);

		FcChar8 *
		FcConfigFilename (const FcChar8 *url);
			
		FcConfig *
		FcConfigCreate ();

		FcConfig *
		FcConfigReference (FcConfig *config);

		void
		FcConfigDestroy (FcConfig *config);

		FcBool
		FcConfigSetCurrent (FcConfig *config);

		FcConfig *
		FcConfigGetCurrent ();

		FcBool
		FcConfigUptoDate (FcConfig *config);
			
		FcBool
		FcConfigBuildFonts (FcConfig *config);

		FcStrList *
		FcConfigGetFontDirs (FcConfig   *config);

		FcStrList *
		FcConfigGetConfigDirs (FcConfig   *config);

		FcStrList *
		FcConfigGetConfigFiles (FcConfig    *config);

		FcChar8 *
		FcConfigGetCache (FcConfig  *config);

		FcBlanks *
		FcConfigGetBlanks (FcConfig *config);

		FcStrList *
		FcConfigGetCacheDirs (const FcConfig	*config);

		int
		FcConfigGetRescanInterval (FcConfig *config);

		FcBool
		FcConfigSetRescanInterval (FcConfig *config, int rescanInterval);

		FcFontSet *
		FcConfigGetFonts (FcConfig	*config,
				  FcSetName	set);

		FcBool
		FcConfigAppFontAddFile (FcConfig    *config,
					const FcChar8  *file);

		FcBool
		FcConfigAppFontAddDir (FcConfig	    *config,
					   const FcChar8   *dir);

		void
		FcConfigAppFontClear (FcConfig	    *config);

		FcBool
		FcConfigSubstituteWithPat (FcConfig	*config,
					   FcPattern	*p,
					   FcPattern	*p_pat,
					   FcMatchKind	kind);

		FcBool
		FcConfigSubstitute (FcConfig	*config,
					FcPattern	*p,
					FcMatchKind	kind);

		const FcChar8 *
		FcConfigGetSysRoot (const FcConfig *config);

		void
		FcConfigSetSysRoot (FcConfig      *config,
					const FcChar8 *sysroot);

		/* fccharset.c */
		FcCharSet*
		FcCharSetCreate ();

		/* deprecated alias for FcCharSetCreate */
		FcCharSet *
		FcCharSetNew ();

		void
		FcCharSetDestroy (FcCharSet *fcs);

		FcBool
		FcCharSetAddChar (FcCharSet *fcs, FcChar32 ucs4);

		FcBool
		FcCharSetDelChar (FcCharSet *fcs, FcChar32 ucs4);

		FcCharSet*
		FcCharSetCopy (FcCharSet *src);

		FcBool
		FcCharSetEqual (const FcCharSet *a, const FcCharSet *b);

		FcCharSet*
		FcCharSetIntersect (const FcCharSet *a, const FcCharSet *b);

		FcCharSet*
		FcCharSetUnion (const FcCharSet *a, const FcCharSet *b);

		FcCharSet*
		FcCharSetSubtract (const FcCharSet *a, const FcCharSet *b);

		FcBool
		FcCharSetMerge (FcCharSet *a, const FcCharSet *b, FcBool *changed);

		FcBool
		FcCharSetHasChar (const FcCharSet *fcs, FcChar32 ucs4);

		FcChar32
		FcCharSetCount (const FcCharSet *a);

		FcChar32
		FcCharSetIntersectCount (const FcCharSet *a, const FcCharSet *b);

		FcChar32
		FcCharSetSubtractCount (const FcCharSet *a, const FcCharSet *b);

		FcBool
		FcCharSetIsSubset (const FcCharSet *a, const FcCharSet *b);

		enum FC_CHARSET_MAP_SIZE = (256/32);
		enum FC_CHARSET_DONE = (cast(FcChar32) -1);

		FcChar32
		FcCharSetFirstPage (const FcCharSet *a, 
					FcChar32	    map[FC_CHARSET_MAP_SIZE],
					FcChar32	    *next);

		FcChar32
		FcCharSetNextPage (const FcCharSet  *a, 
				   FcChar32	    map[FC_CHARSET_MAP_SIZE],
				   FcChar32	    *next);

		/*
		 * old coverage API, rather hard to use correctly
		 */

		FcChar32
		FcCharSetCoverage (const FcCharSet *a, FcChar32 page, FcChar32 *result);

		/* fcdbg.c */
		void
		FcValuePrint (const FcValue v);

		void
		FcPatternPrint (const FcPattern *p);

		void
		FcFontSetPrint (const FcFontSet *s);

		/* fcdefault.c */
		FcStrSet *
		FcGetDefaultLangs ();

		void
		FcDefaultSubstitute (FcPattern *pattern);

		/* fcdir.c */
		FcBool
		FcFileIsDir (const FcChar8 *file);

		FcBool
		FcFileScan (FcFontSet	    *set,
				FcStrSet	    *dirs,
				FcFileCache	    *cache,
				FcBlanks	    *blanks,
				const FcChar8   *file,
				FcBool	    force);

		FcBool
		FcDirScan (FcFontSet	    *set,
			   FcStrSet	    *dirs,
			   FcFileCache	    *cache,
			   FcBlanks	    *blanks,
			   const FcChar8    *dir,
			   FcBool	    force);

		FcBool
		FcDirSave (FcFontSet *set, FcStrSet *dirs, const FcChar8 *dir);

		FcCache *
		FcDirCacheLoad (const FcChar8 *dir, FcConfig *config, FcChar8 **cache_file);
			
		FcCache *
		FcDirCacheRead (const FcChar8 *dir, FcBool force, FcConfig *config);

		FcCache *
		FcDirCacheLoadFile (const FcChar8 *cache_file, stat_t *file_stat);

		void
		FcDirCacheUnload (FcCache *cache);

		/* fcfreetype.c */
		FcPattern *
		FcFreeTypeQuery (const FcChar8 *file, int id, FcBlanks *blanks, int *count);

		/* fcfs.c */

		FcFontSet *
		FcFontSetCreate ();

		void
		FcFontSetDestroy (FcFontSet *s);

		FcBool
		FcFontSetAdd (FcFontSet *s, FcPattern *font);

		/* fcinit.c */
		FcConfig *
		FcInitLoadConfig ();

		FcConfig *
		FcInitLoadConfigAndFonts ();

		FcBool
		FcInit ();

		void
		FcFini ();

		int
		FcGetVersion ();

		FcBool
		FcInitReinitialize ();

		FcBool
		FcInitBringUptoDate ();

		/* fclang.c */
		FcStrSet *
		FcGetLangs ();

		FcChar8 *
		FcLangNormalize (const FcChar8 *lang);

		const FcCharSet *
		FcLangGetCharSet (const FcChar8 *lang);

		FcLangSet*
		FcLangSetCreate ();

		void
		FcLangSetDestroy (FcLangSet *ls);

		FcLangSet*
		FcLangSetCopy (const FcLangSet *ls);

		FcBool
		FcLangSetAdd (FcLangSet *ls, const FcChar8 *lang);

		FcBool
		FcLangSetDel (FcLangSet *ls, const FcChar8 *lang);

		FcLangResult
		FcLangSetHasLang (const FcLangSet *ls, const FcChar8 *lang);

		FcLangResult
		FcLangSetCompare (const FcLangSet *lsa, const FcLangSet *lsb);

		FcBool
		FcLangSetContains (const FcLangSet *lsa, const FcLangSet *lsb);

		FcBool
		FcLangSetEqual (const FcLangSet *lsa, const FcLangSet *lsb);

		FcChar32
		FcLangSetHash (const FcLangSet *ls);

		FcStrSet *
		FcLangSetGetLangs (const FcLangSet *ls);

		FcLangSet *
		FcLangSetUnion (const FcLangSet *a, const FcLangSet *b);

		FcLangSet *
		FcLangSetSubtract (const FcLangSet *a, const FcLangSet *b);

		/* fclist.c */
		FcObjectSet *
		FcObjectSetCreate ();

		FcBool
		FcObjectSetAdd (FcObjectSet *os, const char *object);

		void
		FcObjectSetDestroy (FcObjectSet *os);

		FcObjectSet *
		FcObjectSetVaBuild (const char *first, va_list va);

		FcObjectSet *
		FcObjectSetBuild (const char *first, ...);

		FcFontSet *
		FcFontSetList (FcConfig	    *config,
				   FcFontSet    **sets,
				   int	    nsets,
				   FcPattern    *p,
				   FcObjectSet  *os);

		FcFontSet *
		FcFontList (FcConfig	*config,
				FcPattern	*p,
				FcObjectSet *os);

		/* fcatomic.c */

		FcAtomic *
		FcAtomicCreate (const FcChar8   *file);

		FcBool
		FcAtomicLock (FcAtomic *atomic);

		FcChar8 *
		FcAtomicNewFile (FcAtomic *atomic);

		FcChar8 *
		FcAtomicOrigFile (FcAtomic *atomic);

		FcBool
		FcAtomicReplaceOrig (FcAtomic *atomic);

		void
		FcAtomicDeleteNew (FcAtomic *atomic);

		void
		FcAtomicUnlock (FcAtomic *atomic);

		void
		FcAtomicDestroy (FcAtomic *atomic);

		/* fcmatch.c */
		FcPattern *
		FcFontSetMatch (FcConfig    *config,
				FcFontSet   **sets,
				int	    nsets,
				FcPattern   *p,
				FcResult    *result);

		FcPattern *
		FcFontMatch (FcConfig	*config,
				 FcPattern	*p, 
				 FcResult	*result);

		FcPattern *
		FcFontRenderPrepare (FcConfig	    *config,
					 FcPattern	    *pat,
					 FcPattern	    *font);

		FcFontSet *
		FcFontSetSort (FcConfig	    *config,
				   FcFontSet    **sets,
				   int	    nsets,
				   FcPattern    *p,
				   FcBool	    trim,
				   FcCharSet    **csp,
				   FcResult	    *result);

		FcFontSet *
		FcFontSort (FcConfig	 *config,
				FcPattern    *p,
				FcBool	 trim,
				FcCharSet    **csp,
				FcResult	 *result);

		void
		FcFontSetSortDestroy (FcFontSet *fs);

		/* fcmatrix.c */
		FcMatrix *
		FcMatrixCopy (const FcMatrix *mat);

		FcBool
		FcMatrixEqual (const FcMatrix *mat1, const FcMatrix *mat2);

		void
		FcMatrixMultiply (FcMatrix *result, const FcMatrix *a, const FcMatrix *b);

		void
		FcMatrixRotate (FcMatrix *m, double c, double s);

		void
		FcMatrixScale (FcMatrix *m, double sx, double sy);

		void
		FcMatrixShear (FcMatrix *m, double sh, double sv);

		/* fcname.c */

		/* Deprecated.  Does nothing.  Returns FcFalse. */
		FcBool
		FcNameRegisterObjectTypes (const FcObjectType *types, int ntype);

		/* Deprecated.  Does nothing.  Returns FcFalse. */
		FcBool
		FcNameUnregisterObjectTypes (const FcObjectType *types, int ntype);

		const FcObjectType *
		FcNameGetObjectType (const char *object);

		/* Deprecated.  Does nothing.  Returns FcFalse. */
		FcBool
		FcNameRegisterConstants (const FcConstant *consts, int nconsts);

		/* Deprecated.  Does nothing.  Returns FcFalse. */
		FcBool
		FcNameUnregisterConstants (const FcConstant *consts, int nconsts);

		const FcConstant *
		FcNameGetConstant (const FcChar8 *string);

		FcBool
		FcNameConstant (const FcChar8 *string, int *result);

		FcPattern *
		FcNameParse (const FcChar8 *name);

		FcChar8 *
		FcNameUnparse (FcPattern *pat);

		/* fcpat.c */
		FcPattern *
		FcPatternCreate ();

		FcPattern *
		FcPatternDuplicate (const FcPattern *p);

		void
		FcPatternReference (FcPattern *p);

		FcPattern *
		FcPatternFilter (FcPattern *p, const FcObjectSet *os);

		void
		FcValueDestroy (FcValue v);

		FcBool
		FcValueEqual (FcValue va, FcValue vb);

		FcValue
		FcValueSave (FcValue v);

		void
		FcPatternDestroy (FcPattern *p);

		FcBool
		FcPatternEqual (const FcPattern *pa, const FcPattern *pb);

		FcBool
		FcPatternEqualSubset (const FcPattern *pa, const FcPattern *pb, const FcObjectSet *os);

		FcChar32
		FcPatternHash (const FcPattern *p);

		FcBool
		FcPatternAdd (FcPattern *p, const char *object, FcValue value, FcBool append);
			
		FcBool
		FcPatternAddWeak (FcPattern *p, const char *object, FcValue value, FcBool append);
			
		FcResult
		FcPatternGet (const FcPattern *p, const char *object, int id, FcValue *v);
			
		FcBool
		FcPatternDel (FcPattern *p, const char *object);

		FcBool
		FcPatternRemove (FcPattern *p, const char *object, int id);

		FcBool
		FcPatternAddInteger (FcPattern *p, const char *object, int i);

		FcBool
		FcPatternAddDouble (FcPattern *p, const char *object, double d);

		FcBool
		FcPatternAddString (FcPattern *p, const char *object, const FcChar8 *s);

		FcBool
		FcPatternAddMatrix (FcPattern *p, const char *object, const FcMatrix *s);

		FcBool
		FcPatternAddCharSet (FcPattern *p, const char *object, const FcCharSet *c);

		FcBool
		FcPatternAddBool (FcPattern *p, const char *object, FcBool b);

		FcBool
		FcPatternAddLangSet (FcPattern *p, const char *object, const FcLangSet *ls);

		FcResult
		FcPatternGetInteger (const FcPattern *p, const char *object, int n, int *i);

		FcResult
		FcPatternGetDouble (const FcPattern *p, const char *object, int n, double *d);

		FcResult
		FcPatternGetString (const FcPattern *p, const char *object, int n, FcChar8 ** s);

		FcResult
		FcPatternGetMatrix (const FcPattern *p, const char *object, int n, FcMatrix **s);

		FcResult
		FcPatternGetCharSet (const FcPattern *p, const char *object, int n, FcCharSet **c);

		FcResult
		FcPatternGetBool (const FcPattern *p, const char *object, int n, FcBool *b);

		FcResult
		FcPatternGetLangSet (const FcPattern *p, const char *object, int n, FcLangSet **ls);

		FcPattern *
		FcPatternVaBuild (FcPattern *p, va_list va);
			
		FcPattern *
		FcPatternBuild (FcPattern *p, ...);

		FcChar8 *
		FcPatternFormat (FcPattern *pat, const FcChar8 *format);

		/* fcstr.c */

		FcChar8 *
		FcStrCopy (const FcChar8 *s);

		FcChar8 *
		FcStrCopyFilename (const FcChar8 *s);
			
		FcChar8 *
		FcStrPlus (const FcChar8 *s1, const FcChar8 *s2);
			
		void
		FcStrFree (FcChar8 *s);

		/* These are ASCII only, suitable only for pattern element names */
		import std.ascii;
		alias std.ascii.isUpper FcIsUpper;
		alias std.ascii.isLower FcIsLower;
		alias std.ascii.toLower FcToLower;

		FcChar8 *
		FcStrDowncase (const FcChar8 *s);

		int
		FcStrCmpIgnoreCase (const FcChar8 *s1, const FcChar8 *s2);

		int
		FcStrCmp (const FcChar8 *s1, const FcChar8 *s2);

		const FcChar8 *
		FcStrStrIgnoreCase (const FcChar8 *s1, const FcChar8 *s2);

		const FcChar8 *
		FcStrStr (const FcChar8 *s1, const FcChar8 *s2);

		int
		FcUtf8ToUcs4 (const FcChar8 *src_orig,
				  FcChar32	    *dst,
				  int	    len);

		FcBool
		FcUtf8Len (const FcChar8    *string,
			   int		    len,
			   int		    *nchar,
			   int		    *_wchar);

		enum FC_UTF8_MAX_LEN = 6;

		int
		FcUcs4ToUtf8 (FcChar32	ucs4,
				  FcChar8	dest[FC_UTF8_MAX_LEN]);

		int
		FcUtf16ToUcs4 (const FcChar8	*src_orig,
				   FcEndian		endian,
				   FcChar32		*dst,
				   int		len);	    /* in bytes */

		FcBool
		FcUtf16Len (const FcChar8   *string,
				FcEndian	    endian,
				int		    len,	    /* in bytes */
				int		    *nchar,
				int		    *_wchar);

		FcChar8 *
		FcStrDirname (const FcChar8 *file);

		FcChar8 *
		FcStrBasename (const FcChar8 *file);

		FcStrSet *
		FcStrSetCreate ();

		FcBool
		FcStrSetMember (FcStrSet *set, const FcChar8 *s);

		FcBool
		FcStrSetEqual (FcStrSet *sa, FcStrSet *sb);

		FcBool
		FcStrSetAdd (FcStrSet *set, const FcChar8 *s);

		FcBool
		FcStrSetAddFilename (FcStrSet *set, const FcChar8 *s);

		FcBool
		FcStrSetDel (FcStrSet *set, const FcChar8 *s);

		void
		FcStrSetDestroy (FcStrSet *set);

		FcStrList *
		FcStrListCreate (FcStrSet *set);

		FcChar8 *
		FcStrListNext (FcStrList *list);

		void
		FcStrListDone (FcStrList *list);

		/* fcxml.c */
		FcBool
		FcConfigParseAndLoad (FcConfig *config, const FcChar8 *file, FcBool complain);

	}
}
