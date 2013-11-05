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
}

__gshared
{
	da_FcInit		FcInit;
	da_FcFini		FcFini;
	da_FcFontList	FcFontList;
}
