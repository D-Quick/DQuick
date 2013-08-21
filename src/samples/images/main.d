module main;

import dquick.system.gui_application;
import dquick.item.image_item;

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

		mainWindow.setMainItem("dml/transformations.lua");	/// Window take size of this item
//		mainWindow.setMainItem("dml/image.lua");	/// Window take size of this item

		return GuiApplication.instance().execute();
	}
	catch (Throwable e)
	{
		writeln(e.toString());
		return 1;
	}
}
