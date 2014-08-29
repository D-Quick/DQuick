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
import dquick.script.dmlEngine;

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

			DMLEngineCore	dmlEngineCore = itemBinding.dmlEngine;
			DMLEngine		dmlEngine = cast(DMLEngine)dmlEngineCore;
			lua_State* luaState = dmlEngineCore.luaState;
			// Get delegate type (first param of it's setter)
			alias ParameterTypeTuple!(__traits(getMember, item, PropertyName))[0]	dgType;
			alias ParameterTypeTuple!dgType	delegateParamsTypes;
			dgType	func = delegate(delegateParamsTypes params) // Create a closure that call the lua function
			{
				int	top = lua_gettop(itemBinding.dmlEngine.luaState);
				lua_rawgeti(luaState, LUA_REGISTRYINDEX, luaReference);
				foreach (param; params)
				{
					static if (is(typeof(param) : dquick.script.iItemBinding.IItemBinding))
					{
						dmlEngineCore.addObjectBinding(param);
						dquick.script.utils.valueToLua(luaState, param);
					}
					else
					{
						static if (is(typeof(param) : Object) || __traits(isAbstractClass, typeof(param)) || __traits(isFinalClass, typeof(param)))
						{
							assert(dmlEngine, "No DMLEngine");
							dquick.script.itemBinding.ItemBinding!(typeof(param)) itemBinding = dmlEngine.registerItem!(typeof(param))(param);
							dquick.script.utils.valueToLua(luaState, itemBinding);
						}
						else
						{
							dquick.script.utils.valueToLua(luaState, param);
						}
					}
				}
				itemBinding.dmlEngine.luaPCall(params.length);

				if (lua_gettop(luaState) - top != 1)
					throw new Exception(format("too few or too many return values on delegate %s.%s, got %d, expected 1", itemBinding.id, propertyName, lua_gettop(luaState) - top));

				alias ReturnType!dgType	returnType;
				static if (is(returnType == void))
					return;
				else
				{
					returnType returnVal;

					static if (is(returnType : dquick.script.iItemBinding.IItemBinding))
					{
						dquick.script.utils.valueFromLua!(returnType)(luaState, -1, returnVal);
					}
					else
					{
						static if (is(returnType : Object) || __traits(isAbstractClass, returnType) || __traits(isFinalClass, returnType))
						{
							assert(dmlEngine, "No DMLEngine");
							dquick.script.itemBinding.ItemBinding!(returnType) itemBinding;
							dquick.script.utils.valueFromLua(luaState, -1, itemBinding);
							returnVal = itemBinding.item;
						}
						else
						{
							dquick.script.utils.valueFromLua!(returnType)(luaState, -1, returnVal);
						}
					}

					lua_pop(itemBinding.dmlEngine.luaState, 1); // Pop the result
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
