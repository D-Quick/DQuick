module dquick.renderer3D.iShader;

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
	ParameterType	type;
	void*			values;
}
