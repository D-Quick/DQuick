module dquick.renderer3D.d3d10.renderer;

import dquick.renderer3D.d3d10.util;
import dquick.maths.matrix4x4;
import dquick.maths.vector2s32;
import dquick.utils.resourceManager;

import std.math;
import std.stdio;

static if (renderer == RendererMode.D3D10)
shared static this()
{
	writeln("dquick.renderer3D.d3d10.renderer : shared static this()");
	Renderer.resourceManager = new ResourceManager();
	Renderer.resourceManager.maximumWeight(128 * 1000 * 1024);
}

static if (renderer == RendererMode.D3D10)
shared static ~this()
{
	writeln("dquick.renderer3D.d3d10.renderer : shared static ~this()");
	destroy(Renderer.resourceManager);
	Renderer.resourceManager = null;
}

import dquick.buildSettings;

static if (renderer == RendererMode.D3D10)
struct Renderer
{
	static ResourceManager	resourceManager;	// TODO check the release of resource when it's destroy (need to be destroy before the context) also check it for images

	static void	initialize()										// All Setup For D3D10 Goes Here
	{
		if (mInitialized)
			return;

		mInitialized = true;
	}

	static void	startFrame()
	{
	}

	static void	setViewportSize(in Vector2s32 size)
	{
		mViewportSize = size;
	}

	static Vector2s32	viewportSize()
	{
		return mViewportSize;
	}

	static void currentMDVMatrix(Matrix4x4 matrix)
	{
		mCurrentMDV = matrix;
	}

	static Matrix4x4 currentMDVMatrix()
	{
		return mCurrentMDV;
	}

	static void currentCamera(Matrix4x4 camera)
	{
		mCurrentCamera = camera;
	}

	static Matrix4x4	currentCamera()
	{
		return mCurrentCamera;
	}

	static void	startScissor(int x, int y, int width, int height)
	{
	}

	static void	endScissor()
	{
	}

private:
	static bool			mInitialized;
	static Matrix4x4	mCurrentMDV;
	static Matrix4x4	mCurrentCamera;
	static Vector2s32	mViewportSize;
}
