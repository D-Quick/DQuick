module dquick.item.text_item;

import dquick.item.graphic_item;
import dquick.media.font;
import dquick.renderer_3d.opengl.mesh;

import std.stdio;

class TextItem : GraphicItem
{
public:
	alias Font.Family	FontFamily;

	this()
	{
		mMesh = new Mesh;
	}

	@property void	text(string text)
	{
		mText = text;
		onTextChanged.emit(text);
	}
	@property string	text() {return mText;}
	mixin Signal!(string) onTextChanged;

	@property void	font(string font)
	{
		mFont = font;
		onFontChanged.emit(font);
	}
	@property string	font() {return mFont;}
	mixin Signal!(string) onFontChanged;
	
	@property void	fontSize(int size)
	{
		mFontSize = size;
		onFontSizeChanged.emit(size);
	}
	@property int	fontSize() {return mFontSize;}
	mixin Signal!(int) onFontSizeChanged;
	
	@property void	fontFamily(FontFamily family)
	{
		mFontFamily = family;
		onFontFamilyChanged.emit(family);
	}
	@property FontFamily	fontFamily() {return mFontFamily;}
	mixin Signal!(FontFamily) onFontFamilyChanged;

	override
	void	paint(bool transformationUpdated)
	{
		startPaint(transformationUpdated);
//		mMesh.draw();
		paintChildren();
		endPaint();
	}

	override
	{
		void	setSize(Vector2f32 size)
		{
			GraphicItem.setSize(size);
		}

		@property void	width(float width) {GraphicItem.width = width;}
		@property float	width() {return GraphicItem.width;}
		@property void	height(float height) {GraphicItem.height = height;}
		@property float	height() {return GraphicItem.height;}
	}

private:
	Mesh		mMesh;
	string		mText;
	string		mFont;
	int			mFontSize;
	FontFamily	mFontFamily;
}
