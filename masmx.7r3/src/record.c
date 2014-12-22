#ifdef	RECORD

static int precord(object *l, char *line, char **data, int nest)
{
   static long		 bits;
   static int		 positions;
   static int		 cache_line;
   static long		 address;
   static long		 rbase;
   static linkage	 rflags;
   static line_item	 stage;


   line_item		 temp;
   line_item		*threshold;
   object               *q;
   object               *k;

   int                   x,
                         y;

   int			 offset;

   long			 symbol,
                         mask,
			 lsword;

   char                 *op;
   char                 *argument;
   char			*p;


   if (line == NULL)
   {
      /***************************************************
		**data nonzero is an overlay or union
      ***************************************************/

      #ifdef RECORD_BRANCH
      if (data)
      {
         bits = (long) data;
         if (nest < 0)
         {
            if (y = cache_line - positions)
            {
               if (x = y % word) lshift(&stage, word - x);
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

         if (selector['q'-'a']) printf("R %s %lx\n", l->l.name,
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

         if (selector['q'-'a']) printf("r %s %lx:%lx\n", l->l.name,
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

         if (selector['q'-'a']) printf("return on $root b=%lx\n", bits);

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
            if (selector['q'-'a']) printf("$=%lx\n", loc);
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
         y = frightmost(op, argument);

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

   if ((y = line[0]) && (y ^ ' '))
   {
      k = insert_qltable(line, bits / word * quanta + address, EQUF);

      k->l.r = rflags;
      quadinsert1(rbase,       &k->l.value);         
      quadinsert3(bits % word, &k->l.value);
      quadinsert4(x,           &k->l.value);
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
         if (selector['q'-'a']) printf("[%x/%x/%lx]", nest, positions, bits);
         if (y == 0) return 0;

         if ((x + y) > cache_line)
         {
            /*********************************************
		no new data to join to the cached data
            *********************************************/

            if (offset = y % word) lshift(&stage, word - offset);
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

      if (selector['q'-'a']) printf("[\"%s\" %lx:%x, %x]",
                                     argument, loc, offset, positions);

      if ((*argument == qchar) || (x > 192))
      {
         mask = (1 << byte) - 1;

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
         threshold = xpression(argument, op, NULL);

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

      if (argument = *data) *data = argument = getop(argument);
   }

   return 0;
}

static int record(object *l, char *data, int subfunction)
{
   static int            nest;

   #ifdef RECORD_BRANCH
   static int		 branch_record;
   static long		 offset[STRUCTURE_DEPTH];
   static long		 record_high[STRUCTURE_DEPTH];
   #endif


   long			 origin;

   int                   x,
                         y;

   object		*o;
   char			*p;

   char                  line[124];

   int			 active_b4 = active_x;

   union { long	  p;
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

   #ifdef RECORD_BRANCH
   if (!(branch_record & (1 << active_x))) record_high[active_x] = 0;

   if (subfunction == BRANCH)
   {
      if (selector['p'-'a']) printf("[SF]");
      if ((branch_record & (1 << active_x))
      &&  (o = active_instance[active_x]))
      {
         l->l.value = o->l.value;
         loc = qextractv(o);
         outstanding = 1;
         startp.p = offset[active_x]; 
      }

      branch_record |= 1 << active_x;
   }
   else branch_record &= (-1 ^ (1 << active_x));
   #endif

   active_instance[active_x] = l;
   offset[active_x] = origin = precord(l, NULL, startp.q, nest);
   active_x++;

   if (selector['p'-'a']) printf("$record %s nest %d active %d origin %ld\n",
       l->l.name, nest, active_x, origin);

   nest++;

   for (;;)
   {
      if (masm_level)
      {
         o = next_image[masm_level];
         y = o->t.length;
         o = (object *) ((long) o + y);
         next_image[masm_level] = o;
         p = o->t.text;
         y -= 2;
      }
      else
      {
         y = getline(line, 122);
         p = line;
      }

      if (y < 0)
      {
         if (selector['p'-'a']) printf("eof stop\n");
         break;
      }

      if (selector['p'-'a']) printf("%s>\n", p);

      x = precord(l, p, &data, nest);

      if (x < 0) break;
   }

   #ifdef RECORD_BRANCH
   branch_record &= (1 << active_x) - 1;
   #endif

   nest--;
   active_x--;
   if (x == 0x80000000) x = 0;
   if (selector['p'-'a']) printf("%ld %d action complete nest %d active %d\n",
                                  origin,  x, nest, active_x);

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

      if (nest == 0) loc = qextractv(l) - (y - word + 1) / word * quanta;
      else precord(l, NULL, (char **) (long) -y, -1);

      /*************************************************************
		less is still more
      *************************************************************/
   } 
   #endif

   x += origin;
   if (selector['p'-'a']) printf("[o %ld %d %s]\n", origin, x, l->l.name);
   quadinsert4(-x, &l->l.value);

   l->l.valued = EQUF;
   if (selector['p'-'a']) printf("end\n");
   return 0;
}

#endif
