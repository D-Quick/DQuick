module dquick.script.utils;

import std.regex;
import std.string;
import derelict.lua.lua;
import std.conv;
import std.variant;

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
	static auto com = regex(r"(^)(.)", "gm");
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

string	getPropertyNameFromSignalName(string signalName)
{
	static auto reg = regex("^on(.+)Changed$", "");
	auto	m = match(signalName, reg);
	if (m)
		return toLowerCamelCase(m.captures[1]);
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
		throw new Exception(format("Lua value at index %d is an unknown type, a number, string or boolean was expected\n", index));
	}
}

T	valueFromLua(T)(lua_State* L, int index)
{
	T	value;
	static if (is(T == Variant))
	{
		if (lua_isboolean(L, index))
			value = lua_toboolean(L, index);
		if (lua_isnumber(L, index))
			value = lua_tonumber(L, index);
		else if (lua_isstring(L, index))
			value = to!(string)(lua_tostring(L, index));
		else
			throw new Exception(format("Lua value at index %d is a \"%s\", a number, boolean or string was expected\n", index, getLuaTypeName(L, index)));
	}
	else static if (is(T == bool))
	{
		if (!lua_isboolean(L, index))
			throw new Exception(format("Lua value at index %d is a \"%s\", a boolean was expected\n", index, getLuaTypeName(L, index)));
		value = cast(bool)lua_toboolean(L, index);
	}
	else static if (is(T == int))
	{
		if (!lua_isnumber(L, index))
			throw new Exception(format("Lua value at index %d is a \"%s\", a number was expected\n", index, getLuaTypeName(L, index)));
		value = cast(int)lua_tointeger(L, index);
	}
	else static if (is(T == float))
	{
		if (!lua_isnumber(L, index))
			throw new Exception(format("Lua value at index %d is a \"%s\", a number was expected\n", index, getLuaTypeName(L, index)));
		value = cast(float)lua_tonumber(L, index);
	}
	else static if (is(T == string))
	{
		if (!lua_isstring(L, index))
			throw new Exception(format("Lua value at index %d is a \"%s\", a string was expected\n", index, getLuaTypeName(L, index)));
		value = to!(string)(lua_tostring(L, index));
	}
	else
	{
		throw new Exception(format("Lua value at index %d is a \"%s\", a number, boolean or string was expected\n", index, getLuaTypeName(L, index)));
	}
	return value;
}

void	valueToLua(T)(lua_State* L, T value)
{
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
			throw new Exception(format("Variant has type \"%s\", an int, double, bool or string was expected\n", value.type));
	}
	else static if (is(T == int))
		lua_pushinteger(L, value);
	else static if (is(T == float))
		lua_pushnumber(L, value);
	else static if (is(T == string))
		lua_pushstring(L, value.toStringz());
	else static if (is(T == bool))
		lua_pushboolean(L, value);
	else
	{
		static assert(false);
	}
}

unittest
{
	assert(getSignalNameFromPropertyName("mouseX") == "onMouseXChanged");
	assert(getSignalNameFromPropertyName("X") == "onXChanged");
	assert(getSignalNameFromPropertyName("x") == "onXChanged");

	assert(getPropertyNameFromSignalName("onMouseXChanged") == "mouseX");
	assert(getPropertyNameFromSignalName("onXChanged") == "x");
}
