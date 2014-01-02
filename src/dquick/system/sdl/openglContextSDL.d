module dquick.system.sdl.openglContextSDL;

// TODO Import GL3 and migrate openGL demo code to a up to date code
// Find a way to be restricted to openGL 2 (with upper opengl function declared)
// Link to delerict git repository direcly to be able to get updates

// TODO add an interface
import std.stdio;
import std.c.string;	// for strstr
import std.string;

import derelict.opengl3.gl;
import derelict.opengl3.glx;
import derelict.util.exception;

import dquick.renderer3D.openGL.renderer;
import dquick.maths.matrix4x4;
import dquick.maths.vector2s32;

import derelict.sdl2.sdl;

struct OpenGLContextSDL
{
public:
	~this()
	{
		assert(mContext == null, "release method wasn't called.");
	}

	void	pushSettings()
	{
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);

		SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
		SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
		SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
		SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
		SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
	}

	void	initialize(SDL_Window* window)
	{
		mWindow = window;

		mContext = SDL_GL_CreateContext(mWindow);
		SDL_GL_SetSwapInterval(1);
		// Switch to Latest OpenGL version supported by hardware
		try
		{
			DerelictGL.reload(GLVersion.GL21, false);
		}
		catch(derelict.util.exception.SymbolLoadException e)
		{
			//if (e.symbolName() != "glDebug")
			//	throw e;
		}

		auto	glVersion = glGetString(GL_VERSION);
		if (glVersion)
			printf("[OpenGLContext] OpenGL Version: %s\n", glVersion);
	}

	void	makeCurrent()
	{
		SDL_GL_MakeCurrent(mWindow, mContext);
	}

	void	swapBuffers()
	{
		SDL_GL_SwapWindow(mWindow);
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
		if (mWindow)
		{
			SDL_GL_DeleteContext(mContext);
			mContext = null;
			mWindow = null;
		}
	}

private:
	SDL_Window*		mWindow;
	SDL_GLContext	mContext;
}
