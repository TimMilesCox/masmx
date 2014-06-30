
/*************************************************************************
	gcc -m32 -funsigned-char -DSUPERSET -o masmx masm.c
	gcc -m32 -funsigned-char -o masmz masm.c
	gcc -m32 -funsigned-char -DINTEL -DSUPERSET -o masmx masm.c
	gcc -m32 -funsigned-char -DINTEL -o masmz masm.c
        cl masm.c /J /DMS /DMSW (copy masm.exe to masmz.exe)
	cl masm.c /J /DMS /DMSW /DSUPERSET (copy masm.exe to masmx.exe)
	bcc -K -N -mc -Z -DMS -DDOS -DSUPERSET -emasmx.exe -w- masm.c
	bcc -K -N -mc -Z -DMS -DDOS -emasmz.exe -w- masm.c
	bcc -K -N -mc -Z -DMS -DDOS -DDOS_LINKER -elink7.exe -w- masm.c
	gcc -m32 -funsigned-char -DINTEL -DSUSE -DSUPERSET -o masmx masm.c
	gcc -m32 -funsigned-char -DINTEL -DSUSE -o masmz masm.c
 ***********************************************************************/


#define ESC 7
#undef	WALKP
#define BLOCK 4096
#define DEEP_RECURS	7
#undef	UNREF
#define LEVELUP
#define PREVENTION
#define ABOUND
#define SLIPGUARD
#define USING_NO_REL
#undef	TRACE_RECURS
#undef	TRACE_STORAGE_BRANCH
#define GEOMETRIC_FUNCTIONS
#define	QUI_TUPLE
#define	TIGHTER
#define	ROUNDING
#define CLEATING
#define CODED_EXPRESS

#ifdef	SUPERSET
#else
#ifndef	DOS
#define	BLOCK_WRITE 2048
#endif
#endif

#undef	TRAILING_POINTER
#define BASIC_SCAN

#define	FILE_ARGUMENTS	2

#define STACKED_XPRESS
#undef	BACKSLASH_FUN
#define STACK_TOP_VALUE	NULL
#define	STACK_TOP_CLEAR (char *) 0xFFFFFFFF

#define LITERALS
#define PRINTBYREAD
#define	QNAMES
#undef	LOOKFOR
#define	IN_EQUATE
#define	GBASIS
#define	REVISE_UNARY
#define DRIFT_GUARD_1
#define	EFLAG
#define	XTENDA

		/********Developer Platform may be Intel even when Unix*/

#ifdef	MS	/********Developer Platform MS**************************/

#define INTEL

#ifdef	DOS	/********Developer Platform DOS*************************/

#define OFLAG '-'
#define PATH_SEPARATOR '\\'
#define OBIN "temp.txo"
#define OSYM "temp.msm"

#include <fcntl.h>
#include <stdio.h>
#include <alloc.h>
#include <io.h>
#include <sys/stat.h>
#include <mem.h>
#include <string.h>
#include <stdlib.h>

#define	malloc	farmalloc

#ifdef DOS_LINKER
extern unsigned _stklen = 1024*60;
#else
extern unsigned _stklen = 32*1024;
#endif

#endif	/*****************endif DOS**************************************/

#ifdef MSW	/*********MS Windows*************************************/

#define OFLAG '-'
#define PATH_SEPARATOR '\\'
#define OBIN "temp.txo"
#define OSYM "temp.msm"

#include <fcntl.h>
#include <stdio.h>
#include <malloc.h>
#include <io.h>
#include <sys/stat.h>
#include <string.h>
#include <stdlib.h>

#endif	/******************endif MS Windows******************************/

#else	/******************otherwise Unix(not MS)************************/ 


#ifdef	OSX
#define COOL 300000
#endif

#define OFLAG '-'

#ifdef	DJGPP
#define	PATH_SEPARATOR '\\'
#else
#define PATH_SEPARATOR '/'
#endif

#define OBIN "temp.txo"
#define OSYM "temp.msm"

#include <fcntl.h>
#include <sys/stat.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>

#endif	/***************** End of Developer Platform choices ************/

#ifdef SUSE
#define getline getaline
#endif

#define	LINEAR
#define	TEST_B4
#define C_U

#define	ROUND2
#define	ROUND3

#ifdef	SUPERSET

#define RADIX 192

#ifdef	DOS
#define	RELOCATION
#else
#define	RELOCATION
#endif

#undef	PROCLOC_ASIDE

#undef	RESOLVE_ULTRA
#define	ULTRA_RESOLVE

#undef	RANGE_WARNING

#define	STRUCTURE_DEPTH 8

#else			/*	SUPERSET	*/

#define RADIX 192

#ifdef	DOS
#define	RELOCATION
#define	VERY_STACKED_XPRESSION
#else
#define	RELOCATION
#endif

#undef	PROCLOC_ASIDE

#undef	RESOLVE_ULTRA
#define	ULTRA_RESOLVE

#undef	STRUCTURE_DEPTH 8

#endif			/*	SUPERSET	*/

#define RECURSION 24
#define AUTOMATIC_LITERALS
#define OVERLAY_LITERALS
#define VERSION	"7"

#ifdef	SUPERSET
#define REVISION "3"
#else
#define REVISION "3Z"
#endif

#define	DISPLAY_Q
#define ARRAY 8

#define DPA 24

#define	DISPLAY_V
#define IMAGE_SIZE 2048
#define READSIZE 2048
#define DISPLAY_WIDTH 160
#define	FUNCTION_SYMBOLS 2040

#define OCTALPRINT

#define XPRESSION 64
#define MAPSTACK RECURSION
#define PROMOTE_UNARY
#define LROOT
#define FILENAME_LIMIT 64
#define INCLUDE_MAXDEPTH 12

#undef	LEADING_EDGE
#undef	DISPLAY_F

#ifdef	DOS
#define HASH	4096
#else
#define HASH	65536
#endif

#define PARAGRAPH 4
#define MARGIN 4
#define PARAGRAPH_LOG 2

#ifdef	DOS
#define BANK 32768
#else
#define BANK 262144	/* 65536 */
#endif

#define BANKS 64

#define CACHE_IMAGE

#ifdef INTEL
#define DISPLAY_ATTRIBUTE(p, x)    printf("[%2.2x%2.2x%2.2x%2.2x]",	\
                                              p->b[RADIX/8-4 * x],	\
                                              p->b[RADIX/8-4*x+1],	\
                                              p->b[RADIX/8-4*x+2],	\
                                              p->b[RADIX/8-4*x+3]);
#else

#define DISPLAY_ATTRIBUTE(p, x)                  printf("[%8.8lx]",	\
                                                 p->i[RADIX/32-x]);

#endif

#include "data.c"
#include "csynonym.c"
#include "proto.c"
#include "xamine.c"
#include "flag.c"
#include "quadd_u.c"
#include "xi.c"
#include "loadname.c"
#include "lqualif.c"

#include "ltrailer.c"
#include "innode.c"

#include "hash.c"
#include "buytable.c"
#include "insertl.c"
#include "iqltable.c"

#include "outputs.c"
#include "display.c"

#include "isanequf.c"
#include "paraform.c"
#include "xparam.c"
#include "literal.c"

#include "binary.c"
#include "ilabels.c"
#include "fpxpress.c"
#include "espresso.c"
#include "core.c"
