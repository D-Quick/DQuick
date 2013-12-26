module dquick.script.utils;

import std.regex;
import std.string;
import derelict.lua.lua;
import std.conv;
import std.variant;
import std.traits;
import core.memory;
import std.c.string;
import std.algorithm;
import std.stdio;
import dquick.item.declarativeItem;

string	repeat(string s, int count)
{
	string	result;
	while (count > 0)
	{
		result ~= s;
		count--;
	}
	return result;
}

string	shiftRight(string s, string shiftString, int count)
{
	auto com = ctRegex!(r"(^)(.)", "gm");
	return replace(s, com, "$1" ~ repeat(shiftString, count) ~ "$2");
}

string	toLowerCamelCase(string text)
{
	return toLower(text[0..1]) ~ text[1..$];
}

string	toUpperCamelCase(string text)
{
	return toUpper(text[0..1]) ~ text[1..$];
}

string	getSignalNameFromPropertyName(string propertyName)
{
	return "on" ~ toUpperCamelCase(propertyName) ~ "Changed";
}

string	getPropertyNameFromPropertyDeclaration(string declaration)
{
	if (endsWith(declaration, "Property"))
		return declaration[0 .. declaration.length - "Property".length];
	return "";
}

string	getPropertyNameFromSignalName(string signalName)
{
	if (startsWith(signalName, "on") && endsWith(signalName, "Changed"))
		return toLowerCamelCase(signalName["on".length..signalName.length-"Changed".length]);
	return "";
}

string	getLuaTypeName(lua_State* L, int index)
{
	if (lua_isnil(L, index))
		return "nil";
	else if (lua_isnone(L, index))
		return "none";
	else if (lua_istable(L, index))
		return "table";
	else if (lua_isthread(L, index))
		return "thread";
	else if (lua_isuserdata(L, index))
		return "userdata";
	else if (lua_iscfunction(L, index))
		return "cfunction";
	else if (lua_isfunction(L, index))
		return "funcion";
	else if (lua_islightuserdata(L, index))
		return "lightuserdata";
	else if (lua_isnumber(L, index))
		return "number";
	else if (lua_isstring(L, index))
		return "string";
	else if (lua_isboolean(L, index))
		return "boolean";
	else
	{
		throw new Exception(format("Lua value at index %d is an unknown type, a number, string or boolean was expected", index));
	}
}

enum LuaUserDataType : byte
{
	Item,
	Method,
	Array
}

struct LuaUserDataItem
{
	LuaUserDataType								type = LuaUserDataType.Item;
	dquick.script.iItemBinding.IItemBinding		iItemBinding;
}

struct LuaUserDataMethod
{
	LuaUserDataType								type = LuaUserDataType.Method;
	dquick.script.iItemBinding.IItemBinding		iItemBinding;
}

struct LuaUserDataArray(T)
{
	LuaUserDataType								type = LuaUserDataType.Array;
	T											array;
}

void	valueFromLua(T)(lua_State* L, int index, ref T value)
{
	static assert(isPointer!T == false);

	static if (is(T == Variant))
	{
		if (lua_isboolean(L, index))
			value = cast(bool)lua_toboolean(L, index);
		else if (lua_isnumber(L, index))
			value = lua_tonumber(L, index);
		else if (lua_isstring(L, index))
			value = to!(string)(lua_tostring(L, index));
		else if (lua_istable(L, index))
		{
			assert(false, "Unfinished");
			/+int	count = 0;
			/* table is in the stack at index 't' */
			lua_pushnil(L);  /* first key */
			while (lua_next(L, -2) != 0) {
				/* uses 'key' (at index -2) and 'value' (at index -1) */

				if (count == 0) // First element set the type of the array
				{
					if (lua_isboolean(L, -1))
						value = new bool[0];
					else if (lua_isnumber(L, index))
						value = new ReturnType!(lua_tonumber)[0];
					else if (lua_isstring(L, index))
						value = new string[0];
					else
						throw new Exception(format("Lua value at index %d is a %s that contains a %s, only numbers, booleans or strings was expected", index, getLuaTypeName(L, -3), getLuaTypeName(L, -1)));
				}

				value ~= 10;
				//value.length++;
				Variant	subValue;
				valueFromLua!(typeof(value[value.length - 1]))(L, -1, subValue);

				/* removes 'value'; keeps 'key' for next iteration */
				lua_pop(L, 1);
			}+/
		}
		else
			throw new Exception(format("Lua value at index %d is a %s, a number, boolean or string was expected", index, getLuaTypeName(L, index)));
	}
	else static if (is(T == bool))
	{
		if (!lua_isboolean(L, index))
			throw new Exception(format("Lua value at index %d is a %s, a boolean was expected", index, getLuaTypeName(L, index)));
		value = cast(bool)lua_toboolean(L, index);
	}
	else static if (is(T == int) || is(T == uint) || is(T == enum) || is(T == size_t))
	{
		if (!lua_isnumber(L, index))
			throw new Exception(format("Lua value at index %d is a %s, a number was expected", index, getLuaTypeName(L, index)));
		value = cast(typeof(value))lua_tointeger(L, index);
	}
	else static if (is(T == float))
	{
		if (!lua_isnumber(L, index))
			throw new Exception(format("Lua value at index %d is a %s, a number was expected", index, getLuaTypeName(L, index)));
		value = cast(float)lua_tonumber(L, index);
	}
	else static if (is(T == string))
	{
		if (!lua_isstring(L, index))
			throw new Exception(format("Lua value at index %d is a %s, a string was expected", index, getLuaTypeName(L, index)));
		value = to!(string)(lua_tostring(L, index));
	}
	else static if (is(T : dquick.script.iItemBinding.IItemBinding))
	{
		if (lua_isnil(L, index))
			value = null;
		else
		{
			if (!lua_isuserdata(L, index))
				throw new Exception(format("Lua value at index %d is a %s, a userdata or nil was expected", index, getLuaTypeName(L, index)));

			LuaUserDataItem*	luaUserData = cast(LuaUserDataItem*)lua_touserdata(L, index);

			if (luaUserData.type != LuaUserDataType.Item)
				throw new Exception(format("Lua value at index %d is not an item", index));

			value = cast(T)(luaUserData.iItemBinding);
		}
	}
	else static if (isDynamicArray!T || isStaticArray!T)
	{
		if (lua_istable(L, index))
		{
			static if (isDynamicArray!T)
				value.clear();

			int	count = 0;
			/* table is in the stack at index 't' */
			lua_pushnil(L);  /* first key */
			while (lua_next(L, -2) != 0) {
				/* uses 'key' (at index -2) and 'value' (at index -1) */

				static if (isDynamicArray!T)
					value.length++;
				else if (isStaticArray!T)
				{
					if (count >= value.length)
						throw new Exception(format("Lua value at index %d is a %s that overflows", index, getLuaTypeName(L, -3)));
				}
				valueFromLua!(typeof(value[count]))(L, -1, value[count]);

				/* removes 'value'; keeps 'key' for next iteration */
				lua_pop(L, 1);

				count++;
			}
			static if (isStaticArray!T)
			{
				if (count != value.length)
					throw new Exception(format("Lua value at index %d is a %s that underflows", index, getLuaTypeName(L, -3)));
			}
		}
		else if (lua_isuserdata(L, index))
		{
			LuaUserDataArray!T*	luaUserData = cast(LuaUserDataArray!T*)lua_touserdata(L, index);

			if (luaUserData.type != LuaUserDataType.Array)
				throw new Exception(format("Lua value at index %d is not an array", index));

			value = cast(T)(luaUserData.array);
		}
		else
			throw new Exception(format("Lua value at index %d is a %s, a table or a userdata was expected", index, getLuaTypeName(L, index)));
	}
	else static if (isAssociativeArray!T)
	{
		if (lua_istable(L, index))
		{
			value.clear();

			KeyType!T	key;
			typeof(value[key])	elemValue;

			/* table is in the stack at index 't' */
			lua_pushnil(L);  /* first key */
			while (lua_next(L, -2) != 0) {
				/* uses 'key' (at index -2) and 'value' (at index -1) */

				valueFromLua!(typeof(key))(L, -2, key);
				valueFromLua!(typeof(elemValue))(L, -1, elemValue);
				value[key] = elemValue;

				/* removes 'value'; keeps 'key' for next iteration */
				lua_pop(L, 1);
			}
		}
		else if (lua_isuserdata(L, index))
		{
			LuaUserDataArray!T*	luaUserData = cast(LuaUserDataArray!T*)lua_touserdata(L, index);

			if (luaUserData.type != LuaUserDataType.Array)
				throw new Exception(format("Lua value at index %d is not an array", index));

			value = cast(T)(luaUserData.array);
		}
		else
			throw new Exception(format("Lua value at index %d is a %s, a table or a userdata was expected", index, getLuaTypeName(L, index)));
	}
	else
	{
		static assert(false, fullyQualifiedName2!(T));
	}
}

void	valueToLua(T)(lua_State* L, T value)
{
	static assert(isPointer!T == false);

	static if (is(T == Variant))
	{
		if (value.type == typeid(double))
			lua_pushnumber(L, value.get!double);
		else if (value.type == typeid(int))
			lua_pushnumber(L, value.get!double);
		else if (value.type == typeid(string))
			lua_pushstring(L, value.get!(string).dup.toStringz());
		else if (value.type == typeid(bool))
			lua_pushboolean(L, value.get!bool);
		else
			throw new Exception(format("Variant has type %s, an int, double, bool or string was expected", value.type));
	}
	else static if (is(T == int) || is(T == uint) || is(T == enum) || is(T == size_t))
		lua_pushinteger(L, value);
	else static if (is(T == float))
		lua_pushnumber(L, value);
	else static if (is(T == string))
		lua_pushstring(L, value.toStringz());
	else static if (is(T == bool))
		lua_pushboolean(L, value);
	else static if (is(T : dquick.script.iItemBinding.IItemBinding))
	{
		if (value is null)
			lua_pushnil(L);
		else
		{
			// Create a userdata that contains instance ptr and make it a global for user access
			// It also contains a metatable for the member read and write acces
			void*	userData = lua_newuserdata(L, LuaUserDataItem.sizeof);
			(cast(LuaUserDataItem*)userData).type = LuaUserDataType.Item;
			(cast(LuaUserDataItem*)userData).iItemBinding = value;

			lua_newtable(L);

			lua_pushstring(L, "__index");
			lua_pushcfunction(L, cast(lua_CFunction)&dquick.script.dmlEngineCore.indexLuaBind!T);
			lua_settable(L, -3);
			lua_pushstring(L, "__newindex");
			lua_pushcfunction(L, cast(lua_CFunction)&dquick.script.dmlEngineCore.newindexLuaBind!T);
			lua_settable(L, -3);

			lua_setmetatable(L, -2);
		}
	}
	else static if (isDynamicArray!T || isStaticArray!T)
	{
		// Pass array by value, unoptimized
		/+lua_newtable(L);
		for (int index = 0; index < value.length; index++)
		{
			lua_pushnumber(L, index + 1);
			valueToLua!(typeof(value[index]))(L, value[index]);
			lua_settable(L, -3);
		}+/

		void*	userData = lua_newuserdata(L, (LuaUserDataArray!T).sizeof);
		(cast(LuaUserDataArray!T*)userData).type = LuaUserDataType.Array;
		(cast(LuaUserDataArray!T*)userData).array = value;

		lua_newtable(L);

		lua_pushstring(L, "__index");
		lua_pushcfunction(L, cast(lua_CFunction)&dquick.script.dmlEngineCore.arrayIndexLuaBind!T);
		lua_settable(L, -3);
		lua_pushstring(L, "__newindex");
		lua_pushcfunction(L, cast(lua_CFunction)&dquick.script.dmlEngineCore.arrayNewindexLuaBind!T);
		lua_settable(L, -3);

		lua_setmetatable(L, -2);
	}
	else static if (isAssociativeArray!T)
	{
		// Pass array by value, unoptimized
		/+lua_newtable(L);
		foreach (key, elemValue; value)
		{
			valueToLua!(typeof(key))(L, key);
			valueToLua!(typeof(elemValue))(L, elemValue);
			lua_settable(L, -3);
		}+/

		void*	userData = lua_newuserdata(L, (LuaUserDataArray!T).sizeof);
		(cast(LuaUserDataArray!T*)userData).type = LuaUserDataType.Array;
		(cast(LuaUserDataArray!T*)userData).array = value;

		lua_newtable(L);

		lua_pushstring(L, "__index");
		lua_pushcfunction(L, cast(lua_CFunction)&dquick.script.dmlEngineCore.arrayIndexLuaBind!T);
		lua_settable(L, -3);
		lua_pushstring(L, "__newindex");
		lua_pushcfunction(L, cast(lua_CFunction)&dquick.script.dmlEngineCore.arrayNewindexLuaBind!T);
		lua_settable(L, -3);

		lua_setmetatable(L, -2);
	}
	else
	{
		static assert(false);
	}
}

void	methodFromLua(T)(lua_State* L, int index, ref T object)
{
	assert(isPointer!T == false);

	static if (is(T : dquick.script.iItemBinding.IItemBinding))
	{
		if (lua_isnil(L, index))
			object = null;
		else
		{
			if (!lua_isuserdata(L, index))
				throw new Exception(format("Lua value at index %d is a %s, a userdata or nil was expected", index, getLuaTypeName(L, index)));

			LuaUserDataMethod*	luaUserData = cast(LuaUserDataMethod*)lua_touserdata(L, index);

			if (luaUserData.type != LuaUserDataType.Method)
				throw new Exception(format("Lua value at index %d is not a method", index));

			object = cast(T)(luaUserData.iItemBinding);
		}
	}
	else
	{
		static assert(false, fullyQualifiedName2!(T));
	}
}

void	methodToLua(T, string methodName)(lua_State* L, T object)
{
	assert(isPointer!T == false);

	static if (is(T : dquick.script.iItemBinding.IItemBinding))
	{
		// Create a userdata that contains instance ptr and return it to emulate a method
		// It also contains a metatable for calling
		void*	userData = lua_newuserdata(L, LuaUserDataMethod.sizeof);
		(cast(LuaUserDataMethod*)userData).type = LuaUserDataType.Method;
		(cast(LuaUserDataMethod*)userData).iItemBinding = object;

		// Create metatable
		lua_newtable(L);
		{
			// Call metamethod to instanciate type
			lua_pushstring(L, "__call");
			lua_pushcfunction(L, cast(lua_CFunction)&dquick.script.dmlEngineCore.methodCallLuaBind!(methodName, typeof(object)));
			lua_settable(L, -3);
			// Index metamethod to warn user that it's a method
			lua_pushstring(L, "__index");
			lua_pushcfunction(L, cast(lua_CFunction)&dquick.script.dmlEngineCore.methodIndexLuaBind!(methodName, typeof(object)));
			lua_settable(L, -3);
			// newIndex metamethod to warn user that it's a method
			lua_pushstring(L, "__newindex");
			lua_pushcfunction(L, cast(lua_CFunction)&dquick.script.dmlEngineCore.methodNewIndexLuaBind!(methodName, typeof(object)));
			lua_settable(L, -3);
		}
		lua_setmetatable(L, -2);
	}
	else
	{
		static assert(false);
	}
}

int	luaCallD(alias func)(lua_State* L, int firstParamIndex)
{			
	//static assert(isSomeFunction!func, "func must be a function or a method");
	static assert(__traits(isStaticFunction, func), "func must be a static function");

	// Collect all argument in a tuple
	alias ParameterTypeTuple!func MyParameterTypeTuple;
	MyParameterTypeTuple	parameterTuple;

	if (lua_gettop(L) + 1 - firstParamIndex > parameterTuple.length)
		throw new Exception(format("too many arguments, expected %d", parameterTuple.length));

	foreach (index, paramType; MyParameterTypeTuple)
		dquick.script.utils.valueFromLua!paramType(L, firstParamIndex + index, parameterTuple[index]);
	lua_pop(L, parameterTuple.length);

	// Call D function
	alias ReturnType!func	returnType;
	static if (is(returnType == void))
	{
		func(parameterTuple);
		return 0;
	}
	else
	{
		returnType returnVal = func(parameterTuple);

		// Write return value into lua stack
		valueToLua(L, returnVal);
		return 1;
	}
}

int	luaCallThisD(string funcName, T)(T thisRef, lua_State* L, int firstParamIndex)
{
	static assert(isSomeFunction!(__traits(getMember, T, funcName)) &&
				  !__traits(isStaticFunction, __traits(getMember, T, funcName)) &&
				  !isDelegate!(__traits(getMember, T, funcName)),
				  "func must be a method");

	// Collect all argument in a tuple
	alias ParameterTypeTuple!(__traits(getMember, T, funcName)) MyParameterTypeTuple;
	MyParameterTypeTuple	parameterTuple;

	if (lua_gettop(L) + 1 - firstParamIndex > parameterTuple.length)
		throw new Exception(format("too many arguments, expected %d", parameterTuple.length));

	foreach (index, paramType; MyParameterTypeTuple)
		dquick.script.utils.valueFromLua!paramType(L, firstParamIndex + index, parameterTuple[index]);
	lua_pop(L, parameterTuple.length);

	// Call D function
	alias ReturnType!(__traits(getMember, T, funcName))	returnType;
	static if (is(returnType == void))
	{
		__traits(getMember, thisRef, funcName)(parameterTuple);
		return 0;
	}
	else
	{
		returnType returnVal = __traits(getMember, thisRef, funcName)(parameterTuple);

		// Write return value into lua stack
		valueToLua(L, returnVal);
		return 1;
	}
}

unittest
{
	static assert(getSignalNameFromPropertyName("mouseX") == "onMouseXChanged");
	static assert(getSignalNameFromPropertyName("X") == "onXChanged");
	static assert(getSignalNameFromPropertyName("x") == "onXChanged");

	static assert(getPropertyNameFromSignalName("onMouseXChanged") == "mouseX");
	static assert(getPropertyNameFromSignalName("onXChanged") == "x");

	static assert(getPropertyNameFromPropertyDeclaration("mouseXProperty") == "mouseX");
	static assert(getPropertyNameFromPropertyDeclaration("XProperty") == "X");
	static assert(getPropertyNameFromPropertyDeclaration("xProperty") == "x");
	static assert(getPropertyNameFromPropertyDeclaration("xProp") == "");
}

template PropertyType(T, string member) // Return the type of the property member from T class
{
	alias PropertyTypeImpl!(__traits(getOverloads, T, member))	PropertyType;
}

template PropertyTypeImpl(overloads...) // Transform types in ItemBindingBases
{
	static if (overloads.length == 0)
		alias void	PropertyTypeImpl;
	else
	{
		static if (!is(ReturnType!(overloads[0]) == void) && TypeTuple!(ParameterTypeTuple!(overloads[0])).length == 0)
			alias ReturnType!(overloads[0]) PropertyTypeImpl;
		else
			alias PropertyTypeImpl!(overloads[1 .. $]) PropertyTypeImpl;
	}
}

unittest
{
	class Test {
		int	_prop;
		short	prop() {return cast(short)_prop;}
		int	prop() {return _prop;}
		void	prop(int value) { _prop = value; }
	}

	static assert(is(PropertyType!(Test, "prop") == short));
}

/*
** search for 'objidx' in table at index -1.
** return 1 + string at top if find a good name.
*/
private static int findfield (lua_State *L, int objidx, int level) {
	if (level == 0 || !lua_istable(L, -1))
		return 0;  /* not found */
	lua_pushnil(L);  /* start 'next' loop */
	while (lua_next(L, -2)) {  /* for each pair in table */
		if (lua_type(L, -2) == LUA_TSTRING) {  /* ignore non-string keys */
			if (lua_rawequal(L, objidx, -1)) {  /* found object? */
				lua_pop(L, 1);  /* remove value (but keep name) */
				return 1;
			}
			else if (findfield(L, objidx, level - 1)) {  /* try recursively */
				lua_remove(L, -2);  /* remove table (but keep name) */
				lua_pushliteral(L, ".");
				lua_insert(L, -2);  /* place '.' between the two names */
				lua_concat(L, 3);
				return 1;
			}
		}
		lua_pop(L, 1);  /* remove value */
	}
	return 0;  /* not found */
}


private static int pushglobalfuncname(lua_State* L, lua_Debug* ar)
{
	int top = lua_gettop(L);
	lua_getinfo(L, "f", ar);  /* push function */
	lua_pushglobaltable(L);
	if (findfield(L, top + 1, 2))
	{
		lua_copy(L, -1, top + 1);  /* move name to proper place */
		lua_pop(L, 2);  /* remove pushed values */
		return 1;
	}
	else
	{
		lua_settop(L, top);  /* remove function and global table */
		return 0;
	}
}

private static void pushfuncname(lua_State* L, lua_Debug* ar)
{
	if (ar.namewhat != null)  /* is there a name? */
	{
		lua_pushstring(L, "function ");
		lua_pushstring(L, ar.name);
	}
	else if (ar.what[0] == 'm')  /* main? */
		lua_pushstring(L, "main chunk");
	else if (ar.what[0] == 'C')
	{
		if (pushglobalfuncname(L, ar))
		{
			lua_pushstring(L, "function ");
			lua_pushstring(L, lua_tostring(L, -1));
			lua_remove(L, -2);  /* remove name */
		}
		else
			lua_pushliteral(L, "?");
	}
	else
	{
		lua_pushstring(L, "function <");
		lua_pushstring(L, to!(string)(ar.short_src).toStringz);
		lua_pushstring(L, ":");
		lua_pushstring(L, to!(string)(ar.currentline).toStringz);
		lua_pushstring(L, ">");
	}
}

void	luaError(lua_State* L, string msg)
{
	int top = lua_gettop(L);
	lua_pushstring(L, msg.toStringz());
	lua_Debug ar;
	for (int level = 0; lua_getstack(L, level, &ar); level++)
	{
		lua_getinfo(L, "Sln", &ar);  /* get info about it */
		if (to!(string)(ar.source) != "ItemBindingLuaEnv" &&
			to!(string)(ar.source) != "ComponentEnvChaining") /* is there info? */
		{ 
			lua_pushstring(L, "\n\t");
			if (ar.short_src[0] == '[' && ar.short_src[1] == 'C' && ar.short_src[2] == ']')
				lua_pushstring(L, "[D]");
			else
				lua_pushstring(L, to!(string)(ar.short_src).toStringz);
			if (ar.currentline > 0)
			{
				lua_pushstring(L, ":");
				lua_pushstring(L, to!(string)(ar.currentline).toStringz);
			}
			if (to!(string)(ar.name) != "")
			{
				lua_pushstring(L, " in ");
				pushfuncname(L, &ar);
			}
			lua_concat(L, lua_gettop(L) - top);
		}
	}
	lua_error(L);
}


import std.algorithm;
import std.typetuple;
import std.typecons;
import core.vararg;

/***
* Get the fully qualified name of a type or a symbol. Can act as an intelligent type/symbol to string  converter.
* Example:
* ---
* module mymodule;
* import std.traits;
* struct MyStruct {}
* static assert(fullyQualifiedName!(const MyStruct[]) == "const(mymodule.MyStruct[])");
* static assert(fullyQualifiedName!fullyQualifiedName == "std.traits.fullyQualifiedName");
* ---
*/
template fullyQualifiedName2(T...)
if (T.length == 1)
{

    static if (is(T))
        enum fullyQualifiedName2 = fullyQualifiedNameImplForTypes2!(T[0], false, false, false, false);
    else
        enum fullyQualifiedName2 = fullyQualifiedNameImplForSymbols2!(T[0]);
}


private template fullyQualifiedNameImplForSymbols2(alias T)
{
    static if (__traits(compiles, __traits(parent, T)))
        enum parentPrefix2 = fullyQualifiedNameImplForSymbols2!(__traits(parent, T)) ~ '.';
    else
        enum parentPrefix2 = null;

    enum fullyQualifiedNameImplForSymbols2 = parentPrefix2 ~ (s)
    {
        if(s.skipOver("package ") || s.skipOver("module "))
            return s;
        return s.findSplit("(")[0];
    }(__traits(identifier, T));
}

private template fullyQualifiedNameImplForTypes2(T,
												bool alreadyConst, bool alreadyImmutable, bool alreadyShared, bool alreadyInout)
{
    import std.string;

    // Convenience tags
    enum {
        _const = 0,
        _immutable = 1,
        _shared = 2,
        _inout = 3
    }

    alias TypeTuple!(is(T == const), is(T == immutable), is(T == shared), is(T == inout)) qualifiers;
    alias TypeTuple!(false, false, false, false) noQualifiers;

    string storageClassesString(uint psc)() @property
    {
        alias ParameterStorageClass PSC;

        return format("%s%s%s%s",
					  psc & PSC.scope_ ? "scope " : "",
					  psc & PSC.out_ ? "out " : "",
					  psc & PSC.ref_ ? "ref " : "",
					  psc & PSC.lazy_ ? "lazy " : ""
					  );
    }

    string parametersTypeString(T)() @property
    {
        import std.array, std.algorithm, std.range;

        alias ParameterTypeTuple!(T) parameters;
        alias ParameterStorageClassTuple!(T) parameterStC;

        enum variadic = variadicFunctionStyle!T;
        static if (variadic == Variadic.no)
            enum variadicStr = "";
        else static if (variadic == Variadic.c)
            enum variadicStr = ", ...";
        else static if (variadic == Variadic.d)
            enum variadicStr = parameters.length ? ", ..." : "...";
        else static if (variadic == Variadic.typesafe)
            enum variadicStr = " ...";
        else
            static assert(0, "New variadic style has been added, please update fullyQualifiedName implementation");

        static if (parameters.length)
        {
            string result = join(
								 map!(a => format("%s%s", a[0], a[1]))(
																	   zip([staticMap!(storageClassesString, parameterStC)],
																		   [staticMap!(fullyQualifiedName, parameters)])
																	   ),
								 ", "
								 );

            return result ~= variadicStr;
        }
        else
            return variadicStr;
    }

    string linkageString(T)() @property
    {
        enum linkage = functionLinkage!T;

        if (linkage != "D")
            return format("extern(%s) ", linkage);
        else
            return "";
    }

    string functionAttributeString(T)() @property
    {
        alias FunctionAttribute FA;
        enum attrs = functionAttributes!T;

        static if (attrs == FA.none)
            return "";
        else
            return format("%s%s%s%s%s%s",
						  attrs & FA.pure_ ? " pure" : "",
						  attrs & FA.nothrow_ ? " nothrow" : "",
						  attrs & FA.ref_ ? " ref" : "",
						  attrs & FA.property ? " @property" : "",
						  attrs & FA.trusted ? " @trusted" : "",
						  attrs & FA.safe ? " @safe" : ""
						  );
    }

    string addQualifiers(string typeString,
						 bool addConst, bool addImmutable, bool addShared, bool addInout)
    {
        auto result = typeString;
        if (addShared)
        {
            result = format("shared(%s)", result);
        }
        if (addConst || addImmutable || addInout)
        {
            result = format("%s(%s)",
							addConst ? "const" :
							addImmutable ? "immutable" : "inout",
							result
							);
        }
        return result;
    }

    // Convenience template to avoid copy-paste
    template chain(string current)
    {
        enum chain = addQualifiers(current,
								   qualifiers[_const]     && !alreadyConst,
								   qualifiers[_immutable] && !alreadyImmutable,
								   qualifiers[_shared]    && !alreadyShared,
								   qualifiers[_inout]     && !alreadyInout);
    }

    static if (is(T == string))
    {
        enum fullyQualifiedNameImplForTypes2 = "string";
    }
    else static if (is(T == wstring))
    {
        enum fullyQualifiedNameImplForTypes2 = "wstring";
    }
    else static if (is(T == dstring))
    {
        enum fullyQualifiedNameImplForTypes2 = "dstring";
    }
    else static if (isBasicType!T && !is(T == enum))
    {
        enum fullyQualifiedNameImplForTypes2 = chain!((Unqual!T).stringof);
    }
    else static if (isAggregateType!T || is(T == enum))
    {
        enum fullyQualifiedNameImplForTypes2 = chain!(fullyQualifiedNameImplForSymbols2!T);
    }
    else static if (isStaticArray!T)
    {
        import std.conv;

        enum fullyQualifiedNameImplForTypes2 = chain!(
													 format("%s[%s]", fullyQualifiedNameImplForTypes2!(typeof(T.init[0]), qualifiers), T.length)
													 );
    }
    else static if (isArray!T)
    {
        enum fullyQualifiedNameImplForTypes2 = chain!(
													 format("%s[]", fullyQualifiedNameImplForTypes2!(typeof(T.init[0]), qualifiers))
													 );
    }
    else static if (isAssociativeArray!T)
    {
        enum fullyQualifiedNameImplForTypes2 = chain!(
													 format("%s[%s]", fullyQualifiedNameImplForTypes2!(ValueType!T, qualifiers), fullyQualifiedNameImplForTypes2!(KeyType!T, noQualifiers))
													 );
    }
    else static if (isSomeFunction!T)
    {
        static if (is(T F == delegate))
        {
            enum qualifierString = format("%s%s",
										  is(F == shared) ? " shared" : "",
										  is(F == inout) ? " inout" :
										  is(F == immutable) ? " immutable" :
										  is(F == const) ? " const" : ""
											  );
            enum formatStr = "%s%s delegate(%s)%s%s";
            enum fullyQualifiedNameImplForTypes2 = chain!(
														 format(formatStr, linkageString!T, fullyQualifiedNameImplForTypes2!(ReturnType!T, noQualifiers),
																parametersTypeString!(T), functionAttributeString!T, qualifierString)
														 );
        }
        else
        {
            static if (isFunctionPointer!T)
                enum formatStr = "%s%s function(%s)%s";
            else
                enum formatStr = "%s%s(%s)%s";

            enum fullyQualifiedNameImplForTypes2 = chain!(
														 format(formatStr, linkageString!T, fullyQualifiedNameImplForTypes2!(ReturnType!T, noQualifiers),
																parametersTypeString!(T), functionAttributeString!T)
														 );
        }
    }
    else static if (isPointer!T)
    {
        enum fullyQualifiedNameImplForTypes2 = chain!(
													 format("%s*", fullyQualifiedNameImplForTypes2!(PointerTarget!T, qualifiers))
													 );
    }
    else
        // In case something is forgotten
        static assert(0, "Unrecognized type " ~ T.stringof ~ ", can't convert to fully qualified string");
}
