module dquick.system.sdl.guiApplicationSDL;

import dquick.system.guiApplication;
import dquick.system.sdl.openglContextSDL;

import dquick.utils.utils;

import derelict.sdl2.sdl;

import std.string;
import std.exception;
import std.stdio;
import std.path;

import core.runtime;

shared static this()
{
	writeln("dquick.system.sdl.guiApplicationSDL : shared static this()");
	DerelictSDL2.load();
}

shared static ~this()
{
	writeln("dquick.system.sdl.guiApplicationSDL : shared static ~this()");
	DerelictSDL2.unload();
}

final class GuiApplication : GuiApplicationBase, IGuiApplication
{
public:
	shared static this()
	{
		if (SDL_Init(SDL_INIT_VIDEO) < 0)
			throwError();
	}

	shared static ~this()
	{
		destroy(mInstance);
		mInstance = null;

		SDL_Quit();
	}

	static GuiApplication	instance()
	{
		if (mInstance is null)
			mInstance = new GuiApplication;
		return mInstance;
	}

	override
	{
		void	setApplicationArguments(string[] args) {super.setApplicationArguments(args);}
		void	setApplicationDisplayName(string name) {super.setApplicationDisplayName(name);}
		string	applicationDisplayName() {return super.applicationDisplayName();}
		void	quit() {super.quit();}
	}

	int	execute()
	{
		while (!mQuit)
		{
			SDL_Event	event;

			while (SDL_PollEvent(&event) && !mQuit)
			{
				MouseEvent	mouseEvent;

				//writeln("SDL_PollEvent");
				switch (event.type)
				{
					case SDL_QUIT:
						mQuit = true;
						break;
					case SDL_MOUSEMOTION:
						mouseEvent.type = MouseEvent.Type.Motion;
						fillMouseEvent(mouseEvent);
						sendEvent(event.window.windowID, mouseEvent);
						break;
					case SDL_MOUSEBUTTONDOWN:
						mouseEvent.type = MouseEvent.Type.ButtonPressed;
						mouseEvent.buttons = mouseButtons(event.button.button);
						fillMouseEvent(mouseEvent);
						sendEvent(event.window.windowID, mouseEvent);
						break;
					case SDL_MOUSEBUTTONUP:
						mouseEvent.type = MouseEvent.Type.ButtonReleased;
						mouseEvent.buttons = mouseButtons(event.button.button);
						fillMouseEvent(mouseEvent);
						sendEvent(event.window.windowID, mouseEvent);
						break;
					case SDL_MOUSEWHEEL:
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

			if (!mQuit)
				foreach (Window window; mWindows)
					window.onPaint();
		}
		terminateExecution();
		return 0;
	}

	//==========================================================================
	//==========================================================================

private:
	static void	registerWindow(Window window, Uint32 windowId)
	{
		mWindows[windowId] = window;
	}
	
	static void fillMouseEvent(ref MouseEvent evt)
	{
		uint buttons = SDL_GetMouseState(&evt.position.vector[0], &evt.position.vector[1]);

	}
	
	static MouseEvent.Buttons mouseButtons(Uint32 sdlbuttons)
	{
		MouseEvent.Buttons buttons;
		if(sdlbuttons & SDL_BUTTON(1))
			buttons |= MouseEvent.Buttons.Left;
		if(sdlbuttons & SDL_BUTTON(2))
			buttons |= MouseEvent.Buttons.Middle;
		if(sdlbuttons & SDL_BUTTON(3))
			buttons |= MouseEvent.Buttons.Right;
		return buttons;
	}
	
	static void sendEvent(Uint32 winId, MouseEvent event)
	{
		auto window = winId in mWindows;
		if(window)
			window.onMouseEvent(event);
	}

	static GuiApplication	mInstance;
	static Window[Uint32]	mWindows;
}

//==========================================================================
//==========================================================================

final class Window : WindowBase, IWindow
{
	~this()
	{
		debug destructorAssert(!wasCreated, "Window.close method wasn't called.", mTrace);
	}

	override
	{
		void		setMainItem(GraphicItem item) {super.setMainItem(item);}
		void		setMainItem(string filePath) {super.setMainItem(filePath);}
		GraphicItem	mainItem() {return super.mainItem();}
		DMLEngine	dmlEngine() {return super.dmlEngine();}
	}

	override bool	create()
	{
		debug mTrace = defaultTraceHandler(null);

		WindowBase.create();

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

		mWindowId = mWindowsCounter++;
		GuiApplication.registerWindow(this, SDL_GetWindowID(mWindow));	// Call it just after window creation validation
		return true;
	}

	bool	wasCreated() const
	{
		return (mWindow !is null);
	}

	bool	isMainWindow() const
	{
		return (mWindowId == 0);
	}

	void	show()
	{
	}

	void	setPosition(Vector2s32 newPosition)
	{
		// TODO
		if (fullScreen()/* || maximized()*/)	// Will put corrupted values
			return;

		mPosition = newPosition;	// Utilise pour la creation de la fenetre
	}
	Vector2s32	position() {return mPosition;}

	override void	setSize(Vector2s32 newSize)
	{
		super.setSize(newSize);

		mSize = newSize;
		SDL_SetWindowSize(mWindow, mSize.x, mSize.y);

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

	override void	close()
	{
		if (mWindow)
		{
			mWindowsCounter--;
			mContext.release();
			SDL_DestroyWindow(mWindow);
			mWindow = null;
		}
		super.close();
	}

	//==========================================================================
	//==========================================================================

protected:
	override
	{
		void	onPaint()
		{
			Renderer.startFrame();

			super.onPaint();

			mContext.swapBuffers();
		}

		void	onMouseEvent(MouseEvent mouseEvent) {super.onMouseEvent(mouseEvent);}
	}

private:
	static int	mWindowsCounter = 0;
	int			mWindowId;

	string		mWindowName = "";
	Vector2s32	mPosition;
	Vector2s32	mSize = Vector2s32(640, 480);
	bool		mFullScreen = false;

	SDL_Window*			mWindow = null;
	OpenGLContextSDL	mContext;

	debug Throwable.TraceInfo	mTrace;
}

private static void throwError()
{
	string	message;
	message.format("[GuiApplication] SDL error: %s", SDL_GetError());
	throw new Exception(message);
}
