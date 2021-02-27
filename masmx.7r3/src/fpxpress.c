
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



#undef	TRACK_COMPLEXITY
#define EXCLUDE_OPERATORS 1
#define	INDIRECTION_PMONOLITH

#ifdef	FP_XPRESS

static char *l2r_find(int symbol, char *s, char *e)
{
   while ((s < e) && (*s++ ^ symbol)) ;
   if (s < e) return s;
   return NULL;
}

static int complex(char *s, char *e)
{
   char			*p = s,
			*q;

   #ifdef INDIRECTION_PMONOLITH
   if (*s == '*') return 0;
   #else
   if (*s == '*') return complex(s + 1, e);
   #endif

   while ((p = l2r_find('(', p, e)))
   {
      #ifdef TRACK_COMPLEXITY
      printf("[?]");
      #endif

      q = fendbe(p);

      if (complex(p, q))
      {
          #ifdef TRACK_COMPLEXITY
          printf("[!]");
          #endif

          return 1;
      }

      p = q;
   }

   p = next_binary_nonexponent_operator(s, e, "*+\0*-\0", EXCLUDE_OPERATORS);
   if (p) return 1;

   return 0;
}

static int complex_beyond(char *s, char *e, char *list)
{
   char			*p = s,
			*q;

   #ifdef INDIRECTION_PMONOLITH
   if (*s == '*') return 0;
   #else
   if (*s == '*') return complex(s + 1, e);
   #endif

   while ((p = l2r_find('(', p, e)))
   {
      #ifdef TRACK_COMPLEXITY
      printf("[k?]");
      #endif

      q = fendbe(p);
      if (complex_beyond(p, q, list))
      {
         #ifdef TRACK_COMPLEXITY
         printf("[k!]");
         #endif

         return 1;
      }
      p = q;
   }

   if ((p = next_nonexponent_operator(s, e, list, EXCLUDE_OPERATORS))) return 1;

   return 0;
}

/*************************************************

	detect if part of an expression
	contains variables

	result 0 = it contains runtime variables
	result 1 = it's all known now

	association with a location counter = storage
	$equf = storage
	referenced but external = storage

	user-defined types 128..255 are treated as locations
	they are typically registers

*************************************************/


static int number(char *s, char *e)
{
   object		*l;
   int			 symbol = *s;

   while (symbol == ' ')
   {
      s++;

      if (s == e)
      {
         flag("syntactic anomaly");
         return 0;
      }

      symbol = *s;
   }

   if (symbol == '*') return 0;
   if (symbol == '(') return number(s + 1, e - 1);
   if ((symbol == '-') || (symbol == '+')) return number(s + 1, e);

   if (s < e) l = findlabel(s, e);
   else                  return 1;

   if (!l)
   {
      if (label_highest_byte == 0) return 1;
      return 0;
   }

   if (l->l.r.l.rel) return 0;		/* locator index | 128 = storage */
   if (l->l.valued == 0) return 0;	/* unresolved / external = storage */
   if (l->l.valued == SET) return 2;	/* and not bound to a locator	*/
   if (l->l.r.l.xref < 0) return 0;	/* external ? equals storage	*/
   if (l->l.valued == EQUF) return 0;	/* base displacement construct	*/
   if (l->l.valued & 128) return 0;	/* user supplied ? storage	*/

   return 2;
}

static void fpxpress_assemble(char *name, char *start, char *end, char *tag)
{
   char			 assembly[1040];
   char			*p = assembly;
   int			 symbol;

   int			 __literal;


   if (start == end) return;

   __literal = number(start, end);

   while ((symbol = *name++)) *p++ = symbol;

   if (__literal)
   {
      while ((symbol = *tag++))
      {
         if (symbol == ' ') break;
         *p++ = symbol;
      }

      *p++ = '(';

      if ((__literal == 2) && (twoscomp) && (start != end))
      {
         symbol = *start++;
         if (symbol == '-') symbol = '^';
         *p++ = symbol;
      }
   }
   
   while ((start != end) && (symbol = *start++)) *p++ = symbol;
   if (__literal)           *p++ = ')';

   *p = 0;

   masm_level++;

   /******************************************************

	it is not safe to have argument 2 parameter NULL
	at macro depth > 0

	because the pointer vlist[] does not then get set
	but is nevertheless immediately referenced

   ******************************************************/

   assemble(assembly, "", NULL, NULL);
   masm_level--;
}

static void fpxpress_asmq(char *name)
{
   masm_level++;
   assemble(name, "", NULL, NULL);
   masm_level--;
}

static void trailing_fp_operation(int x, char *s, char *e, char *tag)
{
   if (*s == '(') s++;

   switch (x)
   {
      case PLUS:
         fpxpress_assemble(" $x_add ", s, e, tag);
         break;

      case MINUS:
         fpxpress_assemble(" $x_subtract ", s, e, tag);
         break;

      case MULTIPLY:
         fpxpress_assemble(" $x_multiply ", s, e, tag);
         break;

      case DIVIDE:
         fpxpress_assemble(" $x_divide ", s, e, tag);

   }
}

static void fp_xpress(char *s, char *e, char *tag)
{
   char			*p,
                        *q = s;

   int			 unary = *s;
   int			 x;


   if ((p = floperates(q, e, "+\0-\0"))
   ||  (p = floperates(q, e, "/\0*\0")))
   {
      q = p + 1;

      while (*q == ' ') q++;

      if (complex(q, e))
      {
         fp_xpress(q, e, tag);

         switch (*p)
         {
            case '-':

               fpxpress_asmq(" $x_reserve ");
               fp_xpress(s, p, tag);
               fpxpress_asmq(" $x_retrieve_subtract ");
               break;

            case '+':

               if (complex_beyond(s, p, "+\0-\0*+\0*-\0"))
               {
                  fpxpress_asmq(" $x_reserve ");
                  fp_xpress(s, p, tag);
                  fpxpress_asmq(" $x_retrieve_add ");
                  break;
               }

               x = PLUS;

               while ((q = next_nonexponent_operator(s, p, "+\0-\0", 0)))
               {
                  trailing_fp_operation(x, s, q, tag);
                  x = oper_ator(q, p - q);
                  s = q + ufield[x];
               }

               trailing_fp_operation(x, s, p, tag);

               break;

            case '*':

               if (complex_beyond(s, p, "*+\0*-\0"))	/* "*\0/\0*+\0*-\0" */
               {
                  fpxpress_asmq(" $x_reserve ");
                  fp_xpress(s, p, tag);
                  fpxpress_asmq(" $x_retrieve_multiply ");
                  break;
               }

               x = MULTIPLY;

               while ((q = next_nonexponent_operator(s, p, "*\0/\0", 0)))
               {
                  trailing_fp_operation(x, s, q, tag);
                  x = oper_ator(q, p - q);
                  s = q + ufield[x];
               }

               trailing_fp_operation(x, s, p, tag);
               break;

            case '/':
               fpxpress_asmq(" $x_reserve ");
               fp_xpress(s, p, tag);
               fpxpress_asmq(" $x_retrieve_divide ");
         }
      }
      else
      {
         fp_xpress(s, p, tag);
         if (*q == '(') q++;

         switch(*p)
         {
            case '-':
               fpxpress_assemble(" $x_subtract ", q, e, tag);
               break;

            case '+':
               fpxpress_assemble(" $x_add ", q, e, tag);
               break;

            case '*':
               fpxpress_assemble(" $x_multiply ", q, e, tag);
               break;

            case '/':
               fpxpress_assemble(" $x_divide ", q, e, tag);
         }
      }

      return;
   }

   if (*s == '(')
   {
      fp_xpress(s + 1, e, tag);
      return;
   }

   unary = *s;

   if ((unary == '+') || (unary == '-'))
   {
      if (*(s + 1) == '(')
      {
         fp_xpress(s + 2, e, tag);
         if (unary == '-') fpxpress_asmq(" $x_reverse");
         return;
      }

      if (number(s + 1, e) == 0)
      {
         if (unary == '+') fpxpress_assemble(" $x_load ",          s + 1, e, tag);
         else              fpxpress_assemble(" $x_load_negative ", s + 1, e, tag);

         return;
      }
   }

   fpxpress_assemble(" $x_load ", s, e, tag);
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


