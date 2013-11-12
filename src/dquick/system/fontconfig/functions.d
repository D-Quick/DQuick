module dquick.system.fontconfig.functions;

private
{
	import dquick.system.fontconfig.types;

	const int FC_CHARSET_MAP_SIZE =	256 / 32;
	const int FC_CHARSET_DONE =		cast(FcChar32) -1;

	const int FC_UTF8_MAX_LEN =		6;
}

extern(C)
{
	/* fcblanks.c */
	alias nothrow FcBlanks*				function()																												da_FcBlanksCreate;
	alias nothrow void					function(FcBlanks *b)																									da_FcBlanksDestroy;
	alias nothrow FcBool				function(FcBlanks *b, FcChar32 ucs4)																					da_FcBlanksAdd;
	alias nothrow FcBool				function(FcBlanks *b, FcChar32 ucs4)																					da_FcBlanksIsMember;

	/* fccache.c */
	alias nothrow const FcChar8*		function(const FcCache *c)																								da_FcCacheDir;
	alias nothrow FcFontSet*			function(const FcCache *c)																								da_FcCacheCopySet;
	alias nothrow const FcChar8*		function(const FcCache *c, int i)																						da_FcCacheSubdir;
	alias nothrow int					function(const FcCache *c)																								da_FcCacheNumSubdir;
	alias nothrow int					function(const FcCache *c)																								da_FcCacheNumFont;
	alias nothrow FcBool				function(const FcChar8 *dir, FcConfig *config)																			da_FcDirCacheUnlink;
	alias nothrow FcBool				function(const FcChar8 *cache_file)																						da_FcDirCacheValid;
	alias nothrow FcBool				function(const FcChar8 *cache_dir, FcBool verbose)																		da_FcDirCacheClean;
	alias nothrow void					function(const FcConfig *config)																						da_FcCacheCreateTagFile;

	/* fccfg.c */
	alias nothrow FcChar8*				function()																												da_FcConfigHome;
	alias nothrow FcBool				function(FcBool enable)																									da_FcConfigEnableHome;
	alias nothrow FcChar8*				function(const FcChar8 *url)																							da_FcConfigFilename;
	alias nothrow FcConfig*				function()																												da_FcConfigCreate;
	alias nothrow FcConfig*				function(FcConfig *config)																								da_FcConfigReference;
	alias nothrow void					function(FcConfig *config)																								da_FcConfigDestroy;
	alias nothrow FcBool				function(FcConfig *config)																								da_FcConfigSetCurrent;
	alias nothrow FcConfig*				function()																												da_FcConfigGetCurrent;
	alias nothrow FcBool				function(FcConfig *config)																								da_FcConfigUptoDate;
	alias nothrow FcBool				function(FcConfig *config)																								da_FcConfigBuildFonts;
	alias nothrow FcStrList*			function(FcConfig *config)																								da_FcConfigGetFontDirs;
	alias nothrow FcStrList*			function(FcConfig *config)																								da_FcConfigGetConfigDirs;
	alias nothrow FcStrList*			function(FcConfig *config)																								da_FcConfigGetConfigFiles;
	alias nothrow FcChar8*				function(FcConfig *config)																								da_FcConfigGetCache;
	alias nothrow FcBlanks*				function(FcConfig *config)																								da_FcConfigGetBlanks;
	alias nothrow FcStrList*			function(const FcConfig *config)																						da_FcConfigGetCacheDirs;
	alias nothrow int					function(FcConfig *config)																								da_FcConfigGetRescanInterval;
	alias nothrow FcBool				function(FcConfig *config, int rescanInterval)																			da_FcConfigSetRescanInterval;
	alias nothrow FcFontSet*			function(FcConfig *config, FcSetName set)																				da_FcConfigGetFonts;
	alias nothrow FcBool				function(FcConfig *config, const FcChar8 *file)																			da_FcConfigAppFontAddFile;
	alias nothrow FcBool				function(FcConfig *config, const FcChar8 *dir)																			da_FcConfigAppFontAddDir;
	alias nothrow void					function(FcConfig *config)																								da_FcConfigAppFontClear;
	alias nothrow FcBool				function(FcConfig *config, FcPattern *p, FcPattern *p_pat, FcMatchKind kind)											da_FcConfigSubstituteWithPat;
	alias nothrow FcBool				function(FcConfig *config, FcPattern *p, FcMatchKind kind)																da_FcConfigSubstitute;

	/* fccharset.c */
	alias nothrow FcCharSet*			function()																												da_FcCharSetCreate;

	/* deprecated alias for FcCharSetCreate */
	alias nothrow FcCharSet*			function()																												da_FcCharSetNew;
	alias nothrow void					function(FcCharSet *fcs)																								da_FcCharSetDestroy;
	alias nothrow FcBool				function(FcCharSet *fcs, FcChar32 ucs4)																					da_FcCharSetAddChar;
	alias nothrow FcBool				function(FcCharSet *fcs, FcChar32 ucs4)																					da_FcCharSetDelChar;
	alias nothrow FcCharSet*			function(FcCharSet *src)																								da_FcCharSetCopy;
	alias nothrow FcBool				function(const FcCharSet *a, const FcCharSet *b)																		da_FcCharSetEqual;
	alias nothrow FcCharSet*			function(const FcCharSet *a, const FcCharSet *b)																		da_FcCharSetIntersect;
	alias nothrow FcCharSet*			function(const FcCharSet *a, const FcCharSet *b)																		da_FcCharSetUnion;
	alias nothrow FcCharSet*			function(const FcCharSet *a, const FcCharSet *b)																		da_FcCharSetSubtract;
	alias nothrow FcBool				function(FcCharSet *a, const FcCharSet *b, FcBool *changed)																da_FcCharSetMerge;
	alias nothrow FcBool				function(const FcCharSet *fcs, FcChar32 ucs4)																			da_FcCharSetHasChar;
	alias nothrow FcChar32				function(const FcCharSet *a)																							da_FcCharSetCount;
	alias nothrow FcChar32				function(const FcCharSet *a, const FcCharSet *b)																		da_FcCharSetIntersectCount;
	alias nothrow FcChar32				function(const FcCharSet *a, const FcCharSet *b)																		da_FcCharSetSubtractCount;
	alias nothrow FcBool				function(const FcCharSet *a, const FcCharSet *b)																		da_FcCharSetIsSubset;
	alias nothrow FcChar32				function(const FcCharSet *a, FcChar32 map[FC_CHARSET_MAP_SIZE], FcChar32 *next)											da_FcCharSetFirstPage;
	alias nothrow FcChar32				function(const FcCharSet *a, FcChar32 map[FC_CHARSET_MAP_SIZE], FcChar32 *next)											da_FcCharSetNextPage;

	/*
	* old coverage API, rather hard to use correctly
	*/

	alias nothrow FcChar32				function(const FcCharSet *a, FcChar32 page, FcChar32 *result)															da_FcCharSetCoverage;

	/* fcdbg.c */
	alias nothrow void					function(const FcValue v)																								da_FcValuePrint;
	alias nothrow void					function(const FcPattern *p)																							da_FcPatternPrint;
	alias nothrow void					function(const FcFontSet *s)																							da_FcFontSetPrint;

	/* fcdefault.c */
	alias nothrow FcStrSet*				function()																												da_FcGetDefaultLangs;
	alias nothrow void					function(FcPattern *pattern)																							da_FcDefaultSubstitute;

	/* fcdir.c */
	alias nothrow FcBool				function(const FcChar8 *file)																							da_FcFileIsDir;
	alias nothrow FcBool				function(FcFontSet *set, FcStrSet *dirs, FcFileCache *cache, FcBlanks *blanks, const FcChar8 *file, FcBool force)		da_FcFileScan;
	alias nothrow FcBool				function(FcFontSet *set, FcStrSet *dirs, FcFileCache *cache, FcBlanks *blanks, const FcChar8 *dir, FcBool force)		da_FcDirScan;
	alias nothrow FcBool				function(FcFontSet *set, FcStrSet *dirs, const FcChar8 *dir)															da_FcDirSave;
	alias nothrow FcCache*				function(const FcChar8 *dir, FcConfig *config, FcChar8 **cache_file)													da_FcDirCacheLoad;
	alias nothrow FcCache*				function(const FcChar8 *dir, FcBool force, FcConfig *config)															da_FcDirCacheRead;
//	alias nothrow FcCache*				function(const FcChar8 *cache_file, struct stat *file_stat)																da_FcDirCacheLoadFile;
	alias nothrow void					function(FcCache *cache)																								da_FcDirCacheUnload;

	/* fcfreetype.c */
	alias nothrow FcPattern*			function(const FcChar8 *file, int id, FcBlanks *blanks, int *count)														da_FcFreeTypeQuery;

	/* fcfs.c */

	alias nothrow FcFontSet*			function()																												da_FcFontSetCreate;
	alias nothrow void					function(FcFontSet *s)																									da_FcFontSetDestroy;
	alias nothrow FcBool				function(FcFontSet *s, FcPattern *font)																					da_FcFontSetAdd;

	/* fcinit.c */
	alias nothrow FcConfig*				function()																												da_FcInitLoadConfig;
	alias nothrow FcConfig*				function()																												da_FcInitLoadConfigAndFonts;
	alias nothrow FcBool				function()																												da_FcInit;
	alias nothrow void					function()																												da_FcFini;
	alias nothrow int					function()																												da_FcGetVersion;
	alias nothrow FcBool				function()																												da_FcInitReinitialize;
	alias nothrow FcBool				function()																												da_FcInitBringUptoDate;

	/* fclang.c */
	alias nothrow FcStrSet*				function()																												da_FcGetLangs;
	alias nothrow const FcCharSet*		function(const FcChar8 *lang)																							da_FcLangGetCharSet;
	alias nothrow FcLangSet*			function()																												da_FcLangSetCreate;
	alias nothrow void					function(FcLangSet *ls)																									da_FcLangSetDestroy;
	alias nothrow FcLangSet*			function(const FcLangSet *ls)																							da_FcLangSetCopy;
	alias nothrow FcBool				function(FcLangSet *ls, const FcChar8 *lang)																			da_FcLangSetAdd;
	alias nothrow FcBool				function(FcLangSet *ls, const FcChar8 *lang)																			da_FcLangSetDel;
	alias nothrow FcLangResult			function(const FcLangSet *ls, const FcChar8 *lang)																		da_FcLangSetHasLang;
	alias nothrow FcLangResult			function(const FcLangSet *lsa, const FcLangSet *lsb)																	da_FcLangSetCompare;
	alias nothrow FcBool				function(const FcLangSet *lsa, const FcLangSet *lsb)																	da_FcLangSetContains;
	alias nothrow FcBool				function(const FcLangSet *lsa, const FcLangSet *lsb)																	da_FcLangSetEqual;
	alias nothrow FcChar32				function(const FcLangSet *ls)																							da_FcLangSetHash;
	alias nothrow FcStrSet*				function(const FcLangSet *ls)																							da_FcLangSetGetLangs;
	alias nothrow FcLangSet*			function(const FcLangSet *a, const FcLangSet *b)																		da_FcLangSetUnion;
	alias nothrow FcLangSet*			function(const FcLangSet *a, const FcLangSet *b)																		da_FcLangSetSubtract;

	/* fclist.c */
	alias nothrow FcObjectSet*			function()																												da_FcObjectSetCreate;
	alias nothrow FcBool				function(FcObjectSet *os, const char *object)																			da_FcObjectSetAdd;
	alias nothrow void					function(FcObjectSet *os)																								da_FcObjectSetDestroy;
//	alias nothrow FcObjectSet*			function(const char *first, va_list va)																					da_FcObjectSetVaBuild;
	alias nothrow FcObjectSet*			function(const char *first, ...)																						da_FcObjectSetBuild;
	alias nothrow FcFontSet*			function(FcConfig *config, FcFontSet **sets, int nsets, FcPattern *p, FcObjectSet *os)									da_FcFontSetList;
	alias nothrow FcFontSet*			function(FcConfig *config, FcPattern *p, FcObjectSet *os)																da_FcFontList;

	/* fcatomic.c */
	alias nothrow FcAtomic*				function(const FcChar8 *file)																							da_FcAtomicCreate;
	alias nothrow FcBool				function(FcAtomic *atomic)																								da_FcAtomicLock;
	alias nothrow FcChar8*				function(FcAtomic *atomic)																								da_FcAtomicNewFile;
	alias nothrow FcChar8*				function(FcAtomic *atomic)																								da_FcAtomicOrigFile;
	alias nothrow FcBool				function(FcAtomic *atomic)																								da_FcAtomicReplaceOrig;
	alias nothrow void					function(FcAtomic *atomic)																								da_FcAtomicDeleteNew;
	alias nothrow void					function(FcAtomic *atomic)																								da_FcAtomicUnlock;
	alias nothrow void					function(FcAtomic *atomic)																								da_FcAtomicDestroy;

	/* fcmatch.c */
	alias nothrow FcPattern*			function(FcConfig *config, FcFontSet **sets, int nsets, FcPattern *p, FcResult *result)									da_FcFontSetMatch;
	alias nothrow FcPattern*			function(FcConfig *config, FcPattern *p, FcResult *result)																da_FcFontMatch;
	alias nothrow FcPattern*			function(FcConfig *config, FcPattern *pat, FcPattern *font)																da_FcFontRenderPrepare;
	alias nothrow FcFontSet*			function(FcConfig *config, FcFontSet **sets, int nsets, FcPattern *p, FcBool trim, FcCharSet **csp, FcResult *result)	da_FcFontSetSort;
	alias nothrow FcFontSet*			function(FcConfig *config, FcPattern *p, FcBool trim, FcCharSet **csp, FcResult *result)								da_FcFontSort;
	alias nothrow void					function(FcFontSet *fs)	da_FcFontSetSortDestroy;

	/* fcmatrix.c */
	alias nothrow FcMatrix*				function(const FcMatrix *mat)																							da_FcMatrixCopy;
	alias nothrow FcBool				function(const FcMatrix *mat1, const FcMatrix *mat2)																	da_FcMatrixEqual;
	alias nothrow void					function(FcMatrix *result, const FcMatrix *a, const FcMatrix *b)														da_FcMatrixMultiply;
	alias nothrow void					function(FcMatrix *m, double c, double s)																				da_FcMatrixRotate;
	alias nothrow void					function(FcMatrix *m, double sx, double sy)																				da_FcMatrixScale;
	alias nothrow void					function(FcMatrix *m, double sh, double sv)																				da_FcMatrixShear;

	/* fcname.c */
	alias nothrow FcBool				function(const FcObjectType *types, int ntype)																			da_FcNameRegisterObjectTypes;
	alias nothrow FcBool				function(const FcObjectType *types, int ntype)																			da_FcNameUnregisterObjectTypes;
	alias nothrow const FcObjectType*	function(const char *object)																							da_FcNameGetObjectType;
	alias nothrow FcBool				function(const FcConstant *consts, int nconsts)																			da_FcNameRegisterConstants;
	alias nothrow FcBool				function(const FcConstant *consts, int nconsts)																			da_FcNameUnregisterConstants;
	alias nothrow const FcConstant*		function(const FcChar8 *string)																							da_FcNameGetConstant;
	alias nothrow FcBool				function(const FcChar8 *string, int *result)																			da_FcNameConstant;
	alias nothrow FcPattern*			function(const FcChar8 *name)																							da_FcNameParse;
	alias nothrow FcChar8*				function(FcPattern *pat)																								da_FcNameUnparse;

	/* fcpat.c */
	alias nothrow FcPattern*			function()																												da_FcPatternCreate;
	alias nothrow FcPattern*			function(const FcPattern *p)																							da_FcPatternDuplicate;
	alias nothrow void					function(FcPattern *p)																									da_FcPatternReference;
	alias nothrow FcPattern*			function(FcPattern *p, const FcObjectSet *os)																			da_FcPatternFilter;
	alias nothrow void					function(FcValue v)																										da_FcValueDestroy;
	alias nothrow FcBool				function(FcValue va, FcValue vb)																						da_FcValueEqual;
	alias nothrow FcValue				function(FcValue v)																										da_FcValueSave;
	alias nothrow void					function(FcPattern *p)																									da_FcPatternDestroy;
	alias nothrow FcBool				function(const FcPattern *pa, const FcPattern *pb)																		da_FcPatternEqual;
	alias nothrow FcBool				function(const FcPattern *pa, const FcPattern *pb, const FcObjectSet *os)												da_FcPatternEqualSubset;
	alias nothrow FcChar32				function(const FcPattern *p)																							da_FcPatternHash;
	alias nothrow FcBool				function(FcPattern *p, const char *object, FcValue value, FcBool append)												da_FcPatternAdd;
	alias nothrow FcBool				function(FcPattern *p, const char *object, FcValue value, FcBool append)												da_FcPatternAddWeak;
	alias nothrow FcResult				function(const FcPattern *p, const char *object, int id, FcValue *v)													da_FcPatternGet;
	alias nothrow FcBool				function(FcPattern *p, const char *object)																				da_FcPatternDel;
	alias nothrow FcBool				function(FcPattern *p, const char *object, int id)																		da_FcPatternRemove;
	alias nothrow FcBool				function(FcPattern *p, const char *object, int i)																		da_FcPatternAddInteger;
	alias nothrow FcBool				function(FcPattern *p, const char *object, double d)																	da_FcPatternAddDouble;
	alias nothrow FcBool				function(FcPattern *p, const char *object, const FcChar8 *s)															da_FcPatternAddString;
	alias nothrow FcBool				function(FcPattern *p, const char *object, const FcMatrix *s)															da_FcPatternAddMatrix;
	alias nothrow FcBool				function(FcPattern *p, const char *object, const FcCharSet *c)															da_FcPatternAddCharSet;
	alias nothrow FcBool				function(FcPattern *p, const char *object, FcBool b)																	da_FcPatternAddBool;
	alias nothrow FcBool				function(FcPattern *p, const char *object, const FcLangSet *ls)															da_FcPatternAddLangSet;
	alias nothrow FcResult				function(const FcPattern *p, const char *object, int n, int *i)															da_FcPatternGetInteger;
	alias nothrow FcResult				function(const FcPattern *p, const char *object, int n, double *d)														da_FcPatternGetDouble;
	alias nothrow FcResult				function(const FcPattern *p, const char *object, int n, FcChar8 ** s)													da_FcPatternGetString;
	alias nothrow FcResult				function(const FcPattern *p, const char *object, int n, FcMatrix **s)													da_FcPatternGetMatrix;
	alias nothrow FcResult				function(const FcPattern *p, const char *object, int n, FcCharSet **c)													da_FcPatternGetCharSet;
	alias nothrow FcResult				function(const FcPattern *p, const char *object, int n, FcBool *b)														da_FcPatternGetBool;
	alias nothrow FcResult				function(const FcPattern *p, const char *object, int n, FcLangSet **ls)													da_FcPatternGetLangSet;
//	alias nothrow FcPattern*			function(FcPattern *p, va_list va)																						da_FcPatternVaBuild;
	alias nothrow FcPattern*			function(FcPattern *p, ...)																								da_FcPatternBuild;
	alias nothrow FcChar8*				function(FcPattern *pat, const FcChar8 *format)																			da_FcPatternFormat;

	/* fcstr.c */
	alias nothrow FcChar8*				function(const FcChar8 *s)																								da_FcStrCopy;
	alias nothrow FcChar8*				function(const FcChar8 *s)																								da_FcStrCopyFilename;
	alias nothrow FcChar8*				function(const FcChar8 *s1, const FcChar8 *s2)																			da_FcStrPlus;
	alias nothrow void					function(FcChar8 *s)																									da_FcStrFree;
	/* These are ASCII only, suitable only for pattern element names */
/*	#define	function(c)	((0101 <=(c) &&(c) <= 0132))	da_FcIsUpper
	#define	function(c)	((0141 <=(c) &&(c) <= 0172))	da_FcIsLower
	#define	function(c)	(FcIsUpper(c) ?(c) - 0101 + 0141 :(c))	da_FcToLower*/
	alias nothrow FcChar8*				function(const FcChar8 *s)																								da_FcStrDowncase;
	alias nothrow int					function(const FcChar8 *s1, const FcChar8 *s2)																			da_FcStrCmpIgnoreCase;
	alias nothrow int					function(const FcChar8 *s1, const FcChar8 *s2)																			da_FcStrCmp;
	alias nothrow const FcChar8*		function(const FcChar8 *s1, const FcChar8 *s2)																			da_FcStrStrIgnoreCase;
	alias nothrow const FcChar8*		function(const FcChar8 *s1, const FcChar8 *s2)																			da_FcStrStr;
	alias nothrow int					function(const FcChar8 *src_orig, FcChar32 *dst, int len)																da_FcUtf8ToUcs4;
//	alias nothrow FcBool				function(const FcChar8 *string, int len, int *nchar, int *wchar)														da_FcUtf8Len;
	alias nothrow int					function(FcChar32	ucs4, FcChar8	dest[FC_UTF8_MAX_LEN])																da_FcUcs4ToUtf8;
	alias nothrow int					function(const FcChar8 *src_orig, FcEndian endian, FcChar32 *dst, int len)												da_FcUtf16ToUcs4;
//	alias nothrow FcBool				function(const FcChar8 *string, FcEndian endian, int len, int *nchar, int *wchar)										da_FcUtf16Len;
	alias nothrow FcChar8*				function(const FcChar8 *file)																							da_FcStrDirname;
	alias nothrow FcChar8*				function(const FcChar8 *file)																							da_FcStrBasename;
	alias nothrow FcStrSet*				function()																												da_FcStrSetCreate;
	alias nothrow FcBool				function(FcStrSet *set, const FcChar8 *s)																				da_FcStrSetMember;
	alias nothrow FcBool				function(FcStrSet *sa, FcStrSet *sb)																					da_FcStrSetEqual;
	alias nothrow FcBool				function(FcStrSet *set, const FcChar8 *s)																				da_FcStrSetAdd;
	alias nothrow FcBool				function(FcStrSet *set, const FcChar8 *s)																				da_FcStrSetAddFilename;
	alias nothrow FcBool				function(FcStrSet *set, const FcChar8 *s)																				da_FcStrSetDel;
	alias nothrow void					function(FcStrSet *set)																									da_FcStrSetDestroy;
	alias nothrow FcStrList*			function(FcStrSet *set)																									da_FcStrListCreate;
	alias nothrow FcChar8*				function(FcStrList *list)																								da_FcStrListNext;
	alias nothrow void					function(FcStrList *list)																								da_FcStrListDone;

	/* fcxml.c */
	alias nothrow FcBool				function(FcConfig *config, const FcChar8 *file, FcBool complain)														da_FcConfigParseAndLoad;
}

__gshared
{
	da_FcBlanksCreate						FcBlanksCreate;
	da_FcBlanksDestroy						FcBlanksDestroy;
	da_FcBlanksAdd							FcBlanksAdd;
	da_FcBlanksIsMember						FcBlanksIsMember;

	da_FcCacheDir							FcCacheDir;
	da_FcCacheCopySet						FcCacheCopySet;
	da_FcCacheSubdir						FcCacheSubdir;
	da_FcCacheNumSubdir						FcCacheNumSubdir;
	da_FcCacheNumFont						FcCacheNumFont;
	da_FcDirCacheUnlink						FcDirCacheUnlink;
	da_FcDirCacheValid						FcDirCacheValid;
	da_FcDirCacheClean						FcDirCacheClean;
	da_FcCacheCreateTagFile					FcCacheCreateTagFile;

	da_FcConfigHome							FcConfigHome;
	da_FcConfigEnableHome					FcConfigEnableHome;
	da_FcConfigFilename						FcConfigFilename;
	da_FcConfigCreate						FcConfigCreate;
	da_FcConfigReference					FcConfigReference;
	da_FcConfigDestroy						FcConfigDestroy;
	da_FcConfigSetCurrent					FcConfigSetCurrent;
	da_FcConfigGetCurrent					FcConfigGetCurrent;
	da_FcConfigUptoDate						FcConfigUptoDate;
	da_FcConfigBuildFonts					FcConfigBuildFonts;
	da_FcConfigGetFontDirs					FcConfigGetFontDirs;
	da_FcConfigGetConfigDirs				FcConfigGetConfigDirs;
	da_FcConfigGetConfigFiles				FcConfigGetConfigFiles;
	da_FcConfigGetCache						FcConfigGetCache;
	da_FcConfigGetBlanks					FcConfigGetBlanks;
	da_FcConfigGetCacheDirs					FcConfigGetCacheDirs;
	da_FcConfigGetRescanInterval			FcConfigGetRescanInterval;
	da_FcConfigSetRescanInterval			FcConfigSetRescanInterval;
	da_FcConfigGetFonts						FcConfigGetFonts;
	da_FcConfigAppFontAddFile				FcConfigAppFontAddFile;
	da_FcConfigAppFontAddDir				FcConfigAppFontAddDir;
	da_FcConfigAppFontClear					FcConfigAppFontClear;
	da_FcConfigSubstituteWithPat			FcConfigSubstituteWithPat;
	da_FcConfigSubstitute					FcConfigSubstitute;

	da_FcCharSetCreate						FcCharSetCreate;

	da_FcCharSetNew							FcCharSetNew;
	da_FcCharSetDestroy						FcCharSetDestroy;
	da_FcCharSetAddChar						FcCharSetAddChar;
	da_FcCharSetDelChar						FcCharSetDelChar;
	da_FcCharSetCopy						FcCharSetCopy;
	da_FcCharSetEqual						FcCharSetEqual;
	da_FcCharSetIntersect					FcCharSetIntersect;
	da_FcCharSetUnion						FcCharSetUnion;
	da_FcCharSetSubtract					FcCharSetSubtract;
	da_FcCharSetMerge						FcCharSetMerge;
	da_FcCharSetHasChar						FcCharSetHasChar;
	da_FcCharSetCount						FcCharSetCount;
	da_FcCharSetIntersectCount				FcCharSetIntersectCount;
	da_FcCharSetSubtractCount				FcCharSetSubtractCount;
	da_FcCharSetIsSubset					FcCharSetIsSubset;
	da_FcCharSetFirstPage					FcCharSetFirstPage;
	da_FcCharSetNextPage					FcCharSetNextPage;

	da_FcCharSetCoverage					FcCharSetCoverage;

	da_FcValuePrint							FcValuePrint;
	da_FcPatternPrint						FcPatternPrint;
	da_FcFontSetPrint						FcFontSetPrint;

	da_FcGetDefaultLangs					FcGetDefaultLangs;
	da_FcDefaultSubstitute					FcDefaultSubstitute;

	da_FcFileIsDir							FcFileIsDir;
	da_FcFileScan							FcFileScan;
	da_FcDirScan							FcDirScan;
	da_FcDirSave							FcDirSave;
	da_FcDirCacheLoad						FcDirCacheLoad;
	da_FcDirCacheRead						FcDirCacheRead;
//	da_FcDirCacheLoadFile					FcDirCacheLoadFile;
	da_FcDirCacheUnload						FcDirCacheUnload;

	da_FcFreeTypeQuery						FcFreeTypeQuery;

	da_FcFontSetCreate						FcFontSetCreate;
	da_FcFontSetDestroy						FcFontSetDestroy;
	da_FcFontSetAdd							FcFontSetAdd;

	da_FcInitLoadConfig						FcInitLoadConfig;
	da_FcInitLoadConfigAndFonts				FcInitLoadConfigAndFonts;
	da_FcInit								FcInit;
	da_FcFini								FcFini;
	da_FcGetVersion							FcGetVersion;
	da_FcInitReinitialize					FcInitReinitialize;
	da_FcInitBringUptoDate					FcInitBringUptoDate;

	da_FcGetLangs							FcGetLangs;
	da_FcLangGetCharSet						FcLangGetCharSet;
	da_FcLangSetCreate						FcLangSetCreate;
	da_FcLangSetDestroy						FcLangSetDestroy;
	da_FcLangSetCopy						FcLangSetCopy;
	da_FcLangSetAdd							FcLangSetAdd;
	da_FcLangSetDel							FcLangSetDel;
	da_FcLangSetHasLang						FcLangSetHasLang;
	da_FcLangSetCompare						FcLangSetCompare;
	da_FcLangSetContains					FcLangSetContains;
	da_FcLangSetEqual						FcLangSetEqual;
	da_FcLangSetHash						FcLangSetHash;
	da_FcLangSetGetLangs					FcLangSetGetLangs;
	da_FcLangSetUnion						FcLangSetUnion;
	da_FcLangSetSubtract					FcLangSetSubtract;

	da_FcObjectSetCreate					FcObjectSetCreate;
	da_FcObjectSetAdd						FcObjectSetAdd;
	da_FcObjectSetDestroy					FcObjectSetDestroy;
//	da_FcObjectSetVaBuild					FcObjectSetVaBuild;
	da_FcObjectSetBuild						FcObjectSetBuild;
	da_FcFontSetList						FcFontSetList;
	da_FcFontList							FcFontList;

	da_FcAtomicCreate						FcAtomicCreate;
	da_FcAtomicLock							FcAtomicLock;
	da_FcAtomicNewFile						FcAtomicNewFile;
	da_FcAtomicOrigFile						FcAtomicOrigFile;
	da_FcAtomicReplaceOrig					FcAtomicReplaceOrig;
	da_FcAtomicDeleteNew					FcAtomicDeleteNew;
	da_FcAtomicUnlock						FcAtomicUnlock;
	da_FcAtomicDestroy						FcAtomicDestroy;

	da_FcFontSetMatch						FcFontSetMatch;
	da_FcFontMatch							FcFontMatch;
	da_FcFontRenderPrepare					FcFontRenderPrepare;
	da_FcFontSetSort						FcFontSetSort;
	da_FcFontSort							FcFontSort;

	da_FcMatrixCopy							FcMatrixCopy;
	da_FcMatrixEqual						FcMatrixEqual;
	da_FcMatrixMultiply						FcMatrixMultiply;
	da_FcMatrixRotate						FcMatrixRotate;
	da_FcMatrixScale						FcMatrixScale;
	da_FcMatrixShear						FcMatrixShear;

	da_FcNameRegisterObjectTypes			FcNameRegisterObjectTypes;
	da_FcNameUnregisterObjectTypes			FcNameUnregisterObjectTypes;
	da_FcNameGetObjectType					FcNameGetObjectType;
	da_FcNameRegisterConstants				FcNameRegisterConstants;
	da_FcNameUnregisterConstants			FcNameUnregisterConstants;
	da_FcNameGetConstant					FcNameGetConstant;
	da_FcNameConstant						FcNameConstant;
	da_FcNameParse							FcNameParse;
	da_FcNameUnparse						FcNameUnparse;

	da_FcPatternCreate						FcPatternCreate;
	da_FcPatternDuplicate					FcPatternDuplicate;
	da_FcPatternReference					FcPatternReference;
	da_FcPatternFilter						FcPatternFilter;
	da_FcValueDestroy						FcValueDestroy;
	da_FcValueEqual							FcValueEqual;
	da_FcValueSave							FcValueSave;
	da_FcPatternDestroy						FcPatternDestroy;
	da_FcPatternEqual						FcPatternEqual;
	da_FcPatternEqualSubset					FcPatternEqualSubset;
	da_FcPatternHash						FcPatternHash;
	da_FcPatternAdd							FcPatternAdd;
	da_FcPatternAddWeak						FcPatternAddWeak;
	da_FcPatternGet							FcPatternGet;
	da_FcPatternDel							FcPatternDel;
	da_FcPatternRemove						FcPatternRemove;
	da_FcPatternAddInteger					FcPatternAddInteger;
	da_FcPatternAddDouble					FcPatternAddDouble;
	da_FcPatternAddString					FcPatternAddString;
	da_FcPatternAddMatrix					FcPatternAddMatrix;
	da_FcPatternAddCharSet					FcPatternAddCharSet;
	da_FcPatternAddBool						FcPatternAddBool;
	da_FcPatternAddLangSet					FcPatternAddLangSet;
	da_FcPatternGetInteger					FcPatternGetInteger;
	da_FcPatternGetDouble					FcPatternGetDouble;
	da_FcPatternGetString					FcPatternGetString;
	da_FcPatternGetMatrix					FcPatternGetMatrix;
	da_FcPatternGetCharSet					FcPatternGetCharSet;
	da_FcPatternGetBool						FcPatternGetBool;
	da_FcPatternGetLangSet					FcPatternGetLangSet;
//	da_FcPatternVaBuild						FcPatternVaBuild;
	da_FcPatternBuild						FcPatternBuild;
	da_FcPatternFormat						FcPatternFormat;

	da_FcStrCopy							FcStrCopy;
	da_FcStrCopyFilename					FcStrCopyFilename;
	da_FcStrPlus							FcStrPlus;
	da_FcStrFree							FcStrFree;

	da_FcStrDowncase						FcStrDowncase;
	da_FcStrCmpIgnoreCase					FcStrCmpIgnoreCase;
	da_FcStrCmp								FcStrCmp;
	da_FcStrStrIgnoreCase					FcStrStrIgnoreCase;
	da_FcStrStr								FcStrStr;
	da_FcUtf8ToUcs4							FcUtf8ToUcs4;
//	da_FcUtf8Len							FcUtf8Len;
	da_FcUcs4ToUtf8							FcUcs4ToUtf8;
	da_FcUtf16ToUcs4						FcUtf16ToUcs4;
//	da_FcUtf16Len							FcUtf16Len;
	da_FcStrDirname							FcStrDirname;
	da_FcStrBasename						FcStrBasename;
	da_FcStrSetCreate						FcStrSetCreate;
	da_FcStrSetMember						FcStrSetMember;
	da_FcStrSetEqual						FcStrSetEqual;
	da_FcStrSetAdd							FcStrSetAdd;
	da_FcStrSetAddFilename					FcStrSetAddFilename;
	da_FcStrSetDel							FcStrSetDel;
	da_FcStrSetDestroy						FcStrSetDestroy;
	da_FcStrListCreate						FcStrListCreate;
	da_FcStrListNext						FcStrListNext;
	da_FcStrListDone						FcStrListDone;

	da_FcConfigParseAndLoad					FcConfigParseAndLoad;
}
