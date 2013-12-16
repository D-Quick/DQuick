module dquick.system.win32.guiApplicationWin32;

version (Windows)
{
	import dquick.system.guiApplication;
	import dquick.system.win32.openglContextWin32;

	import std.stdio;
	import std.c.stdlib;
	import std.c.string;	// for memset
	import std.string;
	import std.path;
	import std.exception;

	import std.c.windows.windows;
	pragma(lib, "gdi32.lib");

	final class GuiApplication : GuiApplicationBase, IGuiApplication
	{
	public:
		shared static ~this()
		{
			mInstance = null;
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
			terminateExecution();
			return cast(int)msg.wParam;
		}

		//==========================================================================
		//==========================================================================

	private:
		this() {}

		void	registerWindow(Window window, HWND windowHandle)
		{
			mWindows[windowHandle] = window;
		}

		static GuiApplication	mInstance;

		Window[HWND]	mWindows;
	}

	//==========================================================================
	//==========================================================================

	final class Window : WindowBase, IWindow
	{
		this()
		{
			mWindowId = mWindowsCounter++;
		}

		~this()
		{
			mWindowsCounter--;
		}

		override
		{
			void		setMainItem(GraphicItem item) {super.setMainItem(item);}
			void		setMainItem(string filePath) {super.setMainItem(filePath);}
			GraphicItem	mainItem() {return super.mainItem();}
			DMLEngine	dmlEngine() {return super.dmlEngine();}
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

			GuiApplication.instance().registerWindow(this, mhWnd);

			return true;
		}

		bool	wasCreated() const
		{
			return mhWnd != null;
		}

		bool	isMainWindow() const
		{
			return (mWindowId == 0);
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

		void	setPosition(Vector2s32 newPosition)
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

		override void	setSize(Vector2s32 newSize)
		{
			super.setSize(newSize);

			mSize = newSize;

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

		//==========================================================================
		//==========================================================================

	protected:
		override
		{
			void	destroy()
			{
				mContext = null;
				DestroyWindow(mhWnd);
				super.destroy();
			}

			void	onPaint()
			{
				Renderer.startFrame();

				super.onPaint();

				if (mContext)
					mContext.swapBuffers();
			}

			void	onMouseEvent(MouseEvent mouseEvent) {super.onMouseEvent(mouseEvent);}
		}

	private:
		static int	mWindowsCounter = 0;
		int			mWindowId;

		HWND		mhWnd = null;
		string		mWindowName = "";
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
					if (hWnd in GuiApplication.instance().mWindows)
					{
						GuiApplication.instance().mWindows[hWnd].setPosition(position);
						GuiApplication.instance().mWindows[hWnd].onPaint();
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
					if (hWnd in GuiApplication.instance().mWindows)
						GuiApplication.instance().mWindows[hWnd].setSize(size);
					return 0;
				case WM_COMMAND:
					break;
				case WM_PAINT:
					if (hWnd in GuiApplication.instance().mWindows)
						GuiApplication.instance().mWindows[hWnd].onPaint();
					break;
				case WM_DESTROY:
					if (hWnd in GuiApplication.instance().mWindows)
						GuiApplication.instance().mWindows[hWnd].destroy();
					PostQuitMessage(0);
					break;

				// Mouse events
				case WM_MOUSEMOVE:
					position.x = GET_X_LPARAM(lParam);
					position.y = GET_Y_LPARAM(lParam);
					mouseEvent.type = MouseEvent.Type.Motion;
					mouseEvent.position = position;
					GuiApplication.instance().mWindows[hWnd].onMouseEvent(mouseEvent);
					return 0;
				case WM_LBUTTONDOWN:
					mouseEvent.type = MouseEvent.Type.ButtonPressed;
					mouseEvent.buttons = MouseEvent.Buttons.Left;
					SetCapture(hWnd);
					GuiApplication.instance().mWindows[hWnd].onMouseEvent(mouseEvent);
					return 0;
				case WM_LBUTTONUP:
					mouseEvent.type = MouseEvent.Type.ButtonReleased;
					mouseEvent.buttons = MouseEvent.Buttons.Left;
					ReleaseCapture();
					GuiApplication.instance().mWindows[hWnd].onMouseEvent(mouseEvent);
					return 0;
				case WM_RBUTTONDOWN:
					mouseEvent.type = MouseEvent.Type.ButtonPressed;
					mouseEvent.buttons = MouseEvent.Buttons.Right;
					SetCapture(hWnd);
					GuiApplication.instance().mWindows[hWnd].onMouseEvent(mouseEvent);
					return 0;
				case WM_RBUTTONUP:
					mouseEvent.type = MouseEvent.Type.ButtonReleased;
					mouseEvent.buttons = MouseEvent.Buttons.Right;
					ReleaseCapture();
					GuiApplication.instance().mWindows[hWnd].onMouseEvent(mouseEvent);
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
