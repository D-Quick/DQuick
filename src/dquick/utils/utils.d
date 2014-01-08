module dquick.utils.utils;

import std.stdio;

debug
{
	void	destructorAssert(lazy bool expression, lazy string message)
	{
		if (!expression)
		{
			writeln(message);
			readln();
		}
	}
}
