module dquick.renderer3D.iVBO;

interface IVBO(T)
{
public:
	this(VBOType type);

	void	bind();
	void	unbind();
	void	setArray(T[] array, VBOMode mode);
	void	updateArray(T[] array);
	size_t	length();
}
