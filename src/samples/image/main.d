module dquick.samples.image.main;

import dquick.system.guiApplication;
import dquick.item.imageItem;
import dquick.media.image;
import dquick.maths.vector2s32;

import std.file, std.stdio;
import std.string;
import std.path;
import std.exception;

version(Posix)
{
	// TODO remove that, it's normally linked with DQuick
	pragma(lib, "dl");	// dl functions aren't linked by default with dmd
}

int main(string[] args)
{
	try
	{		
		writeln("Current path: ", absolutePath("."));
		GuiApplication.instance().setApplicationArguments(args);
		GuiApplication.instance().setApplicationDisplayName("DQuick - Images sample");

		writeln("Executable path: ", dirName(thisExePath()));
		chdir(dirName(thisExePath()));

		Window mainWindow = new Window();
		mainWindow.setSize(Vector2s32(800, 600));
		mainWindow.create();

		mainWindow.setMainItem("dml/text - constitution.lua");
//		mainWindow.setMainItem("dml/image2.lua");

		mainWindow.show();

		return GuiApplication.instance().execute();
	}
	catch (Throwable e)
	{
		writeln(e.toString());
		return 1;
	}
}
