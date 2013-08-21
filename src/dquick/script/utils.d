module dquick.script.utils;

import std.regex;
import std.string;

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

unittest
{
	assert(getSignalNameFromPropertyName("mouseX") == "onMouseXChanged");
	assert(getSignalNameFromPropertyName("X") == "onXChanged");
	assert(getSignalNameFromPropertyName("x") == "onXChanged");

	assert(getPropertyNameFromSignalName("onMouseXChanged") == "mouseX");
	assert(getPropertyNameFromSignalName("onXChanged") == "x");
}
