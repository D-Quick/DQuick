module dquick.item.borderImageItem;

import dquick.item.graphicItem;

import dquick.renderer2D.openGL.borderRectangleShader;
import dquick.renderer2D.openGL.borderRectangleVertices;

import std.stdio;

alias BorderRectangleVertices	BorderRectangle;

class BorderImageItem : GraphicItem
{
public:
	alias BorderRectangle.TileMode	TileMode;
	
	this(DeclarativeItem parent = null)
	{
		super(parent);
		debug
		{
			debugMeshColor(Color(128 / 255, 0 / 255, 255 / 255, 1.0f));
		}
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

	@property void	borderLeft(int value) {mRectangle.borderLeft(value); onBorderLeftChanged.emit(value);}
	@property int	borderLeft() {return mRectangle.borderLeft();}
	mixin Signal!(int) onBorderLeftChanged;

	@property void	borderRight(int value) {mRectangle.borderRight(value); onBorderRightChanged.emit(value);}
	@property int	borderRight() {return mRectangle.borderRight();}
	mixin Signal!(int) onBorderRightChanged;

	@property void	borderTop(int value) {mRectangle.borderTop(value); onBorderTopChanged.emit(value);}
	@property int	borderTop() {return mRectangle.borderTop();}
	mixin Signal!(int) onBorderTopChanged;

	@property void	borderBottom(int value) {mRectangle.borderBottom(value); onBorderBottomChanged.emit(value);}
	@property int	borderBottom() {return mRectangle.borderBottom();}
	mixin Signal!(int) onBorderBottomChanged;

	// TODO
	@property void	horizontalTileMode(TileMode mode) {mRectangle.horizontalTileMode(mode);}
	@property void	verticalTileMode(TileMode mode) {mRectangle.verticalTileMode(mode);}

private:
	BorderRectangle	mRectangle;
	string			mSource;
}
