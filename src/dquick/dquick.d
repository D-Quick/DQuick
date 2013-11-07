module dquick;

static import dquick.utils.resourceManager;

static import dquick.system.dynamicLibrary;
static import dquick.system.guiApplication;
static import dquick.system.window;
version (Windows)
{
	static import dquick.system.win32.guiApplicationWin32;
	static import dquick.system.win32.openglContextWin32;
} else version (linux)
{
	static import dquick.system.sdl.guiApplicationSDL;
	static import dquick.system.sdl.openglContextSDL;
}
version (linux)
{
	static import dquick.system.linux.fontconfig.fontconfig;
	static import dquick.system.linux.fontconfig.functions;
	static import dquick.system.linux.fontconfig.types;
}

static import dquick.script.dmlEngine;
static import dquick.script.iItemBinding;
static import dquick.script.itemBinding;
static import dquick.script.nativePropertyBinding;
static import dquick.script.propertyBinding;
static import dquick.script.utils;
static import dquick.script.virtualPropertyBinding;

static import dquick.renderer3D.openGL.material;
static import dquick.renderer3D.openGL.mesh;
static import dquick.renderer3D.openGL.renderer;
static import dquick.renderer3D.openGL.shader;
static import dquick.renderer3D.openGL.shaderProgram;
static import dquick.renderer3D.openGL.texture;
static import dquick.renderer3D.openGL.util;
static import dquick.renderer3D.openGL.VBO;

static import dquick.renderer2D.openGL.borderRectangleShader;
static import dquick.renderer2D.openGL.borderRectangleVertices;
static import dquick.renderer2D.openGL.rectangle;

static import dquick.media.font;
static import dquick.media.geometry;
static import dquick.media.image;

static import dquick.maths.color;
static import dquick.maths.matrix4x4;
static import dquick.maths.quaternion;
static import dquick.maths.rect2s32;
static import dquick.maths.transformation;
static import dquick.maths.vector2f32;
static import dquick.maths.vector2s32;
static import dquick.maths.vector3f32;
static import dquick.maths.vector4f32;

static import dquick.item.borderImageItem;
static import dquick.item.declarativeItem;
static import dquick.item.graphicItem;
static import dquick.item.imageItem;
static import dquick.item.mouseAreaItem;
static import dquick.item.scrollViewItem;
static import dquick.item.textItem;
static import dquick.item.windowItem;

static import dquick.events.mouseEvent;

static import dquick.algorithms.atlas;
static import dquick.algorithms.textToGeometry;

// gl3n
static import gl3n.aabb;
static import gl3n.frustum;
static import gl3n.interpolate;
static import gl3n.linalg;
static import gl3n.math;
static import gl3n.plane;
static import gl3n.util;
static import gl3n.ext.matrixstack;
static import gl3n.color.hsv;

// derelict
static import derelict.util.exception;
static import derelict.util.loader;
static import derelict.util.sharedlib;
static import derelict.util.system;
static import derelict.util.wintypes;
static import derelict.util.xtypes;
static import derelict.tcod.functions;
static import derelict.tcod.libtcod;
static import derelict.tcod.types;
static import derelict.sfml2.audio;
static import derelict.sfml2.audiofunctions;
static import derelict.sfml2.audiotypes;
static import derelict.sfml2.graphics;
static import derelict.sfml2.graphicsfunctions;
static import derelict.sfml2.graphicstypes;
static import derelict.sfml2.network;
static import derelict.sfml2.networkfunctions;
static import derelict.sfml2.networktypes;
static import derelict.sfml2.system;
static import derelict.sfml2.systemfunctions;
static import derelict.sfml2.systemtypes;
static import derelict.sfml2.window;
static import derelict.sfml2.windowfunctions;
static import derelict.sfml2.windowtypes;
static import derelict.sdl2.functions;
static import derelict.sdl2.image;
static import derelict.sdl2.mixer;
static import derelict.sdl2.sdl;
static import derelict.sdl2.ttf;
static import derelict.sdl2.types;
static import derelict.pq.functions;
static import derelict.pq.pq;
static import derelict.pq.types;
static import derelict.opengl3.arb;
static import derelict.opengl3.cgl;
static import derelict.opengl3.constants;
static import derelict.opengl3.deprecatedConstants;
static import derelict.opengl3.deprecatedFunctions;
static import derelict.opengl3.ext;
static import derelict.opengl3.functions;
static import derelict.opengl3.gl;
static import derelict.opengl3.gl3;
static import derelict.opengl3.glx;
static import derelict.opengl3.internal;
static import derelict.opengl3.types;
static import derelict.opengl3.wgl;
static import derelict.openal.al;
static import derelict.openal.functions;
static import derelict.openal.types;
static import derelict.ogg.ogg;
static import derelict.ogg.oggfunctions;
static import derelict.ogg.oggtypes;
static import derelict.ogg.vorbis;
static import derelict.ogg.vorbisenc;
static import derelict.ogg.vorbisencfunctions;
static import derelict.ogg.vorbisenctypes;
static import derelict.ogg.vorbisfile;
static import derelict.ogg.vorbisfilefunctions;
static import derelict.ogg.vorbisfiletypes;
static import derelict.ogg.vorbisfunctions;
static import derelict.ogg.vorbistypes;
static import derelict.ode.functions;
static import derelict.ode.ode;
static import derelict.ode.types;
static import derelict.lua.functions;
static import derelict.lua.lua;
static import derelict.lua.macros;
static import derelict.lua.types;
static import derelict.glfw3.functions;
static import derelict.glfw3.glfw3;
static import derelict.glfw3.types;
static import derelict.freetype.ft;
static import derelict.freetype.functions;
static import derelict.freetype.types;
static import derelict.freeimage.freeimage;
static import derelict.freeimage.functions;
static import derelict.freeimage.types;
static import derelict.freeglut.functions;
static import derelict.freeglut.glut;
static import derelict.freeglut.types;
static import derelict.devil.functions;
static import derelict.devil.il;
static import derelict.devil.ilu;
static import derelict.devil.ilut;
static import derelict.devil.types;
static import derelict.assimp.assimp;
static import derelict.assimp.functions;
static import derelict.assimp.types;
static import derelict.alure.alure;
static import derelict.alure.functions;
static import derelict.alure.types;
