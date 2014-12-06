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



   if (line == NULL)
   {
      /***************************************************
		initialising call
		outermost record
      ***************************************************/

      if (nest == 0)
      {
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
   x = expression(op, argument, NULL);

   if ((y = line[0]) && (y ^ ' '))
   {
      k = insert_qltable(line, bits / word * quanta + address, EQUF);

      k->l.r = rflags;
      quadinsert1(rbase,       &k->l.value);         
      quadinsert3(bits % word, &k->l.value);
      quadinsert4(x,           &k->l.value);
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

static int record(object *l, char *data)
{
   static int            nest;

   long			 origin;
   int                   x,
                         y;

   object		*o;
   char			*p;

   char                  line[124];

   int			 active_b4 = active_x;


   if (l == NULL)
   {
      flag("$record must have a label");
      return 0;
   }

   active_instance[active_x++] = l;

   origin = precord(l, NULL, NULL, nest);

   if (selector['p'-'a']) printf("$record %s nest %d active %d\n", l->l.name, nest, active_x);

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

      if (x < 0)
      {
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
         

         x += origin;
         quadinsert4(-x, &l->l.value);
         break;
      }
   }

   l->l.valued = EQUF;
   if (selector['p'-'a']) printf("end\n");
   return 0;
}

#endif
