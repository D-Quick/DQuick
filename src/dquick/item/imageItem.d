module dquick.item.imageItem;

import dquick.item.graphicItem;

import dquick.renderer2D.openGL.rectangle;

import std.stdio;

class ImageItem : GraphicItem
{
public:
	enum	FillMode
	{
		Stretch,
		PreserveAspectFit,
		PreserveAspectCrop,
		Tile,
		TileVertically,
		TileHorizontally,
	}

	override
	void	paint(bool transformationUpdated)
	{
		startPaint(transformationUpdated);
		mRectangle.draw();
		paintChildren();
		endPaint();
	}

	@property void	source(string filePath)
	{
		mSource = filePath;
		if (!mRectangle.setTexture(filePath))
			writeln("ImageItem::source:: Warning : can't load image \"" ~ filePath ~"\"");
		// TODO If this item is root, update the window size (only when item has to repect the image size)
		setSize(mRectangle.size);
		onSourceChanged.emit(filePath);
	}

	@property string	source() {return mSource;}
	mixin Signal!(string) onSourceChanged;

	void	setFillMode(FillMode newMode)
	{
		mFillMode = newMode;
	}

	override
	{
		void	setSize(Vector2f32 size)
		{
			mRectangle.setSize(size);
			GraphicItem.setSize(size);
		}

		@property void	width(float width) {mRectangle.width = width; GraphicItem.width = width;}
		@property float	width() {return GraphicItem.width;}
		@property void	height(float height) {mRectangle.height = height; GraphicItem.height = height;}
		@property float	height() {return GraphicItem.height;}
	}

private:
	Rectangle	mRectangle;
	FillMode	mFillMode;
	string		mSource;
}
