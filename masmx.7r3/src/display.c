
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



static void print_item(line_item *item)
{
   int			 x = RADIX/8;
   unsigned char	*p = item->b;

   /********************************

	always compiled for
	unsigned char

   ********************************/

   putchar('[');
   while (x--) printf("%2.2x", *p++);
   printf("]\n");
}

static void illustrate_xad(location_counter *q, int location)
{
   #ifdef VALUE
   line_item			 p = q->runbank.p->value;
   #else
   line_item			 p = q->runbank.p->value;
   #endif

   int				 y = (xadw+7)>>3, x = RADIX/8 - y;


   quadd_u(location, &p);
   
   if (y > RADIX/8)
   {
      flag_either_pass("Internal Error J2", "abandon");
      exit(0);
   }

   while (y--) printf("%2.2X", p.b[x++]);
}

static void illustrate(int  location,
			    int bits, 
		      int counter_id, 
			   int dflag,
			  int encode, 
		     line_item *item)

{
   int				 v = 0,
				 bytes = (bits+7) >> 3,
				 i = RADIX/8 - bytes;

   char				 o[96];
   char				 symbol;
   
   location_counter		*q = &locator[counter_id];

   short			 slice = 0;

   unsigned short		 serial_bits = 0,
                                 bits_cached = 0,
                                 x = RADIX/8,
                                 words = (bits + word - 1) / word;

   if ((list > depth) && (pass) && (selector['l'-'a']))
   {
      if (octal)
      {
         printf("%3.3o:", counter_id);

         if (q->flags & 1)
         {
         }
         else
         {
            v = apw + 5;

            if (selector['d'-'a'])
            {
               if (!q->relocatable)
               {
                  if (q->flags & 128) location += q->base;
                  if (q->breakpoint)  location -= q->base;
               }

               if (selector['v'-'a'])
               {
                  printf("%0*lo:", apwx, q->runbank.a);
                  v = apwx + apw + 6;
               }
               else
               {
                  location += q->runbank.a;
               }
            }

            printf("%0*o ", apw, location);
         }
      }
      else
      {
         printf("%2.2X:", counter_id);

         if (q->flags & 1)
         {
            illustrate_xad(q, location);
            printf(":");
            v = xadw/4+4;
         }

         else
         {
            v = apw + 4;     

            if (selector['d'-'a'])
            {
               if (!q->relocatable)
               {
                  if (q->flags & 128) location += q->base;
                  if (q->breakpoint)  location -= q->base;
               }

               if (selector['v'-'a'])
               {
                  printf("%0*lX:", apwx, q->runbank.a);
                  v = apwx + apw + 5;
               }
               else
               {
                  location += q->runbank.a;
               }
            }

            printf("%0*X ", apw, location);
         }
      }

      if (encode)
      {
	 if (octal)
	 {
            i = 96;
            while (words--)
            {
               slice += word;

               while (slice)
               {

                  if (bits_cached < 3)
                  {
                     x--;
                     serial_bits |= (item->b[x]) << bits_cached;
                     bits_cached += 8;
                  }

                  if ((selector['e'-'a']) && (slice < 3))
                  {
                     symbol = serial_bits & ((1 << slice) - 1);
                     serial_bits >>= slice;
                     bits_cached -= slice;
                     slice = 0;
                  }
                  else
                  {
                     symbol = serial_bits & 7;
                     serial_bits >>= 3;
                     bits_cached -= 3;               
                     slice -= 3;
                  }

                  symbol |= '0';
                  i--;
                  o[i] = symbol;
                 
                  if (slice < 0) break;
               }

               if (selector['e'-'a'])
               {
                  i--;
                  o[i] = 32;
               }
            }
            while (i < 96) putchar(o[i++]);
	 }
	 else
	 {
            i = 96;

            while (words--)
            {
               slice += word; 

               while (slice)
               {

                  if (bits_cached < 4)
                  {
                     x--;
                     serial_bits |= (item->b[x]) << bits_cached;
                     bits_cached += 8;
                  }

                  if ((selector['e'-'a']) && (slice < 4))
                  {
                     symbol = serial_bits & ((1 << slice) - 1);
                     serial_bits >>= slice;
                     bits_cached -= slice;
                     slice = 0;
                  }
                  else
                  {
                     symbol = serial_bits & 15;
                     serial_bits >>= 4;
                     bits_cached -= 4;               
                     slice -= 4;
                  }

                  
                  symbol |= '0';
                  if (symbol > '9') symbol += 7;

                  i--;
                  o[i] = symbol;
                 
                  if (slice < 0) break;
               }

               if (selector['e'-'a'])
               {
                  i--;
                  o[i] = 32;
               }
            }
            while (i < 96) putchar(o[i++]);
	 }
	 
	 if (octal) v += (bits + 2) / 3;
         else       v += bytes * 2;

	 if (v > 30)
	 {
	    putchar(10);
	    v = 0;
	 }
      }
      while (v++ < 30) putchar(32);
      putchar(dflag);
      printf("%d %s\n", ll[depth], plix);
      plix[0] = 0;
      lix = 0;
   }
}

#ifndef DOS
static void illustrate_linkage(int x)
{
   static int		 bits,
			 scale,
			 descant,
			 flags;

   static link_offset	*q;



   link_profile		*p = &mapinfo[x];

   int			 xref, rel;

   int			 mask, z, symbol_pair;

   int			 code = p->m.l.y;

   if (!pass) return;
   if (p->scale < 0) return;

   if (p->m.l.y & 16)
   {
   }
   else
   {
      if (p->recursion != maprecursion) return;
      bits = p->slice;
      scale = p->scale;
      flags = code;

      if (!bits) bits = address_size;

      descant = 0;

      if (x)
      {
         q = (link_offset *) p;
         q--;
         descant = q->scale;
      }
   }
    
   if (!code) return;

   if (code & 1)
   {
      rel = p->m.l.rel & 127;
      if (code & 8) printf("(-%2.2x", rel);
      else          printf("(+%2.2x", rel);

      if (descant < 0)
      {
         mask = (1 << (address_size & 7)) - 1;
         z = 6 - (address_size >> 3);

         putchar(':');
         if (mask)
         {
            symbol_pair = q->offset[z-1];
            symbol_pair &= mask;
            printf("%2.2x", symbol_pair);
         }
         while (z < 6) printf("%2.2x", q->offset[z++]);
         printf("/*%2.2x", -descant);
      }
      printf(")%2.2x", bits);
      
      if (scale) printf("*/%2.2x", scale);

      if (flags & 4) putchar('+');
      if (flags & 2) putchar('-');
   }

   if (code & 128)
   {
      xref = p->m.l.xref;

      if (code & 8) printf("[-%4.4x", xref);
      else          printf("[+%4.4x", xref);

      if (descant < 0)
      {
         mask = (1 << (address_size & 7)) - 1;
         z = 6 - (address_size >> 3);

         putchar(':');
         if (mask)
         {
            symbol_pair = q->offset[z-1];
            symbol_pair &= mask;
            printf("%2.2x", symbol_pair);
         }
         while (z < 6) printf("%2.2x", q->offset[z++]);
         printf("/*%2.2x", -descant);
      }
      printf("]%2.2x", bits);
      
      if (scale) printf("*/%2.2x", scale);

      if (flags & 4) putchar('+');
      if (flags & 2) putchar('-');
   }

   printf("\n");
}
#endif
static void walktable(int order)
{
   #ifdef STRUCTURE_DEPTH
   int			 depth = 0;   
   object		*prefix[STRUCTURE_DEPTH];
   #endif
   
   char			*w;
	 
   int			 x, y, i, bits, bytes;

   object		*sr = origin;
   object		*avanti;

   int			 v;
   location_counter	*section;
   


   if (order == 2) sr = floatable;
   
   lr->h.type = UNDEFINED;

   while (sr)
   {
      if ((order == 2) && (sr == floatop)) break;

      x = sr->h.type;

      switch (x)
      {
	 case LABEL:

	    #ifdef STRUCTURE_DEPTH
	    for (i = 0; i < depth; i++) printf("%s:", prefix[i]->l.name);
	    #endif

	    fputs(sr->l.name, stdout);

            x = sr->l.valued;

            if (x == BLANK)
            {
               y = sr->l.r.l.rel & 127;
               section = &locator[y];
               if (section->flags & 128) x = EQUF;
               else                      x = LOCATION;
            }

	    if (x)
	    {
	       if (sr->l.r.l.xref < masm_level) 
	       {
                  putchar('+');

		  if (order == 2) printf("%d", sr->l.r.l.xref);
	       }

	       putchar('=');

	       switch(x)
	       {

		  case INTERNAL_FUNCTION:
		     printf(":F:");
		     break;
		  case FUNCTION:
		     printf(":F%d:", sr->l.passflag);
		     break;
		  case PROC:
		     printf(":P%d:", sr->l.passflag);
                     if (sr->l.r.l.y) printf("(%d)", sr->l.r.l.rel);
                     printf("%d:", sr->l.r.l.xref);
		     break;
		  case NAME:
		     printf(":N%d:", sr->l.passflag);

                     #ifdef ABOUND
                     if (sr->l.passflag &  64) printf("F:");
                     if (sr->l.passflag & 128) printf("P:");
                     #endif

                     if (sr->l.r.l.y) printf("(%d)", sr->l.r.l.rel & 127);
                     printf("%d:", sr->l.r.l.xref);
		     break;
		  case DIRECTIVE:
		     printf(":D:");
		     break;
		  case FILE_LABEL:
		     printf("%x<", sr->l.r.l.rel);
		     break;
		  default:
		     if (sr->l.r.l.rel) printf("$%2.2X:", sr->l.r.l.rel & 127);
                     if (sr->l.r.l.y & 128) printf("[%4.4x]", sr->l.r.l.xref);
		     break;
	       }
	 
	       switch(x)
	       {
		  case FORM:
		     i = 0;
		     while (sr->l.value.b[i])
			printf(".%d", sr->l.value.b[i++]);
		     break;
                  case EQUF:
                     i = 0;

                     while (i < (RADIX/32-1))
                     {
                        if (sr->l.value.i[i]) break;
                        i++;
                     }


                     /*******************************************************

			index in quadextractx is relative 1 from R to L
			as equf_name\1 .. equf_name\6

                     ********************************************************/

                     i = RADIX/32 - i;
                     y = 0;

                     while (y++ < i)
                     {
                        v = quadextractx(&sr->l.value, y);

                        if ((v) || (y == 1))
                        {
                           if ((address_size < 32) && (v & 0x80000000))
                           {
                              printf("*");
                              v &= 0x7FFFFFFF;
                           }

                           printf("%0*X", apw, v);
                        }

                        if (y < i) putchar(',');
                     }
                     
                     break;

		  default:
	       
		     bits = RADIX;
		     i = 0;
		     while (i < RADIX/8-1)
		     {
			if (sr->l.value.b[i+1] & 128)
			{
			   if (sr->l.value.b[i] != 0xff) break;
			}
			else
			{
			   if (sr->l.value.b[i])         break;
			}
			i++;
			bits -= 8;
		     }
		     bits += word-1;
		     bits /= word;
		     bits *= word;
		     bytes = (bits+EIGHT-1) >> 3;
   
		     i = RADIX/8 - bytes;
		     while (i < RADIX/8) printf("%2.2X", sr->l.value.b[i++]);
		     break;
	       }


               /**********************************************
               XREFS also have an along pointer, but they
               won't get in here because their object type
               is XREF not LABEL
               **********************************************/

	       #ifdef STRUCTURE_DEPTH
	       if ((sr->l.down) && (sr->l.valued != PROC)
                                && (sr->l.valued != NAME)
                                && (sr->l.valued != FILE_LABEL)
                                && (sr->l.valued != FUNCTION))
	       {
	          prefix[depth++] = sr;
	          sr = (object *) sr->l.down;
                  putchar(10);
	          continue;
	       }

	       while ((depth) && (!sr->l.along))
	       {
	          depth--;
	          sr = prefix[depth];
	       }

	       if ((depth) && (sr->l.along))
	       {
	          sr = (object *) sr->l.along;
                  putchar(10);
	          continue;
	       }
	       #endif
	    }
            putchar(10);

	    break;
	 case TEXT_SUBSTITUTE:
	    printf(":Tsub:");
	    w = sr->t.text;
	    while ((i = *w++)) putchar(i);
	    putchar(':');
	    fputs(w, stdout);
	    putchar(10);
	    break;

         case PROC:
         case NAME:
         case FUNCTION:
            print_macrohead(sr->t.length, sr->t.text, ":MACRO HEAD:");
            putchar(10);
            break;

	 case TEXT_IMAGE:
	    if (selector['p'-'a'] | selector['q'-'a'] | selector['r'-'a'])
            {
               print_macrotext(sr->t.length, sr->t.text, NULL);
	       putchar(10);
            }
	    break;

	 case END:
            print_macrohead(sr->t.length, sr->t.text, ":MACRO $END:");
            putchar(10);
            break;

	 case BYPASS_RECORD:
	    if ((i = sr->nextbdi.next)) sr = bank[i];
	    else                            return;
	    continue;
	 
	 #ifdef OVERLAY_LITERALS
	 case LITERAL:
            break;
	 #endif
         
         case BREAKPOINT:
            printf("breakpoint %x/%x\n", sr->b.oblong, sr->b.base);
            break;

         case VALUE:
            printf("large address base %x/%x/",
                    sr->v.oblong, sr->v.offset);

            bytes = (xadw+EIGHT-1) >> 3;
   
            i = RADIX/8 - bytes;
            while (i < RADIX/8) printf("%2.2X", sr->v.value.b[i++]);
            printf("\n");

            break;

            #ifdef BINARY
         case XREF:
            printf("[%4.4x]%s\n", sr->x.xref, sr->x.name);
            break;
            #endif

	 default:
	    printf("Object Type %d\n", sr->h.type);
	    break;
      }
      
      /********************************************************

	there should be only labels in the dynamic stack
	and nothing with a 16-bit oblong length

      *********************************************************/

      if      (order == 2) sr = (object *) ((char *) sr + sr->h.length);
      else if (order == 3)
      {
         if (sr->h.type == LITERAL) y = sr->u.oblong;
         else                       y = sr->h.length;

         if (y == 0) break;

         sr = (object *) ((char *) sr + y);
      }
      else sr = sr->l.along;
   }

   #ifdef LITERALS
   #ifdef OVERLAY_LITERALS
   if (order < 2)
   {
      for (x = 0; x < LOCATORS; x++)
      {
	 sr = (object *) ltag[x];
	 while (sr)
	 {
	    printf("$%2.2x:%0*x:%s\n", x,
				       apw, sr->u.loc,
				       sr->u.d);
	    sr = sr->u.along;
	 }
      }
   }
   #endif
   #endif
   
   if (order < 2)
   {
      sr = files;
      while (sr)
      {
	 printf("%s=%x<%0*X\n", sr->l.name,
				sr->l.r.l.rel, 
			 	apw, 
				qextractv(sr));
	 sr = sr->l.along;
      }
   }
}

static void summarise_revision(location_counter *q, unsigned int v, unsigned int high)
{
   printf("[%x] code size changed on 2nd assembly pass", q->touch_base);

   if (octal)
   printf(": $(%o) :%0*o:%0*o\n", (int) ((location_counter *) q - (location_counter *) locator), apw, v, apw, high);
   else
   printf(": $(%2.2X) :%0*X:%0*X\n", (int) ((location_counter *) q - (location_counter *) locator), apw, v, apw, high);
}

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


