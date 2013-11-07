module dquick.system.linux.fontconfig.functions;

private
{
	import dquick.system.linux.fontconfig.types;
}

extern(C)
{
	alias nothrow FcBool		function()													da_FcInit;
	alias nothrow void			function()													da_FcFini;
	alias nothrow FcFontSet*	function(FcConfig* config, FcPattern* p, FcObjectSet* os)	da_FcFontList;
	alias nothrow FcConfig*		function()													da_FcInitLoadConfigAndFonts;
	alias nothrow FcPattern*	function(const FcChar8 *)									da_FcNameParse;
	alias nothrow FcBool		function(FcConfig*, FcPattern*, FcMatchKind)				da_FcConfigSubstitute;
	alias nothrow void			function(FcPattern*)										da_FcDefaultSubstitute;
	alias nothrow FcPattern*	function(FcConfig*, FcPattern*, FcResult*)					da_FcFontMatch;
	alias nothrow FcResult		function(const FcPattern*, const char*, int n, FcChar8**)	da_FcPatternGetString;
	alias nothrow void			function(FcPattern*)										da_FcPatternDestroy;
}

__gshared
{
	da_FcInit					FcInit;
	da_FcFini					FcFini;
	da_FcFontList				FcFontList;
	da_FcInitLoadConfigAndFonts	FcInitLoadConfigAndFonts;
	da_FcNameParse				FcNameParse;
	da_FcConfigSubstitute		FcConfigSubstitute;
	da_FcDefaultSubstitute		FcDefaultSubstitute;
	da_FcFontMatch				FcFontMatch;
	da_FcPatternGetString		FcPatternGetString;
	da_FcPatternDestroy			FcPatternDestroy;
}
