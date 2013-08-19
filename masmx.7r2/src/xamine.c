/***************************************************************

    Copyright   Tim Cox, 2012
    TimMilesCox@gmx.ch
    
    This file is part of masmx.7r2

    mamsx.7r2 is a target-independent meta-assembler for all
    architectures

    masmx.7r2 is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    mamsx.7r2 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with masmx.7r2.  If not, see <http://www.gnu.org/licenses/>.


***************************************************************/


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
      printf("%s ", sr->l.name);
   }
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

   if (skipping) printf("(skipped):::");
   else          printf(":macro text:");

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
      while (symbol = *p++)
      {
	 if (*s == symbol) return s;
      }
      s++;
   }
}


static char *oper_ator(char *c, long len)
{
   char *q, *r;
   int i, j;

   for (i = 0; i < OPERATORS; i++)
   {
      j = len;
      q = c;
      r = o[i];
      while ((*r) && (j))
      {
	 if (*r != *q) break;
	 r++;
	 q++;
	 j--;
      }
      if (*r == 0) return o[i];
   }
   return NULL;
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

static char *contains(char *s, char *e, char *list)
{
   int i = 0;
   int sinquo = 0;
   int quotype = 0;
   int symbol;

   char *rightmost = NULL, *id;
   while (s < e)
   {
      symbol = *s;
      if (symbol == 0) return rightmost;
      if ((symbol == 0x27) || (symbol == qchar))
      {
	 if (!quotype) quotype = symbol;
      }
      if (symbol == quotype) sinquo ^= 1;
      if (sinquo)
      {
	 s++;
	 continue;
      }

      if (symbol == '(') i++;
      if (symbol == ')') i--;

      if (!i)
      {
	 if (id = oper_ator(s, (long) e - (long) s))
	 {
	    if (listed(id, list)) rightmost = s;
	    s+= strlen(id);
	    continue;
	 }
      }   
      s++;
   }

   return rightmost;
}
static char  *getop(char  *l)
{
   #if 1
   int			 symbol;

   l = first_at(l, " ");

   while (symbol = *l)
   {
      if (symbol ^ ' ') break;
      l++;
   }

   if (!symbol) return NULL;
   return l;

   #else

   register int symbol = *l++;
   if (symbol == qchar)
   {
      while (symbol = *l++)
      {
	 if (symbol == qchar)
	 {
	    symbol = *l++;
	    if (symbol != qchar) break;
	 }
      }
   }
   while ((symbol) && (symbol != ' ')) symbol = *l++;
   if (!symbol) return NULL;
   while (*l == ' ') l++;
   if (*l == 0) return NULL;
   return l;

   #endif
}

static char *first_at(char *data, char *mask)
{
   char			 e,
			*f;

   register int			 d;

   int			 bdepth = 0;
   int			 squote = 0;
   int			 btype = 0;

 
   while (d = *data)
   {
      if (!squote)
      {
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

      if ((bdepth | squote | btype) == 0)
      {
	 f = mask;
	 while (e = *f++)
	 {
	    if (d == e) return data;
	 }
      }

      data++;
   }

   return data;
}

static int frightmost(char *data, char *margin)
{
   register int		 d;
   int			 bdepth = 0;
   int			 squote = 0;

   for (;;)
   {
      if (margin == data) return *margin;
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
	 ||  (d == ',') || (d == 32)) return *(margin+1);
      }
   }
}

static char *fendbe(char *s)
{
   int i = 1, quotype = 0, sinquo = 0, symbol;

   while (symbol = *s)
   {
      if ((symbol == qchar) || (symbol == 0x27))
      {
         if (!sinquo) quotype = symbol;
      }

      if (symbol == quotype) sinquo ^= 1;

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
   int i = 0;
   int quotype = 0, sinquo = 0, symbol;

   while (s != e)
   {
      symbol = *s;
      if (symbol == 0) break;
      if ((symbol == qchar) || (symbol == 0x27))
      {
	 if (!sinquo) quotype = symbol;
      }

      if (symbol == quotype) sinquo ^= 1;
      if (!sinquo)
      {
	 if (symbol == '(') i++;
	 if (symbol == ')') i--;
	 if (!i) break;
      }
      s++;
   }
   return s;
}

#if 0
static int fields(char *g)
{
   int i = 0, j;   
   atree *a = vtree[masm_level-1];
   array *b = a->field;


   if (a->ready) return a->count;

   #ifdef WALKP
   printf("PSetup :%s\n", g);
   #endif

   a->ready = 1;
   a->count = i;

   a->field[0].image[0] = NULL;
   a->field[0].count = 0;

   g = getop(g);   

   if (!g)
   {
      vtree[masm_level] = (atree *) b;
      return 0;
   }
   
   for (;;)
   {
      j = 1;
      b->image[0] = g;
      g = first_at(g, ", ");

      while (*g == ',')
      {
	 g++;
	 while(*g == 32) g++;
         if (*g == 0) break;
         b->image[j] = g;
	 g = first_at(g, ", ");
         j++;
      }

      b->count = j;
      b = (array *) &b->image[j];

      while (*g == 32) g++;
      if (*g == 0) break;
      i++;
   }

   a->ready = 1;
   a->count = i;

   vtree[masm_level] = (atree *) b;
   b->ready = 0;
   b->count = 0;

   return i;
}

static array *field(int i)
{
   atree *b = vtree[masm_level-1];
   array *a = b->field;

   if (i > b->count) return NULL;

   while (i--) a = (array *) &a->image[a->count];
   return a;
}

static int substrings(char *g)
{
   int i = 0;
   if (!g) return 0;
   for (;;)
   {
      i++;
      g = first_at(g, tstring);
      if (*g++ != sterm) return i;
   }
}

static char *substring(char *g, int i)
{
   if (!g) return NULL;

   for (;;)
   {
      i--;
      if (!i) break;
      g = first_at(g, tstring);
      if (*g++ != sterm) return NULL;
   }
   return g;
}


/********************************************

#define BAD_PARAFORM	0
#define COMPLETE_LINE	1
#define ALL_FIELDS	2
#define	FIELD		3
#define SUBFIELD	4
#define STAR_SUBFIELD	4+128
#define HASH_SUBFIELD	4+64
#define	SUBSTRING	5
#define STAR_OR_HASH_	128+64
#define STAR__		128
#define HASH__		64

#ifndef BASIC_SCAN
#define UNBOUND_STRING	6
#define UNBOUND_SUBFIELD 7
#define STAR_UNBOUND_SUBFIELD 7+128
#define HASH_UNBOUND_SUBFIELD 7+64
#define UNSAFE_FIELD	8
#endif

typedef struct { char level,field,subfield,sustring; } paraform_code;

********************************************/


static paraform_code encode_paraform(char *p, char **s)
{
   paraform_code	 z = { COMPLETE_LINE, 0, 0, 0 } ;

   int			 symbol;
   char			*q;

   if (!p) return z;

   if (symbol = *p)
   {
      #ifdef SLIPSHO
      printf("[%c][%s]", symbol, p);
      #endif
      p++;
      if (symbol == '(')
      {
         if (*p == ')')
         {
            p++;
            z.level = ALL_FIELDS;
         }
         else
         {
            q = edge(p, ",)");
            z.field = expression(p, q, NULL);
            p = q;
            z.level = FIELD;

            if (symbol = *p)
            {
               p++;
               if (symbol == ',')
               {
                  q = edge(p, ":)");
                  while(*p == 32) p++;
                  z.level = SUBFIELD;

                  if (*p == '*')
                  {
                     z.level = STAR_SUBFIELD;
                     p++;
                  }

                  if (*p == '#')
                  {
                     z.level = HASH_SUBFIELD;
                     p++;
                  }

                  z.subfield = expression(p, q, NULL);
                  p = q;

                  if (symbol = *p)
                  {
                     p++;
                     if (symbol == ')')
                     {
                     }
                     else
                     {
                        if (symbol == ':')
                        {
                           q = edge(p, ")");
                           while (*p == 32) p++;

                           z.sustring = expression(p, q, NULL);
                           z.level = SUBSTRING;
                           p = q;

                           if (symbol = *p)
                           {
                              p++;
                           }
                        }
                        else
                        {
                           z.level = BAD_PARAFORM;
                        }
                     }
                  }
               }
            }
         }
      }
   }

   #ifdef SLIPSHO
   printf("[encode %d %8.8x]", z.level, z);
   #endif

   if (s) *s = p;
   return z;
}
#endif

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

