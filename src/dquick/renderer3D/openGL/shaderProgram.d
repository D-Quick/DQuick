module dquick.renderer_3d.opengl.shader_program;

import dquick.renderer_3d.opengl.util;

import derelict.opengl3.gl;

import std.variant;
import std.string;

// TODO add a management of the program resource

/// This structure hold shader program parameters
class ShaderProgram
{
public:
	void	setProgram(GLuint id) {mProgram = id;}

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
			switch (parameter.type)
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
				default:
					assert(false);
					break;
			}
		}
	}

private:
	GLuint				mProgram = 0;
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
