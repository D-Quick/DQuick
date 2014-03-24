module dquick.renderer3D.iMesh;

import dquick.renderer3D.generic;
import dquick.renderer3D.iTexture;
import dquick.renderer3D.iShader;

import dquick.media.image;

interface IMesh
{
public:
	bool		setTexture(string filePath);
	bool		setTexture(Image image);
	bool		setTexture(ITexture texture);
	ITexture	texture();

	void	setShader(IShader shader);
	IShader	shader();

	void			setShaderProgram(IShaderProgram program);
	IShaderProgram	shaderProgram();

	void			setPrimitiveType(PrimitiveType type);

	void	draw();
	void	construct();
	void	destruct();
}
