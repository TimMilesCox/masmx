
    copyright Tim Cox, 2015
    TimMilesCox@gmx.ch

    This file is part of masmx.7r3

    mamsx.7r3 is a target-independent meta-assembler for all
    architectures

    masmx.7r3 is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    mamsx.7r3 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with masmx.7r3.  If not, see <http://www.gnu.org/licenses/>.

    __________________________________________________________________






_______________________________________________________________________________
This is the freeware code and tests tree
masmx.7r3 documentation and downloads are at http://timmilescox.github.io/masmx
_______________________________________________________________________________







masmx.7r3
_________

masmx.7r3 is a target-indendent meta-assembler for any target
It is used by writing a file of macro code for defining the
target architecture and including that in your source or in
a wrapper which also includes your source

masmx.7r3 runs from shell commmand lines

masmx.7r3 macro language can understand source code syntaxes meant
for other assemblers



Building or just Using
______________________


The documentation proper is three directories down from here, in

        masmx/masmx.7r3/masmx.7r3/doc

and	http:/TimMilesCox.github.io/masmx/masmx.html

If you just want to use masmx.7r2 and the binary for your machine
is already here, then you only need the second tree below this one

        masmx/masmx.7r3/masmx.7r3/

which contains

        doc/    hosts/  targets/

The ready-made binaries are in

	hosts/ubuntu.x86
	hosts/osx.x86
	hosts/osx.ppc
	hosts/win32



hosts contains the binaries and targets contains some macro language
for target architectures

Downloads
_________

The downloads page for everything is

	http:/TimMilesCox.github.io/masmx/

There are a download for binaries and manuals
and a much larger download for build and test


Building and Testing
____________________


	masmx/masmx.7r3/src/README.txt

has some information about building and asmx.7r3 for new targets

