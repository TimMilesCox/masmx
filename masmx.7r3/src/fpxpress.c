#define EXCLUDE_OPERATORS 1

#ifdef	FP_XPRESS

static char *l2r_find(int symbol, char *s, char *e)
{
   while ((s < e) && (*s++ ^ symbol)) ;
   if (s < e) return s;
   return NULL;
}

static int complex(char *s, char *e)
{
   if (*s == '*') return complex(s + 1, e);
   if (*s == '(') return complex(s + 1, e);

   if (l2r_find('(', s, e)) return 1;

   if (next_operator(s, e, "*+\0*-\0", EXCLUDE_OPERATORS)) return 1;

   return 0;
}

static int complex_beyond_add(char *s, char *e)
{
   if (l2r_find('(', s, e)) return 1;
   if (next_operator(s, e, "+\0*+\0*-\0", EXCLUDE_OPERATORS)) return 1;
   return 0;
}

static int complex_beyond_multiply(char *s, char *e)
{
   if (l2r_find('(', s, e)) return 1;
   if (next_operator(s, e, "*\0*+\0*-\0", EXCLUDE_OPERATORS)) return 1;
   return 0;
}

static int number(char *s, char *e)
{
   object		*l;

   if (*s == '*') return 0;

   l = findlabel(s, e);

   if (!l) return 1;
   if (l->l.valued == LOCATION) return 0;
   if (l->l.valued ==     LTAG) return 0;
   if (l->l.valued ==     EQUF) return 0;
   if (l->l.r.l.xref < 0)       return 0;

   return 1;
}

static void fpxpress_assemble(char *name, char *start, char *end)
{
   char			 assembly[1040];
   char			*p = assembly;
   int			 symbol;

   int			 __literal = number(start, end);


   while (symbol = *name++) *p++ = symbol;
   if (__literal)           *p++ = '(';
   while (start != end)     *p++ = *start++;
   if (__literal)           *p++ = ')';

   *p = 0;

   masm_level++;
   assemble(assembly, NULL, NULL, NULL);
   masm_level--;
}

static void fpxpress_asmq(char *name)
{
   masm_level++;
   assemble(name, NULL, NULL, NULL);
   masm_level--;
}

static void fp_xpress(char *s, char *e)
{
   char			*p,
                        *q = s;

   char			 unary = *s;



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
               if (complex_beyond_add(s, p))
               {
                  fpxpress_asmq(" $x_reserve ");
                  fp_xpress(s, p);
                  fpxpress_asmq(" $x_retrieve_add ");
                  break;
               }
               
               fpxpress_assemble(" $x_add ", s, p);

               while (s = next_operator(s, p, "+", 0))
               {
                  s += ofield;
                  fpxpress_assemble(" $x_add ", s, p);
               }

               break;

            case '*':
               if (complex_beyond_multiply(s, p))
               {
                  fpxpress_asmq(" $x_reserve ");
                  fp_xpress(s, p);
                  fpxpress_asmq(" $x_retrieve_multiply ");
                  break;
               }

               fpxpress_assemble(" $x_multiply ", s, p);

               while (s = next_operator(s, p, "*", 0))
               {
                  s += ofield;
                  fpxpress_assemble(" $x_multiply ", s, p);
               }

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

