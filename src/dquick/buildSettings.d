module dquick.buildSettings;

// TODO defines here all static variables checked at compile time to configure the build
enum RendererMode
{
	OpenGL,
	D3D10
}

enum WindowSystem
{
	Native,
	SDL
}

const WindowSystem	windowSystem = WindowSystem.Native;
const RendererMode	renderer = RendererMode.OpenGL;
