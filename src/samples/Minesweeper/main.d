module dquick.samples.minesweeper.main;

import dquick.system.guiApplication;
import dquick.item.imageItem;
import dquick.media.image;
import dquick.maths.vector2s32;

import std.file, std.stdio;
import std.string;
import std.path;
import std.exception;
import std.random;

version(Posix)
{
	// TODO remove that, it's normally linked with DQuick
	pragma(lib, "dl");	// dl functions aren't linked by default with dmd
}

bool	randomBool()
{
	auto x = cast(bool)dice(0.8, 0.2);
	return x;
}

int main(string[] args)
{
	try
	{		
		writeln("Current path: ", absolutePath("."));
		GuiApplication.instance().setApplicationArguments(args);
		GuiApplication.instance().setApplicationDisplayName("DQuick - Minesweeper sample");
		chdir(GuiApplication.instance().directoryPath);
		
		Window mainWindow = new Window();
		mainWindow.setSize(Vector2s32(800, 600));
		mainWindow.create();

		mainWindow.dmlEngine.addFunction!(randomBool, "randomBool")();
		mainWindow.setMainItem("dml/Minesweeper.lua");

		mainWindow.show();

		return GuiApplication.instance().execute();
	}
	catch (Throwable e)
	{
		writeln(e.toString());
		return 1;
	}
}
