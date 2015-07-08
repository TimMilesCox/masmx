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


There are four binaries for each platform
_________________________________________

	masmx	masmz	mmx	imx

The sources of mmx and imx are in this directory src/

They are s_record format converter and i_record format converter

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

There are no endian issues in mmx or imx. Keyword DOS conerns C header includes


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


