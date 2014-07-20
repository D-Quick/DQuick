module dquick.script.propertyBinding;

import std.algorithm;
import std.file, std.stdio;
import std.conv;
import std.string;
import std.array;
import std.c.string;

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
			result ~= format("\t%s.%s\n", dependent.itemBinding.id, dependent.propertyName);
		return result;
	}
	string	displayDependencies()
	{
		string	result;
		foreach (dependencie; dependencies)
			result ~= format("\t%s.%s\n", dependencie.itemBinding.id, dependencie.propertyName);
		return result;
	}

	void	executeBinding()
	{
		assert(itemBinding.dmlEngine !is null);

		// No property binding or slot call while the item is in creation to ensure there is no particular initialisation order between properties of an object
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

			{ // This scope is important for the scope(exit) and scope(failure)
				itemBinding.dmlEngine.currentlyExecutedBindingStack ~= this;
				scope(exit) itemBinding.dmlEngine.currentlyExecutedBindingStack.length--;
				scope(failure) dependencies.clear();

				//writefln("%sinitializationPhase = %d executeBinding %s", repeat("|\t", lvl), initializationPhase, item.id);
				//writefln("top = %d", lua_gettop(luaState));

				int	top = lua_gettop(itemBinding.dmlEngine.luaState);
				lua_rawgeti(itemBinding.dmlEngine.luaState, LUA_REGISTRYINDEX, luaReference);
				itemBinding.dmlEngine.luaPCall(0);

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

			dirty = false;

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

		if (itemBinding.creating == false) // No property binding or slot call while the item is in creation
		{
			// Detect assignment from D that compete with his binding
			if (itemBinding.dmlEngine.propertyBindingBeeingSet !is this && luaReference != -1)
			{
				dirty = true;
				executeBinding();
				return;
			}

			static if (dquick.script.dmlEngine.DMLEngine.showDebug)
				writefln("%s%s.%s.onChanged {", replicate("|\t", itemBinding.dmlEngine.lvl++), itemBinding.id, propertyName);

			if (slotLuaReference != -1)
			{
				lua_rawgeti(itemBinding.dmlEngine.luaState, LUA_REGISTRYINDEX, slotLuaReference);
				itemBinding.dmlEngine.luaPCall(0);
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

			static if (dquick.script.dmlEngine.DMLEngine.showDebug)
			{
				assert(itemBinding.dmlEngine.lvl >= 1);
				itemBinding.dmlEngine.lvl--;
				writefln("%s}", replicate("|\t", itemBinding.dmlEngine.lvl));
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
			static if (dquick.script.dmlEngine.DMLEngine.showDebug)
			{
				writefln("[%s].%s became a dependency of [%s].%s",
						 itemBinding.id,
						 propertyName,
						 itemBinding.dmlEngine.currentlyExecutedBindingStack[itemBinding.dmlEngine.currentlyExecutedBindingStack.length - 1].itemBinding.id,
						 itemBinding.dmlEngine.currentlyExecutedBindingStack[itemBinding.dmlEngine.currentlyExecutedBindingStack.length - 1].propertyName);
			}
			itemBinding.dmlEngine.currentlyExecutedBindingStack[itemBinding.dmlEngine.currentlyExecutedBindingStack.length - 1].dependencies ~= this;
		}
	}

	void	bindingFromLua(lua_State* L, int index)
	{
		if (lua_isfunction(L, index)) // Binding is a lua function
		{
			lua_pushvalue(L, index);// To compensate the value poped by luaL_ref

			// Set _ENV upvalue
			const char*	upvalue = lua_getupvalue(L, -1, 1);
			if (upvalue != null)
			{
				lua_pop(L, 1);
				if (strcmp(upvalue, "_ENV") == 0)
				{					
					lua_rawgeti(L, LUA_REGISTRYINDEX, itemBinding.itemBindingLuaEnvDummyClosureReference);
					lua_upvaluejoin(L, -2, 1, -1, 1);
					lua_pop(L, 1);
				}
			}

			luaReference = luaL_ref(L, LUA_REGISTRYINDEX);
			dirty = true;
			executeBinding();
		}
		else // Binding is just a value
		{
			luaReference = -1;
			valueFromLua(L, index);
		}
	}
}

