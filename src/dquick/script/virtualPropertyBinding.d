module dquick.script.virtual_property_binding;

import std.variant;
import std.conv;
import std.file, std.stdio;
import std.string;
import std.array;

import derelict.lua.lua;

import dquick.script.propertyBinding;
import dquick.script.iItemBinding;

class VirtualPropertyBinding : PropertyBinding
{
	Variant	value;

	this(IItemBinding itemBinding, string propertyName)
	{
		super(itemBinding, propertyName);
	}

	override void	valueFromLua(lua_State* L, int index, bool popFromStack = false)
	{
		value = dquick.script.utils.valueFromLua!Variant(L, index);
		if (popFromStack)
			lua_remove(L, index);
		onChanged();
	}

	override void	valueToLua(lua_State* L)
	{
		super.valueToLua(L);
		dquick.script.utils.valueToLua!Variant(L, value);
	}
}
