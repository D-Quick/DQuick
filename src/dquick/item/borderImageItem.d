module dquick.item.borderImageItem;

import dquick.item.graphicItem;
import dquick.renderer2D.openGL.borderRectangleShader;
import dquick.renderer2D.openGL.borderRectangleVertices;
import dquick.script.itemBinding;

import std.stdio;

alias BorderRectangleVertices	BorderRectangle;

class BorderImageItem : GraphicItem
{
	mixin(dquick.script.itemBinding.I_ITEM_BINDING);
public:
	alias BorderRectangle.TileMode	TileMode;
	
	this(DeclarativeItem parent = null)
	{
		super(parent);
		sourceProperty = new typeof(sourceProperty)(this, this);
		sourceWidthProperty = new typeof(sourceWidthProperty)(this, this);
		sourceHeightProperty = new typeof(sourceHeightProperty)(this, this);
		borderLeftProperty = new typeof(borderLeftProperty)(this, this);
		borderRightProperty = new typeof(borderRightProperty)(this, this);
		borderTopProperty = new typeof(borderTopProperty)(this, this);
		borderBottomProperty = new typeof(borderBottomProperty)(this, this);
		debug
		{
			debugMeshColor(Color(128 / 255, 0 / 255, 255 / 255, 1.0f));
		}
	}
	
	override
	void	paint(bool transformationUpdated)
	{
		if (!visible)
			return;
		startPaint(transformationUpdated);
		mRectangle.draw();
		paintChildren();
		endPaint();
	}

	void	source(string filePath)
	{
		Vector2s32	oldSourceSize = mRectangle.textureSize;

		mSource = filePath;
		if (filePath != "" && !mRectangle.setTexture(filePath))
			writeln("ImageItem::source:: Warning : can't load image \"" ~ filePath ~"\"");
		updateSize(mSize);
		onSourceChanged.emit(filePath);
		if (mRectangle.textureSize.x != oldSourceSize.x)
			onSourceWidthChanged.emit(mRectangle.textureSize.x);
		if (mRectangle.textureSize.y != oldSourceSize.y)
			onSourceHeightChanged.emit(mRectangle.textureSize.y);
	}

	// source
	dquick.script.nativePropertyBinding.NativePropertyBinding!(string, BorderImageItem, "source")	sourceProperty;
	string	source() {return mSource;}
	mixin Signal!(string) onSourceChanged;

	// sourceWidth
	dquick.script.nativePropertyBinding.NativePropertyBinding!(float, BorderImageItem, "sourceWidth")	sourceWidthProperty;
	float	sourceWidth()
	{
		return mRectangle.textureSize.x;
	}
	mixin Signal!(float)	onSourceWidthChanged;

	// sourceHeight
	dquick.script.nativePropertyBinding.NativePropertyBinding!(float, BorderImageItem, "sourceHeight")	sourceHeightProperty;
	float	sourceHeight()
	{
		return mRectangle.textureSize.y;
	}
	mixin Signal!(float)	onSourceHeightChanged;

	override
	{
		void	width(float width) {mRectangle.width = width; GraphicItem.width = width;}
		float	width() {return GraphicItem.width;}
		void	height(float height) {mRectangle.height = height; GraphicItem.height = height;}
		float	height() {return GraphicItem.height;}

		void	release()
		{
			mRectangle.destruct();
		}
	}

	// borderLeft
	dquick.script.nativePropertyBinding.NativePropertyBinding!(int, BorderImageItem, "borderLeft")	borderLeftProperty;
	void	borderLeft(int value) {mRectangle.borderLeft(value); onBorderLeftChanged.emit(value);}
	int	borderLeft() {return mRectangle.borderLeft();}
	mixin Signal!(int) onBorderLeftChanged;

	// borderRight
	dquick.script.nativePropertyBinding.NativePropertyBinding!(int, BorderImageItem, "borderRight")	borderRightProperty;
	void	borderRight(int value) {mRectangle.borderRight(value); onBorderRightChanged.emit(value);}
	int	borderRight() {return mRectangle.borderRight();}
	mixin Signal!(int) onBorderRightChanged;

	// borderTop
	dquick.script.nativePropertyBinding.NativePropertyBinding!(int, BorderImageItem, "borderTop")	borderTopProperty;
	void	borderTop(int value) {mRectangle.borderTop(value); onBorderTopChanged.emit(value);}
	int	borderTop() {return mRectangle.borderTop();}
	mixin Signal!(int) onBorderTopChanged;

	// borderBottom
	dquick.script.nativePropertyBinding.NativePropertyBinding!(int, BorderImageItem, "borderBottom")	borderBottomProperty;
	void	borderBottom(int value) {mRectangle.borderBottom(value); onBorderBottomChanged.emit(value);}
	int	borderBottom() {return mRectangle.borderBottom();}
	mixin Signal!(int) onBorderBottomChanged;

	// TODO
	// horizontalTileMode
	void	horizontalTileMode(TileMode mode) {mRectangle.horizontalTileMode(mode);}

	// TODO
	// verticalTileMode
	void	verticalTileMode(TileMode mode) {mRectangle.verticalTileMode(mode);}

protected:
	void	updateSize(Vector2f32 size)
	{
		mRectangle.setSize(size);
		GraphicItem.width = size.x;
		GraphicItem.height = size.y;
	}

private:
	BorderRectangle	mRectangle;
	string			mSource;
}
