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
		Vector2s32	oldSourceSize = mRectangle.textureSize;

		mSource = filePath;
		if (filePath != "" && !mRectangle.setTexture(filePath))
			writeln("ImageItem::source:: Warning : can't load image \"" ~ filePath ~"\"");
		// TODO If this item is root, update the window size (only when item has to repect the image size)
		updateSize(mSize);
		onSourceChanged.emit(filePath);
		if (mRectangle.textureSize.x != oldSourceSize.x)
			onSourceWidthChanged.emit(mRectangle.textureSize.x);
		if (mRectangle.textureSize.y != oldSourceSize.y)
			onSourceHeightChanged.emit(mRectangle.textureSize.y);
	}

	@property string		source() {return mSource;}
	mixin Signal!(string)	onSourceChanged;

	@property float	sourceWidth()
	{
		return mRectangle.textureSize.x;
	}
	mixin Signal!(float)	onSourceWidthChanged;

	@property float	sourceHeight()
	{
		return mRectangle.textureSize.y;
	}
	mixin Signal!(float)	onSourceHeightChanged;

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

	@property FillMode	fillMode() {return mFillMode;}
	mixin Signal!(FillMode)	onFillModeChanged;

	override
	{
		@property void	width(float width) {updateSize(Vector2f32(width, GraphicItem.height));}
		@property float	width() {return GraphicItem.width;}
		@property void	height(float height) {updateSize(Vector2f32(GraphicItem.width, height));}
		@property float	height() {return GraphicItem.height;}
		@property float	implicitWidth() {return mImplicitSize.x;}
		@property float	implicitHeight() {return mImplicitSize.y;}
	}

protected:
	void	updateSize(Vector2f32 size)
	{
		Vector2f32	oldImplicitSize = mImplicitSize;
		Vector2f32	implicitSize;

		final switch (mFillMode)
		{
			case FillMode.Stretch:
				implicitSize = size;
				break;
			case FillMode.PreserveAspectFit:
				if (sourceWidth / sourceHeight < size.x / size.y)
				{
					implicitSize.x = size.x * (sourceHeight / sourceWidth) * (size.y / size.x);
					implicitSize.y = size.y;
				}
				else
				{
					implicitSize.x = size.x;
					implicitSize.y = size.y * (sourceHeight / sourceWidth) * (size.x / size.y);
				}
				break;
			case FillMode.PreserveAspectCrop:
				if (sourceWidth / sourceHeight < size.x / size.y)
				{
					implicitSize.x = size.x;
					implicitSize.y = size.y * (sourceHeight / sourceWidth) * (size.x / size.y);
				}
				else
				{
					implicitSize.x = size.x * (sourceHeight / sourceWidth) * (size.y / size.x);
					implicitSize.y = size.y;
				}
				break;
			case FillMode.Tile:
				implicitSize = size;
				break;
			case FillMode.TileVertically:
				implicitSize = size;
				break;
			case FillMode.TileHorizontally:
				implicitSize = size;
				break;
			case FillMode.Pad:
				implicitSize = Vector2f32(sourceWidth, sourceHeight);
				break;
		}

		mRectangle.setSize(implicitSize);
		GraphicItem.setSize(size);

		if (implicitSize == mImplicitSize)
			return;

		mImplicitSize = implicitSize;
		if (mImplicitSize.x != oldImplicitSize.x)
			onImplicitWidthChanged.emit(mImplicitSize.x);
		if (mImplicitSize.y != oldImplicitSize.y)
			onImplicitHeightChanged.emit(mImplicitSize.y);
		mTransformationUpdated = true;
	}

private:
	Vector2f32	mImplicitSize = Vector2f32(0.0f, 0.0f);
	Rectangle	mRectangle;
	FillMode	mFillMode = FillMode.Stretch;
	string		mSource;
}
