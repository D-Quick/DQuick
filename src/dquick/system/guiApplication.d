module dquick.system.guiApplication;

public import dquick.system.window;

import dquick.algorithms.scheduler;

import derelict.opengl3.gl;
import derelict.lua.lua;

import std.stdio;

import dquick.buildSettings;

interface IGuiApplication
{
	static IGuiApplication	instance();

	void	setApplicationArguments(string[] args);

	void	setApplicationDisplayName(string name);
	string	applicationDisplayName();

	int		execute();
	void	quit();
}

abstract class GuiApplicationBase : IGuiApplication
{
public:
	void	setApplicationArguments(string[] args)
	{
		assert(mInitialized == false);
		mInitialized = true;
	}

	void	setApplicationDisplayName(string name) {mApplicationDisplayName = name;}
	string	applicationDisplayName() {return mApplicationDisplayName;}

	void	quit() {mQuit = true;}

protected:
	void	terminateExecution()
	{
		Scheduler.terminateAll();
		Renderer.resourceManager.releaseAllResources();
		dquick.media.image.resourceManager.releaseAllResources();
		dquick.media.font.fontManager.clear();
	}

	bool	mQuit = false;

private:
	string	mApplicationDisplayName = "DQuick - Application";
	bool	mInitialized = false;
}

static if (windowSystem == WindowSystem.Native)
{
	version (Windows)
	{
		public import dquick.system.win32.guiApplicationWin32;
	}
	version (Posix)
	{
		public import dquick.system.sdl.guiApplicationSDL;
	}
}
else
	public import dquick.system.sdl.guiApplicationSDL;

static this()
{
	writeln("dquick.system.guiApplication : static this()");
	DerelictGL.load();
	DerelictLua.load();
}

static ~this()
{
	writeln("dquick.system.guiApplication : static ~this()");
	DerelictLua.unload();
	DerelictGL.unload();
}
