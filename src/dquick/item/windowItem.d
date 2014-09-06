module dquick.item.windowItem;

import dquick.item.graphicItem;
import dquick.system.window;
import dquick.system.guiApplication;
import std.signals;

class WindowItem : GraphicItem
{
	// WindowItem cannot be child of any other item
	this()
	{		
		mWindow = new Window();
		mWindow.setMainItem(this);
	}

	void	setSize(Vector2s32 newSize)
	{		
		if(!mWindow.wasCreated)
			mWindow.create();
		mWindow.setSize(newSize);
		onSizeChanged.emit(newSize);
	}
	
	Vector2s32	size() {return mWindow.size;}
	mixin Signal!(Vector2s32) onSizeChanged;
	
	IWindow guiWindow(){return mWindow;}

	override void	width(float width) {setSize(Vector2s32(cast(int)width, mWindow.size.y));}
	override float	width() {return mWindow.size.x;}

	override void	height(float height) {setSize(Vector2s32(mWindow.size.x, cast(int)height));}
	override float	height() {return mWindow.size.y;}

private:
	IWindow mWindow;
}
