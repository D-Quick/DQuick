module dquick.renderer_3d.opengl.shader;

import dquick.renderer_3d.opengl.util;
import dquick.utils.resource_manager;

import derelict.opengl3.gl;

import std.string;
import std.stdio;
import std.file;

class Shader : IResource
{
	mixin ResourceBase;

public:
	this()
	{
	}
	
	~this()
	{
		cleanup();
	}
	
	/// Take a filePath of which correspond to the fragment and vertex shaders files without extention (extentions are "frag" and "vert")
	/// Shader will be compiled and linked
	void	load(string filePath, Variant[] options)
	{
		assert(options == null);
		cleanup();

		mVertexShaderFilePath = filePath ~ ".vert";
		mFragmentShaderFilePath = filePath ~ ".frag";

		compileAndLink();

		mWeight = 0;
		mFilePath = filePath;
	}

	GLuint	getProgram()
	{
		return mShaderProgram;
	}

private:
	void	cleanup()
	{
		if (mVertexShader)
		{
			checkgl!glDeleteShader(mVertexShader);
			mVertexShader = mBadId;
		}
		if (mFragmentShader)
		{
			checkgl!glDeleteShader(mFragmentShader);
			mFragmentShader = mBadId;
		}
		if (mShaderProgram)
		{
			checkgl!glDeleteProgram(mShaderProgram);
			mShaderProgram = mBadId;
		}
	}
	
	uint	loadAndCompileShaderFile(GLenum type, string filePath)
	{
		string	source;
		GLint	length;

		source = cast(string)read(filePath);
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
		scope(failure)cleanup();

		mShaderProgram = checkgl!glCreateProgram();

		mVertexShader = loadAndCompileShaderFile(GL_VERTEX_SHADER, mVertexShaderFilePath);
		if (mVertexShader == 0)
		{
			throw new Exception("Error while compiling vertex shader");
		}		

		mFragmentShader = loadAndCompileShaderFile(GL_FRAGMENT_SHADER, mFragmentShaderFilePath);
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
	
	string	mFragmentShaderFilePath;
	string	mVertexShaderFilePath;
};