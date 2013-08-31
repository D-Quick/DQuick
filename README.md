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

Platforms
====

All platforms have a chance to be supported one day due to the code design choices.
DQuick should work everywhere D is supported, it requires only few additionnal librairies :
 - Lua (will be removed the day it can be replaced by D)
 - FreeType (strongly portable, hard to display texts without it)
 - SDL (temporary as isn't really adapted to window applications, there is some resize issues)
 - SDL_IMAGE (temporary)
 - libpng (will replace SDL_IMAGE, strongly portable)
 - libjpeg (will replace SDL_IMAGE, strongly portable)

To do the SDL replacement we'll use native OS API to create windows and handle events.

Stutas of plaforms :
 - Windows (Main target, native code migration started)
 - Linux (Second target, under SDL, we think to use xcb)
 - MacOS X (Not tested, but we have experience)
 - Android (Not tested, experience, it seems D compilers aren't not ready)
 - iOS (Not tested, experience, it seems D compilers aren't not ready)


How to build
===

Linux (MonoD)
 - install monoD (http://mono-d.alexanderbothe.com/)
 - pull source code
 - go to third-party/SDL-2.0.0
 - build SDL : run './configure; make; sudo make install'
 - go to third-party/SDL_Image-2.0.0
 - you need install libpng-dev, libjpeg-dev
 - build SDL_Image : run './autogen.sh; ./configure; make; sudo make install'
 - launch monoD and open the solution (DQuick-MonoD.sln)

Windows
 - install VisualD
 - pull source code
 - luanch Visual Studio and open the solution (DQuick-VisualD.sln)
