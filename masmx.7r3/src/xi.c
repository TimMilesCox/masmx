
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



#ifdef INTEL
#ifdef DOS

static int qextractv(object *l)
{
    unsigned short	 x = (l->l.value.b[RADIX/8-2] <<  8)
			   |  l->l.value.b[RADIX/8-1];

    unsigned short	 y = (l->l.value.b[RADIX/8-4] <<  8)
			   |  l->l.value.b[RADIX/8-3];

    int			 z = y;

    z <<= 16;
    z  |=  x;

    return z;
}

#ifdef LITERALS
#ifndef	VERY_STACKED_XPRESSION
static int vextractq(object *l)
{
    unsigned short	 x = (l->l.value.b[RADIX/8-2] <<  8)
			   |  l->l.value.b[RADIX/8-1];

    unsigned short	 y = (l->l.value.b[RADIX/8-4] <<  8)
			   |  l->l.value.b[RADIX/8-3];

    int			 z = y;

    z <<= 16;
    z  |=  x;

    return z;
}
#endif
#endif

static void quadinsert(int v, line_item *item)
{
   item->b[RADIX/8-1] = v;
   item->b[RADIX/8-2] = v >>  8;
   item->b[RADIX/8-3] = v >> 16;
   item->b[RADIX/8-4] = v >> 24;
}

static void quadinsert1(int v, line_item *item)
{
   item->b[RADIX/8-5] = v;
   item->b[RADIX/8-6] = v >>  8;
   item->b[RADIX/8-7] = v >> 16;
   item->b[RADIX/8-8] = v >> 24;
}

#ifdef BINARY

static void quadinsert2(int v, line_item *item)
{
   item->b[RADIX/8-9]  = v;
   item->b[RADIX/8-10] = v >>  8;
   item->b[RADIX/8-11] = v >> 16;
   item->b[RADIX/8-12] = v >> 24;
}

static void quadinsert3(int v, line_item *item)
{
   item->b[RADIX/8-13] = v;
   item->b[RADIX/8-14] = v >>  8;
   item->b[RADIX/8-15] = v >> 16;
   item->b[RADIX/8-16] = v >> 24;
}

static void quadinsert4(int v, line_item *item)
{
   item->b[RADIX/8-17] = v;
   item->b[RADIX/8-18] = v >>  8;
   item->b[RADIX/8-19] = v >> 16;
   item->b[RADIX/8-20] = v >> 24;
}

#endif

static int quadextract(line_item *item)
{
    unsigned short	 x = (item->b[RADIX/8-2] <<  8)
			   |  item->b[RADIX/8-1];

    unsigned short	 y = (item->b[RADIX/8-4] <<  8)
			   |  item->b[RADIX/8-3];

    int			 z = y;

    z <<= 16;
    z  |=  x;

    return z;
}

static int quadextract1(line_item *item)
{
    unsigned short	 x = (item->b[RADIX/8-6] <<  8)
			   |  item->b[RADIX/8-5];

    unsigned short	 y = (item->b[RADIX/8-8] <<  8)
			   |  item->b[RADIX/8-7];

    int			 z = y;

    z <<= 16;
    z  |=  x;

    return z;
}

static int quadextractx(line_item *item, int index)
{
   unsigned short	 x = (RADIX/32-index) << 2;

   unsigned short	 y = (item->b[x] << 8)
			   |  item->b[x+1];

   int			 z = y;

   y = (item->b[x+2] << 8) | item->b[x+3];
   z <<= 16;
   z |= y;

   return z;
}

#else		/*  DOS  */

static int qextractv(object *l)
{
   return (l->l.value.b[RADIX/8-4] << 24)
   |      (l->l.value.b[RADIX/8-3] << 16)
   |      (l->l.value.b[RADIX/8-2] <<  8)
   |       l->l.value.b[RADIX/8-1];
}

#ifdef LITERALS
#ifndef	VERY_STACKED_XPRESSION
static int vextractq(object *l)
{
   return (l->v.value.b[RADIX/8-4] << 24)
   |      (l->v.value.b[RADIX/8-3] << 16)
   |      (l->v.value.b[RADIX/8-2] <<  8)
   |       l->v.value.b[RADIX/8-1];
}
#endif
#endif

static void quadinsert(int v, line_item *item)
{
   item->b[RADIX/8-1] = v;
   item->b[RADIX/8-2] = v >>  8;
   item->b[RADIX/8-3] = v >> 16;
   item->b[RADIX/8-4] = v >> 24;
}

static void quadinsert1(int v, line_item *item)
{
   item->b[RADIX/8-5] = v;
   item->b[RADIX/8-6] = v >>  8;
   item->b[RADIX/8-7] = v >> 16;
   item->b[RADIX/8-8] = v >> 24;
}

#ifdef BINARY

static void quadinsert2(int v, line_item *item)
{
   item->b[RADIX/8-9]  = v;
   item->b[RADIX/8-10] = v >>  8;
   item->b[RADIX/8-11] = v >> 16;
   item->b[RADIX/8-12] = v >> 24;
}

static void quadinsert3(int v, line_item *item)
{
   item->b[RADIX/8-13] = v;
   item->b[RADIX/8-14] = v >>  8;
   item->b[RADIX/8-15] = v >> 16;
   item->b[RADIX/8-16] = v >> 24;
}

static void quadinsert4(int v, line_item *item)
{
   item->b[RADIX/8-17] = v;
   item->b[RADIX/8-18] = v >>  8;
   item->b[RADIX/8-19] = v >> 16;
   item->b[RADIX/8-20] = v >> 24;
}

#endif  /* BINARY  */

static int quadextract(line_item *item)
{
   return (item->b[RADIX/8-4] << 24)
   |      (item->b[RADIX/8-3] << 16)
   |      (item->b[RADIX/8-2] <<  8)
   |       item->b[RADIX/8-1];
}

static int quadextract1(line_item *item)
{
   return (item->b[RADIX/8-8] << 24)
   |      (item->b[RADIX/8-7] << 16)
   |      (item->b[RADIX/8-6] <<  8)
   |       item->b[RADIX/8-5];
}

/**********************************************************

	index in quadextractx is relative 1 from R to L
	as equf_name\1 .. equf_name\6

***********************************************************/

static int quadextractx(line_item *item, int index)
{
   int		 x = (RADIX/32-index) << 2;

   return (item->b[x]   << 24)
   |      (item->b[x+1] << 16)
   |      (item->b[x+2] <<  8)
   |       item->b[x+3];
}

#endif	/* DOS	 	*/
#endif	/* INTEL	*/

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


