module dquick.system.win32.setjmp;

version(Windows)
{
	version(X86)
	{
		enum _JBLEN = 64;
		static assert("not ready!");
	}
	else version(X86_64)
		enum _JBLEN = 256;
	else version(IA64)
		enum _JBLEN = 528;
	
	alias ubyte[_JBLEN] jmp_buf;

	extern(C)
	{
		int _setjmp(ref jmp_buf _Buf);
		void longjmp(ref jmp_buf _Buf, int _Value);
	}
	
	alias _setjmp setjmp;
}
