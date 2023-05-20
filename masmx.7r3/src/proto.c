
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




static int expression(char *s, char *e, char *param);
static int ixpression(char *s, char *e, char *param);
static line_item *xpression(char *s, char *e, char *param);
static int assemble(char *line_label,char *param,object *above,txo *image);
static void note(char *k);
static void flag(char *k);
static void flag_either_pass(char name[], char *k);
static char *first_at(char *data, char *mask);
static char *fendb(char *s, char *e);

#ifdef LITERALS
static int literal(char *arg, char *gparam, int tlocator);
#endif

static void rshift(line_item *o, int distance);
static void lshift(line_item *o, short distance);
static int nline(char data[], int z);

static void operand_or(line_item *left, line_item *right);
static void operand_add(line_item *left, line_item *right);

static void produce(int bits, char dflag, line_item *item, txo *image);

static void operand_addcarry(unsigned short c, line_item *o);
static int operand_compare(line_item *left, line_item *right);

#ifdef INTEL

static int qextractv(object *l);
static int vextractq(object *l);
static void quadinsert(int u, line_item *i);
static void quadinsert1(int u, line_item *i);
static void quadinsert2(int u, line_item *i);
static void quadinsert3(int u, line_item *i);
static void quadinsert4(int u, line_item *i);
static int quadextract(line_item *);
static int quadextract1(line_item *i);

static int quadextractx(line_item *i, int index);

static unsigned short read16(int w, line_item *item);
static void write16(int w, int v, line_item *item);
static void quadza(int u, line_item *i);

#else

#define qextractv(o) (o)->l.value.i[RADIX/32-1]
#define vextractq(o) (o)->v.value.i[RADIX/32-1]
#define quadinsert(v, item)  (item)->i[RADIX/32-1] = v
#define quadinsert1(v, item) (item)->i[RADIX/32-2] = v
#define quadinsert2(v, item) (item)->i[RADIX/32-3] = v
#define quadinsert3(v, item) (item)->i[RADIX/32-4] = v
#define quadinsert4(v, item) (item)->i[RADIX/32-5] = v
#define quadextract(item)    (item)->i[RADIX/32-1]
#define quadextract1(item)   (item)->i[RADIX/32-2]

/**********************************************************

	index in quadextractx is relative 1 from R to L
	as equf_name\1 .. equf_name\6

***********************************************************/

#define quadextractx(item, index) (item)->i[RADIX/32-index]

#define read16(index, item)  (item)->h[index]
#define write16(index, value, item) (item)->h[index] = value

static void quadza(int u, line_item *i);

#endif

static void illustrate(int location, 
			    int bits, 
		      int counter_id, 
			   int dflag,
			    int code,
		     line_item *item);

static void illustrate_xad(location_counter *q, int location);
static char *fendbe(char *s);
static object *isanequf(char *field);
static object *insert_qltable(char *l, int equator, int type);
static void characterise(int places, line_item *item);

#ifdef LITERALS
static void output_literals(int tlocator);
#endif

#ifdef RELOCATION
#ifdef DOS
static void map_linkages(int bits, int scale);
static void map_offset(int scale, line_item *item);
static void  o_range(int flags, line_item *ii);
#define display_ra(flags, ii)
static void output_linkage(int x, txo *image, txo *a_image);
#define illustrate_linkage(i)
#else
static void map_linkages(int bits, int scale);
static void map_offset(int scale, line_item *item);
static void o_range(int flags, line_item *ii);
static void display_ra(int flags, line_item *v);
static void output_linkage(int x, txo *image, txo *a_image);
static void illustrate_linkage(int i);
#endif
#endif

static int getline(char *k, int max);
static int zxpression(char *s, char *e, char *param);

static char *substitute(char *text, char *param);
static value *apply_value(int id);
static void print_item(line_item *item);
static void floating_position(int bits, line_item *item);
static void floating_generate(char *a, char *margin, char *param, line_item *item);
static int meaning(char *directive);

#ifdef RECORD
static int record(object *l, char *data, int subfunction);
#endif
static int coded_character(int symbol);
static void record_bits(int bits);
static void brake(char *what, char *why);
static void pack_ltable(object *toplabel);
static void embed_procedure(int type, char *line, char *argument);
static unsigned int checkwaver(line_item *v, object *o);
static int length_mark(int symbol);

#ifdef	FP_XPRESS
static int number(char *s, char *e);
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


