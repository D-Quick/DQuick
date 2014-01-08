module dquick.renderer3D.openGL.VBO;

import dquick.renderer3D.openGL.util;
import dquick.utils.resourceManager;

import dquick.utils.utils;

import derelict.opengl3.gl;

import std.stdio;

final class VBO(T) : IResource
{
	mixin ResourceBase;

public:
	~this()
	{
		debug destructorAssert(mId == 0, "VBO.unload method wasn't called. \n" ~ mTrace.toString());
	}

	void	load(string filePath, Variant[] options)
	{
		unload();

		debug {mTrace = new Throwable("").info;}

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

	void	unload()
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

	void	setArray(T[] array, GLenum type, GLenum mode)
	{
		mArray = array;
		mType = type;
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
			unload();
		checkgl!glGenBuffers(1, &mId);
		bind();
		checkgl!glBufferData(mType, mArray.length * T.sizeof, mArray.ptr, mMode);
		unbind();
	}

	GLuint	mId;
	T[]		mArray;
	GLenum	mType;
	GLenum	mMode;

	debug
	{
		Throwable.TraceInfo	mTrace;
	}
}
