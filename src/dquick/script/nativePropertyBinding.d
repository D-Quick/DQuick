module dquick.script.native_property_binding;

import std.stdio;
import std.conv;
import std.string;
import std.array;

import derelict.lua.lua;

import dquick.script.property_binding;
import dquick.script.i_item_binding;
import dquick.script.item_binding;
import dquick.script.utils;

class NativePropertyBinding(T, ItemType, string PropertyName) : PropertyBinding
{
	this(IItemBinding itemBinding)
	{
		super(itemBinding, PropertyName);
	}

	void	onChanged(T t)
	{
		super.onChanged();
	}

	override void	valueFromLua(lua_State* L, int index, bool popFromStack = false)
	{
		T	value = dquick.script.utils.valueFromLua!T(L, index);
		if (popFromStack)
			lua_remove(L, index);
		static if (__traits(compiles, __traits(getMember, cast(ItemType)(itemBinding.declarativeItem), PropertyName)(value)))
			__traits(getMember, cast(ItemType)(itemBinding.declarativeItem), PropertyName)(value);
		else
			throw new Exception(format("Property \"%s\" is not writeable\n", PropertyName));			
	}

	override void	valueToLua(lua_State* L)
	{
		super.valueToLua(L);
		static if (is(T : dquick.item.declarative_item.DeclarativeItem))
		{

		}

		dquick.script.utils.valueToLua!T(L, __traits(getMember, cast(ItemType)(itemBinding.declarativeItem), PropertyName)());
	}

	template	type()
	{
		alias T	type;
	}
}
