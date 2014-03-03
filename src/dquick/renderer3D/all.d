module dquick.renderer3D.all;

import dquick.buildSettings;

static if (renderer == RendererMode.OpenGL)
{
	public import dquick.renderer3D.openGL.material;
	public import dquick.renderer3D.openGL.mesh;
	public import dquick.renderer3D.openGL.renderer;
	public import dquick.renderer3D.openGL.shader;
	public import dquick.renderer3D.openGL.shaderProgram;
	public import dquick.renderer3D.openGL.texture;
	public import dquick.renderer3D.openGL.util;
	public import dquick.renderer3D.openGL.VBO;
}
else static if (renderer == RendererMode.D3D9)
{
}
else
{
	// TODO throw a compile time error
}
