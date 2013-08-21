module dquick.system.sdl.gui_application;

// TODO voir comment partager plus de code avec la version windows, notamment le comptage des fenetres,...
import dquick.system.gui_application;
import dquick.item.declarative_item;
import dquick.item.graphic_item;
import dquick.system.window;
import dquick.maths.vector2s32;
import dquick.maths.vector2f32;
import dquick.system.sdl.opengl_context_sdl;
import dquick.renderer_3d.opengl.renderer;
import dquick.events.mouse_event;
import dquick.item.image_item;
import dquick.item.border_image_item;
import dquick.item.mouse_area_item;
import dquick.script.dml_engine;

import std.string;
import std.exception;
import std.stdio;
import std.path;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.lua.lua;

shared static this()
{
	DerelictSDL2.load();
	DerelictSDL2Image.load();
	DerelictGL.load();
	DerelictLua.load();
}

shared static ~this()
{
	DerelictLua.unload();
	DerelictGL.unload();
	DerelictSDL2Image.unload();
	DerelictSDL2.unload();
}

class GuiApplication : IGuiApplication
{
public:
	static this()
	{
		if (SDL_Init(SDL_INIT_VIDEO) < 0)
			throwError();
		IMG_Init(IMG_INIT_JPG | IMG_INIT_PNG);
	}

	static ~this()
	{
		destroy(resourceManager);	// Release latest resources because application is exiting
		destroy(mInstance);

		IMG_Quit();
		SDL_Quit();
	}

	static GuiApplication	instance()
	{
		if (mInstance is null)
			mInstance = new GuiApplication;
		return mInstance;
	}

	void	setApplicationArguments(string[] args)
	{
		assert(mInitialized == false);

		mApplicationDirectory = dirName(args[0]) ~ dirSeparator;

		mInitialized = true;
	}

	void	setApplicationDisplayName(string name) {mApplicationDisplayName = name;}
	string	applicationDisplayName() {return mApplicationDisplayName;}

	string	directoryPath() {return mApplicationDirectory;}	/// Return the path of this application

	int	execute()
	{
		while (!mQuit)
		{
			SDL_Event	event;
			Uint32[Uint32]	mouseEventsForWindows;	// map of Windows Id of which have an mouse event

			while (SDL_PollEvent(&event) && !mQuit)
			{
				//writeln("SDL_PollEvent");
				switch (event.type)
				{
					case SDL_QUIT:
						mQuit = true;
						break;
					case SDL_MOUSEMOTION:
						mouseEventsForWindows[event.window.windowID] = event.window.windowID;
						break;
					case SDL_MOUSEBUTTONDOWN:
						mouseEventsForWindows[event.window.windowID] = event.window.windowID;
						break;
					case SDL_MOUSEBUTTONUP:
						mouseEventsForWindows[event.window.windowID] = event.window.windowID;
						break;
					case SDL_MOUSEWHEEL:
						mouseEventsForWindows[event.window.windowID] = event.window.windowID;
						break;
					case SDL_WINDOWEVENT:
						switch (event.window.event)
						{
							case SDL_WINDOWEVENT_SHOWN:	// Called at window creation (need update opengl context size)
								//writeln("SDL_WINDOWEVENT_SHOWN");
								if (event.window.windowID in GuiApplication.mWindows)
									GuiApplication.mWindows[event.window.windowID].setSize(GuiApplication.mWindows[event.window.windowID].size());
								break;
							case SDL_WINDOWEVENT_HIDDEN:
								//writeln("SDL_WINDOWEVENT_HIDDEN");
								break;
							case SDL_WINDOWEVENT_EXPOSED:
								//writeln("SDL_WINDOWEVENT_EXPOSED");
								if (event.window.windowID in GuiApplication.mWindows)
									GuiApplication.mWindows[event.window.windowID].onPaint();
								break;
							case SDL_WINDOWEVENT_MOVED:
								//writeln("SDL_WINDOWEVENT_MOVED");
								if (event.window.windowID in GuiApplication.mWindows)
									GuiApplication.mWindows[event.window.windowID].setPosition(Vector2s32(event.window.data1, event.window.data2));
								break;
							case SDL_WINDOWEVENT_RESIZED:
								//writeln("SDL_WINDOWEVENT_RESIZED");
								if (event.window.windowID in GuiApplication.mWindows)
									GuiApplication.mWindows[event.window.windowID].setSize(Vector2s32(event.window.data1, event.window.data2));
								break;
							case SDL_WINDOWEVENT_MINIMIZED:
								//writeln("SDL_WINDOWEVENT_MINIMIZED");
								break;
							case SDL_WINDOWEVENT_MAXIMIZED:
								//writeln("SDL_WINDOWEVENT_MAXIMIZED");
								break;
							case SDL_WINDOWEVENT_RESTORED:
								//writeln("SDL_WINDOWEVENT_RESTORED");
								break;
							case SDL_WINDOWEVENT_ENTER:
								//writeln("SDL_WINDOWEVENT_ENTER");
								break;
							case SDL_WINDOWEVENT_LEAVE:
								//writeln("SDL_WINDOWEVENT_LEAVE");
								break;
							case SDL_WINDOWEVENT_FOCUS_GAINED:
								//writeln("SDL_WINDOWEVENT_FOCUS_GAINED");
								break;
							case SDL_WINDOWEVENT_FOCUS_LOST:
								//writeln("SDL_WINDOWEVENT_FOCUS_LOST");
								break;
							case SDL_WINDOWEVENT_CLOSE:
								//writeln("SDL_WINDOWEVENT_CLOSE");
								if (event.window.windowID in GuiApplication.mWindows)
									GuiApplication.mWindows.remove(event.window.windowID);
//								GuiApplication.mWindows[event.window.windowID].destroy();
								break;
							default:
								break;
						}
						break;
					default:
						break;
				}
			}
			foreach (key, value; mouseEventsForWindows)
			{
				if (key in GuiApplication.mWindows)
					GuiApplication.mWindows[key].onMouseEvent();
			}

			if (!mQuit)
				foreach (Window window; mWindows)
					window.onPaint();
		}
		return 0;
	}

	void	quit()
	{
		mQuit = true;
	}

	//==========================================================================
	//==========================================================================

private:
	static void	registerWindow(Window window, Uint32 windowId)
	{
		mWindows[windowId] = window;
	}

	static GuiApplication	mInstance;
	static Window[Uint32]	mWindows;

	bool			mQuit = false;
	string			mApplicationDisplayName = "DQuick - Application";
	string			mApplicationDirectory = ".";
	bool			mInitialized = false;
}

//==========================================================================
//==========================================================================

class Window : IWindow
{
	this()
	{
		mWindowId = mWindowsCounter++;
		mScriptContext = new DMLEngine;
		mScriptContext.create();
		mScriptContext.addItemType!(DeclarativeItem, "Item")();
		mScriptContext.addItemType!(ImageItem, "Image")();
		mScriptContext.addItemType!(BorderImageItem, "BorderImage")();
		mScriptContext.addItemType!(MouseAreaItem, "MouseArea")();
	}

	~this()
	{
		destroy();
	}

	bool	create()
	{
		mContext = new OpenGLContextSDL();

		mContext.pushSettings();

		mWindow = SDL_CreateWindow(GuiApplication.instance().applicationDisplayName.toStringz,
									SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
									size().x, size().y,
									SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE /*| SDL_WINDOW_BORDERLESS*/);	// Note to avoid completly border under windows, SDL_WINDOW_RESIZABLE have to be removed
		if (mWindow == null)
		{
			throwError();
			return false;
		}

		mContext.initialize(mWindow);
		Renderer.initialize();

		GuiApplication.registerWindow(this, SDL_GetWindowID(mWindow));	// Call it just after window creation validation
		return true;
	}

	void	destroy()
	{
		if (mWindow)
		{
			.destroy(mScriptContext);
			.destroy(mContext);
			SDL_DestroyWindow(mWindow);
			mWindow = null;
			if (mWindowId == 0)
				GuiApplication.instance.quit();
		}
	}

	/// Window will take size of this item
	void	setMainItem(DeclarativeItem item)
	{
		mRootItem = item;
/*
		GraphicItem	graphicItem = cast(GraphicItem)mRootItem;
		if (graphicItem)
			setSize(graphicItem.size);*/
	}

	/// Window will take size of this item
	void	setMainItem(string filePath)
	{
		mScriptContext.executeFile(filePath);

		mRootItem = mScriptContext.rootItem();
//		assert(cast(GraphicItem)mRootItem);

		//setSize(mRootItem.size);
	}

	DeclarativeItem	mainItem() {return mRootItem;}

	void		setPosition(Vector2s32 newPosition)
	{
		// TODO
		if (fullScreen()/* || maximized()*/)	// Will put corrupted values
			return;

		mPosition = newPosition;	// Utilise pour la creation de la fenetre
	}
	Vector2s32	position() {return mPosition;}

	void		setSize(Vector2s32 newSize)
	{
		mSize = newSize;

		GraphicItem	graphicItem = cast(GraphicItem)mRootItem;
		if (graphicItem && (graphicItem.width != newSize.x || graphicItem.height != newSize.y))	// Don't call size on item if it didn't change (setMainItem call this method)
			graphicItem.setSize(Vector2f32(newSize));

		SDL_SetWindowSize(mWindow, mSize.x, mSize.y);

		if (mContext)
			mContext.resize(mSize.x, mSize.y);
	}
	Vector2s32	size() {return mSize;}

	void	setFullScreen(bool fullScreen) {mFullScreen = fullScreen;}
	bool	fullScreen() {return mFullScreen;}

	Vector2s32	screenResolution() const
	{
		SDL_DisplayMode	displayMode;

		if (SDL_GetDesktopDisplayMode(0, &displayMode) == 0)
			return Vector2s32(displayMode.w, displayMode.h);
		return Vector2s32(0, 0);
	}

	//==========================================================================
	//==========================================================================

private:
	void	onPaint()
	{
		Renderer.startFrame();

		if (mRootItem)
			mRootItem.paint(false);

		if (mContext)
			mContext.swapBuffers();
	}

	void	onMouseEvent()
	{
		if (mRootItem)
		{
			Uint32	buttons;
			int	x;
			int y;

			buttons = SDL_GetMouseState(&x, &y);

			MouseEvent.Buttons	eButtons = MouseEvent.Buttons.Any;
			Vector2s32			ePosition;

			ePosition.x = x;
			ePosition.y = y;

			if (buttons & SDL_BUTTON(SDL_BUTTON_LEFT))
				eButtons |= MouseEvent.Buttons.Left;
			if (buttons & SDL_BUTTON(SDL_BUTTON_MIDDLE))
				eButtons |= MouseEvent.Buttons.Middle;
			if (buttons & SDL_BUTTON(SDL_BUTTON_RIGHT))
				eButtons |= MouseEvent.Buttons.Right;
			if (buttons & SDL_BUTTON(SDL_BUTTON_X1))
				eButtons |= MouseEvent.Buttons.X1;
			if (buttons & SDL_BUTTON(SDL_BUTTON_X2))
				eButtons |= MouseEvent.Buttons.X2;

			MouseEvent	event = MouseEvent(ePosition, eButtons);

			mRootItem.mouseEvent(event);
		}
	}

	DMLEngine	mScriptContext;

	static int	mWindowsCounter = 0;
	int			mWindowId;

	string		mWindowName = "";
	DeclarativeItem	mRootItem;
	Vector2s32	mPosition;
	Vector2s32	mSize = Vector2s32(640, 480);
	bool		mFullScreen = false;

	SDL_Window*			mWindow = null;
	OpenGLContextSDL	mContext;
}

private static void throwError()
{
	string	message;
	message.format("[GuiApplication] SDL error: %s", SDL_GetError());
	throw new Exception(message);
}
