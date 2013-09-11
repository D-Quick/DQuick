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

	this(Vector2s32 position, Buttons buttons)
	{
		mPosition = position;
		mButtons = buttons;
	}

	@property void			buttons(Buttons buttons) {mButtons = buttons;}
	@property Buttons		buttons() {return mButtons;}

	@property void			position(Vector2s32 position) {mPosition = position;}
	@property Vector2s32	position() {return mPosition;}	/// Relative to the window

private:
	Buttons		mButtons = Buttons.Any;
	Vector2s32	mPosition;
}
