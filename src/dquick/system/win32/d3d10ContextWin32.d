module dquick.system.win32.d3d10ContextWin32;

import dquick.buildSettings;

// TODO voir C:\Program Files (x86)\Microsoft DirectX SDK (June 2010)\Samples\C++

static if (renderer == RendererMode.D3D10)
{
	import std.c.windows.windows;

	pragma(lib, "d3d10.lib");	// TODO ajouter la lib dans les fichiers dub et le path dans la conf de visual, ne pas oublier de mettre les headers et le .lib dans les repertoires des dependances
	// TODO dupliquer les primitives opengl pour en faire des version direct 3D

	struct RendererContext
	{
	public:
		~this()
		{
		}

		void	initialize(HWND Hwnd)
		{
		}

		void	makeCurrent()
		{
		}

		void	swapBuffers()
		{
		}

		void	resize(int width, int height)
		{
		}

		void	release()
		{
		}

	private:
		HWND		mHwnd;
	}
}
