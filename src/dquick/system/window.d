module dquick.system.window;

import dquick.item.graphicItem;
import dquick.maths.vector2s32;

interface IWindow
{
	bool		create();
	void		destroy();	/// If call on main Window (first instancied) the application will exit
	
	bool		wasCreated() const;

	void			setMainItem(GraphicItem item);
	void			setMainItem(string filePath);
	GraphicItem		mainItem();

	void		setPosition(Vector2s32 position);
	Vector2s32	position();

	void		setSize(Vector2s32 size);
	Vector2s32	size();

	void		setFullScreen(bool fullScreen);	/// It's recommanded to set the size with the screenResolution method before entering in FullScreen mode to avoid scaling
	bool		fullScreen();

	Vector2s32	screenResolution() const;

	void		show();

	// TODO rajouter les flag maximized et minimized, comme ce sont des etats eclusifs, les mettre en enum avec le fullscreen
}
