module dquick.utils.utils;

import std.stdio;

debug
{
	void	destructorAssert(bool expression, string message, Throwable.TraceInfo trace)
	{
		if (!expression)
		{
			writeln(message);
			if (trace !is null)
				foreach(t; trace)
					writefln("%s", t);
//			readln();
		}
	}
}
