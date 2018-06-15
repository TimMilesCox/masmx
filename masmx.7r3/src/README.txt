
        
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




Use no optimisation options. They go wrong and aren't needed



sparc
osx.ppc BINARIES SUPPLIED ../masmx.7r3/hosts/osx.ppc/

	gcc -m32 -funsigned-char -DSUPERSET -o ../masmx masm.c
        gcc -m32 -funsigned-char -o ../masmz masm.c



osx.x86 BINARIES SUPPLIED ../masmx.7r3/hosts/osx.x86

	gcc -m32 -funsigned-char -DINTEL -DSUPERSET -o ../masmx masm.c
        gcc -m32 -funsigned-char -DINTEL -o ../masmz masm.c



win32	BINARIES SUPPLIED ../masmx.7r3/hosts/win32/

	cl  /J /DMS /DMSW /Fe..\masmz masm.c
        cl  /J /DMS /DMSW /DSUPERSET /Fe..\masmx masm.c


640K.DOS
	bcc -K -N -mc -Z -DMS -DDOS -DSUPERSET -e..\masmx.exe -w- masm.c
        bcc -K -N -mc -Z -DMS -DDOS -e..\masmz.exe -w- masm.c


any x86 Linux
ubuntu	BINARIES SUPPLIED ../masmx.7r3/hosts/ubuntu.x86/

        gcc -m32 -funsigned-char -DINTEL -DSUSE -DSUPERSET -o ../masmx masm.c
        gcc -m32 -funsigned-char -DINTEL -DSUSE -o ../masmz masm.c


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



64-Bit Ubuntu
_____________


	REBUILDING on 64-BIT Ubuntu

	updating Ubuntu x86/32-bit programs on an x86/84-bit Ubuntu platform
	____________________________________________________________________

	masmx / masmz / imx / mmx are a suite of 32-bit programs
	rebuilding and running on 64-bit Ubuntu x86 may need some library updates 

	It's neither necessary nor advisable to change the masmx suite to
	64-bit programs. long integers would need changing to default-size
	integers in hundreds of declarations

	masmx 32-bit resolves 192-bit number expressions

	These library updates will enable gcc to compile 32-bit

	        $ sudo apt-get install gcc-multilib
        	$ sudo apt-get install libc6-dev:i386 gcc:i386

	Then of course use the 32-mit machine option as always to build

        	$ masmx -m32 -funsigned-char -DINTEL -DSUSE -DSUPERSET -o $UBUNTU32_X86/masmx masm.c

	All Linux builds need the SUSE switch


	RUNNING on 64-BIT Ubuntu
	________________________

	running Ubuntu x86/32-bit applications on x86/64-bit Ubuntu platforms
	_____________________________________________________________________

	some library must be added to make this possible

	        $ sudo dpkg --add-architecture i386
        	$ sudo apt-get update
	        $ sudo apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386



To test Unix / Linux builds
___________________________

$ cd ../test.msm
$ ../script
$ diff -w --brief ../result.txo ../test.o3
$ pushd ../test.dds/2r1
$ ./script
$ cd ../1r45p
$ ./script
$ popd
$ ../zscript
$ diff -w --brief ../result.zo3 ../test.zo3

The materials are packed together on OSX which implements chmod
flags somehow differently from Ubuntu (or the memory stick does).
You may need to permit these files before you can test on Linux
or maybe on all non-Darwin Unix

$ chmod 0755 ../script
$ chmod 0755 ../zscript
$ chmod 0755 ../test.dds/2r1/script
$ chmod 0755 ../test.dds/1r45p/script
$ chmod 0755 ../linkpart
$ chmod 0755 ../test.map/mverify
$ chmod 0755 ../test.map/zferify
$ chmod 0755 ../test.gcc/dothis
$ chmod 0755 ../trabble/trabble
$ chmod 0755 ../aside.dem/sgen
$ chmod 0755 bojo
$ chmod 0755 ../coldire
$ chmod 0755 ../ppc_kern

If you copy in the Ubuntu binaries you may even need to permit those
on the Ubuntu platform

$ pushd masmx.3r1/masmx.3r1/hosts/ubuntu.x86
$ chmod 0755 masmx
$ chmod 0755 mmx
$ chmod 0755 imx
$ chmod 0755 masmz
$ popd


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



