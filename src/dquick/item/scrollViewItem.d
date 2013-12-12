module dquick.item.scrollViewItem;

import dquick.item.declarativeItem;
import dquick.item.mouseAreaItem;
import dquick.item.graphicItem;

import dquick.maths.vector2f32;

import std.stdio;

// TODO update position of item when his size change
// TODO cursor out of item/window == mouse released event

class ScrollViewItem : MouseAreaItem
{
public:
	this(DeclarativeItem parent = null)
	{
		super(parent);
		onMouseXChanged.connect(&onMouseX);
		onMouseYChanged.connect(&onMouseY);
		onPressedChanged.connect(&onPressed);
		debug
		{
			debugMeshColor(Color(128 / 255, 0 / 255, 0 / 255, 1.0f));
		}
	}

	override
	{
		void	addChild(DeclarativeItem item)
		{
			GraphicItem	child;

			// We connect only the first child
			if (mChildren.length)
			{
				child = cast(GraphicItem)mChildren[0];
				if (child)
				{
					child.onWidthChanged.disconnect(&fixChildPosition);
					child.onHeightChanged.disconnect(&fixChildPosition);
					child.onImplicitWidthChanged.disconnect(&fixChildPosition);
					child.onImplicitHeightChanged.disconnect(&fixChildPosition);
				}
			}
			MouseAreaItem.addChild(item);
			child = cast(GraphicItem)mChildren[0];
			if (child)
			{
				child.onWidthChanged.connect(&fixChildPosition);
				child.onHeightChanged.connect(&fixChildPosition);
				child.onImplicitWidthChanged.connect(&fixChildPosition);
				child.onImplicitHeightChanged.connect(&fixChildPosition);
			}
		}

		@property void	width(float width)
		{
			MouseAreaItem.width(width);
			fixChildPosition(0.0f);
		}
		@property float	width() {return MouseAreaItem.width();}

		@property void	height(float height)
		{
			MouseAreaItem.height(height);
			fixChildPosition(0.0f);
		}
		@property float	height() {return MouseAreaItem.height();}
	}

protected:
	void	onPressed(bool pressed)
	{
		if (pressed && mChildren.length > 0)
		{
			GraphicItem	child = cast(GraphicItem)mChildren[0];

			if (child)
			{
				mMouseStart = mMousePosition;
				mStartingPosition = Vector2f32(child.x, child.y);
			}
		}
	}

	void	onMouseX(float x)
	{
		if (pressed)
			drag();
	}

	void	onMouseY(float y)
	{
		if (pressed)
			drag();
	}

	void	drag()
	{
		mPosition = mMousePosition - mMouseStart + mStartingPosition;

		fixChildPosition(0.0f);
	}

	/// parameter is unused (it's only to be able to connect signals directly on it)
	void	fixChildPosition(float)
	{
		if (mChildren.length > 0)
		{
			GraphicItem	child = cast(GraphicItem)mChildren[0];

			if (child)
			{
				Vector2f32	size;

				if (child.implicitWidth != float.nan && child.implicitHeight != float.nan)	// Normally always both have to be defined at the same time
					size = Vector2f32(child.implicitWidth, child.implicitHeight);
				else
					size = Vector2f32(child.width, child.height);

				if (mPosition.x < width - size.x)
					mPosition.x  = width - size.x;
				if (mPosition.x > 0.0f)
					mPosition.x = 0.0f;
				if (mPosition.y < height - size.y)
					mPosition.y = height - size.y;
				if (mPosition.y > 0.0f)
					mPosition.y = 0.0f;

				child.x = mPosition.x;
				child.y = mPosition.y;
			}
		}
	}

	Vector2f32	mMouseStart;
	Vector2f32	mStartingPosition;
	Vector2f32	mPosition = Vector2f32(0.0f, 0.0f);
}
