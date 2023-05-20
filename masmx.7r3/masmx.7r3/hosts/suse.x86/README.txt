hosts/suse.x86:  32-Bit Linux executables
_________________________________________

These 32-bit programs are built and run on
64-bit SUSE

They should run on any Linux platform which
allows 32-Bit programs to run

If there is any 64-bit Linux platform where
they don't run, you may need some additional runtime library

On 64-Bit SUSE the following two installation commands
allow these programs both to build and to run

	sudo zypper rm gcc
	sudo zypper in gcc-32bit

64-bit SUSE also executes 32-bit programs built
years ago on 32-Bit Ubuntu, but this may mean some
necessary runtime was obtained along with gcc-32bit

For help TimMilesCox@gmx.ch

