DQuick
======

A GUI library written in D.

You may want take a look at D programming language official web site : dlang.org
and to the framework that inspired us (QtQuick) :
http://blog.qt.digia.com/blog/2013/06/21/overview-of-the-new-features-in-qt-quick/

We are using Lua as scripting language instead of javascript, cause there is no C javascript engine. And a non JIT
interpreter is prefered for some platforms (iOS).

Take a look to the DQuick.pptx for more details.

Status
====

It's currently a simple prototype, don't expect to see something working fine a day.

How to build
===

Linux (MonoD)
	1. install monoD (http://mono-d.alexanderbothe.com/)
	2. pull source code
	3. go to third-party/SDL-2.0.0
	4. build SDL : run './configure; make; sudo make install'
	5. go to third-party/SDL_Image-2.0.0
	6. you need install libpng-dev, libjpeg-dev
	7. build SDL_Image : run './autogen.sh; ./configure; make; sudo make install'
	8. launch monoD and open the solution (DQuick-MonoD.sln)

Windows
	1. install VisualD
	2. pull source code
	3. luanch Visual Studio and open the solution (DQuick-VisualD.sln)
