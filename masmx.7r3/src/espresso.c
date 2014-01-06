#ifdef	ESPRESSO

static int i_complex(char *s, char *e)
{
   if (*s == '*') return complex(s + 1, e);
   if (*s == '(') return complex(s + 1, e);

   if (l2r_find('(', s, e)) return 1;
   if (next_operator(s, e, "*+\0*-\0", EXCLUDE_OPERATORS)) return 1;
   return 0;
}

static int i_complex_beyond_or(char *s, char *e)
{
   if (l2r_find('(', s, e)) return 1;
   if (next_operator(s, e, "++\0*+\0*-\0", EXCLUDE_OPERATORS)) return 1;
   return 0;
}

static int i_complex_beyond_xor(char *s, char *e)
{  
   if (l2r_find('(', s, e)) return 1;
   if (next_operator(s, e, "--\0*+\0*-\0", EXCLUDE_OPERATORS)) return 1;
   return 0;
}     

static int i_complex_beyond_and(char *s, char *e)
{  
   if (l2r_find('(', s, e)) return 1;
   if (next_operator(s, e, "**\0*+\0*-\0", EXCLUDE_OPERATORS)) return 1;
   return 0;
}    

static int i_complex_beyond_add(char *s, char *e)
{  
   if (l2r_find('(', s, e)) return 1;
   if (next_operator(s, e, "+\0*+\0*-\0", EXCLUDE_OPERATORS)) return 1;
   return 0;
}     

static int i_complex_beyond_multiply(char *s, char *e)
{  
   if (l2r_find('(', s, e)) return 1;
   if (next_operator(s, e, "*\0*+\0*-\0", EXCLUDE_OPERATORS)) return 1;
   return 0;
}     

static int storage_addresses(char *s, char *e)
{
   char			*p;


   while (s < e)
   {
      if (*s == '(') return storage_addresses(s + 1, e - 1);
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

static void i_xpress(char *s, char *e)
{
   char                 *p,
                        *q = s;

   int                   unary = *s;
   int			 symbol;


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
         q = p + ofield;
         symbol = 0;
         if (ofield > 1) symbol = *(p + 1);

         if ((i_complex(q, e)) && (storage_addresses(q, e)))
         {
            i_xpress(q, e);

            switch (*p)
            {
               case '=':
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p);
                  fpxpress_asmq(" $i_retrieve_testequal ");
                  break;

               case '^':
                  if (symbol == '=')
                  {
                     fpxpress_asmq(" $i_reserve ");
                     i_xpress(s, p);
                     fpxpress_asmq(" $i_retrieve_testunequal ");
                  }

                  break;

               case '>':
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p);
                  fpxpress_asmq(" $i_retrieve_testgreater ");
                  break;

               case '<':
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p);
                  fpxpress_asmq(" $i_retrieve_testless ");
                  break;

               case '-':
                  if (symbol == '-')
                  {
                     if ((i_complex_beyond_xor(s, p)) && (storage_addresses(s, p)))
                     {
                        fpxpress_asmq(" $i_reserve ");
                        i_xpress(s, p);
                        fpxpress_asmq(" $i_retrieve_xor ");
                        break;
                     }

                     fpxpress_assemble(" $i_xor ", s, p);

                     while (s = next_operator(s, p, "--\0", 0))
                     {
                        s += ofield;
                        fpxpress_assemble(" $i_xor ", s, p);
                     }

                     break;
                  }

                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p);
                  fpxpress_asmq(" $i_retrieve_subtract ");
                  break;

               case '+':
                  if (symbol == '+')
                  {
                     if ((i_complex_beyond_or(s, p)) && (storage_addresses(s, p)))
                     {
                        fpxpress_asmq(" $i_reserve ");
                        i_xpress(s, p);
                        fpxpress_asmq(" $i_retrieve_or ");
                        break;
                     }

                     fpxpress_assemble(" $i_or ", s, p);

                     while (s = next_operator(s, p, "++\0", 0))
                     {
                        s += ofield;
                        fpxpress_assemble(" $i_or ", s, p);
                     }
                     break;
                  }

                  if ((i_complex_beyond_add(s, p)) && (storage_addresses(s, p)))
                  {
                     fpxpress_asmq(" $i_reserve ");
                     i_xpress(s, p);
                     fpxpress_asmq(" $i_retrieve_add ");
                     break;
                  }

                  fpxpress_assemble(" $i_add ", s, p);

                  while (s = next_operator(s, p, "+\0", 0))
                  {
                     s += ofield;
                     fpxpress_assemble(" $i_add ", s, p);
                  }

                  break;

               case '*':
                  if (symbol == '/')
                  {
                     fpxpress_asmq(" $i_reserve ");
                     i_xpress(s, p);
                     fpxpress_asmq(" $i_retrieve_shift ");
                     break;
                  }

                  if (symbol == '*')
                  {
                     if ((i_complex_beyond_and(s, p)) && (storage_addresses(s, p)))
                     {
                        fpxpress_asmq(" $i_reserve ");
                        i_xpress(s, p);
                        fpxpress_asmq(" $i_retrieve_and ");
                        break;
                     }

                     fpxpress_assemble(" $i_and ", s, p);

                     while (s = next_operator(s, p, "**\0", 0))
                     {
                        s += ofield;
                        fpxpress_assemble(" $i_and ", s, p);
                     }

                     break;
                  }

                  if ((i_complex_beyond_multiply(s, p)) && (storage_addresses(s, p)))
                  {
                     fpxpress_asmq(" $i_reserve ");
                     i_xpress(s, p);
                     fpxpress_asmq(" $i_retrieve_multiply ");
                     break;
                  }

                  fpxpress_assemble(" $i_multiply ", s, p);

                  while (s = next_operator(s, p, "*\0", 0))
                  {
                     s += ofield;
                     fpxpress_assemble(" $i_multiply ", s, p);
                  }

                  break;

               case '/':
                  if (symbol == '*')
                  {
                     fpxpress_asmq(" $i_reserve ");
                     i_xpress(s, p);
                     fpxpress_asmq(" $i_retrieve_shift_right ");
                     break;
                  }

                  if (symbol == '/')
                  {
                     if (*(p + 2) == '/')
                     {
                        fpxpress_asmq(" $i_reserve ");
                        i_xpress(s, p);
                        fpxpress_asmq(" $i_retrieve_remainder ");
                        break;
                     }

                     fpxpress_asmq(" $i_reserve ");
                     i_xpress(s, p);
                     fpxpress_asmq(" $i_retrieve_covered_quotient ");
                     break;
                  }

                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p);
                  fpxpress_asmq(" $i_retrieve_divide ");
            }
         }
         else
         {
            i_xpress(s, p);
            if (*q == '(') q++;

            switch(*p)
            {
               case '=':
                  fpxpress_assemble( "$i_testequal ", q, e);
                  break;

               case '^':
                  if (symbol == '-')
                  {
                     fpxpress_assemble( "$i_testunequal ", q, e);
                  }

                  break;

               case '>':
                  fpxpress_assemble( "$i_testgreater ", q, e);
                  break;

               case '<':
                  fpxpress_assemble( "$i_testless ", q, e);
                  break;

               case '-':
                  if (symbol == '-')
                  {
                     fpxpress_assemble( " $i_xor ", q, e);
                     break;
                  }

                  fpxpress_assemble(" $i_subtract ", q, e);
                  break;

               case '+':
                  if (symbol == '+')
                  {
                     fpxpress_assemble( " $i_or ", q, e);
                     break;
                  }

                  fpxpress_assemble(" $i_add ", q, e);
                  break;

               case '*':
                  if (symbol == '*')
                  {
                     fpxpress_assemble( " $i_and ", q, e);
                     break;
                  }

                  if (symbol == '/')
                  {
                     fpxpress_assemble( " $i_shift ", q, e);
                     break;
                  }

                  fpxpress_assemble(" $i_multiply ", q, e);
                  break;

               case '/':
                  if (symbol == '*')
                  {
                     fpxpress_assemble( " $i_shift_right ", q, e);
                     break;
                  }

                  if (symbol == '/')
                  {
                     if (*(p + 2) == '/')
                     {
                        fpxpress_assemble( " $i_remainder ", q, e);
                        break;
                     }

                     fpxpress_assemble( " $i_covered_quotient ", q, e);
                     break;
                  }

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
