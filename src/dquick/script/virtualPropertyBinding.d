module dquick.script.virtualPropertyBinding;

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
		Variant	newValue;
		dquick.script.utils.valueFromLua!Variant(L, index, newValue);
		if (popFromStack)
			lua_remove(L, index);
		if (newValue != value)
		{
			value = newValue;
			onChanged();
		}
	}

	override void	valueToLua(lua_State* L)
	{
		super.valueToLua(L);
		dquick.script.utils.valueToLua!Variant(L, value);
	}
}
