module dquick.item.imageItem;

import dquick.item.graphicItem;

import dquick.renderer2D.openGL.rectangle;

import dquick.media.image;

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
	
	this(DeclarativeItem parent = null)
	{
		super(parent);
		debug
		{
			debugMeshColor(Color(255 / 255, 128 / 255, 0 / 255, 1.0f));
		}
	}

	override
	void	paint(bool transformationUpdated)
	{
		startPaint(transformationUpdated);
		if (mSource != "")
			mRectangle.draw();
		paintChildren();
		endPaint();
	}

	@property void	source(string filePath)
	{
		mSource = filePath;
		if (filePath != "" && !mRectangle.setTexture(filePath))
			writeln("ImageItem::source:: Warning : can't load image \"" ~ filePath ~"\"");
		// TODO If this item is root, update the window size (only when item has to repect the image size)
		setSize(mRectangle.size);
		onSourceChanged.emit(filePath);
		onImplicitWidthChanged.emit(implicitWidth);
		onImplicitHeightChanged.emit(implicitHeight);
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

		@property float	implicitWidth() {return mRectangle.textureSize.x;}

		@property float	implicitHeight() {return mRectangle.textureSize.y;}
	}

private:
	Rectangle	mRectangle;
	FillMode	mFillMode;
	string		mSource;
}
