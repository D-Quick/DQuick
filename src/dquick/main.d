module dquick.main;

version (unittest)
{
	import std.stdio;

	int main(string[] args)
	{
		writeln("Press Enter to quit.");
		readln();
		return 0;
	}
}
