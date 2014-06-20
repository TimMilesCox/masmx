
    copyright Tim Cox, 2012
    TimMilesCox@gmx.ch

    This file is part of masmx.7r2

    mamsx.7r2 is a target-independent meta-assembler for all
    architectures

    masmx.7r2 is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    mamsx.7r2 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with masmx.7r2.  If not, see <http://www.gnu.org/licenses/>.

    __________________________________________________________________



masmx.7r2
_________

masmx.7r2 is a target-indendent meta-assembler for any target
It is used by writing a file of macro code for defining the
target architecture and including that in your source or in
a wrapper which also includes your source

masmx.7r2 runs from shell commmand lines

masmx.7r2 macro language can understand source code syntaxes meant
for other assemblers


Building or just Using
______________________


The documentation proper is two directories down from here, in

        masmx/masmx.7r2/masmx.7r2/doc

If you just want to use masmx.7r2 and the binary for your machine
is already here, then you only need the tree below this one

	masmx/masmx.7r2/masmx.7r2/

which contains

	doc/	hosts/	targets/

hosts contains the binaries and targets contains some macro language
for target architectures

*******************************************************************
NOTE. The binaries masmx masmz mmx imx in this directory may not be
the ones for your platform

Put one of these in your path

	masmx/masmx.7r2/masmx.7r2/hosts/ubuntu.x86/
	masmx/masmx.7r2/masmx.7r2/hosts/osx.x86/
	masmx/masmx.7r2/masmx.7r2/hosts/osx.ppc/
	masmx/masmx.7r2/masmx.7r2/hosts/win32/

******************************************************************


Building
________

You have all this code and these test suites so that you can build
masmx.7r2 for a target which has no binary in this package

Or in case you want to make changes

********************************************************************

NOTE. The test suites use the binaries in this directory

	masmx/masmx.7r2

They may not be the binaries for your platform

put your new binaries in this directory for test

	masmx/masmx.7r2/src$ gcc -m32 -funsigned-char		\
				-DINTEL -DSUPERSET		\
				-o ../masmx masm.c

all the supplied binaries are in

	masmx/masmx.7r2/masmx.7r2/hosts

*********************************************************************

If you build for a new target, the test suites are explained at the
end of this document

Here are the instructions for building masmx/masmx.7r2/src


        #       for big-endian Linux, SPARC and OSX targets

        gcc -m32 -funsigned-char -DSUPERSET -o masmx masm.c
        gcc -m32 -funsigned-char -o masmz masm.c


        #       for little-endian Linux/x86, Solaris/x86 and OSX-Intel
        #       (or ARM) targets

        gcc -m32 -funsigned-char -m32 -DINTEL -DSUPERSET -o masmx masm.c
        gcc -m32 -funsigned-char -m32 -DINTEL -o masmz masm.c


        #       for Windows32

        cl masm.c /J /DMS /DMSW /E masmz.exe
        cl masm.c /J /DMS /DMSW /DSUPERSET /E masmx.exe


        #       for 640K DOS

        bcc -K -N -mc -Z -DMS -DDOS -emasmz.exe -w- masm.c

        #       for Debian and Suse add the -DSUSE flag
        #       and for Delorie gcc for extended memory DOS

        gcc -m32 -funsigned-char -DINTEL -DSUSE -DSUPERSET -o masmx masm.c
        gcc -m32 -funsigned-char -DINTEL -DSUSE -o masmz masm.c


masmx contains its own linker (or generates absolute code in the first place)

Output from masmx is Text Encoded Binary (*.txo)

Absolute .txo files can be formatted with utilites imx (iRecord 16-bit address)
and mmx (S-Record 32-bit address). You have the source of those in case you
want different iRecord and S-Record variants (i.e. different address sizes)

	masmx/masmx.7r2/util.src/

	gcc -m32 -funsigned-char [-DINTEL] -o mmx mmx.c

	cl /J /DDOS /E mmx.exe mmx.c
	bcc -K -DDOS -emmx.exe mmx.c


	gcc -m32 -funsigned-char [-DINTEL] -o imx imx.c

	cl /J /DDOS /E imx.exe imx.c
	bcc -K -DDOS -eimx.exe imx.c



Testing
_______


	cd test.msm
	../script
	diff -w --brief ../result.txo ../test.o3

	pushd ../test.dds/2r1
	./script
	cd ../1r45p
	./script
	popd

	../zscript
	diff -w --brief ../result.zo3 ../test.zo3



Adding Features
_______________


If you write a new feature, place your test assembly source in

	masmx/masmx.7r2/test.msm/

and add a line to

	masmx/masmx.7r2/script
	masmx/masmx.7r2/zscript

to include it in the tests. The difference is, zscript doesn't
opt -y for sorted label table, and also uses the less-featured
masmz, which doesn't have label hierarchy directives

	$tree	$branch	$root

The purpose of the smaller masmz is to build for 640K DOS
