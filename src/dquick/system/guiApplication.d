module dquick.system.guiApplication;

interface IGuiApplication
{
	void	setApplicationArguments(string[] args);

	void	setApplicationDisplayName(string name);
	string	applicationDisplayName();

	int		execute();
	void	quit();
}

version (Windows)
{
	public import dquick.system.win32.guiApplicationWin32;
}
version (Posix)
{
	public import dquick.system.sdl.guiApplicationSDL;
}
