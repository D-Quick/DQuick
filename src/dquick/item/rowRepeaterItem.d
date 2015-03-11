module dquick.item.rowRepeaterItem;

public import dquick.item.graphicItem;
public import std.signals;
import dquick.script.itemBinding;
import std.stdio;
import std.math;
import dquick.script.dmlEngine;

class RowRepeaterItem : GraphicItem, dquick.script.iItemBinding.IItemBinding
{
	mixin(dquick.script.itemBinding.I_ITEM_BINDING);

public:
	this(DeclarativeItem parent = null)
	{
		super(parent);
		idProperty = new typeof(idProperty)(this, this);
		modelProperty = new typeof(modelProperty)(this, this);
		itemDelegateProperty = new typeof(itemDelegateProperty)(this, this);
	}

	// ID
	dquick.script.nativePropertyBinding.NativePropertyBinding!(string, RowRepeaterItem, "id")	idProperty;
	override string	id() { return DeclarativeItem.id(); }
	override void	id(string value) { return DeclarativeItem.id(value); }

	// Model
	dquick.script.nativePropertyBinding.NativePropertyBinding!(LuaValue, RowRepeaterItem, "model")	modelProperty;
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
	dquick.script.delegatePropertyBinding.DelegatePropertyBinding!(GraphicItem delegate(), RowRepeaterItem, "itemDelegate")	itemDelegateProperty;
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

protected:
	Object[]	modelItems;
}
