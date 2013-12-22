module dquick.script.propertyBinding;

import std.algorithm;
import std.file, std.stdio;
import std.conv;
import std.string;
import std.array;

import derelict.lua.lua;

import dquick.script.dmlEngine;
import dquick.script.iItemBinding;

class PropertyBinding
{
	int	_slotLuaReference = -1;
	void	slotLuaReference(int luaRef)
	{
		if (_slotLuaReference != -1)
			luaL_unref(itemBinding.dmlEngine.luaState, LUA_REGISTRYINDEX, _slotLuaReference);
		_slotLuaReference = luaRef;
	}
	int		slotLuaReference()
	{
		return _slotLuaReference;
	}

	int	_luaReference = -1;
	void	luaReference(int luaRef)
	{
		if (_luaReference != -1)
			luaL_unref(itemBinding.dmlEngine.luaState, LUA_REGISTRYINDEX, _luaReference);
		_luaReference = luaRef;
	}
	int		luaReference()
	{
		return _luaReference;
	}

	PropertyBinding[]	dependencies;
	PropertyBinding[PropertyBinding]	dependents;

	byte	dirty;

	dquick.script.iItemBinding.IItemBinding itemBinding;

	string	propertyName;
	this(IItemBinding itemBinding, string propertyName)
	{
		this.itemBinding = itemBinding;
		this.propertyName = propertyName;
		dirty = true;
	}
	string	displayDependents()
	{
		string	result;
		foreach (dependent; dependents)
			result ~= format("%s.%s\n", dependent.itemBinding.id, dependent.propertyName);
		return result;
	}

	void	executeBinding()
	{
		assert(itemBinding.dmlEngine !is null);

		if (dirty == false || itemBinding.creating == true)
			return;

		if (luaReference != -1)
		{
			// Binding overflow or property binding loop detection
			if (itemBinding.dmlEngine.currentlyExecutedBindingStack.length >= itemBinding.dmlEngine.propertyBindingStackSize)
			{
				string	bindingLoopCallStack;
				int	loopCount = 0;
				for (int index = cast(int)(itemBinding.dmlEngine.currentlyExecutedBindingStack.length - 1);  index >= 0; index--)
				{
					bindingLoopCallStack ~= itemBinding.dmlEngine.currentlyExecutedBindingStack[index].itemBinding.id;
					bindingLoopCallStack ~= ".";
					bindingLoopCallStack ~= itemBinding.dmlEngine.currentlyExecutedBindingStack[index].propertyName;
					bindingLoopCallStack ~= "\n";
					if (itemBinding.dmlEngine.currentlyExecutedBindingStack[index] is this)
					{
						loopCount++;
						if (loopCount == 2)
							break;
					}
				}
				if (loopCount != 0)
					throw new Exception(format("property binding loop detected, callstack:\n%s...", bindingLoopCallStack));
				else
					throw new Exception(format("binding stack overflow (more than 50):\n%s...", bindingLoopCallStack));
			}

			static if (dquick.script.dmlEngineCore.DMLEngineCore.showDebug)
			{
				writefln("%s%s.%s.executeBinding {", replicate("|\t", itemBinding.dmlEngine.lvl++), itemBinding.id, propertyName);
				scope(exit)
				{
					assert(itemBinding.dmlEngine.lvl >= 1);
					itemBinding.dmlEngine.lvl--;
					writefln("%s}", replicate("|\t", itemBinding.dmlEngine.lvl));
				}
			}

			foreach (dependency; dependencies)
				dependency.dependents[this] = null;

			dependencies.clear();

			{
				itemBinding.dmlEngine.currentlyExecutedBindingStack ~= this;
				scope(exit) itemBinding.dmlEngine.currentlyExecutedBindingStack.length--;
				scope(failure) dependencies.clear();

				//writefln("%sinitializationPhase = %d executeBinding %s", repeat("|\t", lvl), initializationPhase, item.id);
				//writefln("top = %d", lua_gettop(luaState));

				int	top = lua_gettop(itemBinding.dmlEngine.luaState);
				lua_rawgeti(itemBinding.dmlEngine.luaState, LUA_REGISTRYINDEX, luaReference);
				if (lua_pcall(itemBinding.dmlEngine.luaState, 0, LUA_MULTRET, 0) != LUA_OK)
				{
					string error = to!(string)(lua_tostring(itemBinding.dmlEngine.luaState, -1));
					lua_pop(itemBinding.dmlEngine.luaState, 1);
					throw new Exception(error);
				}

				static if (dquick.script.dmlEngine.DMLEngine.showDebug)
				{
					foreach (dependency; dependencies)
					{
						writefln("%sdepend on %s.%s", replicate("|\t", itemBinding.dmlEngine.lvl), dependency.itemBinding.id, dependency.propertyName);
					}
				}
				foreach (dependency; dependencies)
					dependency.dependents[this] = this;

				if (lua_gettop(itemBinding.dmlEngine.luaState) - top != 1)
					throw new Exception(format("too few or too many return values on property binding %s.%s, got %d, expected 1", itemBinding.id, propertyName, lua_gettop(itemBinding.dmlEngine.luaState) - top));
			}

			// Put this so that onChanged can detect it's a value change from binding or from D
			itemBinding.dmlEngine.propertyBindingBeeingSet = this;
			valueFromLua(itemBinding.dmlEngine.luaState, -1, true);
			itemBinding.dmlEngine.propertyBindingBeeingSet = null;
		}
	}

	void	onChanged()
	{
		if (itemBinding.dmlEngine is null)
			return;

		if (itemBinding.creating == false)
		{
			// Detect assignment from D that compete with his binding
			if (itemBinding.dmlEngine.propertyBindingBeeingSet !is this && luaReference != -1)
			{
				dirty = true;
				executeBinding();
				return;
			}

			dirty = false;
			static if (dquick.script.dmlEngine.DMLEngine.showDebug)
				writefln("%s%s.%s.onChanged {", replicate("|\t", itemBinding.dmlEngine.lvl++), itemBinding.id, propertyName);

			if (slotLuaReference != -1)
				itemBinding.dmlEngine.execute(slotLuaReference);

			static if (dquick.script.dmlEngine.DMLEngine.showDebug)
			{
				assert(itemBinding.dmlEngine.lvl >= 1);
				itemBinding.dmlEngine.lvl--;
				writefln("%s}", replicate("|\t", itemBinding.dmlEngine.lvl));
			}

			auto dependentsCopy = dependents.dup;
			foreach (dependent; dependentsCopy)
			{
				if (dependent !is null)
					dependent.dirty = true;
			}
			foreach (dependent; dependentsCopy)
			{
				if (dependent !is null)
					dependent.executeBinding();
			}
		}
	}

	void	valueFromLua(lua_State* L, int index, bool popFromStack = false)
	{
	}

	void	valueToLua(lua_State* L)
	{
		executeBinding();
		if (itemBinding.dmlEngine.currentlyExecutedBindingStack.length > 0)
		{
			assert(itemBinding.dmlEngine.currentlyExecutedBindingStack[itemBinding.dmlEngine.currentlyExecutedBindingStack.length - 1] !is this);
			itemBinding.dmlEngine.currentlyExecutedBindingStack[itemBinding.dmlEngine.currentlyExecutedBindingStack.length - 1].dependencies ~= this;
		}
	}

	void	bindingFromLua(lua_State* L, int index)
	{
		if (lua_isfunction(L, index)) // Binding is a lua function
		{
			lua_pushvalue(L, index);// To compensate the value poped by luaL_ref

			// Set _ENV upvalue
			if (lua_getupvalue(L, -1, 1) != null)
			{
				lua_pop(L, 1);
				lua_rawgeti(L, LUA_REGISTRYINDEX, itemBinding.itemBindingLuaEnvDummyClosureReference);
				lua_upvaluejoin(L, -2, 1, -1, 1);
				lua_pop(L, 1);
			}

			luaReference = luaL_ref(L, LUA_REGISTRYINDEX);
			dirty = true;
			executeBinding();
		}
		else // Binding is juste a value
		{
			luaReference = -1;
			valueFromLua(L, index);
		}
	}
}

