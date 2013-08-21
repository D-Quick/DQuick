module dquick.system.gui_application;

interface IGuiApplication
{
	void	setApplicationArguments(string[] args);

	void	setApplicationDisplayName(string name);
	string	applicationDisplayName();

	int		execute();
	void	quit();
}

/*version (Windows)
{
	public import dquick.system.win32.gui_application;
}
version (Posix)
{*/
	public import dquick.system.sdl.gui_application;
//}
