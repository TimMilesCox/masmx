
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



#ifdef	ESPRESSO

static int storage_addresses(char *s, char *e)
{
   char			*p;


   while (s < e)
   {
      if (*s == ' ')
      {
         s++;
         continue;
      }

      if (*s == '(')
      {
         p = fendb(s, e);
         if (storage_addresses(s+1, p)) return 1;
         return storage_addresses(p + 1, e);
      }

      if (*s == '+') return storage_addresses(s + 1, e);
      if (*s == '-') return storage_addresses(s + 1, e);

      if ((p = next_binary_operator(s, e, NULL, 0)))
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

static void trailing_integer_operation(int x, char *s, char *e, char *tag)
{
   if (*s == '(') s++;

   switch (x)
   {
      case OR:
         fpxpress_assemble(" $i_or ", s, e, tag);
         break;

      case XOR:
         fpxpress_assemble(" $i_xor ", s, e, tag);
         break;

      case PLUS:
         fpxpress_assemble(" $i_add ", s, e, tag);
         break;

      case MINUS:
         fpxpress_assemble(" $i_subtract ", s, e, tag);
         break;

      case MULTIPLY:
         fpxpress_assemble(" $i_multiply ", s, e, tag);
         break;

      case DIVIDE:
         fpxpress_assemble(" $i_divide ", s, e, tag);
         break;

      case COVERED_QUOTIENT:
         fpxpress_assemble(" $i_covered_quotient ", s, e, tag);
         break;

      case REMAINDER:
         fpxpress_assemble(" $i_remainder ", s, e, tag);
         break;
   }
}


static void i_xpress(char *s, char *e, char *tag)
{
   char                 *p,
                        *q = s;

   int                   unary = *s;
   int			 symbol;
   int			 this_operator;


   #if 0
   while (*s == ' ') *s++;
   #endif

   if (storage_addresses(s, e))
   {
      #if 0
      if ((unary == '+') || (unary == '-')
      ||  (unary == '*') || (unary == '^')) q++;
      #endif

      #if OPERATORS == 19
      if ((p = operates(q, e, "^=\0=\0"))
      ||  (p = operates(q, e, "^>\0>\0"))
      ||  (p = operates(q, e, "^<\0<\0"))
      ||  (p = operates(q, e, "--\0++\0"))
      ||  (p = operates(q, e, "/*\0*/\0"))
      ||  (p = operates(q, e, "**\0"))
      ||  (p = operates(q, e, "+\0-\0"))
      ||  (p = operates(q, e, "/\0//\0///\0*\0")))
      #endif

      #if OPERATORS == 17
      if ((p = operates(q, e, "^=\0=\0"))
      ||  (p = operates(q, e, ">\0<\0"))
      ||  (p = operates(q, e, "--\0++\0"))
      ||  (p = operates(q, e, "/*\0*/\0"))
      ||  (p = operates(q, e, "**\0"))
      ||  (p = operates(q, e, "+\0-\0"))
      ||  (p = operates(q, e, "/\0//\0///\0*\0")))
      #endif
      {
         this_operator = oper_ator(p, e - p);
         q = p + ufield[this_operator];

         while (*q == ' ') q++;

         symbol = 0;
         if (ofield > 1) symbol = *(p + 1);


         if ((complex(q, e)) && (storage_addresses(q, e)))
         {
            i_xpress(q, e, tag);
 
            switch (this_operator)
            {
               case EQUAL:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p, tag);
                  fpxpress_asmq(" $i_retrieve_testequal ");
                  break;

               case UNEQUAL:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p, tag);
                  fpxpress_asmq(" $i_retrieve_testunequal ");

                  break;

                  #if OPERATORS == 19
               case NOT_GREATER:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p, tag);
                  fpxpress_asmq(" $i_retrieve_test_nogreater ");
                  break;
                  #endif

               case GREATER:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p, tag);
                  fpxpress_asmq(" $i_retrieve_testgreater ");
                  break;

                  #if OPERATORS == 19
               case NOT_LESS:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p, tag);
                  fpxpress_asmq(" $i_retrieve_test_noless ");
                  break;
                  #endif

               case LESS:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p, tag);
                  fpxpress_asmq(" $i_retrieve_testless ");
                  break;

               case XOR:
                  if ((complex_beyond(s, p, "++\0--\0*+\0*-\0")) && (storage_addresses(s, p)))
                  {
                     fpxpress_asmq(" $i_reserve ");
                     i_xpress(s, p, tag);
                     fpxpress_asmq(" $i_retrieve_xor ");
                     break;
                  }

                  while ((q = next_operator(s, p, "++\0--\0", 0)))
                  {
                     trailing_integer_operation(this_operator, s, q, tag);
                     this_operator = oper_ator(q, p - q);
                     s = q + ufield[this_operator];
                  }

                  trailing_integer_operation(this_operator, s, p, tag);

                  break;

               case MINUS:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p, tag);
                  fpxpress_asmq(" $i_retrieve_subtract ");
                  break;

               case OR:
                  if ((complex_beyond(s, p, "++\0--\0*+\0*-\0")) && (storage_addresses(s, p)))
                  {
                     fpxpress_asmq(" $i_reserve ");
                     i_xpress(s, p, tag);
                     fpxpress_asmq(" $i_retrieve_or ");
                     break;
                  }

                  while ((q = next_operator(s, p, "++\0--\0", 0)))
                  {
                     trailing_integer_operation(this_operator, s, q, tag);
                     this_operator = oper_ator(q, p - q);
                     s = q + ufield[this_operator];
                  }

                  trailing_integer_operation(this_operator, s, p, tag);


                  break;

               case PLUS:
                  if ((complex_beyond(s, p, "+\0-\0*+\0*-\0")) && (storage_addresses(s, p)))
                  {
                     fpxpress_asmq(" $i_reserve ");
                     i_xpress(s, p, tag);
                     fpxpress_asmq(" $i_retrieve_add ");
                     break;
                  }


                  while ((q = next_operator(s, p, "+\0-\0", 0)))
                  {
                     trailing_integer_operation(this_operator, s, q, tag);
                     this_operator = oper_ator(q, p - q);
                     s = q + ufield[this_operator];
                  }

                  trailing_integer_operation(this_operator, s, p, tag);


                  break;

               case SHIFT:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p, tag);
                  fpxpress_asmq(" $i_retrieve_shift ");
                  break;

               case AND:
                  if ((complex_beyond(s, p, "**\0*+\0*-\0")) && (storage_addresses(s, p)))
                  {
                     fpxpress_asmq(" $i_reserve ");
                     i_xpress(s, p, tag);
                     fpxpress_asmq(" $i_retrieve_and ");
                     break;
                  }

                  while ((q = next_operator(s, p, "**\0", 0)))
                  {
                     fpxpress_assemble(" $i_and ",  s, q, tag);
                     s = q + ufield[AND];
                  }

                  fpxpress_assemble(" $i_and ", s, p, tag);

                  break;

               case MULTIPLY:			/*	"*\0///\0//\0/\0*+\0*-\0"	*/
                  if ((complex_beyond(s, p, "*+\0*-\0")) && (storage_addresses(s, p)))
                  {
                     fpxpress_asmq(" $i_reserve ");
                     i_xpress(s, p, tag);
                     fpxpress_asmq(" $i_retrieve_multiply ");
                     break;
                  }

                  while ((q = next_operator(s, p, "*\0///\0//\0/\0", 0)))
                  {
                     trailing_integer_operation(this_operator, s, q, tag);
                     this_operator = oper_ator(q, p - q);
                     s = q + ufield[this_operator]; 
                  }

                  trailing_integer_operation(this_operator, s, p, tag);

                  break;

               case SHIFT_RIGHT:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p, tag);
                  fpxpress_asmq(" $i_retrieve_shift_right ");
                  break;

               case REMAINDER:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p, tag);
                  fpxpress_asmq(" $i_retrieve_remainder ");
                  break;

               case COVERED_QUOTIENT:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p, tag);
                  fpxpress_asmq(" $i_retrieve_covered_quotient ");
                  break;

               case DIVIDE:
                  fpxpress_asmq(" $i_reserve ");
                  i_xpress(s, p, tag);
                  fpxpress_asmq(" $i_retrieve_divide ");
            }
         }
         else
         {
            i_xpress(s, p, tag);
            if (*q == '(') q++;

            while (*q == ' ') q++;

            switch (this_operator)
            {
               case EQUAL:
                  fpxpress_assemble( " $i_testequal ", q, e, tag);
                  break;

               case UNEQUAL:
                  fpxpress_assemble( " $i_testunequal ", q, e, tag);
                  break;

                  #if OPERATORS == 19
               case NOT_GREATER:
                  fpxpress_assemble( " $i_test_nogreater ", q, e, tag);
                  break;
                  #endif

               case GREATER:
                  fpxpress_assemble( " $i_testgreater ", q, e, tag);
                  break;

                  #if OPERATORS == 19
               case NOT_LESS:
                  fpxpress_assemble( " $i_test_noless ", q, e, tag);
                  break;
                  #endif

               case LESS:
                  fpxpress_assemble( " $i_testless ", q, e, tag);
                  break;

               case XOR:
                  fpxpress_assemble( " $i_xor ", q, e, tag);
                  break;

               case MINUS:
                  fpxpress_assemble(" $i_subtract ", q, e, tag);
                  break;

               case OR:
                  fpxpress_assemble( " $i_or ", q, e, tag);
                  break;

               case PLUS:
                  fpxpress_assemble(" $i_add ", q, e, tag);
                  break;

               case AND:
                  fpxpress_assemble( " $i_and ", q, e, tag);
                  break;

               case SHIFT:
                  fpxpress_assemble( " $i_shift ", q, e, tag);
                  break;

               case MULTIPLY:
                  fpxpress_assemble(" $i_multiply ", q, e, tag);
                  break;

               case SHIFT_RIGHT:
                  fpxpress_assemble( " $i_shift_right ", q, e, tag);
                  break;

               case REMAINDER:
                  fpxpress_assemble( " $i_remainder ", q, e, tag);
                  break;

               case COVERED_QUOTIENT:
                  fpxpress_assemble( " $i_covered_quotient ", q, e, tag);
                  break;

               case DIVIDE:
                  fpxpress_assemble(" $i_divide ", q, e, tag);
            }
         }

         return;
      }
   }

   if (*s == '(')
   {
      i_xpress(s + 1, e, tag);
      return;
   }

   unary = *s;

   if ((unary == '+') || (unary == '-'))
   {
      if (number(s + 1, e) == 0)
      {
         if (*(s + 1) == '(')
         {
            i_xpress(s + 2, e, tag);
            if (unary == '-') fpxpress_asmq(" $i_reverse");
            return;
         }

         if (unary == '+') fpxpress_assemble(" $i_load ",          s + 1, e, tag);
         else              fpxpress_assemble(" $i_load_negative ", s + 1, e, tag);

         return;
      }
   }

   fpxpress_assemble(" $i_load ", s, e, tag);
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


