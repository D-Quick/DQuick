module dquick.renderer3D.openGL.shaderProgram;

import dquick.renderer3D.openGL.util;

import derelict.opengl3.gl;

import std.variant;
import std.string;

// TODO add a management of the program resource

/// This structure hold shader program parameters
struct ShaderProgram
{
public:
	static const GLuint	badId = 0;

	void	program(GLuint id) {mProgram = id;}
	GLuint	program() {return mProgram;}

	void	setParameter(string name, ParameterType type, void* values)
	{
		Parameter*	parameter;

		parameter = (name in mParameters);
		if (parameter is null)
		{
			Parameter	empty;
			mParameters[name] = empty;

			mParameters[name].id = checkgl!glGetUniformLocation(mProgram, name.toStringz);
			parameter = (name in mParameters);
			parameter.name = name;
		}
		parameter.type = type;
		parameter.values = values;
	}

	void	execute()
	{
		assert(mProgram != 0);

		checkgl!glUseProgram(mProgram);

		// TODO see how to limit the number of types and doing something smarter
		foreach (parameter; mParameters)
		{
			final switch (parameter.type)
			{
				case ParameterType.Int:
					glUniform1i(parameter.id, *(cast(int*)parameter.values));
					break;
				case ParameterType.Float:
					glUniform1f(parameter.id, *(cast(float*)parameter.values));
					break;
				case ParameterType.Float2D:
					glUniform2fv(parameter.id, 1, cast(float*)parameter.values);
					break;
				case ParameterType.Matrix4f:
					glUniformMatrix4fv(parameter.id, 1, false, cast(float*)parameter.values);
					break;
			}
		}
	}

private:
	GLuint				mProgram = badId;
	Parameter[string]	mParameters;
};

enum ParameterType
{
	Int,
	Float,
	Float2D,
	Matrix4f,
}

private
struct Parameter
{
	string			name;	// For debuging
	GLint			id;
	ParameterType	type;
	void*			values;
}
