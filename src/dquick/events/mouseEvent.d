module dquick.events.mouse_event;

public import dquick.maths.vector2s32;

struct MouseEvent
{
public:
	enum	Buttons
	{
		Any			= 0x00,
		Left		= 0x01,
		Right		= 0x02,
		Middle		= 0x04,
		X1			= 0x08,
		X2			= 0x10,
	}

	bool		moved = false;			// If true position is valid
	Vector2s32	position;
	bool		pressed = false;		// If true buttons is valid
	bool		released = false;		// If true buttons is valid
	Buttons		buttons = Buttons.Any;
}
