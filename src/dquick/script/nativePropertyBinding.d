module dquick.script.native_property_binding;

import std.stdio;
import std.conv;
import std.string;
import std.array;

import derelict.lua.lua;

import dquick.script.propertyBinding;
import dquick.script.iItemBinding;
import dquick.script.item_binding;
import dquick.script.utils;

class NativePropertyBinding(ValueType, ItemType, string PropertyName) : PropertyBinding
{
	ItemType	item;
	this(IItemBinding itemBinding, ItemType item)
	{
		this.item = item;
		super(itemBinding, PropertyName);
	}

	void	onChanged(ValueType t)
	{
		super.onChanged();
	}

	override void	valueFromLua(lua_State* L, int index, bool popFromStack = false)
	{
		ValueType	value = dquick.script.utils.valueFromLua!ValueType(L, index);
		if (popFromStack)
			lua_remove(L, index);
		static if (__traits(compiles, __traits(getMember, cast(ItemType)(itemBinding.declarativeItem), PropertyName)(value)))
			__traits(getMember, item, PropertyName)(value);
		else
			throw new Exception(format("Property \"%s\" is not writeable\n", PropertyName));
	}

	override void	valueToLua(lua_State* L)
	{
		super.valueToLua(L);
		ValueType	value = __traits(getMember, cast(ItemType)(item), PropertyName);
		dquick.script.utils.valueToLua!ValueType(L, value);
	}

	template	type()
	{
		alias T	type;
	}
}
