module dquick.renderer3D.iRenderer;

import dquick.maths.vector2s32;
import dquick.maths.matrix4x4;

interface IRenderer
{
	static void			initialize();
	static void			startFrame();
	static void			setViewportSize(in Vector2s32 size);
	static Vector2s32	viewportSize();
	static void			currentMDVMatrix(Matrix4x4 matrix);
	static Matrix4x4	currentMDVMatrix();
	static void			currentCamera(Matrix4x4 camera);
	static Matrix4x4	currentCamera();
	static void			startScissor(int x, int y, int width, int height);
	static void			endScissor();
}
