
/******************************************************************

                Copyright Tim Cox, 2015

                TimMilesCox@gmx.ch

        This source code is part of the masmx.7r3
        target-independent meta-assembler

        The masmx.7r3 meta-assembler is free software licensed
        with the GNU General Public Licence Version 3

        The same licence encompasses all accompanying software
        and documentation

        The full licence text is included with these materials

        See also the licensing notice at the foot of this document

*******************************************************************/





#define UNDEFINED	0		/* label not in this assembly	*/
#define EIGHT		8

#define LOCATION	127		/* automatic label type		*/

#define FORM			59	/* directive name + label type	*/
#define PROC			1	/* directive name + label type	*/
#define NAME 2				/* directive names		*/
#define END 3
#define DO 4
#define IF 6
#define ELSE 7
#define ELSEIF 8
#define ENDIF 9
#define FLAGF 10
#define NOTEF 11
#define INCLUDE 12
#define FUNCTION		13	/* directive name + label type */
#define EXIT 14
#define EQU			16	/* directive name + label type */
#define SET			17	/* directive name + label type */
#define DATA_CODE 20
#define ASCII 21
#define WORD 25
#define BYTE 26
#define RETURN 27
#define LIST 28
#define	PATH	29
#define PLIST	30

#define RES 34

#define LITS 123
#define SNAP 40
#define QUANTUM 41
#define LWIDTH 42
#define AWIDTH 43
#define LTERM 44
#define STERM 45
#define TWOSCOMP 47
#define CONT_CHAR 48
#define FLAG 51
#define FLOATING_POINT 52
#define CHARACTERISTIC 53
#define QUOTEC 54
#define TRACE 57
#define NOTE 58
#define	NOP 60
#define SUFFIX 61

#ifdef	STRUCTURE_DEPTH
#define	BRANCH 63
#endif

#define OCTAL 65
#define HEX 66
#define EQUF			67	/* directive name + label type	*/
#define INFO 68				/* directive names		*/
#define SET_OPTION 69

#ifdef	STRUCTURE_DEPTH
#define TREE 70
#define ROOT 71
#endif

#define	SYM 75
#define	LOAD 76

#define PART_EQUF

#ifdef RELOCATION
#define OFFSET			1
#define BINARY			250	/* label type */
#define VOID			248
#define	LONG_ABSOLUTE		220
#define XREFS			1024

#define MULTUPLES
#define RANGE_FLAGS		2
#define RANGE_FLAGS1		3

#endif

#ifdef	BINARY
#define	PUSHREL	77			/* directive */
#endif

#define BLANK   78
#define STORE	79

#ifdef	SUPERSET
#define	FP_XPRESS 80
#define	ESPRESSO  81
#endif

#ifdef	STRUCTURE_DEPTH
#define	RECORD	82
#define	RECORD_BRANCH
#endif

#define ZERO_CODE_POINT	91

#define LABEL 'L'                      /* 0x4c = 76 */
#define TEXT_SUBSTITUTE 'S'            /* 0x53 = 83 */
#define TEXT_IMAGE 'T'                 /* 0x54 = 84 */
#define BYPASS_RECORD 'Z'              /* 0x5A = 90 */
#define BREAKPOINT 'B'		       /* 0x42 = 66 */
#define VALUE 'V'		       /* 0x56 = 86 */
#define XREF 'X'		       /* 0x58 = 88 */

#define INTERNAL_FUNCTION	125

#define DIRECTIVE		126
#define FILE_LABEL		124
#define LTAG			LITS	/* 123				*/

#define LOCTR 0				/* internal function names	*/
#define PNAME 1

#define REGION 6
#define LITERAL 7
#define TYPE 8
#define OPTION 9
#define REL 10
#define NET 11
#define	SYNONYMS 12
#define TOP_SYNONYMS 13
#define CHILD_SYNONYMS 14
#define TOP_CHILD_SYNONYMS 15
#define	SIMPLE_BASE 16
#define	ABSOLUTE 17
#define	BANK_INDEX 18
#define	ZENITH	4040

#ifdef	BINARY
#define	LONG_TRAILER
#define	LOAD_LONG
#endif

#define LOCATORS 72

#define PROCLOC

#ifdef	DOS

#undef	BINARY
#undef	VOID
#undef	LOAD
#undef	LONG_ABSOLUTE
#define	VERY_STACKED_XPRESSION

#define	LONG_TRAILER
#undef	INFO

#endif

#define	DEFAULT_ZERO_CODE_POINT	0x00002700
#define	AQUARTETS		12

typedef struct {  char			   flag[26]; } flag_box;

typedef union  {  unsigned int                   i;
		  struct { char              y;
			   char            rel;
			   short          xref; } l; } linkage;

typedef struct { char                  type, length; } header_word;

typedef union  {   unsigned char         b[RADIX/8];
		   unsigned short       h[RADIX/16];
		   int                 i[RADIX/32]; } line_item;

typedef struct { line_item		      upper,
					      lower; } shift_matrix;

typedef struct { char  type,length, passflag,valued;
		 linkage                          r;

                                        #ifdef HASH
		 void			  *hashlink;
                                             #endif

                                      #ifdef BINARY
		 void			      *link;
                                             #endif

		 void                        *along, 
					      *down;
		 line_item                    value;
		 char               name[PARAGRAPH]; } label;

typedef struct { char                  type, length;
		 unsigned short                next; } bdlink;

typedef struct { char type,length,text[PARAGRAPH-2]; } textline;

typedef struct { char                     type, rel;
                 unsigned short             oblong;   
		 void                       *along;
		 int                           loc;
		 unsigned short       symbols, bits;
		 char                 d[IMAGE_SIZE]; } txo;

#define	TXO_HEADER	sizeof(txo) - IMAGE_SIZE
   
typedef struct { char                  type, length;
                 unsigned short              oblong;
                 void                        *along;
                 int                          base; } breakpoint;

typedef struct { char                  type, length;
                 unsigned short             oblong;
                 unsigned int               offset;
                 line_item                    value; } value;

typedef struct { char                  type, length;
                 short                         xref;
                 void                        *along;
                 char               name[PARAGRAPH]; } xref;

typedef union  { header_word                      h;
                 unsigned int			  i;
		 label                            l;
		 bdlink                     nextbdi; 
		 txo                              u;
                 breakpoint                       b;
		 textline                         t;
                 xref                             x;
                 value                            v; } object;

typedef struct { char                  b[PARAGRAPH]; } paragraph;

typedef struct { unsigned short        ready, count;
                 char                 *image[ARRAY]; } array;

typedef struct { unsigned short        ready, count;
                 array                 field[ARRAY]; } atree; 

#ifdef XREFS

typedef struct { int                base[LOCATORS]; } segment_base_array;

typedef struct { segment_base_array        segments;
                 object       *pointer_array[XREFS]; } xref_list;

#endif

typedef struct { char		     base[LOCATORS]; } touch_table;

#define BAD_PARAFORM	0
#define COMPLETE_LINE	1
#define ALL_FIELDS	2
#define	FIELDS		7
#define	FIELD		3
#define SUBFIELD	4
#define STAR_SUBFIELD	4+128
#define HASH_SUBFIELD	4+64
#define	SUBSTRING	5
#define STAR_OR_HASH_	128+64
#define STAR__		128
#define HASH__		64


typedef struct { char level,field,subfield,sustring; } paraform_code;

typedef struct { short                        scale;   
		 char              slice, recursion;
		 linkage                          m; } link_profile;

typedef struct { short                        scale;
                 char                     offset[6]; } link_offset;

#ifdef BLOCK

typedef struct { unsigned short                r, w;
                 char                      d[BLOCK]; } rcb;

#endif
   
#ifdef QUI_TUPLE

typedef struct { char		*name;
		 int		value;
		 int		 type; } qui_tuple;


#endif

#define	OPERATORS 19

#if	OPERATORS == 17

enum	{	UNEQUAL, EQUAL, GREATER, LESS,
		REMAINDER, COVERED_QUOTIENT, SHIFT_RIGHT, DIVIDE,
		AND, SHIFT, EXPONENT_PLUS, EXPONENT_MINUS,
		MULTIPLY, XOR, MINUS, OR, PLUS } ;

static char ufield[] = {	sizeof("^=")   - 1,	sizeof("=") - 1,
				sizeof(">")   - 1,	sizeof("<")  - 1,
				sizeof("///") - 1,	sizeof("//") - 1,
				sizeof("/*")  - 1,	sizeof("/")  - 1,
				sizeof("**")  - 1,	sizeof("*/") - 1,
				sizeof("*+")  - 1,	sizeof("*-") - 1,
				sizeof("*")   - 1,	sizeof("--") - 1,
				sizeof("-")   - 1,	sizeof("++") - 1,
				sizeof("+")   - 1			  } ;

   static char *o[] = { "^=",
			"=",
			">",
			"<",
			"///",
			"//",
			"/*",
			"/",
			"**",
			"*/",
			"*+",
			"*-",
			"*",
			"--",
			"-",
			"++",
			"+"     } ;
#endif

#if	OPERATORS == 19

enum	{	UNEQUAL, EQUAL, NOT_GREATER, GREATER, NOT_LESS, LESS,
		REMAINDER, COVERED_QUOTIENT, SHIFT_RIGHT, DIVIDE,
		AND, SHIFT, EXPONENT_PLUS, EXPONENT_MINUS,
		MULTIPLY, XOR, MINUS, OR, PLUS } ;

static char ufield[] = {	sizeof("^=")  - 1,	sizeof("=")  - 1,
				sizeof("^>")  - 1,	sizeof(">")  - 1,
				sizeof("^<")  - 1,	sizeof("<")  - 1,
				sizeof("///") - 1,	sizeof("//") - 1,
				sizeof("/*")  - 1,	sizeof("/")  - 1,
				sizeof("**")  - 1,	sizeof("*/") - 1,
				sizeof("*+")  - 1,	sizeof("*-") - 1,
				sizeof("*")   - 1,	sizeof("--") - 1,
				sizeof("-")   - 1,	sizeof("++") - 1,
				sizeof("+")   - 1 			  } ;


   static char *o[] = { "^=",
			"=",
			"^>",
			">",
			"^<",
			"<",
			"///",
			"//",
			"/*",
			"/",
			"**",
			"*/",
			"*+",
			"*-",
			"*",
			"--",
			"-",
			"++",
			"+"	} ;
#endif

static char tstring[] = ":, ";

static int		 word = 24,
			 byte = 8,
			 address_size = 24,
			 address_quantum = 24,
			 quanta = 1;

static int		 ofield,
			 otag;

#if RADIX==192
static line_item zero_o = { 0,0,0, 0,0,0, 0,0,0, 0,0,0, 
			    0,0,0, 0,0,0, 0,0,0, 0,0,0  } ;
			 
static line_item minus_o = { 255,255,255, 255,255,255, 
			     255,255,255, 255,255,255, 
			     255,255,255, 255,255,255, 
			     255,255,255, 255,255,255 } ;
#endif

#if RADIX==96
static line_item zero_o = { 0,0,0, 0,0,0, 0,0,0, 0,0,0 } ;
			 
static line_item minus_o = { 255,255,255, 255,255,255, 
			     255,255,255, 255,255,255 } ;
#endif

typedef struct { int				    loc,
                                                  lroot,
                                                   base,
                                             breakpoint,
                                             litlocator;
                 union { long a; value *p; }    runbank;
                 char    rbase, bias, touch_base, flags;
                 int			    relocatable; } location_counter;
                 
static location_counter locator[LOCATORS];


#ifdef OVERLAY_LITERALS
static txo *ltag[LOCATORS];
#endif

static breakpoint *lpart[LOCATORS];

static int loc;
static int actual_lbase;
static int counter_of_reference;
static location_counter *actual = locator;

static object *lr, *floatable, *floatop, *earliest_tsub;

static object *entry[RECURSION]; 
static object *next_image[RECURSION];

static int banx; 
static unsigned remainder = BANK-MARGIN, flotsam = BANK-MARGIN;

#ifdef INBANK
static char		 inbank[BANK];
static char		 overbank[BANK];
static object		*bank[BANKS] = { (object *) inbank };
#else

static object		*bank[BANKS];
#endif
static char		*label_margin, *second_margin;
static int		 label_length;

static int		 label_highest_byte;


#ifdef STRUCTURE_DEPTH
static int		 active_x, branch_present;
static object		*active_instance[STRUCTURE_DEPTH];
static unsigned int	 active_origin[STRUCTURE_DEPTH];
static unsigned int	 branch_high[STRUCTURE_DEPTH];
static int		 treeflag;
#endif

static int masm_level, pass, background_pass;

static int ifdepth, skipping;

static int		 skipstate, satisficed = 1;

static int function_scope;
static int traverse_id;

static char octal = 0;
static char lterm = '.', sterm = ':', cont_char =';', qchar = '"';
static int twoscomp = 1; 

static int ll[INCLUDE_MAXDEPTH] = { 0, 0, 0, 0, 0, 0, 0, 0 };
static int linex, list, plist;


static int fpwidth = 96;
static int transient_floating_bits = 0;
static int floating_conversion = 0;
static int floating_field = 0;
static int guard_pattern = 0xE0;

static int characteristic_width[18] = { 8,  8, 12, 24, 24, 24,
                                       24, 24, 24, 24, 24, 24,
				       24, 24, 24, 24, 24, 24 } ;
static int handle[INCLUDE_MAXDEPTH];
static int ohandle, depth, nhandle;

static int lwidth = 60;
static int tsubs, pass1_tsubs, litloc;

static int zero_code_point = DEFAULT_ZERO_CODE_POINT;
static int ecount=0, ucount=0;
static int context_string;
static int suffix, code = ASCII; 
static int code_set[256]
 = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,
    16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
    32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,
    48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,
    64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,
    80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,
    96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,
    112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,
    128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,
    144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,
    160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,
    176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,
    192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,
    208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,
    224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,
    240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255 } ;


static object *files;
static object *file_label[INCLUDE_MAXDEPTH]; 

static int			 lix,
				 apw = 6,
				 apwx = 6;

static char			*column_r;

static char			 plix[DISPLAY_WIDTH + 4];

static char			  selector[26];
static char			 uselector[26];

static flag_box			 initial_flags;
static flag_box			initial_uflags;

static atree			tree[RECURSION];
static atree		      *vtree[RECURSION] = { tree };

#ifdef RELOCATION
static int		 maprecursion;
static link_profile	 mapinfo[MAPSTACK];
static link_profile	*mapx = mapinfo;

#endif


static object		*origin;
static char		 name[256];


#ifdef INDEX
static int		 iindex, insert_point;
static object		*pointer_array[INDEX];
#endif

#ifdef HASH
static int		 insert_point;
static object		*pointer_array[HASH];
#endif

#ifdef SYNONYMS
#ifdef STRUCTURE_DEPTH
static object		*stem_pointer;

static int		 stem_length;
#endif
#endif

static int		 xadw = 48;

#ifdef BLOCK

static rcb *actual_block;
static rcb *block[INCLUDE_MAXDEPTH];

#endif

static int		 outstanding = 1;

#ifdef	BINARY
#ifdef	XREF

static object		*xref_wait;
static short		 xrefx = XREFS - 1;

static touch_table	 one_touch;

#endif
#endif

#ifdef REPORT_QNAMES
static int		 qnames;
#endif


#ifdef VERY_STACKED_XPRESSION
static line_item		 ostac[XPRESSION+1];
static line_item		*sp = &ostac[XPRESSION];
#endif
   
static int			 forward_reference;

static int		 	 file_arguments;
static char			*filename[FILE_ARGUMENTS];

static char			 path[204];

#ifdef RECORD
static int			 branch_record;
static int			 record_nest;
static int			 branch_restart;
#endif


/**************************************************************************


LICENCE NOTE

    Copyright Tim Cox, 2015
    TimMilesCox@gmx.ch

    This source code is part of the masmx.7r3 target-independent
    meta-assembler.

    masmx.7r3 is free software. It is licensed
    under the GNU General Public Licence Version 3.

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


