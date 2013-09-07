module dquick.item.text_item;

import dquick.item.graphic_item;
import dquick.media.font;
import dquick.media.image;
import dquick.renderer_3d.opengl.mesh;
import dquick.maths.vector2s32;
import dquick.maths.color;

import std.stdio;
import std.typecons;
import std.string;

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
		mMesh.draw();
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
	void	buildMesh()
	{
		mMesh = new Mesh();

		Font	font;

		Image[]	images;

		font = fontManager.getFont(mFont, mFontSize);

		Vector2s32	cursor;

		cursor.x = 0;
		cursor.y = /*cast(int)font.linegap*/ mFontSize;

		foreach (dchar charCode; mText)
		{
			Tuple!(Glyph, bool)	glyphTuple;
			Glyph				glyph;
			bool				alreadyLoaded;

			glyphTuple = font.loadGlyph(charCode);
			glyph = glyphTuple[0];
			alreadyLoaded = glyphTuple[1];

			if (!alreadyLoaded)
			{
				// Allocate image if need
				while (glyph.atlasIndex >= images.length)
				{
					images ~= new Image;
					images[$ - 1].create(format("ImageAtlas-%d", images.length),
										 fontManager.getAtlas(images.length - 1).size().x,
										 fontManager.getAtlas(images.length - 1).size().y,
										 4);
					images[$ - 1].fill(Color(1.0f, 1.0f, 1.0f, 0.0f), Vector2s32(0, 0), images[$ - 1].size());
				}

				// Write glyph in image
				images[glyph.atlasIndex].blit(glyph.image,
											  Vector2s32(0, 0),
											  Vector2s32(glyph.atlasRegion.width, glyph.atlasRegion.height),
											  Vector2s32(glyph.atlasRegion.x, glyph.atlasRegion.y));
			}

			Vector2s32	pos;

			pos.x = glyph.offset.x;
			pos.y = -glyph.offset.y;
/*			textImage.blit(glyph.image,
						   Vector2s32(0, 0),
						   Vector2s32(glyph.atlasRegion.width, glyph.atlasRegion.height),
						   Vector2s32(cursor.x + pos.x, cursor.y + pos.y));*/
			cursor.x = cursor.x + glyph.advance.x;
		}
	}

	Mesh		mMesh;
	string		mText;
	string		mFont;
	int			mFontSize;
	FontFamily	mFontFamily;
}
