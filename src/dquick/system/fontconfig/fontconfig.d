module dquick.system.fontconfig.fontconfig;

public
{
	import dquick.system.fontconfig.types;
	import dquick.system.fontconfig.functions;
}

private
{
    import derelict.util.loader;
    import derelict.util.system;

    static if (Derelict_OS_Posix)
    {
		enum libNames = "libfontconfig.so,libfontconfig.so.1";
    }
    else static if (Derelict_OS_Windows)
		enum libNames = "libfontconfig-1.dll";
	else
        static assert(0, "Need to implement fontconfig libNames for this operating system.");
}

class DerelictFontConfigLoader : SharedLibLoader
{
    protected
    {
        override void loadSymbols()
        {
			bindFunc(cast(void**)&FcBlanksCreate,						"FcBlanksCreate");
			bindFunc(cast(void**)&FcBlanksDestroy,						"FcBlanksDestroy");
			bindFunc(cast(void**)&FcBlanksAdd,							"FcBlanksAdd");
			bindFunc(cast(void**)&FcBlanksIsMember,						"FcBlanksIsMember");

			bindFunc(cast(void**)&FcCacheDir,							"FcCacheDir");
			bindFunc(cast(void**)&FcCacheCopySet,						"FcCacheCopySet");
			bindFunc(cast(void**)&FcCacheSubdir,						"FcCacheSubdir");
			bindFunc(cast(void**)&FcCacheNumSubdir,						"FcCacheNumSubdir");
			bindFunc(cast(void**)&FcCacheNumFont,						"FcCacheNumFont");
			bindFunc(cast(void**)&FcDirCacheUnlink,						"FcDirCacheUnlink");
			bindFunc(cast(void**)&FcDirCacheValid,						"FcDirCacheValid");
			bindFunc(cast(void**)&FcDirCacheClean,						"FcDirCacheClean");
			bindFunc(cast(void**)&FcCacheCreateTagFile,					"FcCacheCreateTagFile");

			bindFunc(cast(void**)&FcConfigHome,							"FcConfigHome");
			bindFunc(cast(void**)&FcConfigEnableHome,					"FcConfigEnableHome");
			bindFunc(cast(void**)&FcConfigFilename,						"FcConfigFilename");
			bindFunc(cast(void**)&FcConfigCreate,						"FcConfigCreate");
			bindFunc(cast(void**)&FcConfigReference,					"FcConfigReference");
			bindFunc(cast(void**)&FcConfigDestroy,						"FcConfigDestroy");
			bindFunc(cast(void**)&FcConfigSetCurrent,					"FcConfigSetCurrent");
			bindFunc(cast(void**)&FcConfigGetCurrent,					"FcConfigGetCurrent");
			bindFunc(cast(void**)&FcConfigUptoDate,						"FcConfigUptoDate");
			bindFunc(cast(void**)&FcConfigBuildFonts,					"FcConfigBuildFonts");
			bindFunc(cast(void**)&FcConfigGetFontDirs,					"FcConfigGetFontDirs");
			bindFunc(cast(void**)&FcConfigGetConfigDirs,				"FcConfigGetConfigDirs");
			bindFunc(cast(void**)&FcConfigGetConfigFiles,				"FcConfigGetConfigFiles");
			bindFunc(cast(void**)&FcConfigGetCache,						"FcConfigGetCache");
			bindFunc(cast(void**)&FcConfigGetBlanks,					"FcConfigGetBlanks");
			bindFunc(cast(void**)&FcConfigGetCacheDirs,					"FcConfigGetCacheDirs");
			bindFunc(cast(void**)&FcConfigGetRescanInterval,			"FcConfigGetRescanInterval");
			bindFunc(cast(void**)&FcConfigSetRescanInterval,			"FcConfigSetRescanInterval");
			bindFunc(cast(void**)&FcConfigGetFonts,						"FcConfigGetFonts");
			bindFunc(cast(void**)&FcConfigAppFontAddFile,				"FcConfigAppFontAddFile");
			bindFunc(cast(void**)&FcConfigAppFontAddDir,				"FcConfigAppFontAddDir");
			bindFunc(cast(void**)&FcConfigAppFontClear,					"FcConfigAppFontClear");
			bindFunc(cast(void**)&FcConfigSubstituteWithPat,			"FcConfigSubstituteWithPat");
			bindFunc(cast(void**)&FcConfigSubstitute,					"FcConfigSubstitute");

			bindFunc(cast(void**)&FcCharSetCreate,						"FcCharSetCreate");

			bindFunc(cast(void**)&FcCharSetNew,							"FcCharSetNew");
			bindFunc(cast(void**)&FcCharSetDestroy,						"FcCharSetDestroy");
			bindFunc(cast(void**)&FcCharSetAddChar,						"FcCharSetAddChar");
			bindFunc(cast(void**)&FcCharSetDelChar,						"FcCharSetDelChar");
			bindFunc(cast(void**)&FcCharSetCopy,						"FcCharSetCopy");
			bindFunc(cast(void**)&FcCharSetEqual,						"FcCharSetEqual");
			bindFunc(cast(void**)&FcCharSetIntersect,					"FcCharSetIntersect");
			bindFunc(cast(void**)&FcCharSetUnion,						"FcCharSetUnion");
			bindFunc(cast(void**)&FcCharSetSubtract,					"FcCharSetSubtract");
			bindFunc(cast(void**)&FcCharSetMerge,						"FcCharSetMerge");
			bindFunc(cast(void**)&FcCharSetHasChar,						"FcCharSetHasChar");
			bindFunc(cast(void**)&FcCharSetCount,						"FcCharSetCount");
			bindFunc(cast(void**)&FcCharSetIntersectCount,				"FcCharSetIntersectCount");
			bindFunc(cast(void**)&FcCharSetSubtractCount,				"FcCharSetSubtractCount");
			bindFunc(cast(void**)&FcCharSetIsSubset,					"FcCharSetIsSubset");
			bindFunc(cast(void**)&FcCharSetFirstPage,					"FcCharSetFirstPage");
			bindFunc(cast(void**)&FcCharSetNextPage,					"FcCharSetNextPage");

			bindFunc(cast(void**)&FcCharSetCoverage,					"FcCharSetCoverage");

			bindFunc(cast(void**)&FcValuePrint,							"FcValuePrint");
			bindFunc(cast(void**)&FcPatternPrint,						"FcPatternPrint");
			bindFunc(cast(void**)&FcFontSetPrint,						"FcFontSetPrint");

			bindFunc(cast(void**)&FcGetDefaultLangs,					"FcGetDefaultLangs");
			bindFunc(cast(void**)&FcDefaultSubstitute,					"FcDefaultSubstitute");

			bindFunc(cast(void**)&FcFileIsDir,							"FcFileIsDir");
			bindFunc(cast(void**)&FcFileScan,							"FcFileScan");
			bindFunc(cast(void**)&FcDirScan,							"FcDirScan");
			bindFunc(cast(void**)&FcDirSave,							"FcDirSave");
			bindFunc(cast(void**)&FcDirCacheLoad,						"FcDirCacheLoad");
			bindFunc(cast(void**)&FcDirCacheRead,						"FcDirCacheRead");
//			bindFunc(cast(void**)&FcDirCacheLoadFile,					"FcDirCacheLoadFile");
			bindFunc(cast(void**)&FcDirCacheUnload,						"FcDirCacheUnload");

			bindFunc(cast(void**)&FcFreeTypeQuery,						"FcFreeTypeQuery");

			bindFunc(cast(void**)&FcFontSetCreate,						"FcFontSetCreate");
			bindFunc(cast(void**)&FcFontSetDestroy,						"FcFontSetDestroy");
			bindFunc(cast(void**)&FcFontSetAdd,							"FcFontSetAdd");

			bindFunc(cast(void**)&FcInitLoadConfig,						"FcInitLoadConfig");
			bindFunc(cast(void**)&FcInitLoadConfigAndFonts,				"FcInitLoadConfigAndFonts");
			bindFunc(cast(void**)&FcInit,								"FcInit");
			bindFunc(cast(void**)&FcFini,								"FcFini");
			bindFunc(cast(void**)&FcGetVersion,							"FcGetVersion");
			bindFunc(cast(void**)&FcInitReinitialize,					"FcInitReinitialize");
			bindFunc(cast(void**)&FcInitBringUptoDate,					"FcInitBringUptoDate");

			bindFunc(cast(void**)&FcGetLangs,							"FcGetLangs");
			bindFunc(cast(void**)&FcLangGetCharSet,						"FcLangGetCharSet");
			bindFunc(cast(void**)&FcLangSetCreate,						"FcLangSetCreate");
			bindFunc(cast(void**)&FcLangSetDestroy,						"FcLangSetDestroy");
			bindFunc(cast(void**)&FcLangSetCopy,						"FcLangSetCopy");
			bindFunc(cast(void**)&FcLangSetAdd,							"FcLangSetAdd");
			bindFunc(cast(void**)&FcLangSetDel,							"FcLangSetDel");
			bindFunc(cast(void**)&FcLangSetHasLang,						"FcLangSetHasLang");
			bindFunc(cast(void**)&FcLangSetCompare,						"FcLangSetCompare");
			bindFunc(cast(void**)&FcLangSetContains,					"FcLangSetContains");
			bindFunc(cast(void**)&FcLangSetEqual,						"FcLangSetEqual");
			bindFunc(cast(void**)&FcLangSetHash,						"FcLangSetHash");
			bindFunc(cast(void**)&FcLangSetGetLangs,					"FcLangSetGetLangs");
			bindFunc(cast(void**)&FcLangSetUnion,						"FcLangSetUnion");
			bindFunc(cast(void**)&FcLangSetSubtract,					"FcLangSetSubtract");

			bindFunc(cast(void**)&FcObjectSetCreate,					"FcObjectSetCreate");
			bindFunc(cast(void**)&FcObjectSetAdd,						"FcObjectSetAdd");
			bindFunc(cast(void**)&FcObjectSetDestroy,					"FcObjectSetDestroy");
//			bindFunc(cast(void**)&FcObjectSetVaBuild,					"FcObjectSetVaBuild");
			bindFunc(cast(void**)&FcObjectSetBuild,						"FcObjectSetBuild");
			bindFunc(cast(void**)&FcFontSetList,						"FcFontSetList");
			bindFunc(cast(void**)&FcFontList,							"FcFontList");

			bindFunc(cast(void**)&FcAtomicCreate,						"FcAtomicCreate");
			bindFunc(cast(void**)&FcAtomicLock,							"FcAtomicLock");
			bindFunc(cast(void**)&FcAtomicNewFile,						"FcAtomicNewFile");
			bindFunc(cast(void**)&FcAtomicOrigFile,						"FcAtomicOrigFile");
			bindFunc(cast(void**)&FcAtomicReplaceOrig,					"FcAtomicReplaceOrig");
			bindFunc(cast(void**)&FcAtomicDeleteNew,					"FcAtomicDeleteNew");
			bindFunc(cast(void**)&FcAtomicUnlock,						"FcAtomicUnlock");
			bindFunc(cast(void**)&FcAtomicDestroy,						"FcAtomicDestroy");

			bindFunc(cast(void**)&FcFontSetMatch,						"FcFontSetMatch");
			bindFunc(cast(void**)&FcFontMatch,							"FcFontMatch");
			bindFunc(cast(void**)&FcFontRenderPrepare,					"FcFontRenderPrepare");
			bindFunc(cast(void**)&FcFontSetSort,						"FcFontSetSort");
			bindFunc(cast(void**)&FcFontSort,							"FcFontSort");

			bindFunc(cast(void**)&FcMatrixCopy,							"FcMatrixCopy");
			bindFunc(cast(void**)&FcMatrixEqual,						"FcMatrixEqual");
			bindFunc(cast(void**)&FcMatrixMultiply,						"FcMatrixMultiply");
			bindFunc(cast(void**)&FcMatrixRotate,						"FcMatrixRotate");
			bindFunc(cast(void**)&FcMatrixScale,						"FcMatrixScale");
			bindFunc(cast(void**)&FcMatrixShear,						"FcMatrixShear");

			bindFunc(cast(void**)&FcNameRegisterObjectTypes,			"FcNameRegisterObjectTypes");
			bindFunc(cast(void**)&FcNameUnregisterObjectTypes,			"FcNameUnregisterObjectTypes");
			bindFunc(cast(void**)&FcNameGetObjectType,					"FcNameGetObjectType");
			bindFunc(cast(void**)&FcNameRegisterConstants,				"FcNameRegisterConstants");
			bindFunc(cast(void**)&FcNameUnregisterConstants,			"FcNameUnregisterConstants");
			bindFunc(cast(void**)&FcNameGetConstant,					"FcNameGetConstant");
			bindFunc(cast(void**)&FcNameConstant,						"FcNameConstant");
			bindFunc(cast(void**)&FcNameParse,							"FcNameParse");
			bindFunc(cast(void**)&FcNameUnparse,						"FcNameUnparse");

			bindFunc(cast(void**)&FcPatternCreate,						"FcPatternCreate");
			bindFunc(cast(void**)&FcPatternDuplicate,					"FcPatternDuplicate");
			bindFunc(cast(void**)&FcPatternReference,					"FcPatternReference");
			bindFunc(cast(void**)&FcPatternFilter,						"FcPatternFilter");
			bindFunc(cast(void**)&FcValueDestroy,						"FcValueDestroy");
			bindFunc(cast(void**)&FcValueEqual,							"FcValueEqual");
			bindFunc(cast(void**)&FcValueSave,							"FcValueSave");
			bindFunc(cast(void**)&FcPatternDestroy,						"FcPatternDestroy");
			bindFunc(cast(void**)&FcPatternEqual,						"FcPatternEqual");
			bindFunc(cast(void**)&FcPatternEqualSubset,					"FcPatternEqualSubset");
			bindFunc(cast(void**)&FcPatternHash,						"FcPatternHash");
			bindFunc(cast(void**)&FcPatternAdd,							"FcPatternAdd");
			bindFunc(cast(void**)&FcPatternAddWeak,						"FcPatternAddWeak");
			bindFunc(cast(void**)&FcPatternGet,							"FcPatternGet");
			bindFunc(cast(void**)&FcPatternDel,							"FcPatternDel");
			bindFunc(cast(void**)&FcPatternRemove,						"FcPatternRemove");
			bindFunc(cast(void**)&FcPatternAddInteger,					"FcPatternAddInteger");
			bindFunc(cast(void**)&FcPatternAddDouble,					"FcPatternAddDouble");
			bindFunc(cast(void**)&FcPatternAddString,					"FcPatternAddString");
			bindFunc(cast(void**)&FcPatternAddMatrix,					"FcPatternAddMatrix");
			bindFunc(cast(void**)&FcPatternAddCharSet,					"FcPatternAddCharSet");
			bindFunc(cast(void**)&FcPatternAddBool,						"FcPatternAddBool");
			bindFunc(cast(void**)&FcPatternAddLangSet,					"FcPatternAddLangSet");
			bindFunc(cast(void**)&FcPatternGetInteger,					"FcPatternGetInteger");
			bindFunc(cast(void**)&FcPatternGetDouble,					"FcPatternGetDouble");
			bindFunc(cast(void**)&FcPatternGetString,					"FcPatternGetString");
			bindFunc(cast(void**)&FcPatternGetMatrix,					"FcPatternGetMatrix");
			bindFunc(cast(void**)&FcPatternGetCharSet,					"FcPatternGetCharSet");
			bindFunc(cast(void**)&FcPatternGetBool,						"FcPatternGetBool");
			bindFunc(cast(void**)&FcPatternGetLangSet,					"FcPatternGetLangSet");
//			bindFunc(cast(void**)&FcPatternVaBuild,						"FcPatternVaBuild");
			bindFunc(cast(void**)&FcPatternBuild,						"FcPatternBuild");
			bindFunc(cast(void**)&FcPatternFormat,						"FcPatternFormat");

			bindFunc(cast(void**)&FcStrCopy,							"FcStrCopy");
			bindFunc(cast(void**)&FcStrCopyFilename,					"FcStrCopyFilename");
			bindFunc(cast(void**)&FcStrPlus,							"FcStrPlus");
			bindFunc(cast(void**)&FcStrFree,							"FcStrFree");

			bindFunc(cast(void**)&FcStrDowncase,						"FcStrDowncase");
			bindFunc(cast(void**)&FcStrCmpIgnoreCase,					"FcStrCmpIgnoreCase");
			bindFunc(cast(void**)&FcStrCmp,								"FcStrCmp");
			bindFunc(cast(void**)&FcStrStrIgnoreCase,					"FcStrStrIgnoreCase");
			bindFunc(cast(void**)&FcStrStr,								"FcStrStr");
			bindFunc(cast(void**)&FcUtf8ToUcs4,							"FcUtf8ToUcs4");
//			bindFunc(cast(void**)&FcUtf8Len,							"FcUtf8Len");
			bindFunc(cast(void**)&FcUcs4ToUtf8,							"FcUcs4ToUtf8");
			bindFunc(cast(void**)&FcUtf16ToUcs4,						"FcUtf16ToUcs4");
//			bindFunc(cast(void**)&FcUtf16Len,							"FcUtf16Len");
			bindFunc(cast(void**)&FcStrDirname,							"FcStrDirname");
			bindFunc(cast(void**)&FcStrBasename,						"FcStrBasename");
			bindFunc(cast(void**)&FcStrSetCreate,						"FcStrSetCreate");
			bindFunc(cast(void**)&FcStrSetMember,						"FcStrSetMember");
			bindFunc(cast(void**)&FcStrSetEqual,						"FcStrSetEqual");
			bindFunc(cast(void**)&FcStrSetAdd,							"FcStrSetAdd");
			bindFunc(cast(void**)&FcStrSetAddFilename,					"FcStrSetAddFilename");
			bindFunc(cast(void**)&FcStrSetDel,							"FcStrSetDel");
			bindFunc(cast(void**)&FcStrSetDestroy,						"FcStrSetDestroy");
			bindFunc(cast(void**)&FcStrListCreate,						"FcStrListCreate");
			bindFunc(cast(void**)&FcStrListNext,						"FcStrListNext");
			bindFunc(cast(void**)&FcStrListDone,						"FcStrListDone");

			bindFunc(cast(void**)&FcConfigParseAndLoad,					"FcConfigParseAndLoad");
		}
    }
    public
    {
        this()
        {
            super(libNames);
        }
    }
}

__gshared DerelictFontConfigLoader DerelictFontConfig;

shared static this()
{
	DerelictFontConfig = new DerelictFontConfigLoader();
}

shared static ~this()
{
	DerelictFontConfig.unload();
}
