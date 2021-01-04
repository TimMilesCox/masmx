
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





#ifdef	RECORD

static int precord(object *l, char *line, char **data, int nest)
{
   static int		 bits;
   static int		 rbase;
   static int		 positions;
   static int		 cache_line;
   static int		 address;
   static linkage	 rflags;
   static line_item	 stage;


   line_item		 temp;
   line_item		*threshold;
   object               *q;
   object               *k;

   int                   x,
                         y;

   int			 offset;

   int			 symbol,
                         mask,
			 lsword;

   char                 *op;
   char                 *argument;
   char			*p;

   int			 branch_mask = (1 << active_x) - 1;

   int			 pointer;

   int			 position;


   if (line == NULL)
   {
      /***************************************************
		**data nonzero is an overlay or union
      ***************************************************/

      #ifdef RECORD_BRANCH
      if (data)
      {
         bits = (int) data & 0x7FFFFFFF;
         if (nest < 0)
         {
            if ((y = cache_line - positions))
            {
               if ((x = y % word)) lshift(&stage, word - x);
               produce(y, '+', &stage, NULL);
               stage = zero_o;
               positions = cache_line;
            }
            return bits;
         }

         /***********************************************
		starting a 2nd or subsequent branch
         ***********************************************/
      }
      #endif

      /***************************************************
		initialising call
      ***************************************************/

      if (nest == 0)
      {
         /***********************************************
		outermost record
         ***********************************************/

         if (selector['q'-'a']) printf("R %s %x\n", l->l.name,
                                        loc);
         bits = 0;
         address = loc;
         rflags.l.rel = counter_of_reference | 128;
         if (actual->relocatable) rflags.l.y = 1;
         rbase = actual->rbase;
         stage = zero_o;
         positions = cache_line = RADIX / word * word;
         outstanding = 1;
      }
      else
      {
         /***********************************************
		nested  record
         ***********************************************/

         if (selector['q'-'a']) printf("r %s %x:%x\n", l->l.name,
                                        address + bits / word,
                                        bits % word);

         quadinsert(address + bits / word * quanta, &l->l.value);
         quadinsert3(bits % word,                   &l->l.value);
      }

      l->l.valued = EQUF;
      l->l.r = rflags;
      quadinsert1(rbase, &l->l.value);
      return bits;
   }

   if (selector['q'-'a']) printf("%s<\n", line);

   op = getop(line);
   argument = NULL;

   if (op)
   {
      argument = getop(op);

      x = -1;
      x = -1;
      k = findlabel(op, NULL);

      if (k)
      {
         y = k->l.valued;

         if ((y == NAME) || y == (PROC))
         {
            assemble(line, argument, NULL, NULL);
            return 0;
         }

         if (y == DIRECTIVE) x = quadextract(&k->l.value);
         if (x == END) brake("", "$end in unsafe position");
      }
   }
   else return 0;

   if (x < 0)
   {
   }
   else
   {
      if (x == ROOT)
      {
         nest--;

         if (selector['q'-'a']) printf("return on $root b=%x\n", bits);

         if (nest == 0)
         {
            if (pass)
            {
               y = cache_line - positions;

               /********************************************

                y = pending data bits

               ********************************************/

               if (y)
               {
                  x = bits % word;
                  if (x) lshift(&stage, word - x);
                  produce(y, '+', &stage, NULL);
                  stage = zero_o;
               }

               if (selector['q'-'a']) printf("[b %x]\n", y);
            }

            loc = address + (bits + word - 1) / word * quanta;
            if (selector['q'-'a']) printf("$=%x\n", loc);
         }

         if (bits == 0) return 0x80000000;

         return -bits;
      }

      if (x == DO)
      {
         k = NULL;

         if ((y = line[0]) && (y ^ ' '))
         {
            k = insert_qltable(line, 0, SET);
            k->l.valued = SET;
            k->l.r.i = 0;
            k->l.r.l.xref = masm_level;
         }

         if (argument)
         {
	    op = first_at(argument, ",");

            if (*op == ',')
            {
               y = expression(argument, op, "");

               for (x = 0; x < y; x++)
               {
                  if (k) quadinsert(x + 1, &k->l.value);
                  precord(l, op+1, data, nest);
               }
            }
            else flag("[tag] $do count,text");
         }
         else flag("[tag] $do count,text");

         return 0;
      }

      if (selector['q'-'a']) printf("[propose %s][D %p->%p]\n", line, data, *data);

      if ((x == WORD) || (x == BYTE) || (x == AWIDTH) || (x == QUANTUM))
      {
         /**************************************************************
		directive names which are also function names
		and can be tokens in the bit-size expression
                so drop thru
         **************************************************************/
      }
      else
      {
         if ((x == INCLUDE) || (x == RECORD) || (x == BYTE)
         ||  (x == IF)      || (x == ELSEIF) || (x == ENDIF)
	 ||  (x == LIST)    || (x == PLIST)
         ||  (x == OCTAL)   || (x == HEX)
	 ||  (x == SET)     || (x == EQU)
         ||  (x == SNAP)    || (x == TRACE)  || (x == NOP)                        
         ||  (x == NOTE)    || (x == FLAG)   || (x == EXIT))
         {
            assemble(line, argument, NULL, NULL);
         }
         else note("not processed within record template");
         return 0;
      }
   }


   argument = first_at(op, " ");
   symbol = 0;

   if (argument > op)
   {
      p = argument - 1;
      symbol = *p;

      if ((symbol == 'u') || (symbol == 's'))
      {
         y = *frightmost(op, argument);

         if ((y < '0') || (y > '9' + 1))
         {
            if (p > op)
            {
               p--;
               y = *p;
               if (y == ':') argument = p;
               else if ((y == ')') || (y == '\'') || (y == qchar)) argument = p + 1;
               else symbol = 0;
            }
            else symbol = 0;
         }
         else argument = p;
      }
   }

   x = expression(op, argument, NULL);

   #ifdef BRANCH
   if (x) branch_record &= branch_mask;

   /*****************************************************

	an intervening displacement means
	a following nest $record,$branch
	may not be a branch overlay on a
	previous $record,$branch
	
   *****************************************************/
   #endif

   if ((y = line[0]) && (y ^ ' '))
   {
      pointer = bits / word * quanta + address;
      position = bits % word;
      k = insert_qltable(line, pointer, EQUF);

      k->l.r = rflags;
      quadinsert1(rbase,    &k->l.value);         
      quadinsert3(position, &k->l.value);
      quadinsert4(x,        &k->l.value);
      y = uselector['Y'-'A'];
      if (symbol == 's') y = 1;
      if (symbol == 'u') y = 0;
      if (y) k->l.value.b[RADIX/8-5*4] = 128;
   }

   y = cache_line - positions;
   if (y == 0) loc = bits / word * quanta + address;
   offset = bits % word;
   bits += x;

   if (pass)
   {
      argument = *data;

      if (argument == NULL)
      {
         if (selector['q'-'a']) printf("[%x/%x/%x]", nest, positions, bits);
         if (y == 0) return 0;

         if ((x + y) > cache_line)
         {
            /*********************************************
		no new data to join to the cached data
            *********************************************/

            if ((offset = y % word)) lshift(&stage, word - offset);
            produce(y, '+', &stage, NULL);
            stage = zero_o;
            positions = cache_line;
            outstanding = 1;
            return 0;
         }

         /************************************************
		shift the cached data
		deplete available cache bit positions
         ************************************************/

         argument = "";
      }

      if (y == 0) positions -= offset;

      if (selector['q'-'a']) printf("[\"%s\" %x:%x, %x]",
                                     argument, loc, offset, positions);

      if ((*argument == qchar) || (x > 192))
      {
         mask = (byte == 32) ? 0xFFFFFFFF : (1 << byte) - 1;;

         for (;;)
         {
            x -= byte;
            if (x < 0) break;

            symbol = string_read(argument);
            argument = NULL;

            if (symbol)
            {
               /******************************************
				escaped zero
               ******************************************/

               if (symbol == zero_code_point) symbol = 0;
            }
            else symbol = string_space();

            symbol &= mask;

            positions -= byte;
            y = 0;

            if (positions < 0)
            {
               y = byte + positions;
               positions = cache_line;

               if (y)
               {
                  lshift(&stage, y);
                  lsword = quadextract(&stage);
                  lsword |= symbol >> (byte - y);
                  quadinsert(lsword, &stage);
               }

               produce(cache_line, '+', &stage, NULL);
               stage = zero_o;
               quadinsert(symbol, &stage);
               positions += y - byte;
            }

            lshift(&stage, byte);
            lsword = quadextract(&stage);
            lsword |= symbol;
            quadinsert(lsword, &stage);                    
         }

         if (x += byte)
         {
            positions -= x;

            if (positions < 0)
            {
               y = x + positions;
               positions = cache_line;
               if (y) lshift(&stage, y);
               produce(cache_line, '+', &stage, NULL);
               x -= y;
               positions -= x;
               stage = zero_o;
            }

            lshift(&stage, x);
         }
      }
      else
      {
         positions -= x;
         op = first_at(argument, " ");
         transient_floating_bits = x;
         threshold = xpression(argument, op, NULL);
         transient_floating_bits = 0;

         if (selector['q'-'a']) printf("[-%d=%d]\n", x, positions);

         if (positions < 0)
         {
            y = x + positions;
            positions = cache_line;

            if (y)
            {
               if (selector['q'-'a']) printf("[*/%x]", y);
               lshift(&stage, y);
               temp = *threshold;
               lshift(&temp, RADIX - x);
               rshift(&temp, RADIX - y);
               operand_or(&stage, &temp);
            }

            produce(positions, '+', &stage, NULL);
            if (selector['q'-'a']) printf("[B %x]\n", positions);
            x -= y;
            positions -= x;
            stage = zero_o;
         }

         lshift(&stage, x);
         temp = *threshold;
         lshift(&temp, RADIX - x);
         rshift(&temp, RADIX - x);
         operand_or(&stage, &temp);
      }

      if ((argument = *data)) *data = argument = getop(argument);
   }

   return 0;
}

static int record(object *l, char *data, int subfunction)
{
   #ifdef RECORD_BRANCH
   static int		 offset[STRUCTURE_DEPTH];
   static int		 record_high[STRUCTURE_DEPTH];
   #endif


   int			 origin;

   int                   x,
                         y;

   object		*o;
   char			*p;

   char                  line[256];

   int			 active_b4 = active_x;

   union { int	  p;
	   char	**q; }	 startp = { 0 } ;		


   if (l == NULL)
   {
      flag("$record must have a label");
      return 0;
   }

   if (active_x == STRUCTURE_DEPTH)
   {
      for (x = 0; x < STRUCTURE_DEPTH; x++)
      {
         flag_either_pass(active_instance[x]->l.name,
                          "$record nesting runaway");
      }

      brake("", "abandon");
   }

   l->l.passflag = masm_level;

   #ifdef RECORD_BRANCH
   if (!(branch_record & (1 << active_x))) record_high[active_x] = 0;

   if (subfunction == BRANCH)
   {
      if (selector['p'-'a'] )
      {
         printf("[$%x:%x:%x:]\n", counter_of_reference,
                                       loc,
                                       record_high[active_x]);
      }

      if ((branch_record & (1 << active_x))
      &&  (loc == branch_restart)
      &&  (o = active_instance[active_x]))
      {
         l->l.value = o->l.value;
         loc = qextractv(o);
         outstanding = 1;
         startp.p = offset[active_x] | 0x80000000 ;
      }

      branch_record |= 1 << active_x;
   }
   else branch_record &= (-1 ^ (1 << active_x));
   #endif


   active_instance[active_x] = l;
   offset[active_x] = origin = precord(l, NULL, startp.q, record_nest);
   active_x++;

   if (selector['p'-'a']) printf("$record %s nest %d active %d origin %d\n",
       l->l.name, record_nest, active_x, origin);

   if ((actual->flags & 129) == 1)
   {
      note("assembling $record data in giant address space without automatic base index");
      note("caution: data names in a $record do not contain giant adresses");
      note("load and use a base index override referencing these data names:  NAME,Rx");
      note("point the base index register to the start of the $record structure");
   }

   record_nest++;

   for (;;)
   {
      if (masm_level)
      {
         o = next_image[masm_level];
         y = o->t.length;
         o = (object *) ((char *) o + y);
         next_image[masm_level] = o;
         p = o->t.text;
         y = o->t.length;
         y -= 2;
      }
      else
      {
         y = getline(line, 250);
         p = line;
      }

      if (y < 0)
      {
         printf("eof in $record stop\n");
	 printf("%s\n", active_instance[active_x - 1]->l.name);
         exit(0);
      }

      if (selector['p'-'a']) printf("%s>\n", p);

      x = precord(l, p, &data, record_nest);

      if (x < 0) break;
   }

   #ifdef RECORD_BRANCH
   branch_record &= (1 << active_x) - 1;
   #endif

   record_nest--;
   active_x--;
   if (x == 0x80000000) x = 0;

   if (selector['p'-'a']) printf("%d %d action complete nest %d active %d\n",
                                  origin,  x, record_nest, active_x);

   if (active_x ^ active_b4)
   {
      printf("name tree manipulated out of line %x %x\n", active_x, active_b4);
      active_x = active_b4;
   }
         
   #ifdef RECORD_BRANCH
   if (branch_record & (1 << active_x))
   {
      /*************************************************************
		these numbers are positives represented as negatives
		so less is comparatively more
      *************************************************************/

      y = record_high[active_x];
      if (x < y) record_high[active_x] = y = x;
      else 
      {
         /*********************************************************
		force the global bits count to the highest
		it has been
         *********************************************************/

         if (selector['p'-'a']) printf("[< %d]\n", x);
         outstanding = 1;
      }

      if (record_nest == 0) loc = qextractv(l) - (y - word + 1) / word * quanta;
      else precord(l, NULL, (char **) (long) -y, -1);

      /*************************************************************
		less is still more
      *************************************************************/
   } 
   #endif

   x += origin;
   if (selector['p'-'a']) printf("[o %d %d %s]\n", origin, x, l->l.name);
   quadinsert4(-x, &l->l.value);

   l->l.valued = EQUF;
   if (selector['p'-'a'])
   {
      if (octal) printf("%0*o end\n", apw, loc);
      else       printf("%0*x end\n", apw, loc);
   }

   branch_restart = loc;
   return 0;
}

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


