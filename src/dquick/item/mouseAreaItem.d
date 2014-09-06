module dquick.item.mouseAreaItem;

import dquick.item.graphicItem;
import dquick.maths.vector2s32;
import dquick.maths.vector3f32;
import dquick.maths.vector4f32;
import dquick.script.itemBinding;

import std.string;
import std.signals;
import std.stdio;

import std.stdio;

class MouseAreaItem : GraphicItem
{
	mixin(dquick.script.itemBinding.I_ITEM_BINDING);
public:
	alias MouseEvent.Buttons	Buttons;
	
	this(DeclarativeItem parent = null)
	{
		super(parent);
		containsMouseProperty = new typeof(containsMouseProperty)(this, this);
		enableProperty = new typeof(enableProperty)(this, this);
		mouseXProperty = new typeof(mouseXProperty)(this, this);
		mouseYProperty = new typeof(mouseYProperty)(this, this);
		windowMouseXProperty = new typeof(windowMouseXProperty)(this, this);
		windowMouseYProperty = new typeof(windowMouseYProperty)(this, this);
		pressedProperty = new typeof(pressedProperty)(this, this);
		pressedButtonsProperty = new typeof(pressedButtonsProperty)(this, this);
		preventStealingProperty = new typeof(preventStealingProperty)(this, this);
		propagateComposedEventsProperty = new typeof(propagateComposedEventsProperty)(this, this);
		debug
		{
			debugMeshColor(Color(0 / 255, 128 / 255, 255 / 255, 1.0f));
		}
	}

	// containsMouse
	dquick.script.nativePropertyBinding.NativePropertyBinding!(bool, MouseAreaItem, "containsMouse")	containsMouseProperty;
	bool					containsMouse() {return mContainsMouse;}
	mixin Signal!(bool)		onContainsMouseChanged;

	// enable
	dquick.script.nativePropertyBinding.NativePropertyBinding!(bool, MouseAreaItem, "enable")	enableProperty;
	void					enable(bool flag) {mEnable = flag; onEnableChanged.emit(mEnable);}
	bool					enable() {return mEnable;}
	mixin Signal!(bool)		onEnableChanged;

	// mouseX
	dquick.script.nativePropertyBinding.NativePropertyBinding!(float, MouseAreaItem, "mouseX")	mouseXProperty;
	float					mouseX() {return mMousePosition.x;}
	mixin Signal!(float)	onMouseXChanged;

	// mouseY
	dquick.script.nativePropertyBinding.NativePropertyBinding!(float, MouseAreaItem, "mouseY")	mouseYProperty;
	float					mouseY() {return mMousePosition.y;}
	mixin Signal!(float)	onMouseYChanged;

	// windowMouseX
	dquick.script.nativePropertyBinding.NativePropertyBinding!(float, MouseAreaItem, "windowMouseX")	windowMouseXProperty;
	float					windowMouseX() {return mWindowMousePosition.x;}
	mixin Signal!(float)	onWindowMouseXChanged;

	// windowMouseY
	dquick.script.nativePropertyBinding.NativePropertyBinding!(float, MouseAreaItem, "windowMouseY")	windowMouseYProperty;
	float					windowMouseY() {return mWindowMousePosition.y;}
	mixin Signal!(float)	onWindowMouseYChanged;

	// pressed
	dquick.script.nativePropertyBinding.NativePropertyBinding!(bool, MouseAreaItem, "pressed")	pressedProperty;
	bool					pressed() {return computePressedStatus();}	// Convience method that return true if Left button is pressed
	mixin Signal!(bool)		onPressedChanged;

	// pressedButtons
	dquick.script.nativePropertyBinding.NativePropertyBinding!(Buttons, MouseAreaItem, "pressedButtons")	pressedButtonsProperty;
	Buttons					pressedButtons() {return mPressedButtons;}
	mixin Signal!(Buttons)	onPressedButtonsChanged;

	// preventStealing
	dquick.script.nativePropertyBinding.NativePropertyBinding!(bool, MouseAreaItem, "preventStealing")	preventStealingProperty;
	void					preventStealing(bool flag) {mPreventStealing = flag; onPreventStealingChanged.emit(mPreventStealing);}
	bool					preventStealing() {return mPreventStealing;}
	mixin Signal!(bool)		onPreventStealingChanged;

	// propagateComposedEvents
	dquick.script.nativePropertyBinding.NativePropertyBinding!(bool, MouseAreaItem, "propagateComposedEvents")	propagateComposedEventsProperty;
	void					propagateComposedEvents(bool flag) {mPropagateComposedEvents = flag; onPropagateComposedEventsChanged.emit(mPropagateComposedEvents);}
	bool					propagateComposedEvents() {return mPropagateComposedEvents;}
	mixin Signal!(bool)		onPropagateComposedEventsChanged;

	override
	void	mouseEvent(ref MouseEvent event)
	{
		if (enable)
		{
			assert(mTransformationUpdated == false);

			// Backup previous status
			bool		previousContainsMouse = mContainsMouse;
			bool		previousPressed = computePressedStatus();
			Vector2f32	previousMousePosition = mMousePosition;
			Vector2s32	previousWindowMousePosition = mWindowMousePosition;
			Buttons		previousPressedButtons = mPressedButtons;
			// --

			Vector3f32	transformedPoint;
			
			if (event.type == MouseEvent.Type.Motion)
				mWindowMousePosition = event.position;

			if (event.type == MouseEvent.Type.ButtonPressed)
				mPressedButtons |= event.buttons;
			if (event.type == MouseEvent.Type.ButtonReleased)
				mPressedButtons = mPressedButtons & (event.buttons ^ cast(Buttons)(-1));

			transformedPoint = Vector3f32(mMatrix.inverse() * Vector4f32(Vector3f32(mWindowMousePosition.x, mWindowMousePosition.y, 0)));
			mMousePosition = Vector2f32(transformedPoint.x, transformedPoint.y);
			mContainsMouse = isIn(transformedPoint);

			// Emit signals (after updates of all members to avoid deprecated values usage in slots)
			if (mWindowMousePosition.x != previousWindowMousePosition.x)
				onWindowMouseXChanged.emit(mWindowMousePosition.x);
			if (mWindowMousePosition.y != previousWindowMousePosition.y)
				onWindowMouseYChanged.emit(mWindowMousePosition.y);

			if (mMousePosition.x != previousMousePosition.x)
				onMouseXChanged.emit(mMousePosition.x);
			if (mMousePosition.y != previousMousePosition.y)
				onMouseYChanged.emit(mMousePosition.y);

			if (mContainsMouse != previousContainsMouse)
				onContainsMouseChanged.emit(mContainsMouse);

			if (mPressedButtons != previousPressedButtons)
				onPressedButtonsChanged.emit(mPressedButtons);

			bool	pressed = computePressedStatus();
			if (pressed != previousPressed)
				onPressedChanged.emit(pressed);
			// --
		}
		GraphicItem.mouseEvent(event);
	}

protected:
	bool	isIn(Vector3f32 transformedPoint)
	{
		return (transformedPoint.x >= 0.0f && transformedPoint.x < width &&
		        transformedPoint.y >= 0.0f && transformedPoint.y < height);
	}

	bool	computePressedStatus()
	{
		return (mPressedButtons != Buttons.None) && mContainsMouse;
	}

	bool		mEnable = true;
	bool		mContainsMouse = false;
	bool		mPreventStealing = false;
	bool		mPropagateComposedEvents = false;

	Vector2f32	mMousePosition = Vector2f32(0.0f, 0.0f);
	Vector2s32	mWindowMousePosition = Vector2s32(0, 0);
	Buttons		mPressedButtons = Buttons.None;
}
