module dquick.renderer3D.d3d10.VBO;

import dquick.renderer3D.d3d10.util;
import dquick.renderer3D.generic;
import dquick.utils.resourceManager;

import dquick.utils.utils;

import std.stdio;

import core.runtime;

import dquick.buildSettings;

static if (renderer == RendererMode.D3D10)
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

//	IDirect3DVertexBuffer9*	buffer;

	T[]		mArray;

	debug Throwable.TraceInfo	mTrace;
}
