
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



static int left(int symbol)
{
   symbol >>= 4;
   symbol += '0';
   if (symbol > '9') symbol += 7;
   return symbol;
}

static int right(int symbol)
{
   symbol &= 15;
   symbol += '0';
   if (symbol > '9') symbol += 7;
   return symbol;
}

static void unwind()
{
   int x = 1;
   object *sr;

   flag_either_pass("Subassembly Nesting Runaway", "abandon");

   while (x < masm_level)
   {
      sr = entry[x++];
      if (sr) printf("%s ", sr->l.name);
      else    printf("**** ");
   }
   putchar('\n');
   exit(0);
}

#ifdef BLOCK_WRITE
static void block_write(int handle, char *q, int bytes)
{
   static char		 b[BLOCK_WRITE];
   static char		*p = b;
   static int		 x = BLOCK_WRITE;

   int			 transfer;


   if (!q)
   {
      if (uselector['W'-'A']) printf("\n__BWF_[%d:%d]%d\n%*s\n",
                              nhandle, ohandle, handle, BLOCK_WRITE - x, b);

      write(handle, b, BLOCK_WRITE - x);
      x = BLOCK_WRITE;
      p = b;
   }

   while (bytes)
   {
      transfer = bytes;
      if (transfer > x) transfer = x;
      memcpy(p, q, transfer);

      p += transfer;
      q += transfer;
      bytes -= transfer;
      x -= transfer;

      if (!x)
      {
         if (uselector['W'-'A']) printf("\n__BW_[%d:%d]%d\n%*s\n",
                                 nhandle, ohandle, handle, BLOCK_WRITE, b);

         write(handle, b, BLOCK_WRITE);
         p = b;
         x = BLOCK_WRITE;
      }
   }
}

#define write block_write
#endif

static void print_macrotext(int x, char *p, char *macro)
{
   char			 symbol;
   char			*q = (macro) ? macro : "sub";

   if (skipping) printf("%d[%d](skipped):::", masm_level, x);
   else          printf("%d[%d]:macro text:", masm_level, x);

   while (x--)
   {
      symbol = *p++;
      if (!symbol) break;
      if (symbol == ESC)
      {
         fputs(q, stdout);
         continue;
      }
      putchar(symbol);
   }
}

static void print_macrohead(int x, char *p, char *style)
{
   char			 symbol;

   fprintf(stdout, "%d|", masm_level);
   if (skipping) fputs("(skipped):::", stdout);
   else          fputs(style, stdout);

   while (x--)
   {
      symbol = *p++;
      if (!symbol) break;
      if (symbol == ESC)
      {
         printf("sub");
         continue;
      }
      putchar(symbol);
   }
}

static void stop()
{
   flag_either_pass("", "line too long");
   exit(0);
}

static void brake(char *what, char *why)
{
   flag_either_pass(what, why);
   exit(0);
}

static int digitstring_fraction(char *left, char *right)
{
   int		 symbol = *left;
   int		 digits = 0;


   if ((symbol == '+') || (symbol == '-')) left++;

   while (left < right)
   {
      symbol = *left++;
      if (symbol == '.') return digits;
      if (symbol  < '0') break;
      if (symbol  > '9') break;
      digits++;
   }

   return 0;
}

static char *edge(char *s, char *m)
{
   char *p;
   char symbol;

   for  (;;)
   {
      if (!(*s)) return s;
      p = m;
      while ((symbol = *p++))
      {
	 if (*s == symbol) return s;
      }
      s++;
   }
}


static int oper_ator(char *c, int len)
{
   char		*q, *p;
   int		 i, j, symbol;

   for (i = 0; i < OPERATORS; i++)
   {
      j = len;
      q = c;
      p = o[i];

      while ((symbol = *p) && (j))
      {
	 if (symbol != *q) break;
	 p++;
	 q++;
	 j--;
      }

      if (symbol == 0) return i;	/* o[i];*/
   }

   return -1; /* NULL; */
}

/* detect a string among a list of strings */ 

static char *listed(char *p,  char *list)
{
   while (*list)
   {
      if (strcmp(p, list) == 0) return list;
      while (*list++);
   }
   return NULL;
}

/* detect operator among subset of operators */


static char *next_operator(char *s, char *e, char *list, int exclude)
{
   int		 bdepth = 0;
   int		 inquo  = 0;

   int		 symbol;
   int		 x;
   int		 y;

   char		*p;


   while (s < e)
   {
      symbol = *s;
      if (symbol == 0) break;

      if (symbol == '\'')
      {
         if (!(inquo & 2)) inquo ^= 1;
      }

      if (symbol == '\"')
      {
         if (!(inquo & 1)) inquo ^= 2;
      }

      if (!inquo)
      {
         if (symbol == '(') bdepth++;
         if (symbol == ')') bdepth--;
         if (symbol == '[') bdepth++;
         if (symbol == ']') bdepth--;

         if (!bdepth)
         {
            y = oper_ator(s, e - s);

            if (y < 0)
            {
            }
            else
            {
               p = o[y];
               x = ufield[y];

               if (!list)
               {
                  ofield = x;
                  return s;
               }

               if (listed(p, list))
               {
                  otag = y;
                  ofield = x;
                  if (exclude == 0) return s;
               }
               else
               {
                  if (exclude) return s;
               }

               s += x;
               continue;
            }
         }
      }

      s++;
   }

   return NULL;
}

static char *contains(char *s, char *e, char *list)
{
   char		*rightmost = NULL;

   while ((s = next_operator(s, e, list, 0)))
   {
       rightmost = s;
       s += ofield;
   }

   return rightmost;
}

static char *operates(char *s, char *e, char *list)
{
   char		*candidate = NULL,
		*rewind;

   int		 symbol;

   while ((candidate = contains(s, e, list)))
   {
      rewind = candidate;
      e = candidate;

      while (rewind > s)
      {
         rewind--;
         symbol = *rewind;
         if (symbol == '*') break;
         if (symbol == '/') break;
         if (symbol == '+') break;
         if (symbol == '-') break;
         if (symbol ^  ' ') return candidate;
      }
   }

   return candidate;
}

static char  *getop(char  *l)
{
   int			 symbol;

   l = first_at(l, " ");

   while ((symbol = *l))
   {
      if (symbol ^ ' ') break;
      l++;
   }

   if (!symbol) return NULL;
   return l;
}

static char *first_at(char *data, char *mask)
{
   char			 e,
			*f;

   register int			 d;

   int			 bdepth = 0;
   int			 squote = 0;
   int			 btype = 0;

 
   while ((d = *data))
   {
      if (!squote)
      {
         #ifdef SQUARE
         if (d == '(')
         {
            btype &= (1 << bdepth) - 1;
            bdepth++;
         }

         if (d == ')')
         {
            if (bdepth)
            {
               bdepth--;
               if (btype & (1 << bdepth)) flag("balancing brace is [ not (");
               #if 1
               data++;
               continue;
               #endif
            }
            #if 0
            else flag("( missing before )");
            #endif
         }
                  
         if (d == '[')
         {
            btype |= (1 << bdepth);
            bdepth++;
         }

         if (d == ']')
         {
            if (bdepth)
            {
               bdepth--;
               if ((btype & (1 << bdepth)) == 0) flag("balancing brace is ( not [");
               #if 1
               data++;
               continue;
               #endif
            }
            #if 0
            else flag("[ missing before ]");
            #endif
         }
         #else
         if (btype == '[')
         {
            if (d == ']') btype = 0;
         }
         else
         {
            if (d == '(') bdepth++;
            if (d == ')')
            {
               if (bdepth)
               {
                  bdepth--;
                  data++;
                  continue;
               }
            }
         }

         if (!bdepth)
         {
            if (d == '[') btype = '[';
         }
         #endif
      }

      if (d == qchar)
      {
         if ((squote & 2) == 0) squote ^= 1;
      }
      else
      {
         if (d == 0x27)
         {
            if ((squote & 1) == 0) squote ^= 2;
         }
      }

      #ifdef SQUARE
      if ((bdepth | squote) == 0)
      #else
      if ((bdepth | squote | btype) == 0)
      #endif
      {
	 f = mask;
	 while ((e = *f++))
	 {
	    if (d == e) return data;
	 }
      }

      data++;
   }

   return data;
}

static char *frightmost(char *data, char *margin)
{
   register int		 d;
   int			 bdepth = 0;
   int			 squote = 0;

   for (;;)
   {
      if (margin == data) return margin;
      margin--;
      d = *margin;

      if (!squote)
      {
         if (d == ')') bdepth++;
         if ((d == '(') && (bdepth)) bdepth--;
      }

      if (d == qchar)
      {
         if ((squote & 2) == 0) squote ^= 1;
      }
      else
      {
         if (d == 0x27)
         {
            if ((squote & 1) == 0)  squote ^= 2;
         }
      }

      if ((!bdepth) && (!squote))
      {
	 if ((d == '+') || (d == '-') || (d == '*') || (d == '/')
	 ||  (d == ',') || (d == 32)) return margin + 1;
      }
   }
}

static char *fendbe(char *s)
{
   int		 i = 1, sinquo = 0, symbol;

   while ((symbol = *s))
   {
      if (symbol == qchar)
      {
         if ((sinquo & 1) == 0) sinquo ^= 2;
      }

      if (symbol == 0x27)
      {
         if ((sinquo & 2) == 0) sinquo ^= 1;
      }

      if (!sinquo)
      {
         if (symbol == ')') i--;
         if (symbol == '(') i++;
      }
      s++;
      if (!i) break;
   }
   return s;
}

static char *fendb(char *s, char *e)
{
   int		 i = 0;
   int		 sinquo = 0, symbol;

   while (s != e)
   {
      symbol = *s;
      if (symbol == 0) break;

      if (symbol == qchar)
      {
         if ((sinquo & 1) == 0) sinquo ^= 2;
      }

      if (symbol == 0x27)
      {
         if ((sinquo & 2) == 0) sinquo ^= 1;
      }

      if (!sinquo)
      {
	 if (symbol == '(') i++;
	 if (symbol == ')') i--;
	 if (!i) break;
         if (i < 0) break;
      }
      s++;
   }
   return s;
}


static char *past_parentheses(char *s)
{
   int bnest = 0;
   for (;;)
   {
      if (*s == 0) return s;
      if (*s == '(') bnest++;
      if (*s == ')')
      {
	 bnest--;
	 if (bnest < 0) bnest = 0;
	 if (!bnest) return ++s;
      }
      s++;
   }
}


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


