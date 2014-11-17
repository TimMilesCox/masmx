#ifdef	RECORD

static int precord(object *l, char *line, char **data, int bytes)
{
   static int		 bits;
   static int		 positions;
   static long		 address;
   static long		 rbase;
   static line_item	 stage;


   line_item		 temp;
   line_item		*threshold;
   object               *q;
   object               *k;

   int                   x,
                         y,
                         field;

   char                 *op;
   char                 *argument;

   if (line == NULL)
   {
      /***************************************************
		initialising call
		outermost record
      ***************************************************/

      bits = 0;
      address = loc;
      rbase = actual->rbase;
      stage = zero_o;
      positions = RADIX / word * word;
      outstanding = 1;
      return 0;
   }

   if (selector['q'-'a']) printf("%s<\n", line);

   op = getop(line);
   argument = NULL;

   if (op)
   {
      argument = getop(op);
      x = meaning(op);
   }
   else return 0;

   if (x < 0)
   {
   }
   else
   {
      if (x == ROOT)
      {
         active_x--;

         if ((pass  == 0)
         ||  (*data == NULL)) loc = address + (bits + word - 1) / word;
         if (selector['q'-'a']) printf("return on $root $=%lx\n", loc);

         return -1;
      }

      if (x == END) return RETURN;

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
               y = expression(argument, op, NULL);

               field = strlen(op+ 1);
               for (x = 0; x < y; x++)
               {
                  if (k) quadinsert(x + 1, &k->l.value);
                  precord(l, op+1, data, field);
               }
            }
            else flag("[tag] $do count,text");
         }
         else flag("[tag] $do count,text");

         return 0;
      }

      if ((x == RECORD) && (argument = *data))
      {
         printf("[%s]\n", *data);
         return record(l, data);
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
         if ((x == INCLUDE) || (x == RECORD) || (x==SNAP)
         ||  (x == IF)      || (x == ELSEIF) || (x == ENDIF)
         ||  (x == EXIT))
         {
            assemble(line, NULL, NULL, NULL);
         }
         else note("not processed within record template");
         return 0;
      }
   }

   argument = first_at(op, " ");
   x = expression(op, argument, NULL);

   if ((y = line[0]) && (y ^ ' '))
   {
      k = insert_qltable(line, bits / word + address, EQUF);

      quadinsert1(rbase,       &k->l.value);         
      quadinsert3(bits % word, &k->l.value);
      quadinsert4(x,           &k->l.value);
   }

   bits += x;

   if (pass)
   {
      if (selector['q'-'a']) printf("[**%p]", data);
      if (argument = *data)
      {
         if (selector['q'-'a'])
         {
            printf("[*%p]", argument);
            if (argument) printf("[\"%s\"]", argument);
         }

         if (*argument == qchar)
         {
         }
         else
         {
            op = first_at(argument, " ");
            threshold = xpression(argument, op, NULL);
            positions -= x;

            if (selector['q'-'a']) printf("[-%d=%d]\n", x, positions);

            if (positions < 0)
            {
               y = x + positions;
               positions = RADIX / word * word;

               if (y)
               {
                  lshift(&stage, y);
                  temp = *threshold;
                  lshift(&temp, RADIX - x);
                  rshift(&temp, RADIX - y);
                  operand_or(&stage, &temp);
               }

               produce(positions, '+', &stage, NULL);
               if (selector['q'-'a']) printf("[B %d]\n", positions);
               x -= y;
               positions -= x;
            }

            lshift(&stage, x);
            temp = *threshold;
            lshift(&temp, RADIX - x);
            rshift(&temp, RADIX - x);
            operand_or(&stage, &temp);
         }

         *data = argument = getop(argument);

         if (argument == NULL)
         {
            y = RADIX / word * word;
            y -= positions;

            /********************************************

		y = pending data bits

            ********************************************/

            if (y)
            {
               if (x = y % word) lshift(&stage, word - x);
               produce(y, '+', &stage, NULL);
            }

            if (selector['q'-'a']) printf("[b %d]\n", y);

         }
      }
   }

   return 0;
}

static int record(object *l, char **data)
{
   static int            nest;


   int                   x,
                         y;

   object		*o;
   char			*p;

   char                  line[124];



   if (l == NULL)
   {
      flag("$record must have a label");
      return;
   }

   active_instance[active_x++] = l;

   if (nest == 0) precord(l, NULL, NULL, 0);

   if (selector['p'-'a']) printf("$record %s nest %d active %d\n", l->l.name, nest, active_x);

   nest++;

   for (;;)
   {
      if (masm_level)
      {
         o = next_image[masm_level];
         y = o->t.length;
/*         p = o->t.text; */
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

      x = precord(l, p, data, y);

      if (x == RETURN) return RETURN;

      if (x < 0)
      {
         nest--;
         if (selector['p'-'a']) printf("action complete nest %d active %d\n", nest, active_x);
         break;
      }
   }

   if (selector['p'-'a']) printf("end\n");
   return 0;
}

#endif
