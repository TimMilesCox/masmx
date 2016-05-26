REBUILDING on 64-BIT

updating Ubuntu x86/32-bit programs on an x86/84-bit Ubuntu platform
____________________________________________________________________

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


RUNNING on 64-BIT
_________________

running Ubuntu x86/32-bit applications on x86/64-bit Ubuntu platforms
_____________________________________________________________________

some library must be added to make this possible

	$ sudo dpkg --add-architecture i386
	$ sudo apt-get update
	$ sudo apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386

