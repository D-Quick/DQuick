module dquick.script.virtual_property_binding;

import std.variant;
import std.conv;
import std.file, std.stdio;
import std.string;
import std.array;

import derelict.lua.lua;

import dquick.script.property_binding;
import dquick.script.i_item_binding;

class VirtualPropertyBinding : PropertyBinding
{
	Variant	value;

	this(IItemBinding itemBinding, string propertyName)
	{
		super(itemBinding, propertyName);
	}

	override void	valueFromLua(lua_State* L, int index, bool popFromStack = false)
	{
		if (lua_isnumber(L, index))
			value = lua_tonumber(L, index);
		else if (lua_isstring(L, index))
			value = to!(string)(lua_tostring(L, index));
		else
			writefln("VirtualPropertyBinding.valueFromLua: param %d is not a number nor a string\n", index);
		if (popFromStack)
			lua_remove(L, index);
		onChanged();
	}

	override void	valueToLua(lua_State* L)
	{
		super.valueToLua(L);
		if (value.type == typeid(double))
			lua_pushnumber(L, value.get!double);
		else if (value.type == typeid(int))
			lua_pushnumber(L, value.get!double);
		else if (value.type == typeid(string))
			lua_pushstring(L, value.get!(string).dup.toStringz());
		else if (value.type == typeid(bool))
			lua_pushboolean(L, value.get!bool);
		else
			assert(false);
	}
}
