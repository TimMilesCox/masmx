#ifdef	ESPRESSO

static int storage_addresses(char *s, char *e)
{
   char			*p;


   while (s < e)
   {
      if (*s == '(')
      {
         p = fendb(s, e);
         if (storage_addresses(s+1, p)) return 1;
         return storage_addresses(p + 1, e);
      }

      if (*s == '+') return storage_addresses(s + 1, e);
      if (*s == '-') return storage_addresses(s + 1, e);

      if (p = next_operator(s, e, NULL, 0))
      {
         if (number(s, p) == 0) return 1;
         s = p + ofield;
      }
      else
      {
         if (number(s, e) == 0) return 1;
         s = e;
      }
   }

   return 0;
}

static void trailing_integer_operation(int x, char *s, char *e)
{
   if (*s == '(') s++;

   switch (x)
   {
      case OR:
         fpxpress_assemble(" $i_or ", s, e);
         break;

      case XOR:
         fpxpress_assemble(" $i_xor ", s, e);
         break;

      case PLUS:
         fpxpress_assemble(" $i_add ", s, e);
         break;

      case MINUS:
         fpxpress_assemble(" $i_subtract ", s, e);
         break;

      case MULTIPLY:
         fpxpress_assemble(" $i_multiply ", s, e);
         break;

      case DIVIDE:
         fpxpress_assemble(" $i_divide ", s, e);
         break;

      case COVERED_QUOTIENT:
         fpxpress_assemble(" $i_covered_quotient ", s, e);
         break;

      case REMAINDER:
         fpxpress_assemble(" $i_remainder ", s, e);
         break;
   }
}


static void i_xpress(char *s, char *e)
{
   char                 *p,
                        *q = s;

   int                   unary = *s;
   int			 symbol;
   int			 this_operator;


   if (storage_addresses(s, e))
   {
      if ((unary == '+') || (unary == '-')
      ||  (unary == '*') || (unary == '^')) q++;

      if ((p = contains(q, e, "=\0^=\0"))
      ||  (p = contains(q, e, ">\0<\0"))
      ||  (p = contains(q, e, "--\0++\0"))
      ||  (p = contains(q, e, "/*\0*/\0"))
      ||  (p = contains(q, e, "**\0"))
      ||  (p = contains(q, e, "+\0-\0"))
      ||  (p = contains(q, e, "/\0//\0///\0*\0")))
      {
         this_operator = oper_ator(p, e - p);
         q = p + ufield[this_operator];

         symbol = 0;
         if (ofield > 1) symbol = *(p + 1);


         if ((complex(q, e)) && (storage_addresses(q, e)))
         {
            i_xpress(q, e);
 
            switch (this_operator)
            {
               case EQUAL:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p);
                  fpxpress_asmq(" $i_retrieve_testequal ");
                  break;

               case UNEQUAL:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p);
                  fpxpress_asmq(" $i_retrieve_testunequal ");

                  break;

               case GREATER:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p);
                  fpxpress_asmq(" $i_retrieve_testgreater ");
                  break;

               case LESS:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p);
                  fpxpress_asmq(" $i_retrieve_testless ");
                  break;

               case XOR:
                  if ((complex_beyond(s, p, "++\0--\0*+\0*-\0")) && (storage_addresses(s, p)))
                  {
                     fpxpress_asmq(" $i_reserve ");
                     i_xpress(s, p);
                     fpxpress_asmq(" $i_retrieve_xor ");
                     break;
                  }

                  while (q = next_operator(s, p, "++\0--\0", 0))
                  {
                     trailing_integer_operation(this_operator, s, q);
                     this_operator = oper_ator(q, p - q);
                     s = q + ufield[this_operator];
                  }

                  trailing_integer_operation(this_operator, s, p);

                  break;

               case MINUS:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p);
                  fpxpress_asmq(" $i_retrieve_subtract ");
                  break;

               case OR:
                  if ((complex_beyond(s, p, "++\0--\0*+\0*-\0")) && (storage_addresses(s, p)))
                  {
                     fpxpress_asmq(" $i_reserve ");
                     i_xpress(s, p);
                     fpxpress_asmq(" $i_retrieve_or ");
                     break;
                  }

                  while (q = next_operator(s, p, "++\0--\0", 0))
                  {
                     trailing_integer_operation(this_operator, s, q);
                     this_operator = oper_ator(q, p - q);
                     s = q + ufield[this_operator];
                  }

                  trailing_integer_operation(this_operator, s, p);


                  break;

               case PLUS:
                  if ((complex_beyond(s, p, "+\0-\0*+\0*-\0")) && (storage_addresses(s, p)))
                  {
                     fpxpress_asmq(" $i_reserve ");
                     i_xpress(s, p);
                     fpxpress_asmq(" $i_retrieve_add ");
                     break;
                  }


                  while (q = next_operator(s, p, "+\0-\0", 0))
                  {
                     trailing_integer_operation(this_operator, s, q);
                     this_operator = oper_ator(q, p - q);
                     s = q + ufield[this_operator];
                  }

                  trailing_integer_operation(this_operator, s, p);


                  break;

               case SHIFT:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p);
                  fpxpress_asmq(" $i_retrieve_shift ");
                  break;

               case AND:
                  if ((complex_beyond(s, p, "**\0*+\0*-\0")) && (storage_addresses(s, p)))
                  {
                     fpxpress_asmq(" $i_reserve ");
                     i_xpress(s, p);
                     fpxpress_asmq(" $i_retrieve_and ");
                     break;
                  }

                  while (q = next_operator(s, p, "**\0", 0))
                  {
                     fpxpress_assemble(" $i_and ",  s, q);
                     s = q + ufield[AND];
                  }

                  fpxpress_assemble(" $i_and ", s, p);

                  break;

               case MULTIPLY:
                  if ((complex_beyond(s, p, "*\0///\0//\0/\0*+\0*-\0")) && (storage_addresses(s, p)))
                  {
                     fpxpress_asmq(" $i_reserve ");
                     i_xpress(s, p);
                     fpxpress_asmq(" $i_retrieve_multiply ");
                     break;
                  }

                  while (q = next_operator(s, p, "*\0///\0//\0/\0", 0))
                  {
                     trailing_integer_operation(this_operator, s, q);
                     this_operator = oper_ator(q, p - q);
                     s = q + ufield[this_operator]; 
                  }

                  trailing_integer_operation(this_operator, s, p);

                  break;

               case SHIFT_RIGHT:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p);
                  fpxpress_asmq(" $i_retrieve_shift_right ");
                  break;

               case REMAINDER:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p);
                  fpxpress_asmq(" $i_retrieve_remainder ");
                  break;

               case COVERED_QUOTIENT:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p);
                  fpxpress_asmq(" $i_retrieve_covered_quotient ");
                  break;

               case DIVIDE:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p);
                  fpxpress_asmq(" $i_retrieve_divide ");
            }
         }
         else
         {
            i_xpress(s, p);
            if (*q == '(') q++;

            switch (this_operator)
            {
               case EQUAL:
                  fpxpress_assemble( "$i_testequal ", q, e);
                  break;

               case UNEQUAL:
                  fpxpress_assemble( "$i_testunequal ", q, e);
                  break;

               case GREATER:
                  fpxpress_assemble( "$i_testgreater ", q, e);
                  break;

               case LESS:
                  fpxpress_assemble( "$i_testless ", q, e);
                  break;

               case XOR:
                  fpxpress_assemble( " $i_xor ", q, e);
                  break;

               case MINUS:
                  fpxpress_assemble(" $i_subtract ", q, e);
                  break;

               case OR:
                  fpxpress_assemble( " $i_or ", q, e);
                  break;

               case PLUS:
                  fpxpress_assemble(" $i_add ", q, e);
                  break;

               case AND:
                  fpxpress_assemble( " $i_and ", q, e);
                  break;

               case SHIFT:
                  fpxpress_assemble( " $i_shift ", q, e);
                  break;

               case MULTIPLY:
                  fpxpress_assemble(" $i_multiply ", q, e);
                  break;

               case SHIFT_RIGHT:
                  fpxpress_assemble( " $i_shift_right ", q, e);
                  break;

               case REMAINDER:
                  fpxpress_assemble( " $i_remainder ", q, e);
                  break;

               case COVERED_QUOTIENT:
                  fpxpress_assemble( " $i_covered_quotient ", q, e);
                  break;

               case DIVIDE:
                  fpxpress_assemble(" $i_divide ", q, e);
            }
         }

         return;
      }
   }

   if (*s == '(')
   {
      i_xpress(s + 1, e);
      return;
   }

   unary = *s;

   if ((unary == '+') || (unary == '-'))
   {
      if (number(s + 1, e) == 0)
      {
         if (unary == '+') fpxpress_assemble(" $i_load ",          s + 1, e);
         else              fpxpress_assemble(" $i_load_negative ", s + 1, e);

         return;
      }
   }

   fpxpress_assemble(" $i_load ", s, e);
}


#endif
