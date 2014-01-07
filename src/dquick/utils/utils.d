module dquick.utils.utils;

import std.stdio;

void	destructorAssert(bool expression, string message)
{
	debug
	{
		if (!expression)
		{
			writeln(message);
			readln();
		}
	}
}
