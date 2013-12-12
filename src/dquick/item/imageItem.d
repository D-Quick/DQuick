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
		Stretch,				// the image is scaled to fit
		PreserveAspectFit,		// the image is scaled uniformly to fit without cropping
		PreserveAspectCrop,		// the image is scaled uniformly to fill, cropping if necessary
		Tile,					// the image is duplicated horizontally and vertically
		TileVertically,			// the image is stretched horizontally and tiled vertically
		TileHorizontally,		// the image is stretched vertically and tiled horizontally
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
	mixin Signal!(string)	onSourceChanged;

	@property Vector2s32	sourceSize() {return Vector2s32(0, 0);}
	mixin Signal!(Vector2s32)	onSourceSizeChanged;

	@property void	fillMode(FillMode mode)
	{
		if (mode == mFillMode)
			return;

		mFillMode = mode;
		onFillModeChanged.emit(mode);
		setSize(GraphicItem.size());
	}

	@property FillMode	fillMode() {return mFillMode;}
	mixin Signal!(FillMode)	onFillModeChanged;

	override
	{
		void	setSize(Vector2f32 size)
		{
			Vector2f32	implicitSize;

			final switch (mFillMode)
			{
				case FillMode.Stretch:
					implicitSize = size;
					break;
				case FillMode.PreserveAspectFit:
					if (sourceSize.x / sourceSize.y < size.x / size.y)
					{
						implicitSize.x = size.x * (sourceSize.y / sourceSize.x);
						implicitSize.y = size.y;
					}
					else
					{
						implicitSize.x = size.x;
						implicitSize.y = size.y * (sourceSize.y / sourceSize.x);
					}
					break;
				case FillMode.PreserveAspectCrop:
					implicitSize.x = size.x;
					implicitSize.y = size.y * (sourceSize.x / sourceSize.y);
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
			}

			mRectangle.setSize(implicitSize);
			GraphicItem.setSize(size);

			if (implicitSize == mImplicitSize)
				return;

			mImplicitSize = implicitSize;
			onImplicitWidthChanged.emit(mImplicitSize.x);
			onImplicitHeightChanged.emit(mImplicitSize.y);
		}

		@property void	width(float width) {mRectangle.width = width; GraphicItem.width = width;}
		@property float	width() {return GraphicItem.width;}
		@property void	height(float height) {mRectangle.height = height; GraphicItem.height = height;}
		@property float	height() {return GraphicItem.height;}

		@property float	implicitWidth() {return mRectangle.textureSize.x;}

		@property float	implicitHeight() {return mRectangle.textureSize.y;}
	}

private:
	Vector2f32	mImplicitSize = Vector2f32(0.0f, 0.0f);
	Rectangle	mRectangle;
	FillMode	mFillMode = FillMode.Stretch;
	string		mSource;
}
