module dquick.samples.animation.main;

import dquick.system.guiApplication;
import dquick.item.windowItem;
import dquick.item.imageItem;
import dquick.animation.animation;

import std.file, std.stdio;
import std.path;
import core.time;

int main(string[] args)
{
	try
	{
		writeln("Current path: ", absolutePath("."));
		GuiApplication.instance().setApplicationArguments(args);
		GuiApplication.instance.setApplicationDisplayName("DQuick - Animation sample");
		
		writeln("Executable path: ", dirName(thisExePath()));
		chdir(dirName(thisExePath()));

		WindowItem wnd = new WindowItem();
		wnd.width = 512;
		wnd.height = 512;

		ImageItem image = new ImageItem(wnd);
		image.source = "images/pngtest.png";
		image.width = 64;
		image.height = 64;
		
		LoopedAnimation loopAnim = new LoopedAnimation();
		loopAnim.loops = LoopedAnimation.infinite;
		
		SequentialAnimation seqAnim = new SequentialAnimation(loopAnim);
		
		ParallelAnimation posAnim1 = new ParallelAnimation(seqAnim);
		posAnim1.duration = dur!"seconds"(2);
		{
			LinearAnimation!float xAnim = new LinearAnimation!float(posAnim1, &image.x);
			xAnim.from = 0;
			xAnim.to = wnd.width - image.width;
			xAnim.duration = dur!"seconds"(2);
			
			LinearAnimation!float yAnim = new LinearAnimation!float(posAnim1, &image.y);
			yAnim.from = 0;
			yAnim.to = wnd.height - image.height;
			yAnim.duration = dur!"seconds"(2);
		}
		
		ParallelAnimation posAnim2 = new ParallelAnimation(seqAnim);
		posAnim2.duration = dur!"seconds"(2);
		{
			LinearAnimation!float xAnim = new LinearAnimation!float(posAnim2, &image.x);
			xAnim.from = wnd.width - image.width;
			xAnim.to = 0;
			xAnim.duration = dur!"seconds"(2);
			
			LinearAnimation!float yAnim = new LinearAnimation!float(posAnim2, &image.y);
			yAnim.from = wnd.height - image.height;
			yAnim.to = 0;
			yAnim.duration = dur!"seconds"(2);
		}
		
		loopAnim.setMaxDuration();
		loopAnim.running = true;
		
		float bttW = 128;
		float bttH = 32;
		
		ImageItem btt = new ImageItem(wnd);
		btt.y = 16;
		btt.source = "images/Qt/toolbutton.png";
			
		ParallelAnimation bttSizeAnim = new ParallelAnimation();
		bttSizeAnim.duration = dur!"msecs"(1500);
		
		LinearAnimation!float bttXAnim = new LinearAnimation!float(bttSizeAnim, &btt.x);
		bttXAnim.from = wnd.width/2;
		bttXAnim.to = wnd.width/2 - bttW/2;
		bttXAnim.duration = dur!"msecs"(1500);
		LinearAnimation!float bttWAnim = new LinearAnimation!float(bttSizeAnim, &btt.width);
		bttWAnim.from = 0;
		bttWAnim.to = bttW;
		bttWAnim.duration = dur!"msecs"(1500);
		LinearAnimation!float bttHAnim = new LinearAnimation!float(bttSizeAnim, &btt.height);
		bttHAnim.from = 0;
		bttHAnim.to = bttH;
		bttHAnim.duration = dur!"msecs"(1500);
		
		bttSizeAnim.running = true;
				
		wnd.guiWindow.show();
		
		return GuiApplication.instance.execute();
	}
	catch(Exception exc)
	{
		writeln("Exception!");
		writeln(exc.toString);
		return 1;
	}
}
