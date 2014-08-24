module dquick.renderer3D.all;

import dquick.buildSettings;

public import dquick.renderer3D.generic;

static if (renderer == RendererMode.OpenGL)
{
	public import dquick.renderer3D.openGL.mesh;
	public import dquick.renderer3D.openGL.renderer;
	public import dquick.renderer3D.openGL.shader;
	public import dquick.renderer3D.openGL.texture;
	public import dquick.renderer3D.openGL.util;
	public import dquick.renderer3D.openGL.VBO;
}
else static if (renderer == RendererMode.D3D10)
{
	public import dquick.renderer3D.d3d10.mesh;
	public import dquick.renderer3D.d3d10.renderer;
	public import dquick.renderer3D.d3d10.shader;
	public import dquick.renderer3D.d3d10.texture;
	public import dquick.renderer3D.d3d10.util;
	public import dquick.renderer3D.d3d10.VBO;
}
else
{
	static assert(false, "RendererMode not supported :\""~ renderer ~"\"");
}
