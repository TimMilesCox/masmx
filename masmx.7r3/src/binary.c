
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



#ifdef	BINARY
#define	QSEMA33

static int quartets(char *p)
{
   int		 z = 0;
   int		 symbol;

   while ((symbol = *p++))
   {
      if ((symbol > 0x2F) && (symbol < 0x3A)) symbol &= 15;
      else
      {
         if ((symbol > 0x60) && (symbol < 0x7B)) symbol &= 0x5F;

         if ((symbol > 0x40) && (symbol < 0x5B)) symbol -= 55;
         else break;
      }

      z <<= 4;
      z |= symbol;
   }
   return z;
}

static int load_quartets(char *p, line_item *v)
{
   int			 symbol, bits = 0;

   *v = zero_o;

   while ((symbol = *p++))
   {
      if ((symbol > 0x2F) && (symbol < 0x3A))
      {
         symbol &= 15;
      }
      else
      {
         if ((symbol > 0x40) && (symbol < 0x5B)) symbol -= 55;
         else break;
      }

      lshift(v, 4);
      v->b[RADIX/8-1] |= symbol;
      bits += 4;
   }
   return bits;
}

static int load_signed_quartets(char *p, line_item *v)
{
   int                   symbol, bits = 0;

   *v = zero_o;

   while ((symbol = *p++))
   {
      if ((symbol > 0x2F) && (symbol < 0x3A))
      {
         symbol &= 15;
      }
      else
      {
         if ((symbol > 0x40) && (symbol < 0x5B)) symbol -= 55;
         else break;
      }

      if (bits == 0)
      {
         if (symbol & 8) *v = minus_o;
      }

      lshift(v, 4);
      v->b[RADIX/8-1] |= symbol;
      bits += 4;
   }
   return bits;
}

int strict_quartets(int symbols, char *p)
{
   int		 z = 0;
   int		 symbol;

   while (symbols--)
   {
      symbol = *p++;

      if ((symbol > 0x2F) && (symbol < 0x3A)) symbol &= 15;
      else
      {
         if ((symbol > 0x60) && (symbol < 0x7B)) symbol &= 0x5F;

         if ((symbol > 0x40) && (symbol < 0x5B)) symbol -= 55;
         else
         {
            flag("binary quartet symbol missing");
            break;
         }
      }

      z <<= 4;
      z |= symbol;
   }
   return z;
}

static int strict_address(char *p)
{
   int		 symbols = ((address_size) + 3) >> 2;

   return strict_quartets(symbols, p);
}

static int strict_locator(char *p, char mark)
{
   int		 x;

   if (p[2] != mark)
   {
      flag_either_pass(p, "locator format2 error"); 
      exit(0);
   }

   x = strict_quartets(2, p);

   if ((x < 0) || (x > LOCATORS - 1))
   {
      flag_either_pass(p, "locator not in 0..71");
      exit(0);
   }

   return x;
}

static int strict_formal_locator(char *p, char mark)
{
   if (*p != '$')
   {
      flag_either_pass(p, "locator format1 error"); 
      exit(0);
   }
   return strict_locator(p + 1, mark);
}

static void transfer_address(char *p)
{
   int		 x = strict_locator(p+1, ':');
   int		 z = strict_address(p+4);
   xref_list	*q = file_label[depth]->l.down;
   
   if (q) z += q->segments.base[x];
   outcounter(x, z, "\n>");
}

static xref_list *assure_xlist(object *f)
{
   static xref_list		 zero_base_array;

   xref_list			*q = f->l.down;

   if (q) return q;

   q = (xref_list *)    malloc(sizeof(xref_list));

   if (!q)
   {
      flag_either_pass("cannot write temp link tables", "abandon");
      exit(0);
   }

   *q = zero_base_array;
   f->l.down = q;
   return q;
}

static void load_int_breakpoint(char *p)
{
   int			 x = strict_locator(p+2, ':');
   location_counter	*q = &locator[x];
   value		*v = (value *) q->runbank.p;
   xref_list		*xrefs = file_label[depth]->l.down;


   if ((q->flags & 1) == 0)
   {
      if (q->touch_base)
      {
         flag("change to large absolute address");
         return;
      }
   }

   q->flags |= 3;

   if (!v)
   {
      v =  apply_value(x);
      q->runbank.p =  v;
   }

   load_quartets(p + 5, &v->value);

   #ifdef TRACE_LONG_RELOAD
   printf("[%s RUNBANK__ $%x %x p%x/%x P%x]\n", file_label[depth]->l.name,
                                             x, q->runbank.a,
                                               q->loc, loc,
                       ((value *) q->runbank)->value.i[5]);
   #endif
}

static int binary_switch_locator(char *p, short ordered,
                                          short order1,
                                          short order[])
{
   int		 x = strict_formal_locator(p, ':');
   int		 y = order1;
   xref_list	*q  = file_label[depth]->l.down;

   if (ordered)
   {
      for (;;)
      {
         if (y < 0) return 0;
         if (x == y) break;
         y = order[y];
      }
   }

   actual->loc = loc;	/* ???????????? */

   counter_of_reference = x;
   actual = &locator[x];

   if (p[4] == '*')
   {
      return 1;
   }

   loc = strict_address(p + 4);

   if (q) loc += q->segments.base[x];

   #ifdef QSEMA33
   actual->touch_base = 3;
   #else
   actual->touch_base = 1;
   #endif

   outstanding = 1;
   return 1;
}

static int load_binary_summary(char *p)
{
   int			 x = strict_formal_locator(p + 1, '*');
   int			 alignment;
   unsigned int	 low, high, size, base;
   location_counter	*q = &locator[x];
   value		*v = (value *) q->runbank.p;
   xref_list		*xl  = file_label[depth]->l.down;

   #if 0
   if (pass)
   {
      return x;
   }
   #endif

   alignment = strict_address(p + 5);
   high = 1 << (address_size - 1);

   if (alignment & high)
   {
      high <<= 1;
      high--;
      alignment &= high;
      alignment ^= high;
      alignment++;
   }

   low       = strict_address(p + 5 + apw + 1);
   high      = strict_address(p + 5 + 2 * apw + 2);

   #if 1
   if (pass)
   {
      base = q->base;
      if (xl) base = xl->segments.base[x];
      size = high - low;
      if (low < base) low += base;
      high = low + size;

      #if 0
      printf("[$%x:%lx:%lx:%lx:%lx:%lx:%lx]", x, base, size, q->runbank.a, low, high, q->loc);
      #endif

      if (high > q->loc)
      {
         q->loc = high;
         if (x == counter_of_reference) /*&& (q->flags & 1)*/ loc = high;
      }

      #if 1
      #ifdef QSEMA33
      q->touch_base = 3;
      #else
      q->touch_base = 1;
      #endif
      #endif
      
      return x;
   }
   #endif

   q->relocatable = alignment;

   if (q->flags & 1)
   {
      if (alignment) v->offset = q->loc;
      else           v->offset =    low;
   }

   else

   q->runbank.a = low;

   if (((selector['b'-'a']) && ((q->flags & 1) == 0))
   ||  (q->bias)) q->runbank.a += q->loc;

   if ((selector['d'-'a']) && ((q->flags | q->relocatable) == 0)) q->base = low;

   q->loc = high;

   if ((x == counter_of_reference) && (q->flags & 1)) loc = high;
   return x;
}

static object *binary_load_label(char *p, short ordered,
                                          short  order1,
                                          short order[])
{
   char			 lname[72];
   int			 symbol;
   int			 x = 0;
   int			 y = 0;
   int			 z = order1;
   line_item		 v = zero_o;
   object		*o;
   location_counter	*q;

   while ((symbol = *p++))
   {
      if (symbol == ':') break;
      lname[x++] = symbol;
      if (x > 70) break;
   }

   lname[x] = 0;

   if (*p ^ '$')
   {
      /****************************************************
        label of a data value
      ****************************************************/

      if (uselector['X'-'A'])
      {
         load_signed_quartets(p, &v);
         o = insert_ltable(lname + 1, lname + x, &v, SET);

         if (o)
         {
            o->l.valued = SET;
            o->l.r.i = 0;
            o->l.r.l.xref = -1;
            o->l.value = v;
         }

         return o;
      }
   }


   y = strict_formal_locator(p, ':');

   /*******************************************************

	where the inclusion pass is selective by location
	counter

	to avoid multiple inclusion of one label

   *******************************************************/


   if (ordered)
   {
      for (;;)
      {
         if (z < 0) return NULL;
         if (z == y) break;
         z = order[z];
      }
   }

   q = &locator[y];

   load_quartets(p + 4, &v);

   o = insert_ltable(lname + 1, &lname[x], &v, LOCATION);

   if (o)
   {
      o->l.value    =   v;
      o->l.r.l.xref =  -1;
      o->l.r.l.rel  =   y;
      o->l.r.l.y    =   0;

      if ((int) q->relocatable) o->l.r.l.y = 1;
   }

   return o;
}

static short xref_index(object *o)
{
   int		*p,
		*q;

   int		 difference;

   int		 x = o->l.length - sizeof(label) + sizeof(xref),
		 y;

   short	 v;

   object	*s = (object *) xref_wait;

   while (s)
   {
      if (s->x.length == x)
      {
         y = x - sizeof(xref) + PARAGRAPH;
         y >>= 2;

         p = (int *) s->x.name;
         q = (int *) o->l.name;

         while (y--)
         {
            if ((difference = *p++ ^ *q++)) break;
         }

         if (!difference) return s->x.xref;
      }
      s = s->x.along;
   }

   if (xrefx < ucount)
   {
      flag_either_pass(o->l.name, "xref index collision, abandon");
      exit(0);
   }

   v = xrefx--;

   y = x - sizeof(xref) + PARAGRAPH;
   y >>= 2;

   s = lr;
   if (remainder < x) s = buy_ltable();

   p = (int *) s->x.name;
   q = (int *) o->l.name;

   s->x.type = XREF;
   s->x.length = x;
   s->x.xref = v;

   s->x.along = xref_wait;
   xref_wait = s;

   while (y--) *p++ = *q++;

   lr = (object *) p;
   remainder -= x;   

   return v;
}

static void load_binary(char *p)
{
   static touch_table untouched;

   char		 assembly[160] = " $map ";
   char		 xlabel[72];

   object	*f = file_label[depth];

   xref_list	*q = f->l.down;

   location_counter *sample;

   char		*s, *limit;
   int		 symbol, index;
   object	*o;
   object	*xpo_list_head = NULL;

   int		 x, y;
   int		 absolute = 0;

   short	 ordered = 0;
   short	 included = 1;
   short	 order1 = -1;
   short	 last_in_order;
   short	 order[LOCATORS];

   int		 alignment, v;

   touch_table	 touched = untouched;

   int		 prelix = lix;


   lix = DISPLAY_WIDTH + 8;

   s = getop(p);

   if (s)
   {
      symbol = *s++;
      if (symbol == '$')
      {
         symbol = *s++;
         if (symbol == '(')
         {
            for(;;)
            {
               limit = edge(s, ",)");
               x = expression(s, limit, NULL);

               if ((x < 0) || (x > LOCATORS+1))
               {
                  flagp1("locator number out of range");
               }
               else
               {
                  ordered++;

                  if (order1 < 0)
                  {
                     order1 = x;
                  }
                  else
                  {
                     order[last_in_order] = x;
                  }
                  last_in_order = x;
                  order[x] = -1;
               }

               s = limit;
               symbol = *s++;
               if (symbol != ',') break;

               for (;;)
               {
                  symbol = *s;
                  if (symbol != 32) break;
                  s++;
               }
            }
         }
         else flag ("locator order list syntax error2");
      }
      else flag("locator order list syntax error1");
   }

   if (actual->relocatable == 0) absolute = 1;

   for (;;)
   {
      x = nline(&assembly[6], 148);

      if (x < 0)
      {
         close(handle[depth]);
         depth--;

         if (depth < 0)
         {
            if (!selector['w'-'a']) printf("*EOF*\n");
            break;
         }

         #ifdef BLOCK
         actual_block = block[depth];
         #endif

         break;
      }

      ll[depth]++;
      plix[lix] = 0;


      switch (assembly[6])
      {
         case '$':

            if (!pass) break;

            included = binary_switch_locator(&assembly[6], ordered,
                                                           order1,
                                                           order);
            break;

         case '+':
            if (pass) break;
            o = binary_load_label(&assembly[6], ordered, order1, order);

            if (o)
            {
               if (o->l.valued ^ LOCATION) break;
               o->l.link = xpo_list_head;
               xpo_list_head = o;
            }

            break;

         case '-':
            if (pass) break;
            s = &assembly[7];
            index = -1;
            x = 0;

            while ((symbol = *s++))
            {
               if (symbol == ':')
               {
                  symbol = *s++;
                  if (symbol == '[')
                  {
                     index = strict_quartets(4, s);
                     break;
                  }
               }
               xlabel[x++] = symbol;
            }

            xlabel[x] = 0;

            if (index < 0)
            {
               flagp1("external reference badly formed");
               exit(0);
            }

            if (index > XREFS - 1)
            {
               flagp1("too many external references");
               exit(0);
            }

            q = assure_xlist(f);
            o = findlabel(xlabel, NULL);

            if (!o)
            {
                o = insert_qltable(xlabel, 0, UNDEFINED);

                if (!o)
                {
                   flag("label not added");
                   break;
                }

                o->l.r.l.xref = -1;
            }

            q->pointer_array[index] = o;            

            break;

         case ':':

            if (ordered)
            {
               x = strict_formal_locator(&assembly[7], '*');
               y = order1;

               for (;;)
               {
                  if (y < 0) break;
                  if (y == x) break;
                  y = order[y];
               }
               if (y < 0) break;
            }

            x = load_binary_summary(&assembly[6]);
            touched.base[x] = 1;

            if (!ordered)
            {
               if (order1 < 0)
               {
                  order1 = x;
               }
               else
               {
                  order[last_in_order] = x;
               }
               last_in_order = x;
               order[x] = -1;
            }

            break;

         case '>':
            if (!pass) break;
            if (!included) break;

            if (assembly[10] == ':')
            {
               write(ohandle, "\n", 1);
               write(ohandle, assembly + 6, x);
               break;
            }

            transfer_address(&assembly[6]);
            break;

         case '@':

            #ifdef LONG_TRAILER
            load_int_breakpoint(&assembly[6]);
            #endif

            break;

         case '.':
            break;

         default:
            if (!pass) break;
            if (!included) break;

            assemble(assembly, "", NULL, NULL);
      }
   }

   if (pass)
   {
      actual->loc = loc;
      if (actual->touch_base == 0) actual->loc = 0;
   }
   else
   {
      x = order1;

      for (;;)
      {
         if (x < 0) break;

         if (touched.base[x])
         {
            sample = &locator[x];
            actual = sample;
            counter_of_reference = x;
            alignment = sample->relocatable;

            if (alignment)
            {
               touched.base[x] = 4;

               /***********************************************
               here the transition from a relocatable segment
               to an absolute segment is forced because a segment
               previously included in THIS $include,$binary is
               absolute, or there is an absolute location counter
               switch somewhere up front:: $(n:address)

               i e this is a simple absolute collection of the
               segments in program
               ***********************************************/

               q = assure_xlist(f);

               if (alignment < 0) alignment = -alignment;

               if ((absolute) && (!one_touch.base[x]))
               {
                  v = loc;

                  if (((selector['b'-'a']) && ((sample->flags & 1) == 0))
                  ||  (sample->bias))
                  {
                     v = sample->runbank.a;
                  }

                  if (sample->flags & 1)
                  {
                     v = sample->runbank.p->offset;
                  }

                  v = (v + alignment - 1) & -alignment;

                  loc = v;

                  if (!sample->touch_base) sample->base = loc;
                  loc += sample->loc;
                  sample->loc =loc;

                  sample->relocatable = 0;
               }
               else
               {
                  loc = sample->lroot;

                  loc = (loc + alignment - 1) & -alignment;

                  v = loc;

                  if (!sample->touch_base) sample->base = loc;

                  loc += sample->loc;
                  sample->loc = loc;

                  sample->lroot = loc;

                  absolute = 0;
               }

               q->segments.base[x]  = v;
            }
            else
            {
               loc = sample->loc;

               if (sample->flags & 1)
               {
                  v = sample->runbank.p->offset;
               }
               else
               {
                  if (sample->loc < loc) flag("code address moved back");
                  if (!sample->touch_base) sample->base = sample->runbank.a;
                  v = sample->base;
               }

               absolute = 1;
            }

            if (selector['l'-'a'])
            {
               #ifdef DOS
               printf("%s:$(%d) %u locations decimal ", f->l.name,
                                       x, loc - v);
               #else
               printf("%s:$(%d) %u %s decimal ", f->l.name,
                                        x, loc - v,
               (address_quantum == 8) ? "bytes" : "words");
               #endif

               if (sample->relocatable)
               {
                  printf("[*%d] ", sample->relocatable);
               }

               if (octal) printf("from octal %0*o to %0*o",
                                     apw, v, apw, loc);
               else printf("from hexadecimal %0*X to %0*X",
                                     apw, v, apw, loc);

               if (sample->flags & 1)
               {
                  if (selector['d'-'a'])
                  {
                     printf(" +");
                     illustrate_xad(sample, 0);
                  }
               }

               putchar('\n');
            }

            #ifdef QSEMA33
            sample->touch_base = 3;
            #else
            sample->touch_base = 1;
            #endif
         }

         x = order[x];
      }

      if ((actual->flags & 1) | actual->bias) loc = actual->loc;
      else                                    actual->loc = loc;

      o = xpo_list_head;

      while (o)
      {
         x = o->l.r.l.rel;
         sample = &locator[x];
         
         if ((y = touched.base[x]))
         {
            if (sample->flags & 1)
            {
               if (y == 4)
               {
                  if (!sample->runbank.p)
                  {
                     flag_either_pass(o->l.name, "adding void base, abandon");
                     exit(0);
                  }

                  operand_add(&o->l.value,
                              &sample->runbank.p->value);
               }
            }

            o->l.r.l.y = 0;
            if (sample->relocatable) o->l.r.l.y = 1;
        
            if ((q) && (q->segments.base[x]))
            {
               quadd_u(q->segments.base[x], &o->l.value);
            }
         }

         o = o->l.link;
      }
   }

   lix = prelix;
}

static void offset_frame(line_item *item)
{
   link_offset		*p = (link_offset *) mapx - 1;
   unsigned short	*h = (unsigned short *) p;


   *item = zero_o;
   if (p->offset[0] & 128) *item = minus_o;

   item->h[RADIX/16-3] = h[1];
   item->h[RADIX/16-2] = h[2];
   item->h[RADIX/16-1] = h[3];
}

static int load_offset(char *p, line_item *v)
{
   int			 symbol, bits = 0;

   *v = zero_o;

   while ((symbol = *p++))
   {
      if ((symbol > 0x2F) && (symbol < 0x3A))
      {
         symbol &= 15;
      }
      else
      {
         if ((symbol > 0x40) && (symbol < 0x5B)) symbol -= 55;
         else break;
      }

      if (!bits)
      {
         if (symbol & 8) *v  = minus_o;
      }

      lshift(v, 4);
      v->b[RADIX/8-1] |= symbol;
      bits += 4;
   }
   return bits;
}

/***********************************************
a relocation tuple+offset has been adjusted with
$INFO directive. The adjusted offset is copied
to all other tuples for the same field
***********************************************/

static void propagate_downwards(link_offset *o)
{
   link_offset			*q = o;
   link_profile			*p = (link_profile *) q + 1;

   short			 descant = q->scale,
                                 scale   = p->scale;

   char				 bits    = p->slice;


   while (q > (link_offset *) &mapinfo[1])
   {
      q -= 2;

      if (q->scale ^ descant) break;

      p = (link_profile *) q + 1;

      if (p->slice ^  bits) break;
      if (p->scale ^ scale) break;

      *q = *o;
   }
}

/**********************************************************
a relocation tuple with offset tuple has been stacked.
If it's on top of other tuples+offset for the same field,
the earlier offset is copied so that adjustments already
made are carried forward
**********************************************************/

static void propagate_upwards(int descant, int scale, int bits)
{
   link_profile			*p;
   link_offset			*o = (link_offset *) mapx - 1;
   link_offset			*q = o;

   if (q > (link_offset *) &mapinfo[1])
   {
      q -= 2;

      if (q->scale == descant)
      {
         p = (link_profile *) q + 1;
         if ((p->slice == bits) && (p->scale == scale)) *o = *q;
      }
   }
}

static int mantissa(char *s)
{
   int			 i = quartets(s);

   return i;
}

static int scale(char *s)
{
   int			 i = 0;
   int			 symbol;

   while ((symbol = *s++))
   {
      if (((symbol > 0x2F) && (symbol < 0x3A))
      ||  ((symbol > 0x40) && (symbol < 0x5B))
      ||  ((symbol > 0x60) && (symbol < 0x7B)))
      {
      }
      else break;
   }

   if (symbol == '*')
   {
      symbol = *s++;
      {
         if (symbol == '/') i = quartets(s);
      }
   }
   else
   {
      if (symbol == '/')
      {
         symbol = *s++;
         if (symbol == '*')
         {
            i = quartets(s);
            i = -i;
         }
      }
   }

   return i;
}

#endif	/*	BINARY	*/

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


