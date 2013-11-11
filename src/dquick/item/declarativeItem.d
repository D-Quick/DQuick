module dquick.item.declarativeItem;

public import dquick.events.mouseEvent;

public import dquick.maths.matrix4x4;

import std.stdio;

// TODO take a look to http://doc.qt.digia.com/qt-maemo/qml-item.html
// TODO bind it

// http://qt-project.org/doc/qt-4.8/qgraphicsitem.html#sorting

class DeclarativeItem
{
public:
	@property void		id(string id) {mId = id;}
	@property string	id() {return mId;}

	@property void				parent(DeclarativeItem parent) {mParent = parent;}
	@property DeclarativeItem	parent() {return mParent;}

	void	addChild(DeclarativeItem item)
	{
		mChildren ~= item;
		item.parent = this;
	}

	void	paint(bool transformationUpdated)
	{
		paintChildren();
	}

	void	mouseEvent(ref MouseEvent event)
	{
/*		writeln(event.type);
		if (event.type == MouseEvent.Type.Pressed || event.type == MouseEvent.Type.Released)
			writeln(event.buttons);
		if (event.type == MouseEvent.Type.Move)
			writeln(event.position);
*/
		for (auto i = 0; i < mChildren.length; i++)
			mChildren[i].mouseEvent(event);
	}

	Matrix4x4	matrix()
	{
		return mMatrix;
	}
	
protected:
	void	paintChildren()
	{
		for (auto i = 0; i < mChildren.length; i++)
			mChildren[i].paint(mTransformationUpdated);
	}

	string				mId;
	DeclarativeItem[]	mChildren;
	DeclarativeItem		mParent;
	bool				mTransformationUpdated = false;
	Matrix4x4			mMatrix = switchMatrixRowsColumns(Matrix4x4.identity());
}
