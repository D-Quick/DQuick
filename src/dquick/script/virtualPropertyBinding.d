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
	int	valueRef = -1;

	this(IItemBinding itemBinding, string propertyName)
	{
		super(itemBinding, propertyName);
	}

	override void	valueFromLua(lua_State* L, int index, bool popFromStack = false)
	{
		int	equal;
		if (valueRef != -1)
		{
			lua_rawgeti(L, LUA_REGISTRYINDEX, valueRef);
			equal = lua_compare(L, -2, -1, LUA_OPWQ);
			lua_pop(L, 1);
		}
		if (valueRef == -1 || equal != 1)
		{
			if (valueRef != -1)
				luaL_unref(L, LUA_REGISTRYINDEX, valueRef);
			if (popFromStack == false)
				lua_pushvalue(L, -1); // Composensate luaL_ref's pop
			valueRef = luaL_ref(L, LUA_REGISTRYINDEX);
			onChanged();
		}
	}

	override void	valueToLua(lua_State* L)
	{
		super.valueToLua(L);
		assert(valueRef != -1);
		lua_rawgeti(L, LUA_REGISTRYINDEX, valueRef);
	}
}
