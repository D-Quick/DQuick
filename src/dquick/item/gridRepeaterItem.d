module dquick.item.gridRepeaterItem;

public import dquick.item.graphicItem;
public import std.signals;
import dquick.script.itemBinding;
import std.stdio;
import std.math;
import dquick.script.dmlEngine;

class GridRepeaterItem : GraphicItem, dquick.script.iItemBinding.IItemBinding
{
	mixin(dquick.script.itemBinding.I_ITEM_BINDING);

public:
	this(DeclarativeItem parent = null)
	{
		super(parent);

		mColumns = 4;
		mSpacing = 0.0f;

		idProperty = new typeof(idProperty)(this, this);
		columnsProperty = new typeof(columnsProperty)(this, this);
		columnSizesProperty = new typeof(columnSizesProperty)(this, this);
		rowSizesProperty = new typeof(rowSizesProperty)(this, this);
		modelProperty = new typeof(modelProperty)(this, this);
		itemDelegateProperty = new typeof(itemDelegateProperty)(this, this);
		spacingProperty = new typeof(spacingProperty)(this, this);
	}

	// ID
	dquick.script.nativePropertyBinding.NativePropertyBinding!(string, GridRepeaterItem, "id")	idProperty;
	override string	id() { return DeclarativeItem.id(); }
	override void	id(string value) { return DeclarativeItem.id(value); }

	// columns
	dquick.script.nativePropertyBinding.NativePropertyBinding!(uint, GridRepeaterItem, "columns")	columnsProperty;
	void	columns(uint columns)
	{
		mColumns = columns;
		onColumnsChanged.emit(columns);
	}
	uint	columns() {return mColumns;}
	mixin Signal!(uint) onColumnsChanged;
	uint	mColumns;

	// columnSizes
	dquick.script.nativePropertyBinding.NativePropertyBinding!(float[], GridRepeaterItem, "columnSizes")	columnSizesProperty;
	float[]		columnSizesBinding()
	{
		DeclarativeItem[]	children = childrenProperty.value;
		GraphicItem[]	graphicChildren;
		foreach (DeclarativeItem child; children)
		{
			GraphicItem	graphicChild = cast(GraphicItem)(child);
			if (graphicChild)
				graphicChildren ~= graphicChild;
		}

		uint	columns = columnsProperty.value;
		float[]	columnSizes;
		columnSizes.length = columns;
		for (uint colIndex = 0; colIndex < columns; colIndex++)
		{
			columnSizes[colIndex] = 0.0f;
			for (uint index = colIndex; index < graphicChildren.length; index += columns)
			{
				if (graphicChildren[index].widthProperty.value > columnSizes[colIndex])
					columnSizes[colIndex] = graphicChildren[index].widthProperty.value;
			}
		}
		return columnSizes;
	}
	void	columnSizes(float[] value)
	{
		if (mColumnSizes != value)
		{
			mColumnSizes = value;
			doPositioning();
			onColumnSizesChanged.emit(value);
		}
	}	
	float[]	columnSizes() {return mColumnSizes;}
	mixin Signal!(float[]) onColumnSizesChanged;
	float[]	mColumnSizes;

	// rowSizes
	dquick.script.nativePropertyBinding.NativePropertyBinding!(float[], GridRepeaterItem, "rowSizes")	rowSizesProperty;
	float[]		rowSizesBinding()
	{
		DeclarativeItem[]	children = childrenProperty.value;
		GraphicItem[]	graphicChildren;
		foreach (DeclarativeItem child; children)
		{
			GraphicItem	graphicChild = cast(GraphicItem)(child);
			if (graphicChild)
				graphicChildren ~= graphicChild;
		}

		uint	columns = columnsProperty.value;
		uint	rows = (graphicChildren.length + (columns - 1)) / columns;
		float[]	rowSizes;
		rowSizes.length = rows;
		for (uint rowIndex = 0; rowIndex < rows; rowIndex++)
		{
			rowSizes[rowIndex] = 0.0f;
			for (uint index = rowIndex * columns; index < graphicChildren.length; index += 1)
			{
				if (graphicChildren[index].heightProperty.value > rowSizes[rowIndex])
					rowSizes[rowIndex] = graphicChildren[index].heightProperty.value;
			}
		}
		return rowSizes;
	}
	void	rowSizes(float[] value)
	{
		if (mRowSizes != value)
		{
			mRowSizes = value;
			doPositioning();
			onRowSizesChanged.emit(value);
		}
	}	
	float[]	rowSizes() {return mRowSizes;}
	mixin Signal!(float[]) onRowSizesChanged;
	float[]	mRowSizes;

	// Model
	dquick.script.nativePropertyBinding.NativePropertyBinding!(LuaValue, GridRepeaterItem, "model")	modelProperty;
	void	model(LuaValue value)
	{
		if (mModel != value)
		{
			if (mModel.valueRef != -1)
				luaL_unref(dmlEngine.luaState, LUA_REGISTRYINDEX, mModel.valueRef);

			mModel = value;

			// Get model userdata on the stack with the ref
			lua_rawgeti(dmlEngine.luaState, LUA_REGISTRYINDEX, mModel.valueRef);

			// Get items list
			// (used to get pointers and identify model items to keep the view stable when item are inserted before the current scrolling)
			auto oldModelItems = modelItems;
			dquick.script.utils.valueFromLua(dmlEngine.luaState, -1, modelItems);

			// Regenerate children
			auto childrenCopy = children;
			foreach (DeclarativeItem child; childrenCopy)
				removeChild(child);

			{ // For the scope(exit)
				dmlEngine.beginTransaction();
				scope(exit) dmlEngine.endTransaction();

				foreach (int i, Object modelItem; modelItems)
				{
					// Call the user delegate that create a child from a model object
					GraphicItem	child = itemDelegate()();

					// Get model item and set it as "model" property to child
					lua_pushinteger(dmlEngine.luaState, i + 1); // Push model table index
					lua_gettable(dmlEngine.luaState, -2); // Index the model table
					if (lua_isuserdata(dmlEngine.luaState, -1) == false)
						throw new Exception(format("Lua value at key %d is a %s, a userdata was expected", i + 1, getLuaTypeName(dmlEngine.luaState, -1)));
					lua_pushstring(dmlEngine.luaState, "model"); // Push key
					lua_insert(dmlEngine.luaState, -2); // Move key before value

					child.valueFromLua(dmlEngine.luaState); // Set it as property
					lua_pop(dmlEngine.luaState, 2);

					addChild(child);
				}

				// Pop the userdata model
				lua_pop(dmlEngine.luaState, 1);
			}

			onModelChanged.emit(value);
		}
	}
	LuaValue		model()
	{
		return mModel;
	}
	mixin Signal!(LuaValue) onModelChanged;
	LuaValue		mModel;

	// Delegate
	dquick.script.delegatePropertyBinding.DelegatePropertyBinding!(GraphicItem delegate(), GridRepeaterItem, "itemDelegate")	itemDelegateProperty;
	void	itemDelegate(GraphicItem delegate() value)
	{
		if (mItemDelegate != value)
		{
			mItemDelegate = value;
			onItemDelegateChanged.emit(value);
		}
	}
	GraphicItem delegate()		itemDelegate()
	{
		return mItemDelegate;
	}
	mixin Signal!(GraphicItem delegate()) onItemDelegateChanged;
	GraphicItem delegate() mItemDelegate;

	/*void	addChild(dquick.script.itemBinding.ItemBinding!(GraphicItem))
	{

	}*/

	// implicitWidth
	override float	implicitWidthBinding()
	{
		auto columnSizes = columnSizesProperty.value;
		auto spacing = spacingProperty.value;
		float	implicitWidth = 0.0f;
		foreach (columnSize; columnSizes)
			implicitWidth += columnSize + spacing;
		implicitWidth -= spacing;
		return implicitWidth;
	}
	override void	implicitWidth(float value)
	{
		if (mImplicitWidth != value)
		{
			mImplicitWidth = value;
			onImplicitWidthChanged.emit(value);
		}
	}
	override float	implicitWidth()
	{
		return mImplicitWidth;
	}
	float	mImplicitWidth;

	// implicitHeight
	override float	implicitHeightBinding()
	{
		auto rowSizes = rowSizesProperty.value;
		auto spacing = spacingProperty.value;
		float	implicitHeight = 0.0f;
		foreach (rowSize; rowSizes)
			implicitHeight += rowSize + spacing;
		implicitHeight -= spacing;
		return implicitHeight;
	}
	override void	implicitHeight(float value)
	{
		if (mImplicitHeight != value)
		{
			mImplicitHeight = value;
			onImplicitHeightChanged.emit(value);
		}
	}
	override float	implicitHeight()
	{
		return mImplicitHeight;
	}
	float	mImplicitHeight;

	// spacing
	dquick.script.nativePropertyBinding.NativePropertyBinding!(float, GridRepeaterItem, "spacing")	spacingProperty;
	void	spacing(float value)
	{
		mSpacing = value;
		doPositioning();
		onSpacingChanged.emit(mSpacing);
	}
	float	spacing() {return mSpacing;}
	mixin Signal!(float) onSpacingChanged;
	float	mSpacing;

protected:
	void	doPositioning()
	{
		DeclarativeItem[]	children = childrenProperty.value;
		GraphicItem[]	graphicChildren;
		foreach (DeclarativeItem child; children)
		{
			GraphicItem	graphicChild = cast(GraphicItem)(child);
			if (graphicChild)
				graphicChildren ~= graphicChild;
		}

		float	colX = 0.0f;
		for (uint colIndex = 0; colIndex < columnSizes.length; colIndex++)
		{
			for (uint index = colIndex; index < graphicChildren.length; index += columns)
				graphicChildren[index].x = colX;
			colX += columnSizes[colIndex] + mSpacing;
		}

		float	rowY = 0.0f;
		for (uint rowIndex = 0; rowIndex < rowSizes.length; rowIndex++)
		{
			for (uint index = rowIndex * columns; index < graphicChildren.length; index += 1)
				graphicChildren[index].y = rowY;
			rowY += rowSizes[rowIndex] + mSpacing;
		}
	}


	Object[]	modelItems;
}

unittest
{
	DMLEngineCore	dmlEngine = new DMLEngineCore;
	dmlEngine.create();
	dmlEngine.addObjectBindingType!(DeclarativeItem, "Item");
	dmlEngine.addObjectBindingType!(GraphicItem, "GraphicItem");
	dmlEngine.addObjectBindingType!(GridRepeaterItem, "GridRepeater");

	{
		string lua = q"(
			GridRepeater {
				id = "gridRepeater1",
				--Item {
				--},
				model = function()
					return {
						Item {
							width = 10
						},
						Item {
							width = 20
						},
						Item {
							width = 30
						},
					}
				end,
				itemDelegate = function()
					return GraphicItem {
						width = function()
							return model.width
						end,
						height = 20
					}
				end,
				columns = 2,
				spacing = 6
			}
		)";
		dmlEngine.execute(lua, "");
		assert(dmlEngine.getLuaGlobal!GraphicItem("gridRepeater1").children.length == 3);
		//assert(cast(DeclarativeItem)dmlEngine.getLuaGlobal!GraphicItem("gridRepeater1").children[0]);
		assert((cast(GraphicItem)dmlEngine.getLuaGlobal!GraphicItem("gridRepeater1").children[0]).x == 0);
		assert((cast(GraphicItem)dmlEngine.getLuaGlobal!GraphicItem("gridRepeater1").children[1]).x == 36);
		assert((cast(GraphicItem)dmlEngine.getLuaGlobal!GraphicItem("gridRepeater1").children[2]).x == 0);
	}
}