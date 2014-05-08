module dquick.renderer3D.iTexture;

import dquick.media.image;
import dquick.maths.vector2s32;

interface ITexture
{
public:
	/// Replace the texture's image by the new one, format need to be the same (size, bytes per pixels, color encoding)
	void		update(Image image);
	bool		isLoaded();
	Vector2s32	size();

protected:
	void	load(Image image);
}
