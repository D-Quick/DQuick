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
		Stretch,				// (default) the image is scaled to fit
		PreserveAspectFit,		// the image is scaled uniformly to fit without cropping
		PreserveAspectCrop,		// the image is scaled uniformly to fill, cropping if necessary
		Tile,					// the image is duplicated horizontally and vertically
		TileVertically,			// the image is stretched horizontally and tiled vertically
		TileHorizontally,		// the image is stretched vertically and tiled horizontally
		Pad,					// the image is not transformed
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
		if (!visible)
			return;
		startPaint(transformationUpdated);
		if (mSource != "")
			mRectangle.draw();
		paintChildren();
		endPaint();
	}

	@property void	source(string filePath)
	{
		Vector2s32	oldImplicitSize = mRectangle.textureSize;

		mSource = filePath;
		if (filePath != "" && !mRectangle.setTexture(filePath))
			writeln("ImageItem::source:: Warning : can't load image \"" ~ filePath ~"\"");
		updateSize(Vector2f32(width, height));
		onSourceChanged.emit(filePath);
		if (mRectangle.textureSize.x != oldImplicitSize.x)
			onImplicitWidthChanged.emit(mRectangle.textureSize.x);
		if (mRectangle.textureSize.y != oldImplicitSize.y)
			onImplicitHeightChanged.emit(mRectangle.textureSize.y);
	}

	@property float	paintedWidth() {return mPaintedSize.x;}
	mixin Signal!(float)	onPaintedWidthChanged;

	@property float	paintedHeight() {return mPaintedSize.y;}
	mixin Signal!(float)	onPaintedHeightChanged;

	@property string		source() {return mSource;}
	mixin Signal!(string)	onSourceChanged;

	@property void	fillMode(FillMode mode)
	{
		if (mode == mFillMode)
			return;

		mFillMode = mode;
		onFillModeChanged.emit(mode);
		updateSize(mSize);
	}

	@property FillMode	fillMode() {return mFillMode;}
	mixin Signal!(FillMode)	onFillModeChanged;

	override
	{
		@property void	width(float width) {GraphicItem.width = width; updateSize(Vector2f32(width, height));}
		@property float	width() {return GraphicItem.width;}
		@property void	height(float height) {GraphicItem.height = height; updateSize(Vector2f32(width, height));}
		@property float	height() {return GraphicItem.height;}
		@property float	implicitWidth()
		{
			return mRectangle.textureSize.x;
		}

		@property float	implicitHeight()
		{
			return mRectangle.textureSize.y;
		}
	}

protected:
	void	updateSize(Vector2f32 size)
	{
		Vector2f32	oldPaintedSize = mPaintedSize;
		Vector2f32	paintedSize;

		final switch (mFillMode)
		{
			case FillMode.Stretch:
				paintedSize = size;
				break;
			case FillMode.PreserveAspectFit:
				if (implicitWidth / implicitHeight < size.x / size.y)
				{
					paintedSize.x = size.x * (implicitHeight / implicitWidth) * (size.y / size.x);
					paintedSize.y = size.y;
				}
				else
				{
					paintedSize.x = size.x;
					paintedSize.y = size.y * (implicitHeight / implicitWidth) * (size.x / size.y);
				}
				break;
			case FillMode.PreserveAspectCrop:
				if (implicitWidth / implicitHeight < size.x / size.y)
				{
					paintedSize.x = size.x;
					paintedSize.y = size.y * (implicitHeight / implicitWidth) * (size.x / size.y);
				}
				else
				{
					paintedSize.x = size.x * (implicitHeight / implicitWidth) * (size.y / size.x);
					paintedSize.y = size.y;
				}
				break;
			case FillMode.Tile:
				paintedSize = size;
				break;
			case FillMode.TileVertically:
				paintedSize = size;
				break;
			case FillMode.TileHorizontally:
				paintedSize = size;
				break;
			case FillMode.Pad:
				paintedSize = Vector2f32(implicitWidth, implicitHeight);
				break;
		}

		mRectangle.setSize(paintedSize);

		if (paintedSize == mPaintedSize)
			return;

		mPaintedSize = paintedSize;
		if (mPaintedSize.x != oldPaintedSize.x)
			onPaintedWidthChanged.emit(mPaintedSize.x);
		if (mPaintedSize.y != oldPaintedSize.y)
			onPaintedHeightChanged.emit(mPaintedSize.y);
		mTransformationUpdated = true;
	}

private:
	Vector2f32	mPaintedSize = Vector2f32(0.0f, 0.0f);
	Rectangle	mRectangle;
	FillMode	mFillMode = FillMode.Stretch;
	string		mSource;
}
