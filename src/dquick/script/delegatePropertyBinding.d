module dquick.script.delegatePropertyBinding;

import std.stdio;
import std.conv;
import std.string;
import std.array;
import std.traits;

import derelict.lua.lua;

import dquick.script.propertyBinding;
import dquick.script.iItemBinding;
import dquick.script.itemBinding;
import dquick.script.utils;
import dquick.script.nativePropertyBinding;

class DelegatePropertyBinding(ValueType, ItemType, string PropertyName) : NativePropertyBinding!(ValueType, ItemType, PropertyName)
{
	this(IItemBinding itemBinding, ItemType item)
	{
		super(itemBinding, item);
		dirty = false;
	}

	override void	executeBinding() // delegate's function is not a binding, do nothing
	{
		dirty = false;
	}

	override void	valueFromLua(lua_State* L, int index, bool popFromStack = false)
	{
		assert(false);	
	}

	override void	valueToLua(lua_State* L)
	{
		if (luaReference != -1)
			lua_rawgeti(L, LUA_REGISTRYINDEX, luaReference);
		else
			lua_pushnil(L);
	}

	override void	bindingFromLua(lua_State* L, int index)
	{
		if (lua_isfunction(L, index)) // Binding is a lua function
		{
			super.bindingFromLua(L, index);

			lua_State* luaState = itemBinding.dmlEngine.luaState;
			alias ParameterTypeTuple!(__traits(getMember, item, PropertyName))[0]	dgType;
			dgType	func = delegate(ParameterTypeTuple!dgType params) // Create a closure that call the lua function
			{
				int	top = lua_gettop(itemBinding.dmlEngine.luaState);
				lua_rawgeti(luaState, LUA_REGISTRYINDEX, luaReference);
				foreach (param; params)
					lua_pushnumber(luaState, param);
				if (lua_pcall(luaState, params.length, LUA_MULTRET, 0) != LUA_OK)
				{
					string error = to!(string)(lua_tostring(itemBinding.dmlEngine.luaState, -1));
					lua_pop(itemBinding.dmlEngine.luaState, 1);
					throw new Exception(error);
				}

				if (lua_gettop(luaState) - top != 1)
					throw new Exception(format("too few or too many return values on delegate %s.%s, got %d, expected 1", itemBinding.id, propertyName, lua_gettop(luaState) - top));

				alias ReturnType!dgType	returnType;
				static if (is(returnType == void))
					return;
				else
				{
					returnType returnVal;
					dquick.script.utils.valueFromLua!(returnType)(luaState, -1, returnVal);
					return returnVal;
				}
			};
			static if (__traits(compiles, __traits(getMember, cast(ItemType)(item), PropertyName)(func)))
				__traits(getMember, item, PropertyName)(func);
			else
				throw new Exception(format("property \"%s\" is read only", PropertyName));	
		}
		else // Binding is just a value
		{
			luaReference = -1;
			__traits(getMember, item, PropertyName)(null);
		}
	}
}
