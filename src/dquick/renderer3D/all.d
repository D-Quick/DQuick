module dquick.renderer3D.all;

import dquick.buildSettings;

public import dquick.renderer3D.generic;

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
	public import dquick.renderer3D.d3d9.material;
	public import dquick.renderer3D.d3d9.mesh;
	public import dquick.renderer3D.d3d9.renderer;
	public import dquick.renderer3D.d3d9.shader;
	public import dquick.renderer3D.d3d9.shaderProgram;
	public import dquick.renderer3D.d3d9.texture;
	public import dquick.renderer3D.d3d9.util;
	public import dquick.renderer3D.d3d9.VBO;
}
else
{
	static assert(false, "RendererMode not supported :\""~ renderer ~"\"");
}
