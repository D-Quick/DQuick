module main;

import dquick.system.guiApplication;
import dquick.item.imageItem;

import std.file, std.stdio;
import std.string;
import std.path;
import std.exception;

int main(string[] args)
{
	try
	{
		writeln("Current path: ", absolutePath("."));
		GuiApplication.instance().setApplicationArguments(args);
		GuiApplication.instance().setApplicationDisplayName("DQuick - Images sample");

		Window	mainWindow = new Window();
		mainWindow.create();

		ImageItem mainDML = new ImageItem();

		chdir(GuiApplication.instance().directoryPath);

		mainWindow.setMainItem("dml/text - constitution.lua");
//		mainWindow.setMainItem("dml/image.lua");

		mainWindow.show();

		return GuiApplication.instance().execute();
	}
	catch (Throwable e)
	{
		writeln(e.toString());
		return 1;
	}
}
