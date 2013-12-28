module dquick.renderer3D.openGL.shader;

import dquick.renderer3D.openGL.util;
import dquick.utils.resourceManager;

import derelict.opengl3.gl;

import std.string;
import std.stdio;
import std.file;

final class Shader : IResource
{
	mixin ResourceBase;

public:
	this()
	{
	}
	
	~this()
	{
		unload();
	}
	
	/// Take a filePath of which correspond to the fragment and vertex shaders files without extention (extentions are "frag" and "vert")
	/// Shader will be compiled and linked
	void	load(string filePath, Variant[] options)
	{
		unload();

		if (options == null)
		{
			mVertexShaderSource = cast(string)read(filePath ~ ".vert");
			mFragmentShaderSource = cast(string)read(filePath ~ ".frag");

/*			if (mVertexShaderSource.length == 0 || mFragmentShaderSource.length == 0)
				throw new Exception(format("Can't find shader files : %s or %s", filePath ~ ".vert", filePath ~ ".frag"));*/
		}
		else
		{
			assert(options.length == 2);
			assert(options[0].type() == typeid(string));
			assert(options[1].type() == typeid(string));

			mVertexShaderSource = options[0].get!string;
			mFragmentShaderSource = options[1].get!string;
		}

		compileAndLink();

		mWeight = 0;
		mFilePath = filePath;
	}

	GLuint	getProgram()
	{
		return mShaderProgram;
	}

private:
	void	unload()
	{
		if (mVertexShader != mBadId)
		{
			checkgl!glDeleteShader(mVertexShader);
			mVertexShader = mBadId;
		}
		if (mFragmentShader != mBadId)
		{
			checkgl!glDeleteShader(mFragmentShader);
			mFragmentShader = mBadId;
		}
		if (mShaderProgram != mBadId)
		{
			checkgl!glDeleteProgram(mShaderProgram);
			mShaderProgram = mBadId;
		}
	}

	uint	loadAndCompileShader(GLenum type, string source)
	{
		GLint	length;

		length = cast(GLint)source.length;

		GLuint shader = checkgl!glCreateShader(type);
		
		auto	ssp = source.ptr;
		checkgl!glShaderSource(shader, 1, &ssp, &length);
		
		checkgl!glCompileShader(shader);
		
		GLint status;
		checkgl!glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
		
		if (status == GL_FALSE)
		{
			GLint logLength;
			checkgl!glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
			
			if (logLength > 0)
			{
				ubyte[]	log;

				log.length = logLength;
				checkgl!glGetShaderInfoLog(shader, logLength, &logLength, cast(GLchar*)log.ptr);
				
				writefln("\n%s", cast(string)log);
			}
			throw new Exception(format("Failed to compile shader: %s", filePath));
		}
		
		return shader;
	}
	
	void	compileAndLink()
	{
		scope(failure)unload();

		mShaderProgram = checkgl!glCreateProgram();

		mVertexShader = loadAndCompileShader(GL_VERTEX_SHADER, mVertexShaderSource);
		if (mVertexShader == 0)
		{
			throw new Exception("Error while compiling vertex shader");
		}		

		mFragmentShader = loadAndCompileShader(GL_FRAGMENT_SHADER, mFragmentShaderSource);
		if (mFragmentShader == 0)
		{
			throw new Exception("Error while compiling fragment shader");
		}

		checkgl!glAttachShader(mShaderProgram, mVertexShader);
		checkgl!glAttachShader(mShaderProgram, mFragmentShader);

		linkProgram();
	}

	void	linkProgram()
	{
		checkgl!glLinkProgram(mShaderProgram);
		
		GLint status;
		checkgl!glGetProgramiv(mShaderProgram, GL_LINK_STATUS, &status);
		if (status == GL_FALSE)
		{
			debug	// Retrieve the log
			{
				//checkgl!glValidateProgram(mShaderProgram);
				GLint	logLength;
				checkgl!glGetProgramiv(mShaderProgram, GL_INFO_LOG_LENGTH, &logLength);
				if (logLength > 0)
				{
					GLchar[]	log = new char[](logLength);

					glGetProgramInfoLog(mShaderProgram, logLength, &logLength, log.ptr);
					if (logLength > 0)	// It seems GL_INFO_LOG_LENGTH can return 1 instead of 0
						writeln("Shader log :\n" ~ log);
				}
			}
			throw new Exception("Failed to link program");
		}
	}
	
	static const GLuint	mBadId = 0;

	GLuint	mFragmentShader = mBadId;
	GLuint	mVertexShader = mBadId;
	GLuint	mShaderProgram = mBadId;
	
	string	mFragmentShaderSource;
	string	mVertexShaderSource;
};
