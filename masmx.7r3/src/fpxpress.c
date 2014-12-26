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

   while (p = l2r_find('(', p, e))
   {
      q = fendbe(p);

      if (complex(p, q))
      {
          return 1;
      }

      p = q;
   }

   if (next_operator(s, e, "*+\0*-\0", EXCLUDE_OPERATORS)) return 1;

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

   while (p = l2r_find('(', p, e))
   {
      q = fendbe(p);
      if (complex_beyond(p, q, list))
      {
         return 1;
      }
      p = q;
   }

   if (p = next_operator(s, e, list, EXCLUDE_OPERATORS)) return 1;

   return 0;
}

static int number(char *s, char *e)
{
   object		*l;

   if (*s == '*') return 0;
   if (*s == '(') return number(s+1, e-1);

   if (s < e) l = findlabel(s, e);
   else                  return 1;

   if (!l)
   {
      if (label_highest_byte == 0) return 1;
      return 0;
   }

   if (l->l.r.l.rel) return 0;
   if (l->l.valued == 0) return 0;
   if (l->l.r.l.xref < 0) return 0;
   if (l->l.valued == EQUF) return 0;

   return 1;
}

static void fpxpress_assemble(char *name, char *start, char *end)
{
   char			 assembly[1040];
   char			*p = assembly;
   int			 symbol;

   int			 __literal;


   if (start == end) return;

   __literal = number(start, end);

   while (symbol = *name++) *p++ = symbol;
   if (__literal)           *p++ = '(';
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

static void trailing_fp_operation(int x, char *s, char *e)
{
   if (*s == '(') s++;

   switch (x)
   {
      case PLUS:
         fpxpress_assemble(" $x_add ", s, e);
         break;

      case MINUS:
         fpxpress_assemble(" $x_subtract ", s, e);
         break;

      case MULTIPLY:
         fpxpress_assemble(" $x_multiply ", s, e);
         break;

      case DIVIDE:
         fpxpress_assemble(" $x_divide ", s, e);

   }
}

static void fp_xpress(char *s, char *e)
{
   char			*p,
                        *q = s;

   int			 unary = *s;
   int			 x;


   if ((unary == '+') || (unary == '-') || (unary == '*')) q++;

   if ((p = contains(q, e, "+\0-\0"))
   ||  (p = contains(q, e, "/\0*\0")))
   {
      q = p + 1;

      if (complex(q, e))
      {
         fp_xpress(q, e);

         switch (*p)
         {
            case '-':
               fpxpress_asmq(" $x_reserve ");
               fp_xpress(s, p);
               fpxpress_asmq(" $x_retrieve_subtract ");
               break;

            case '+':

               if (complex_beyond(s, p, "+\0-\0*+\0*-\0"))
               {
                  fpxpress_asmq(" $x_reserve ");
                  fp_xpress(s, p);
                  fpxpress_asmq(" $x_retrieve_add ");
                  break;
               }


               x = PLUS;

               while (q = next_operator(s, p, "+\0-\0", 0))
               {
                  trailing_fp_operation(x, s, q);
                  x = oper_ator(q, p - q);
                  s = q + ufield[x];
               }

               trailing_fp_operation(x, s, p);
               break;

            case '*':
               if (complex_beyond(s, p, "*\0/\0*+\0*-\0"))
               {
                  fpxpress_asmq(" $x_reserve ");
                  fp_xpress(s, p);
                  fpxpress_asmq(" $x_retrieve_multiply ");
                  break;
               }

               x = MULTIPLY;

               while (q = next_operator(s, p, "*\0/\0", 0))
               {
                  trailing_fp_operation(x, s, q);
                  x = oper_ator(q, p - q);
                  s = q + ufield[x];
               }

               trailing_fp_operation(x, s, p);
               break;

            case '/':
               fpxpress_asmq(" $x_reserve ");
               fp_xpress(s, p);
               fpxpress_asmq(" $x_retrieve_divide ");
         }
      }
      else
      {
         fp_xpress(s, p);
         if (*q == '(') q++;

         switch(*p)
         {
            case '-':
               fpxpress_assemble(" $x_subtract ", q, e);
               break;

            case '+':
               fpxpress_assemble(" $x_add ", q, e);
               break;

            case '*':
               fpxpress_assemble(" $x_multiply ", q, e);
               break;

            case '/':
               fpxpress_assemble(" $x_divide ", q, e);
         }
      }

      return;
   }

   if (*s == '(')
   {
      fp_xpress(s + 1, e);
      return;
   }

   unary = *s;

   if ((unary == '+') || (unary == '-'))
   {
      if (number(s + 1, e) == 0)
      {
         if (unary == '+') fpxpress_assemble(" $x_load ",          s + 1, e);
         else              fpxpress_assemble(" $x_load_negative ", s + 1, e);

         return;
      }
   }

   fpxpress_assemble(" $x_load ", s, e);
}

#endif

