module dquick.item.scroll_view_item;

import dquick.item.mouse_area_item;
import dquick.item.graphic_item;

import dquick.maths.vector2f32;

import std.stdio;

// TODO update position of item when his size change
// TODO cursor out of item/window == mouse released event

class ScrollViewItem : MouseAreaItem
{
public:
	this()
	{
		onPressedChanged.connect(&onPressed);
		onMouseXChanged.connect(&onMouseX);
		onMouseYChanged.connect(&onMouseY);
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
		if (mChildren.length > 0)
		{
			GraphicItem	child = cast(GraphicItem)mChildren[0];

			if (child)
			{
				Vector2f32	pos;
				Vector2f32	size;

				if (child.implicitWidth != float.nan && child.implicitHeight != float.nan)	// Normally always both have to be defined at the same time
					size = Vector2f32(child.implicitWidth, child.implicitHeight);
				else
					size = Vector2f32(child.width, child.height);

				pos = mMousePosition - mMouseStart + mStartingPosition;

				if (pos.x < width - size.x)
					pos.x  = width - size.x;
				if (pos.x > 0.0f)
					pos.x = 0.0f;
				if (pos.y < height - size.y)
					pos.y = height - size.y;
				if (pos.y > 0.0f)
					pos.y = 0.0f;

				child.x = pos.x;
				child.y = pos.y;
			}
		}
	}

	Vector2f32	mMouseStart;
	Vector2f32	mStartingPosition;
}
