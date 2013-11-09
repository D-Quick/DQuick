module main;

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
		chdir(GuiApplication.instance().directoryPath);
		
		Image imgA = new Image();
		imgA.load("images/Alpha-blue-trans.png");
		Image imgB = new Image();
		imgB.load("images/pngtest.png");
		
		Image result = new Image();
		result.create("test.png", 800, 600, 4);
		result.blit(imgB, Vector2s32(0, 0), imgB.size, Vector2s32(0, 0));
		result.blit(imgA, Vector2s32(0, 0), imgA.size, Vector2s32(0, 0));
		result.save("test.png");

		Window	mainWindow = new Window();
		mainWindow.create();

		ImageItem mainDML = new ImageItem();

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
