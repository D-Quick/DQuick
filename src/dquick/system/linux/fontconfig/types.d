module dquick.system.linux.fontconfig.types;

bool	FcTrue = true;
bool	FcFalse = false;

alias bool	FcBool;
alias void	FcConfig;
alias void	FcPattern;

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
