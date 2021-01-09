
        
/******************************************************************

                Copyright Tim Cox, 2015

                TimMilesCox@gmx.ch                       
        
        This document is guidance on building the masmx.7r3         
        target-independent meta-assembler
                                                       
        The masmx.7r3 meta-assembler is free software licensed
        with the GNU General Public Licence Version 3                
        
        The same licence encompasses all accompanying software 
        and documentation
                                                     
        The full licence text is included with these materials                         
        
        See also the licensing notice at the foot of this document                   
        
*******************************************************************/





This is the practical note for building masmx
_____________________________________________


masmz is a minor set without SUPERSET. It was at one time
different in implementation and performed slightly differently,
but now the implementation masmx / masmz is uniform and simplified

masmz does not have structures or target runtime algorithm generator

masmz was the only version small enough for 640K DOS, but there
has been no recent opportunity to build or test on any kind of DOS
and the masmz minor set has probably grown too large for bcc -mc
(memory model compact). Any larger bcc memory model would swamp 640K
before any labels were buffered. Code would also need revision

INTEL means only, this is a little-endian platform. Mostly they are,
and are actually Intel. All Microsoft platforms are assumed to be
"INTEL", i.e. little-endian

Two platforms are big-endian, OSX for PowerPC and SPARC / Solaris
Binaries are supplied for osx.ppc
There has been no recent opportunity to build and test for SPARC



Easy to Use Build Scripts
_________________________

Directory src now has scripts for constructing updated masmx and masmz
on and for platforms osx.x86 osx.ppc ubuntu.x86 win32

	./bosx86
	./bosx64
	./ppcbosx
	./bsuse
	./bsuse.x64 
	./bw32

These builds all use the same source which is portable between 64-bit and 32-bit targets
The builds conclude by telling you how to run the test suites

The following calls are used for platforms and compiler systems which
have so far constructed masmx

	-DINTEL	is necessary for any little endian target
		whether similar to x86 or quite different like ARM

		INTEL switch indicates a byte-swapping platform data bus

		options for Microsoft MS assert INTEL automatically

	-DSUSE	is necessary for any clang compiler system to avoid a function name clash readline()

	unsigned char is necessary
	unsigned char options on platforms so far are
	
		-funsigned-char		gcc
		-K			bcc	Borland
		/J			cl	Microsoft

Use no optimisation options. They go wrong and aren't needed

The compile lines known so far are


sparc
osx.ppc BINARIES SUPPLIED ../masmx.7r3/hosts/osx.ppc/

	gcc -m32 -funsigned-char -DSUPERSET -o ../masmx masm.c
        gcc -m32 -funsigned-char -o ../masmz masm.c



osx.x86 BINARIES SUPPLIED ../masmx.7r3/hosts/osx.x86

	gcc -m32 -funsigned-char -DINTEL -DSUPERSET -o ../masmx masm.c
        gcc -m32 -funsigned-char -DINTEL -o ../masmz masm.c

osx.x64_64 BINARIES SUPPLIED ../masmx.7r3/hosts/osx.x¨64

	gcc -m32 -funsigned-char -DINTEL [-DSUSE] -DSUPERSET -o ../masmx masm.c
	gcc -m64 -funsigned-char -DINTEL [-DSUSE] -o ../masmz masm.c

	recent compilers are clang and [-DSUSE] is needed
	to avoid function name clash readline()

win32	BINARIES SUPPLIED ../masmx.7r3/hosts/win32/

	cl  /J /DMS /DMSW /Fe..\masmz masm.c
        cl  /J /DMS /DMSW /DSUPERSET /Fe..\masmx masm.c


640K.DOS
	bcc -K -N -mc -Z -DMS -DDOS -DSUPERSET -e..\masmx.exe -w- masm.c
        bcc -K -N -mc -Z -DMS -DDOS -e..\masmz.exe -w- masm.c


any x86 Linux
suse	BINARIES SUPPLIED ../masmx.7r3/hosts/suse.x86/

        gcc -m32 -funsigned-char -DINTEL -DSUSE -DSUPERSET -o ../masmx masm.c
        gcc -m32 -funsigned-char -DINTEL -DSUSE -o ../masmz masm.c

any x86_64 Linux
suse	BINARIES SUPPLIED ../masmx.7r3/hosts/suse.x64/

	gcc -m64 -funsigned-char -DINTEL -DSUSE -DSUPERSET -o ../masmx masm.c
	gcc -m64 -funsigned-char -DINTEL -DSUSE -o ../masmz masm.c

There are five binaries for each platform
_________________________________________

	masmx	masmz	mmx	imx	symbol

The sources of mmx, imx and symbol are in this directory src/

mmx and imx are s_record format converter and i_record format converter

For Microsoft
_____________

bcc -K -DDOS -e..\mmx.exe mmx.c
cl /J /DDOS /Fe..\mmx.exe mmx.c

bcc -K -DDOS -e..\imx.exe imx.c
cl /J /DDOS /Fe..\imx.exe imx.c


For any Unix or Linux
_____________________

gcc -m32 -funsigned-char -o../mmx mmx.c
gcc -m32 -funsigned-char -o../imx imx.c




There are no endian issues in mmx or imx. Keyword DOS concerns C header includes




symbol utility build for all platforms
______________________________________

symbol extracts exported names from assembly output txo files
in order to capture the names and values as environmental variables

symbol command line is in the release note rel_note.txt

build for POSIX systems is

        gcc -m32 -funsigned-char -o $MASMX_BINARY_PATH/symbol symbol.c

build for MS Windows is

        cl /J /Fe%MASMX_BINARY_PATH%\symbol symbol.c



64-Bit Linux
_____________


	Running on 64-BIT Linux

	32-bit and 64-bit binaries are supplied

	some 64-bit linux distros need extra ibrary download to run any 32-bit binary

	however 64-bit openSUSE does not appear to have any problems with 32-bit binaries

	building the masmx binaries for Linux uses the same source code for 32-bit and 64-bit

	updating Ubuntu x86/32-bit programs on an x86/84-bit Ubuntu platform

	Linux seems to have clang compiler suite as standard
	so -DSUSE switch is always needed to avoid function name clash readline()

	on some Linux distros you need to re-enable a lot of scripts for build and test

	of for any reason it becomes necessary to regenerate and retest
	the openSUSE-generated binaries on Ubuntu

	the build script bubuntu which displays a list of scripts you need to re-enable

	src $ cat bubuntu

	echo this should be ubuntu.x86

	gcc -m32 -funsigned-char -DINTEL -DSUSE -DSUPERSET -o ../masmx masm.c
	gcc -m32 -funsigned-char -DINTEL -DSUSE -o ../masmz masm.c
	cp ../masmx ../masmx.7r3/hosts/ubuntu.x86
	cp ../masmz ../masmx.7r3/hosts/ubuntu.x86
	cp ../masmx.7r3/hosts/ubuntu.x86/imx ..
	cp ../masmx.7r3/hosts/ubuntu.x86/mmx ..
	echo	cd ../test.msm
	echo	chmod 0755 ugo
	echo	run ./ugo
	echo	run ./alltests

	src $ cd ../test.msm
	test.msm $ cat ugo

	chmod 0755 alltests
	chmod 0755 ../script
	chmod 0755 ../zscript
	chmod 0755 ../test.dds/2r1/script
	chmod 0755 ../test.dds/1r45p/script
	chmod 0755 ../linkpart
	chmod 0755 ../test.map/mverify
	chmod 0755 ../test.map/zferify
	chmod 0755 ../test.gcc/dothis
	chmod 0755 ../trabble/trabble
	chmod 0755 ../aside.dem/sgen
	chmod 0755 bojo
	chmod 0755 ../coldfire
	chmod 0755 ../ppc_kern
	chmod 0755 ../imx
	chmod 0755 ../mmx

Testing on win32
________________

 cd test.msm
 ..\w32.bat\script
 fc /L /W ..\result.txo\* ..\test.txo\* > ..\diff1
 pushd ..\test.dds\2r1
 script
 cd ..\1r45p
 script
 popd
 ..\w32.bat\zscript
 fc /L /W ..\result.zo3\* ..\test.zo3\* > ..\diff2



/**************************************************************************


LICENCE NOTE

    Copyright Tim Cox, 2015
    TimMilesCox@gmx.ch

    This document is guidance on building the masmx.7r3
    target-independent meta-assembler.

    masmx.7r3 is free software. It is licensed
    under the GNU General Public Licence Version 3

    You can redistribute it and/or modify masmx.7r3
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    masmx.7r3 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with masmx.7r3.  If not, see <http://www.gnu.org/licenses/>.

*************************************************************************/



