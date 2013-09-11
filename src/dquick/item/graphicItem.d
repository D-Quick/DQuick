module dquick.item.graphic_item;

public import dquick.item.declarative_item;
public import dquick.maths.vector2f32;
public import dquick.maths.transformation;

public import dquick.renderer_3d.opengl.renderer;

public import std.signals;
import std.stdio;

// TODO Verifier la gestion des matrices, j'ai un doute sur la bonne application/restoration des transformation (Je crains que la matrice de la camera soit ecrasee)

/// Interface for items that can be renderer or have some geometrical properties
class GraphicItem : DeclarativeItem
{
public:
	this()
	{
		mSize = Vector2f32(0, 0);
		mTransformationUpdated = true;
	}

	// TODO add implicitWidth and implicitHeight? http://qt-project.org/doc/qt-5.0/qtquick/qquickitem.html#implicitHeight-prop

	/// Have to be called only on rootItem by window
	void	setSize(Vector2f32 size)
	{
		if (size == mSize)
			return;
		mSize = size;
		mTransformation.origin.x = mSize.x / 2.0f;
		mTransformation.origin.y = mSize.y / 2.0f;
		mTransformationUpdated = true;
		onWidthChanged.emit(mSize.x);
		onHeightChanged.emit(mSize.y);
	}

	@property void	width(float width)
	{
		if (width == mSize.x)
			return;
		mSize.x = width;
		mTransformation.origin.x = mSize.x / 2.0f;
		mTransformationUpdated = true;
		onWidthChanged.emit(width);
	}
	@property float	width() {return mSize.x;}
	mixin Signal!(float) onWidthChanged;

	@property void	height(float height)
	{
		if (height == mSize.y)
			return;
		mSize.y = height;
		mTransformation.origin.y = mSize.y / 2.0f;
		mTransformationUpdated = true;
		onHeightChanged.emit(height);
	}
	@property float	height() {return mSize.y;}
	mixin Signal!(float) onHeightChanged;

	@property void	x(float x)
	{
		if (x == mTransformation.position.x)
			return;
		mTransformation.position.x = x;
		mTransformationUpdated = true;
		onXChanged.emit(x);
	}
	@property float	x() {return mTransformation.position.x;}
	mixin Signal!(float) onXChanged;

	@property void	y(float y)
	{
		if (y == mTransformation.position.y)
			return;
		mTransformation.position.y = y;
		mTransformationUpdated = true;
		onYChanged.emit(y);
	}
	@property float	y() {return mTransformation.position.y;}
	mixin Signal!(float) onYChanged;

	/// Change the scale factor, tranformation origin is the center of item
	@property void	scale(float value)
	{
		if (value == mTransformation.scaling.y)
			return;
		mTransformation.scaling.x = value;
		mTransformation.scaling.y = value;
		mTransformationUpdated = true;
		onScaleChanged.emit(value);
	}
	@property float	scale() {return mTransformation.scaling.x;}
	mixin Signal!(float) onScaleChanged;

	/// Change the orientation angle in degrees clockwise, tranformation origin is the center of item
	@property void	orientation(float value)
	{
		if (mOrientation == value)
			return;
		mOrientation = value;
		mTransformationUpdated = true;
		mTransformation.orientation = Quaternion.zrotation((value % 360.0) / 180 * std.math.PI);
		onOrientationChanged.emit(value);
	}
	@property float	orientation() {return mOrientation;}
	mixin Signal!(float) onOrientationChanged;

	override
	void	paint(bool transformationUpdated)
	{
		startPaint(transformationUpdated);
		paintChildren();
		endPaint();
	}

protected:
	void	startPaint(bool transformationUpdated)
	{
		if (transformationUpdated)
			mTransformationUpdated = true;
		
		if (mTransformationUpdated)
		{
			if (parent())
				mMatrix = parent().matrix() * mTransformation.toMatrix();
			else
				mMatrix = mTransformation.toMatrix();
		}

		Renderer.currentMDVMatrix(switchMatrixRowsColumns(Renderer.currentCamera * mMatrix));
	}

	void	endPaint()
	{
		mTransformationUpdated = false;
	}

	bool	isIn(Vector2f32 point)
	{
		assert(false);
		version(release)
		return false;
	}

	Transformation	mTransformation;
	Vector2f32		mSize;
	float			mOrientation = 0.0f;
}
