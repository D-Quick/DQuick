module dquick.system.win32.openglContextWin32;

// TODO Import GL3 and migrate openGL demo code to a up to date code
// Find a way to be restricted to openGL 2 (with upper opengl function declared)
// Link to delerict git repository direcly to be able to get updates

version (Windows)
{
	import std.c.windows.windows;

	import std.stdio;
	import std.c.string;	// for strstr
	import std.string;

/*	import c.gl.gl;
	import c.gl.wgl;
	import c.gl.wglext;*/
	import derelict.opengl3.wgl;
	import derelict.opengl3.gl;

	import dquick.renderer3D.openGL.renderer;
	import dquick.maths.matrix4x4;
	import dquick.maths.vector2s32;

	import dquick.utils.utils;

	struct OpenGLContext
	{
	public:
		~this()
		{
			debug destructorAssert(mContext == null, "OpenGLContext.release method wasn't called.");
		}

		void	initialize(HWND Hwnd)
		{
/*			c.gl.wgl.load();
			c.gl.wglext.load();
			c.gl.gl.load();
			c.gl.glext.load();
*/
			// Paramètres de rendu
			PIXELFORMATDESCRIPTOR PixelDescriptor = 
			{
				PIXELFORMATDESCRIPTOR.sizeof,   // size of this pfd
				1,                               // version number
				PFD_DRAW_TO_WINDOW |             // support window
				PFD_SUPPORT_OPENGL |             // support OpenGL
				PFD_DOUBLEBUFFER,               // double buffered
				//PFD_SWAP_EXCHANGE,
				PFD_TYPE_RGBA,                   // RGBA type
				32,                              // 32-bit color depth
				0, 0, 0, 0, 0, 0,                // color bits ignored
				1,                               // alpha buffer
				0,                               // shift bit ignored
				0,                               // no accumulation buffer
				0, 0, 0, 0,                      // accum bits ignored
				32,                              // 32-bit z-buffer
				32,                              // 32-bits stencil buffer
				0,                               // no auxiliary buffer
				PFD_MAIN_PLANE,                  // main layer
				0,                               // reserved
				0, 0, 0                          // layer masks ignored
			};

			// Récupération du Hwnd et du HDC de la fenêtre de rendu
			mHwnd   = Hwnd;
			mHandle = GetDC(Hwnd);
			if (!mHandle)
				throw new Exception("[TeOpenGLContext::initialize(void* handle)] Unable to get DC.");


			//--------------------------------------------------------------------

			if (wglChoosePixelFormatARB)	// TODO see why it's not loaded
			{
				int[]	attributs =
				[
					WGL_DRAW_TO_WINDOW_ARB, GL_TRUE,
					WGL_SUPPORT_OPENGL_ARB, GL_TRUE,
					WGL_DOUBLE_BUFFER_ARB, GL_TRUE,
					WGL_SWAP_METHOD_ARB, WGL_SWAP_EXCHANGE_ARB,            //< this is what make the modal dialog work
					WGL_PIXEL_TYPE_ARB,	WGL_TYPE_RGBA_ARB,
					WGL_COLOR_BITS_ARB, 32,
					WGL_ALPHA_BITS_ARB, 8,
					WGL_DEPTH_BITS_ARB, 24,
					WGL_STENCIL_BITS_ARB, 8,
					0, 0
				];

				int		theFormat = 0;
				UINT	numFormats = -1;
				if (!wglChoosePixelFormatARB(mHandle, attributs.ptr, null, 1, &theFormat, &numFormats))
					throw new Exception("[TeOpenGLContext::initialize(void* handle)] wglChoosePixelFormatARB error.");
			}
			//--------------------------------------------------------------------

			int	iPixelFormat = ChoosePixelFormat(mHandle, &PixelDescriptor);
			if (!iPixelFormat)
				throw new Exception("[TeOpenGLContext::initialize(void* handle)] Unsported pixel format.");

			// Choix du meilleur format de pixels
			if (!SetPixelFormat(mHandle, iPixelFormat, &PixelDescriptor))
				throw new Exception("[TeOpenGLContext::initialize(void* handle)] Unable to set pixel format.");

			// Création du contexte de rendu
			mContext = wglCreateContext(mHandle);
			if (!mContext)
				throw new Exception("[TeOpenGLContext::initialize(void* handle)] Unable to create the context.");
			if (!wglMakeCurrent(mHandle, mContext))
				throw new Exception("[TeOpenGLContext::initialize(void* handle)] Unable to make context current.");

/*			if (WGLExtensionSupported("WGL_EXT_swap_control"))
			{
				if (wglSwapIntervalEXT)
					wglSwapIntervalEXT(0);
			}*/

			// Switch to Latest OpenGL version supported by hardware
/*			try
			{*/
				DerelictGL.reload(GLVersion.GL21, false);
/*			}
			catch (derelict.util.exception.SymbolLoadException e)
			{
				//if (e.symbolName() != "glDebug")
				//	throw e;
			}
*/
			auto	glVersion = glGetString(GL_VERSION);
			if (glVersion)
				printf("[OpenGLContext] OpenGL Version: %s\n", glVersion);
		}

		void	makeCurrent()
		{
			wglMakeCurrent(mHandle, mContext);
		}

		void	swapBuffers()
		{
			SwapBuffers(mHandle);
		}

		void	resize(int width, int height)
		{
			if (height==0)										// Prevent A Divide By Zero By
			{
				height=1;										// Making Height Equal One
			}


			Renderer.setViewportSize(Vector2s32(width, height));						// Reset The Current Viewport

			Matrix4x4	camera;
			camera = Matrix4x4.orthographic(0.0, width, height, 0.0, -100.0, 100.0);
			Renderer.currentCamera(camera);
			//		Renderer.currentMDVMatrix(switchMatrixRowsColumns(camera));
		}

		void	release()
		{
			if (mContext)
			{
				wglDeleteContext(mContext);
				mContext = null;
			}
		}

	private:
		HWND		mHwnd;
		HDC			mHandle;
		HGLRC		mContext;
	}

	// TODO add this extension to Derelict
	private bool	WGLExtensionSupported(const char *extension_name)
	{
/*		if (!wglGetExtensionsStringEXT ||
			strstr(wglGetExtensionsStringEXT(), extension_name) == null)*/
			return false;
//		return true;
	}

	extern (Windows)
	{
		int		ChoosePixelFormat(HDC hdc, const PIXELFORMATDESCRIPTOR *ppfd);
		BOOL	SwapBuffers(HDC);

		/* PIXELFORMATDESCRIPTOR flags */
		enum
		{
			PFD_DOUBLEBUFFER           = 0x00000001,
			PFD_STEREO                 = 0x00000002,
			PFD_DRAW_TO_WINDOW         = 0x00000004,
			PFD_DRAW_TO_BITMAP         = 0x00000008,
			PFD_SUPPORT_GDI            = 0x00000010,
			PFD_SUPPORT_OPENGL         = 0x00000020,
			PFD_GENERIC_FORMAT         = 0x00000040,
			PFD_NEED_PALETTE           = 0x00000080,
			PFD_NEED_SYSTEM_PALETTE    = 0x00000100,
			PFD_SWAP_EXCHANGE          = 0x00000200,
			PFD_SWAP_COPY              = 0x00000400,
			PFD_SWAP_LAYER_BUFFERS     = 0x00000800,
			PFD_GENERIC_ACCELERATED    = 0x00001000,
			PFD_SUPPORT_DIRECTDRAW     = 0x00002000,
			PFD_DIRECT3D_ACCELERATED   = 0x00004000,
			PFD_SUPPORT_COMPOSITION    = 0x00008000,
		}

		/* PIXELFORMATDESCRIPTOR flags for use in ChoosePixelFormat only */
		enum
		{
			PFD_DEPTH_DONTCARE         = 0x20000000,
			PFD_DOUBLEBUFFER_DONTCARE  = 0x40000000,
			PFD_STEREO_DONTCARE        = 0x80000000,
		}

		/* pixel types */
		enum
		{
			PFD_TYPE_RGBA        = 0,
			PFD_TYPE_COLORINDEX  = 1,
		}

		/* layer types */
		enum
		{
			PFD_MAIN_PLANE       = 0,
			PFD_OVERLAY_PLANE    = 1,
			PFD_UNDERLAY_PLANE   = (-1),
		}

		enum
		{
			WGL_NUMBER_PIXEL_FORMATS_ARB	= 0x2000,
			WGL_DRAW_TO_WINDOW_ARB			= 0x2001,
			WGL_DRAW_TO_BITMAP_ARB			= 0x2002,
			WGL_ACCELERATION_ARB			= 0x2003,
			WGL_NEED_PALETTE_ARB			= 0x2004,
			WGL_NEED_SYSTEM_PALETTE_ARB		= 0x2005,
			WGL_SWAP_LAYER_BUFFERS_ARB		= 0x2006,
			WGL_SWAP_METHOD_ARB				= 0x2007,
			WGL_NUMBER_OVERLAYS_ARB			= 0x2008,
			WGL_NUMBER_UNDERLAYS_ARB		= 0x2009,
			WGL_TRANSPARENT_ARB				= 0x200A,
			WGL_TRANSPARENT_RED_VALUE_ARB	= 0x2037,
			WGL_TRANSPARENT_GREEN_VALUE_ARB = 0x2038,
			WGL_TRANSPARENT_BLUE_VALUE_ARB	= 0x2039,
			WGL_TRANSPARENT_ALPHA_VALUE_ARB = 0x203A,
			WGL_TRANSPARENT_INDEX_VALUE_ARB = 0x203B,
			WGL_SHARE_DEPTH_ARB				= 0x200C,
			WGL_SHARE_STENCIL_ARB			= 0x200D,
			WGL_SHARE_ACCUM_ARB				= 0x200E,
			WGL_SUPPORT_GDI_ARB				= 0x200F,
			WGL_SUPPORT_OPENGL_ARB			= 0x2010,
			WGL_DOUBLE_BUFFER_ARB			= 0x2011,
			WGL_STEREO_ARB					= 0x2012,
			WGL_PIXEL_TYPE_ARB				= 0x2013,
			WGL_COLOR_BITS_ARB				= 0x2014,
			WGL_RED_BITS_ARB				= 0x2015,
			WGL_RED_SHIFT_ARB				= 0x2016,
			WGL_GREEN_BITS_ARB				= 0x2017,
			WGL_GREEN_SHIFT_ARB				= 0x2018,
			WGL_BLUE_BITS_ARB				= 0x2019,
			WGL_BLUE_SHIFT_ARB				= 0x201A,
			WGL_ALPHA_BITS_ARB				= 0x201B,
			WGL_ALPHA_SHIFT_ARB				= 0x201C,
			WGL_ACCUM_BITS_ARB				= 0x201D,
			WGL_ACCUM_RED_BITS_ARB			= 0x201E,
			WGL_ACCUM_GREEN_BITS_ARB		= 0x201F,
			WGL_ACCUM_BLUE_BITS_ARB			= 0x2020,
			WGL_ACCUM_ALPHA_BITS_ARB		= 0x2021,
			WGL_DEPTH_BITS_ARB				= 0x2022,
			WGL_STENCIL_BITS_ARB			= 0x2023,
			WGL_AUX_BUFFERS_ARB				= 0x2024,
			WGL_NO_ACCELERATION_ARB			= 0x2025,
			WGL_GENERIC_ACCELERATION_ARB	= 0x2026,
			WGL_FULL_ACCELERATION_ARB		= 0x2027,
			WGL_SWAP_EXCHANGE_ARB			= 0x2028,
			WGL_SWAP_COPY_ARB				= 0x2029,
			WGL_SWAP_UNDEFINED_ARB			= 0x202A,
			WGL_TYPE_RGBA_ARB				= 0x202B,
			WGL_TYPE_COLORINDEX_ARB			= 0x202C,
		}
	}
}
