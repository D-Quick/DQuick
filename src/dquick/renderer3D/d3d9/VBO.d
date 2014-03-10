module dquick.renderer3D.d3d9.VBO;

import dquick.renderer3D.d3d9.util;
import dquick.utils.resourceManager;

import dquick.utils.utils;

import std.stdio;

import core.runtime;

import dquick.buildSettings;

static if (renderer == RendererMode.D3D9)
final class VBO(T) : IResource
{
	mixin ResourceBase;

public:
	this(VBOType type)
	{
		mType = type;
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
			&& options[0].type() == typeid(GLenum)
			&& options[1].type() == typeid(GLenum)
			&& options[2].type() == typeid(T[]));
		mType = options[0].get!GLenum();
		mMode = options[1].get!GLenum();
		mArray = options[2].get!(T[])();

		mWeight = mArray.sizeof;
		mFilePath = filePath;
	}

	void	release()
	{
		checkgl!glDeleteBuffers(1, &mId);
		mId = 0;
	}

	@property GLuint	id() {return mId;}

	void	bind()
	{
		assert(mId != 0);
		checkgl!glBindBuffer(mType, mId);
	}

	void	unbind()
	{
		checkgl!glBindBuffer(mType, 0);
	}

	void	setArray(T[] array, GLenum mode)
	{
		mArray = array;
		mMode = mode;
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
