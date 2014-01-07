module dquick.utils.utils;

import std.stdio;

debug
{
	void	destructorAssert(bool expression, string message, Throwable.TraceInfo trace)
	{
		if (!expression)
		{
			writeln(message);
			readln();
		}
	}
}
