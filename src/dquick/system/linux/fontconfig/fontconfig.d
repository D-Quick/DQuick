module dquick.system.linux.fontconfig.fontconfig;

public
{
	import dquick.system.linux.fontconfig.types;
	import dquick.system.linux.fontconfig.functions;
}

private
{
    import derelict.util.loader;
    import derelict.util.system;

    static if(Derelict_OS_Posix)
    {
		enum libNames = "libfontconfig.so,libfontconfig.so.1";
    }
    else
        static assert(0, "Need to implement fontconfig libNames for this operating system.");
}

class DerelictFontConfigLoader : SharedLibLoader
{
    protected
    {
        override void loadSymbols()
        {
			bindFunc(cast(void**)&FcInit,					"FcInit");
			bindFunc(cast(void**)&FcFini,					"FcFini");
			bindFunc(cast(void**)&FcFontList,				"FcFontList");
			bindFunc(cast(void**)&FcInitLoadConfigAndFonts,	"FcInitLoadConfigAndFonts");
			bindFunc(cast(void**)&FcNameParse,				"FcNameParse");
			bindFunc(cast(void**)&FcConfigSubstitute,		"FcConfigSubstitute");
			bindFunc(cast(void**)&FcDefaultSubstitute,		"FcDefaultSubstitute");
			bindFunc(cast(void**)&FcFontMatch,				"FcFontMatch");
			bindFunc(cast(void**)&FcPatternGetString,		"FcPatternGetString");
			bindFunc(cast(void**)&FcPatternDestroy,			"FcPatternDestroy");
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
