module dquick.events.mouseEvent;

public import dquick.maths.vector2s32;

struct MouseEvent
{
public:
	enum	Type
	{
		Motion,
		Entered,
		Left,
		ButtonPressed,
		ButtonReleased
	}

	enum	Buttons
	{
		None		= 0x00,
		Left		= 0x01,
		Right		= 0x02,
		Middle		= 0x04,
		X1			= 0x08,
		X2			= 0x10,
	}

	Type		type;
	Vector2s32	position;
	Buttons		buttons = Buttons.None; // buttons causing this event.
}
