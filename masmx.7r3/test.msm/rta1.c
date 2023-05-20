#define BASE		0
#define ICACHE		128
#define DCACHE		256
#define	ICACHE_P	320
#define ICACHE_Q	384
#define DCACHE_P	448
#define DCACHE_Q	512

#define LAST		2
#define LEFT_VALID	0
#define RIGHT_VALID	1

typedef struct { unsigned char       b[3]; } word;
typedef struct { word                w[8]; } mline;

typedef struct { mline             m[512]; } page;
typedef struct { page               p[64]; } bank;

typedef union  { word           w[262144];
                 unsigned short i[262144]; } xbank;

typedef union  { bank		 b[65536];
                 page         p[64*65536]; } executable_device;

typedef struct { xbank           x[65536]; } device;

static word 		r[256];
static word		initial[1024];
static word		port[1024];

#define R		0
#define K		1
#define X		2
#define Y		3
#define	A		4

#define P		12
#define Q		13
#define DP		14
#define SP		15

#define X_R		128
#define X_K		129
#define X_X		130
#define X_Y		131
#define	X_A		132

#define X_P		140
#define X_Q		141
#define X_DP		142
#define X_SP		143

#define SEE1		16384
#define SEE2		8192
#define	SEE3		4096
#define SEE4		2048
#define SEE5		1024
#define	SEE6		512
#define	SEE7		256
#define HALFWORD	128

#define CARRY		16
#define SIGN		8
#define ZERO		4
#define PARITY		2
#define LOW_BIT		0

#define	W0		0
#define T1		1
#define T2		2
#define T3		3

#define H1		2
#define H2		3

#define	I		4
#define XI		5

#define SHIFTS_JUMPS	6
#define LARGE_OPS	7

#define SR		0
#define SK		8
#define SX		16
#define SY		24
#define SA		32
#define	SB		40
#define Z		48
#define T		56

#define LR		64
#define LK		72
#define LX		80
#define LY		88
#define LA		96
#define LB		104
#define INC		112
#define DEC		120

#define OR		128
#define ORB		136
#define	AND		144
#define ANDB		152
#define XOR		160
#define TA		168
#define AX		176
#define AY		184

#define AA		192
#define AB		200
#define	ANA		208
#define	ANB		216
#define	M		224
#define MF		232
#define	D		240
#define PUSH		248

#define ON		0+XI
#define OFF		8+XI

#define II		32+XI
#define IR		40+XI
#define LRET		48+XI
#define FRET		56+XI

#define L		112+XI
#define _AX		120+XI

#define INA		4
#define INB		12
#define	OUTA		20
#define OUTB		28
#define PLVA		36
#define SABR		52
#define SBBR		60
#define FSABR		116
#define FSBBR		124

#define SAR		6
#define SBR		14
#define	DSR		22
#define LCAL		30
#define SAL		38
#define	SBL		46
#define DSL		54
#define RAR		70
#define RBR		78
#define DRR		86
#define RAL		102
#define RBL		110
#define DRL		118
#define J		126
#define SAA		134
#define SBA		142
#define DSA		150
#define JDR		166
#define JDK		174
#define JNC		182
#define	JC		190
#define JP		198
#define JM		206
#define JNZ		214
#define JZ		222
#define JPE		230
#define JPO		238
#define JE		246
#define	JO		254

#define TS		7
#define N		15
#define SIM		23
#define LABT		31
#define SRS		39
#define LRS		47
#define GO		55
#define CALL		63
#define QS		71
#define QL		79
#define FLP		87
#define DPX		95
#define FA		103
#define FAN		111
#define FM		119
#define FD		127

#define EX		159
#define DLSC		167
#define	MTA		175
#define	SC		183
#define LC		191
#define DS		199
#define DL		207
#define DA		215
#define	DAN		223
#define LSC		231
#define DTAB		239
#define SRC		247
#define SLC		255

static unsigned short im, flags,
   inverse_limit, relative_page,
                   base_page, p,
                   carry, xpage;


static executable_device executable;
static device fs1;


main()
{
   mline	*ip = 0;
   word		i;

   int			cmask
			cmask2;
   unsigned short	selector, way,
                      way_selector, j;

   for (;;)
   {
      if ((!xpage) && (p < 1024)) i = initial[p];
      else
      {
         if (carry)
         {
            printf("Jump out of Ibank\n");
         }

         if ((!(j & 7)) || (!ip))
         {
            selector = (p >> 3) & 127 | port;
            cmask = (xpage << 2 ) | ((p >> 10) & 3);

            way = (port[ICACHE+selector].b[LAST];
            way_selector = selector + ICACHE_P + way;
            way >>= 7;

            cmask2 = (port[way_selector].b[0] << 16)
                   | (port[way_selector].b[1] <<  8)
                   |  port[way_selector].b[2];

            if ((port[ICACHE+selector].b[way]) && (cmask == cmask2))
            {
               ip = &executable.p[xpage].m[p >> 3];
            }
            else
            {
               way_selector ^= 128;
               port[ICACHE+selector].b[LAST] ^= 128;
               way ^= 1; 

               cmask2 = (port[way_selector].b[0] << 16)
                      | (port[way_selector].b[1] <<  8)
                      |  port[way_selector].b[2];

               if ((port[ICACHE+selector].b[way]) && (cmask == cmask2))
               {
                  ip = &executable.p[xpage].m[p >> 3];
               }
               else
               {
                  /***********************************************
                  this is where you check if you're going to
                  ***********************************************/

                  port[ICACHE+selector].b[way] = 1;
                  port[way_selector].b[2] = cmask;                  
                  port[way_selector].b[1] = cmask >> 8;                  
                  port[way_selector].b[0] = cmask >> 16;                  

                  ip = &executable.p[xpage].m[p >> 3];
               }
            }
         }
         i = ip->w[j & 7];
      }

      p++;

      if (p & 0xF000)
      {
         relative_page++;
         xpage++;
         carry = relative_page + inverse_limit;
         carry &= 0xF000;
         p &= 0x0FFF;
      }

      j = i.b[0] & 7;

      switch (j)
      {
         case XI:
            operand.b[11] = i.b[2];
            operand.b[10] = i.b[1];
            (char) operand.b[9] = (char) i.b[1] >> 7;
            break;
         default:
      }
   }
}
