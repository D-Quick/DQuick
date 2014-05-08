module dquick.renderer3D.openGL.VBO;

import dquick.renderer3D.openGL.util;
import dquick.utils.resourceManager;
import dquick.utils.utils;
import dquick.renderer3D.generic;
import dquick.buildSettings;

import derelict.opengl3.gl;

import std.stdio;

import core.runtime;

static if (renderer == RendererMode.OpenGL)
final class VBO(T) : IResource
{
	mixin ResourceBase;

public:
	this(VBOType type)
	{
		mType = typeToGLenum(type);
	}

	~this()
	{
		debug destructorAssert(mId == 0, "VBO.release method wasn't called.", mTrace);
	}

	void	load(string filePath, Variant[] options)
	{
		release();

		debug mTrace = defaultTraceHandler(null);

		assert(options && options.length == 2
			&& options[0].type() == typeid(VBOType)
			&& options[1].type() == typeid(VBOMode)
			&& options[2].type() == typeid(T[]));
		mType = typeToGLenum(options[0].get!VBOType());
		mMode = modeToGLenum(options[1].get!VBOMode());
		mArray = options[2].get!(T[])();

		mWeight = mArray.sizeof;
		mFilePath = filePath;
	}

	void	release()
	{
		checkgl!glDeleteBuffers(1, &mId);
		mId = 0;
	}

	void	bind()
	{
		assert(mId != 0);
		checkgl!glBindBuffer(mType, mId);
	}

	void	unbind()
	{
		checkgl!glBindBuffer(mType, 0);
	}

	void	setArray(T[] array, VBOMode mode)
	{
		mArray = array;
		mMode = modeToGLenum(mode);
		create();
	}

	void	updateArray(T[] array)
	{
		assert(mId != 0);
		mArray = array;
		bind();
		checkgl!glBufferData(mType, mArray.length * T.sizeof, mArray.ptr, mMode);
		unbind();
	}

	size_t	length() {return mArray.length;}

private:
	static const GLenum typeToGLenum(VBOType type)
	{
		final switch(type)
		{
			case VBOType.Indexes:
				return GL_ELEMENT_ARRAY_BUFFER;
			case VBOType.Geometry:
				return GL_ARRAY_BUFFER;
		}
	}

	static const GLenum modeToGLenum(VBOMode type)
	{
		final switch(type)
		{
			case VBOMode.Static:
				return GL_STATIC_DRAW;
			case VBOMode.Dynamic:
				return GL_DYNAMIC_DRAW;
		}
	}

	@property GLuint	id() {return mId;}

	void	create()
	{
		if (mId != 0)
			release();
		checkgl!glGenBuffers(1, &mId);
		if (mId == mBadId)
			throw new Exception("[Texture] Unable to generate a vbo");
		bind();
		checkgl!glBufferData(mType, mArray.length * T.sizeof, mArray.ptr, mMode);
		unbind();
	}

	static const GLuint	mBadId = 0;	// Useful if on some platforms 0 can be used for a VBO id

	GLuint	mId;
	T[]		mArray;
	GLenum	mType;
	GLenum	mMode;

	debug Throwable.TraceInfo	mTrace;
}
