module dquick.system.win32.guiApplicationWin32;

version (Windows)
{
	import dquick.system.guiApplication;
	import dquick.item.declarativeItem;
	import dquick.item.graphicItem;
	import dquick.system.window;
	import dquick.maths.vector2s32;
	import dquick.item.imageItem;
	import dquick.item.textItem;
	import dquick.item.borderImageItem;
	import dquick.item.mouseAreaItem;
	import dquick.item.scrollViewItem;
	import dquick.script.dmlEngine;

	import std.stdio;
	import std.c.stdlib;
	import std.c.string;	// for memset
	import std.string;
	import std.path;
	import std.exception;

	import std.c.windows.windows;
	pragma(lib, "gdi32.lib");

	import dquick.system.win32.openglContextWin32;

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
			MSG		msg;

			while (!mQuit)
			{
				while (PeekMessageA(&msg, null, 0, 0, PM_REMOVE))
				{
					TranslateMessage(&msg);
					DispatchMessageA(&msg);
				}

				if (!mQuit)
					foreach (Window window; mWindows)
						window.onPaint();
			}
			return msg.wParam;
		}

		void	quit()
		{
			mQuit = true;
		}

		//==========================================================================
		//==========================================================================

	private:
		this() {}

		static void	registerWindow(Window window, HWND windowHandle)
		{
			mWindows[windowHandle] = window;
		}

		static GuiApplication	mInstance;
		static bool				mQuit = false;

		static string		mApplicationDisplayName = "DQuick - Application";
		static string		mApplicationDirectory = ".";
		static bool			mInitialized = false;
		static Window[HWND]	mWindows;
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
			mScriptContext.addItemType!(GraphicItem, "GraphicItem")();
			mScriptContext.addItemType!(ImageItem, "Image")();
			mScriptContext.addItemType!(TextItem, "Text")();
			mScriptContext.addItemType!(BorderImageItem, "BorderImage")();
			mScriptContext.addItemType!(MouseAreaItem, "MouseArea")();
			mScriptContext.addItemType!(ScrollViewItem, "ScrollView")();
		}

		~this()
		{
			destroy();
		}

		bool	create()
		{
			if (mhWnd)
				throw new Exception("[Window] Must be destroy before, being able to create a new one.");

			string		windowName;

			windowName = mWindowName;
			if (!windowName.length)	// If this Window don't have a particular name, we use the applicationName
				windowName = GuiApplication.instance().applicationDisplayName;

			WNDCLASS	wndclass;
			HINSTANCE	hInstance = GetModuleHandleA(null);

			wndclass.style         = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
			wndclass.lpfnWndProc   = &WindowProc;
			wndclass.cbClsExtra    = 0;
			wndclass.cbWndExtra    = 0;
			wndclass.hInstance     = hInstance;
			wndclass.hIcon         = null; // TODO cast(HICON)LoadImage(hInstance, MAKEINTRESOURCE(mIconId), IMAGE_ICON, GetSystemMetrics(SM_CXICON), GetSystemMetrics(SM_CYICON), 0);
			wndclass.hCursor       = null;
			wndclass.hbrBackground = null;
			wndclass.lpszMenuName  = null;
			wndclass.lpszClassName = windowName.toStringz;

			if (!RegisterClassA(&wndclass))
			{
				MessageBoxA(null, "Couldn't register Window Class!", windowName.toStringz, MB_ICONERROR);
				return false;
			}

			if (fullScreen())
			{
				RECT	WindowRect;
				DWORD	dwExStyle = WS_EX_APPWINDOW | WS_EX_TOPMOST;
				DWORD	dwStyle = WS_POPUP;

				WindowRect.left = 0;
				WindowRect.right = size().x;
				WindowRect.top = 0;
				WindowRect.bottom = size().y;
				AdjustWindowRectEx(&WindowRect, dwStyle, false, dwExStyle);	// Adjust Window To True Requested Size
				mhWnd = CreateWindowExA(dwExStyle,					// Extended Style For The Window
									windowName.toStringz,					// Class Name
									windowName.toStringz,					// Window Title
									WS_CLIPSIBLINGS |						// Required Window Style
									WS_CLIPCHILDREN |						// Required Window Style
									dwStyle,								// Selected Window Style
									0, 0,									// Window Position
									WindowRect.right-WindowRect.left,		// Calculate Adjusted Window Width
									WindowRect.bottom-WindowRect.top,		// Calculate Adjusted Window Height
									null,									// No Parent Window
									null,									// No Menu
									hInstance,								// Instance
									cast(void*)this);						// Pass Window To WM_CREATE to register it

				DEVMODE	dmScreenSettings;									// Device Mode
				memset(&dmScreenSettings, 0, dmScreenSettings.sizeof);		// Makes Sure Memory's Cleared
				dmScreenSettings.dmSize = dmScreenSettings.sizeof;			// Size Of The Devmode Structure
				dmScreenSettings.dmPelsWidth = size().x;					// Selected Screen Width
				dmScreenSettings.dmPelsHeight = size().y;					// Selected Screen Height
				//dmScreenSettings.dmBitsPerPel	= 32;						// Selected Bits Per Pixel
				dmScreenSettings.dmFields = /*DM_BITSPERPEL |*/DM_PELSWIDTH | DM_PELSHEIGHT;
				// Try To Set Selected Mode And Get Results.  NOTE: CDS_FULLSCREEN Gets Rid Of Start Bar.
				if (ChangeDisplaySettingsA(&dmScreenSettings, CDS_FULLSCREEN) != DISP_CHANGE_SUCCESSFUL)
				{
					// If The Mode Fails, Offer Two Options.  Quit Or Run In A Window.
					MessageBoxA(null, "The Fullscreen Mode Is Not Supported By\nYour Video Card.", windowName.toStringz, MB_ICONERROR);
					setFullScreen(false);
				}
				ShowWindow(mhWnd, SW_MAXIMIZE);
				ShowWindow(mhWnd, WS_MAXIMIZE);
			}
			else
			{
				RECT	WindowRect;
				DWORD	dwExStyle = WS_EX_APPWINDOW;
				DWORD	dwStyle = WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_CLIPSIBLINGS | WS_CLIPCHILDREN;

				// TODO
//				if (maximized())
//					dwStyle |= WS_MAXIMIZE;

				WindowRect.left = 0;
				WindowRect.right = size().x;
				WindowRect.top = 0;
				WindowRect.bottom = size().y;
				AdjustWindowRectEx(&WindowRect, dwStyle, FALSE, dwExStyle);	// Adjust Window To True Requested Size
				mhWnd = CreateWindowA(windowName.toStringz, windowName.toStringz,
									 dwStyle,
									 position().x, position().y, 
									 WindowRect.right - WindowRect.left, WindowRect.bottom - WindowRect.top,
									 null, null, hInstance, cast(void*)this);
			}

			if (mhWnd is null)
			{
				MessageBoxA(null, "Couldn't create window.", windowName.toStringz, MB_ICONERROR);
				throw new Exception(format("Couldn't create window \"%s\"", windowName));
			}

			// TODO
//			SendMessage(mhWnd,WM_SETICON,ICON_BIG,(LPARAM)LoadIcon(hInstance, "IDR_MAINFRAME"));

			mContext = new OpenGLContext();
			mContext.initialize(mhWnd);
			Renderer.initialize();
			mContext.resize(size().x, size().y);

			GuiApplication.registerWindow(this, mhWnd);

			return true;
		}

		bool	wasCreated() const
		{
			return mhWnd != null;
		}

		void	show()
		{
			// TODO
			//			if (maximized())
			//				ShowWindow(mhWnd, SW_SHOWMAXIMIZED);		// Show The Window maximized
			//			else
			ShowWindow(mhWnd, SW_SHOWDEFAULT);			// SW_SHOWDEFAULT to use same value retrieve normaly with the WinMain entry point
			SetForegroundWindow(mhWnd);						// Slightly Higher Priority
			SetFocus(mhWnd);								// Sets Keyboard Focus To The Window
			UpdateWindow(mhWnd);
		}

		void	destroy()
		{
			.destroy(mScriptContext);
			.destroy(mContext);
			mContext = null;
			DestroyWindow(mhWnd);
			if (mWindowId == 0)
				GuiApplication.instance.quit();
		}

		/// Window will take size of this item
		void	setMainItem(GraphicItem item)
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

			mRootItem = mScriptContext.rootItem!GraphicItem();
			if (mRootItem is null)
				throw new Exception("There is no root item or it's not a GraphicItem");

			mRootItem.setSize(Vector2f32(size()));
		}

		GraphicItem	mainItem() {return mRootItem;}

		void		setPosition(Vector2s32 newPosition)
		{
			// TODO
			if (fullScreen()/* || maximized()*/)	// Will put corrupted values
				return;

			mPosition = newPosition;	// Utilise pour la creation de la fenetre

			if (!mhWnd)
				return;

			RECT	rcWindow;
			GetWindowRect(mhWnd, &rcWindow);	// Retourne des valeurs valides
			mPosition = Vector2s32(rcWindow.left, rcWindow.top);

			// Rien d'autre a faire car Windows deplace directement la fenetre
		}
		Vector2s32	position() {return mPosition;}

		void	setSize(Vector2s32 newSize)
		{
			mSize = newSize;

			if (mRootItem)
				mRootItem.setSize(Vector2f32(newSize));

			// Resizing Window
			RECT	rcClient, rcWindow;
			POINT	ptDiff;

			GetClientRect(mhWnd, &rcClient);
			GetWindowRect(mhWnd, &rcWindow);
			ptDiff.x = (rcWindow.right - rcWindow.left) - rcClient.right;
			ptDiff.y = (rcWindow.bottom - rcWindow.top) - rcClient.bottom;
			MoveWindow(mhWnd, rcWindow.left, rcWindow.top, mSize.x + ptDiff.x, mSize.y + ptDiff.y, true);
			// --

			if (mContext)
				mContext.resize(mSize.x, mSize.y);
		}
		Vector2s32	size() {return mSize;}

		void	setFullScreen(bool fullScreen) {mFullScreen = fullScreen;}
		bool	fullScreen() {return mFullScreen;}

		Vector2s32	screenResolution() const
		{
			RECT	rc;
			GetWindowRect(GetDesktopWindow(), &rc);
			return Vector2s32(rc.right - rc.left, rc.bottom - rc.top);
		}

		DMLEngine	dmlEngine() {return mScriptContext;}

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

		void	onMouseEvent(MouseEvent mouseEvent)
		{
			if (mRootItem)
			{
				mRootItem.mouseEvent(mouseEvent);
			}
		}

		DMLEngine	mScriptContext;

		static int	mWindowsCounter = 0;
		int			mWindowId;

		HWND		mhWnd = null;
		string		mWindowName = "";
		GraphicItem	mRootItem;
		Vector2s32	mPosition;
		Vector2s32	mSize = Vector2s32(640, 480);
		bool		mFullScreen = false;

		OpenGLContext	mContext;
	}

	//==========================================================================
	//==========================================================================

	extern(Windows) LRESULT	WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow
	{
		Vector2s32	size;
		Vector2s32	position;
		bool		state;
//		POINTS		pos;

		MouseEvent	mouseEvent;

		try
		{
			switch (message)
			{
				// Window events
				case WM_CREATE:
					break;
				case WM_MOVE:		// position de cliet arena
					break;
				case WM_MOVING:		// position de la fenetre
					position.x = LOWORD(lParam);
					position.y = HIWORD(lParam);
					if (hWnd in GuiApplication.mWindows)
					{
						GuiApplication.mWindows[hWnd].setPosition(position);
						GuiApplication.mWindows[hWnd].onPaint();
					}
					return 0;
				case WM_SIZE:
					/*if (wParam == SIZE_MAXIMIZED)
						if (hWnd in GuiApplication.mWindows)
							GuiApplication.mWindows[hWnd].setMaximized(true);
					else if (wParam == SIZE_RESTORED)
						if (hWnd in GuiApplication.mWindows)
							GuiApplication.mWindows[hWnd].setMaximized(false);*/
					size.x = LOWORD(lParam);
					size.y = HIWORD(lParam);
					if (hWnd in GuiApplication.mWindows)
						GuiApplication.mWindows[hWnd].setSize(size);
					return 0;
				case WM_COMMAND:
					break;
				case WM_PAINT:
					if (hWnd in GuiApplication.mWindows)
						GuiApplication.mWindows[hWnd].onPaint();
					break;
				case WM_DESTROY:
					if (hWnd in GuiApplication.mWindows)
						GuiApplication.mWindows[hWnd].destroy();
					PostQuitMessage(0);
					break;

				// Mouse events
				case WM_MOUSEMOVE:
					position.x = GET_X_LPARAM(lParam);
					position.y = GET_Y_LPARAM(lParam);
					mouseEvent.type = MouseEvent.Type.Motion;
					mouseEvent.position = position;
					GuiApplication.mWindows[hWnd].onMouseEvent(mouseEvent);
					return 0;
				case WM_LBUTTONDOWN:
					mouseEvent.type = MouseEvent.Type.ButtonPressed;
					mouseEvent.buttons = MouseEvent.Buttons.Left;
					SetCapture(hWnd);
					GuiApplication.mWindows[hWnd].onMouseEvent(mouseEvent);
					return 0;
				case WM_LBUTTONUP:
					mouseEvent.type = MouseEvent.Type.ButtonReleased;
					mouseEvent.buttons = MouseEvent.Buttons.Left;
					ReleaseCapture();
					GuiApplication.mWindows[hWnd].onMouseEvent(mouseEvent);
					return 0;
				case WM_RBUTTONDOWN:
					mouseEvent.type = MouseEvent.Type.ButtonPressed;
					mouseEvent.buttons = MouseEvent.Buttons.Right;
					SetCapture(hWnd);
					GuiApplication.mWindows[hWnd].onMouseEvent(mouseEvent);
					return 0;
				case WM_RBUTTONUP:
					mouseEvent.type = MouseEvent.Type.ButtonReleased;
					mouseEvent.buttons = MouseEvent.Buttons.Right;
					ReleaseCapture();
					GuiApplication.mWindows[hWnd].onMouseEvent(mouseEvent);
					return 0;

				default:
					break;
			}
		}
		catch (Throwable e)
		{
			collectException(MessageBoxA(null, e.toString().toStringz, "Error", MB_OK | MB_ICONEXCLAMATION));	// PS: string.toString() method is not nothrow
		}
		return DefWindowProcA(hWnd, message, wParam, lParam);
	}

	// Declaring missing Win32 definitions
	extern (Windows)
	{
		BOOL	DestroyWindow(HWND);
		HANDLE	LoadImage(HINSTANCE hinst, LPCTSTR lpszName, UINT uType, int cxDesired, int cyDesired, UINT fuLoad);
		HWND	GetDesktopWindow();
		LONG	ChangeDisplaySettingsA(DEVMODE *lpDevMode, DWORD dwflags);
		BOOL	MoveWindow(HWND hWnd, int X, int Y, int nWidth, int nHeight, BOOL bRepaint);
		HWND	SetCapture(HWND hWnd);
		BOOL	ReleaseCapture();

		int	GET_X_LPARAM(LPARAM lParam) { return cast(int)(cast(short)LOWORD(lParam)); }
		int	GET_Y_LPARAM(LPARAM lParam) { return cast(int)(cast(short)HIWORD(lParam)); }

		struct DEVMODE {
			CHAR/*TCHAR*/ dmDeviceName[32 /*CCHDEVICENAME*/];
			WORD  dmSpecVersion;
			WORD  dmDriverVersion;
			WORD  dmSize;
			WORD  dmDriverExtra;
			DWORD dmFields;
			union {
				struct {
					short dmOrientation;
					short dmPaperSize;
					short dmPaperLength;
					short dmPaperWidth;
					short dmScale;
					short dmCopies;
					short dmDefaultSource;
					short dmPrintQuality;
				};
				struct {
					POINT/*POINTL*/ dmPosition;
					DWORD  dmDisplayOrientation;
					DWORD  dmDisplayFixedOutput;
				};
			};
			short dmColor;
			short dmDuplex;
			short dmYResolution;
			short dmTTOption;
			short dmCollate;
			CHAR/*TCHAR*/ dmFormName[32 /*CCHFORMNAME*/];
			WORD  dmLogPixels;
			DWORD dmBitsPerPel;
			DWORD dmPelsWidth;
			DWORD dmPelsHeight;
			union {
				DWORD dmDisplayFlags;
				DWORD dmNup;
			};
			DWORD dmDisplayFrequency;
	//		#if (WINVER >= 0x0400)
			DWORD dmICMMethod;
			DWORD dmICMIntent;
			DWORD dmMediaType;
			DWORD dmDitherType;
			DWORD dmReserved1;
			DWORD dmReserved2;
	//		#if (WINVER >= 0x0500) || (_WIN32_WINNT >= 0x0400)
			DWORD dmPanningWidth;
			DWORD dmPanningHeight;
	//		#endif 
	//		#endif 
		};
		alias DEVMODE	*PDEVMODE;
		alias DEVMODE	*LPDEVMODE;

		enum
		{
			DM_PELSWIDTH =	0x00080000L,
			DM_PELSHEIGHT =	0x00100000L,
		}

		enum
		{
			CDS_FULLSCREEN =	0x00000004,
		}

		enum
		{
			DISP_CHANGE_SUCCESSFUL =	0,
			DISP_CHANGE_RESTART =		1,
			DISP_CHANGE_FAILED =		-1,
			DISP_CHANGE_BADMODE =		-2,
			DISP_CHANGE_NOTUPDATED =	-3,
			DISP_CHANGE_BADFLAGS =		-4,
			DISP_CHANGE_BADPARAM =		-5,
			DISP_CHANGE_BADDUALVIEW =	-6,
		}

		enum
		{
			WM_MOVING =		0x0216,
		}
	}
}
