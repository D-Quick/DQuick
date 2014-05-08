module dquick.renderer3D.iShader;

import dquick.renderer3D.generic;

interface IShader
{
public:
	IShaderProgram	getProgram();
	void			release();
}

interface IShaderProgram
{
public:
	void	setParameter(string name, ParameterType type, void* values);
	void	execute();
};

private
struct Parameter
{
	string			name;	// For debuging
	ParameterType	type;
	void*			values;
}
