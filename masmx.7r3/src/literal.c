
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





#ifdef LITERALS

static void write_breakpoint(int x, int v)
{
   breakpoint		*p = lpart[x],
                        *q = (breakpoint *) lr;
                        
   if (remainder < sizeof(breakpoint)) q = (breakpoint *) buy_ltable();
   
   lr = (object *) ((char *) lr + sizeof(breakpoint));
   remainder -= sizeof(breakpoint);
   
   q->type = BREAKPOINT;
   q->length = sizeof(breakpoint);
   q->oblong = x;
   q->along = NULL;
   q->base = v;
   
   if (!p)
   {
      lpart[x] = q;
      return;
   }
   
   while (p->along) p = (breakpoint *) p->along;
   p->along = (void *) q;
}

static int read_breakpoint(int x)
{
   breakpoint		*p = lpart[x];
   int			 v = (p) ? p->base : 0;
   
   if (p) lpart[x] = (breakpoint *) p->along;

   return v;
}



/********************************************************************

	this routine allows the literal engine to
	decide whether to put a unary plus in the
	command position before the extracted literal
	expression for assembly as

		(labels+numbers)	->	+	labels+numbers

	this doesn't need to be done:

	if there is already a unary sign there:

		(^0AAAA5555)		->	^0AAAA5555

		(-1.5)			->	-1.5

		(+	1.5)		->	+	1.5

	and does not need to be done:

	if the token is in quotes:

		("Gruesse Welt")	->	"Gruesse Welt"

	and does not need to be done:

	if the token is a name of a code producing macro ($PROC):

		(descriptor_macro	address, size, FLAGS)
		->	descriptor_macro	address, size, FLAGS

		(jump_instruction_name		target)
		->	jump_instruction_name		target

	because all those are opcode-position tokens which produce
	a constant.

	Any label which isn't a $PROC and any number string gets
	the unary + placed in front if it does not have a unary
	sign +-^ already. This includes the names of masm7-supplied
	functions and user-written macro functions

		(EQUATED_VALUE_LABEL)	->	+	EQUATED_VALUE_LABEL

		(33)			->	+	33

		(BIG_ADDRESS)		->	+	BIG_ADDRESS

		($)			->	+	$

		(my_logarithm_macro(224))
					->	+ my_logarithm_macro(224)


	and this allows the literal to go into the assembly
	as it were a sensible line of code

	an accidental void literal () is also given the +
	and consequently a diagnostic is output, the assembly
	is marked in error, and a zero constant is assembled.

	what's actually returned to the literal routine is

	-1	the tokens in the expression are a number without
		a unary symbol, prepend the +

	0	there is a unary sign there or it's a quote string,
		don't prepend another unary sign

	class of label

		if that label represents an inline macro,
		($PROC) that is a command which produces a constant,
		don't prepend anything

		if that is any other sort of label, including functions,
		its meaning is a number value, prepend the +

*********************************************************************/

static int isacommand(char *p)
{
   int			 symbol;
   object		*l1;

   while ((symbol = *p))
   {
      if (symbol != 32) break;
      p++;
   }

   if (symbol ==     0) return -1;
   if (symbol ==   '+') return  0;
   if (symbol ==   '-') return  0;
   if (symbol ==   '^') return  0;
   if (symbol == qchar) return  0;

   l1 = findlabel(p, NULL);

   if (l1)
   {
      if (l1->l.valued == NAME)
      {
         if (l1->l.passflag & 128) return PROC;
      }

      if (l1->l.valued == UNDEFINED) return LOCATION;
      return l1->l.valued;
   }

   return -1;
}

static int literal(char *arg, char *gparam, int tlocator)
{
   int			 t = 3, bdepth = 1, x;
   int			 v;
   char			 newmodel[READSIZE] = "   ";
   int			 inquote = 0;
   int			 rvalue, symbol;
   int			 zflag = uselector['Z'-'A'];
   
   location_counter	*tloc = &locator[tlocator];

   #ifdef OVERLAY_LITERALS
   txo			*sr;
   #endif

   #ifdef DOS
   txo image = { LITERAL,        0, 0, NULL, 0, 0, 0 } ;
   #else
   txo image = { LITERAL, tlocator, 0, NULL, 0, 0, 0 } ;
   #endif
   
   /* paragraph */ unsigned int		*p, *q;

   #ifdef DOS
   image.rel = tlocator;
   #endif
   
   if ((actual->flags == 128)
   &&  (actual->base  ==   0)
   &&  (actual->runbank.a == 0)
   &&  (actual->relocatable == 0))
   {
      note("void section literal request dropped");
      return 0;
   }

   /***************************************************

	currently in a dsect
	don't generate anything or update
	the literal location counter

   ***************************************************/

   if ((tloc->flags == 128)
   &&  (tloc->base  ==   0)
   &&  (tloc->runbank.a == 0)
   && (!tloc->relocatable))
   {
      flagg("literal in void section");
      return 0;
   }
   
   if (tloc->breakpoint > 63)
   {
      flagg("only 64 breakpoint parts may contain literals");
      return 0;
   }

   if (!pass) return 0;
   
   arg++;             
   if (tlocator > LOCATORS-1)
   {
      flagf("Location Counter of Literal Out of Range");
      return 0;
   }

   while ((symbol = *arg++))
   {
      if (symbol == qchar)
      {
         if ((inquote & 2) == 0) inquote ^= 1;
      }
      else
      {
         if (symbol == 0x27)
         {
            if ((inquote & 1) == 0) inquote ^= 2;
         }
      }

      if (!inquote)
      {
	 if (symbol == '(') bdepth++;
	 if (symbol == ')') bdepth--;
	 if (!bdepth) break;
      }

      newmodel[t++] = symbol;
   }
   
   newmodel[t] = 0;

   symbol = isacommand(newmodel + 3);

   if ((symbol < 0)
   || ((symbol) && (symbol != FORM) && (symbol != PROC)))
   {
       newmodel[1] = '+';
   }

   if ((selector['q'-'a']) && (pass) && (plist > masm_level))
   {
      printf("::::(%2.2x)::::%s\n", tlocator, newmodel);
   }

   uselector['Z'-'A'] = 1;

   #ifdef STRUCTURE_DEPTH
   treeflag = 1;
   #endif

   #ifdef RELOCATION
   maprecursion++;
   rvalue = assemble(newmodel, gparam, NULL, &image);
   maprecursion--;
   #else
   rvalue = assemble(newmodel, gparam, NULL, &image);
   #endif

   uselector['Z'-'A'] = zflag;

   #ifdef STRUCTURE_DEPTH
   treeflag = 0;
   #endif

   xpression(STACK_TOP_CLEAR, STACK_TOP_CLEAR, gparam);

   t = image.symbols;
   image.d[t++] = 0;

   if ((selector['q'-'a']) && (pass) && (plist > masm_level))
   {
      printf("[%x:%s]\n", t, image.d);
   }

   v = tloc->litlocator;

   #if 0	/* this is now checked at the end */

   if (tloc->loc > v)
   {
      flag("literal table overlaps 2nd pass code");
   }

   #endif
   
   #ifdef RELOCATION
   if (tloc->relocatable)
   {
      #ifdef USING_NO_REL
      if (!(tloc->flags & 128))
      #endif
      
      mapx->m.l.y |= 1;
   }
   mapx->m.l.rel = tlocator;
   #endif
   
   #ifdef OVERLAY_LITERALS
   sr = ltag[tlocator];

   if (sr)
   {
      for (;;)
      {
	  x =  strcmp(sr->d, image.d); 
	  if (x == 0)
	  {
             #ifdef LITWISE
             printf("[hit return %x]\n", sr->loc);
             #endif

	     return sr->loc;
	  }
	  if (!sr->along)break;
	  sr = sr->along;
      }
   }
   #endif
   

   tloc->litlocator = v + image.bits/address_quantum;

   #ifdef LITWISE
   printf("[miss insert %x/%x]\n", v, tloc->litlocator);
   #endif
   
   while (t & PARAGRAPH-1) image.d[t++] = 0;
   t += TXO_HEADER;
   
   image.oblong = t;
   
   image.loc = v;
   
   image.rel = tlocator;
   
   #ifdef OVERLAY_LITERALS
   p = (unsigned int *) lr;
   if (t > remainder) p = (unsigned int *) buy_ltable();
   remainder -= t;

   if (sr) sr->along = p;
   else
   {
      image.along = ltag[tlocator];
      ltag[tlocator] = (txo *) p;
   }

   q = (unsigned int *) &image;
   t >>= 2;
   while (t--) *p++ = *q++;
   
   if ((selector['q'-'a']) && (pass) && (plist > masm_level))
   {
      printf("[%4.4x:%x:%x:%s %p %p]\n", ((txo *) lr)->oblong,
                                         ((txo *) lr)->symbols,
                                         ((txo *) lr)->bits,
                                         ((txo *) lr)->d, lr, p);
   }

   lr = (object *) p;

   #endif

   #if	0	/*	def LROOT	*/
   if (tloc->loc >= tloc->lroot)    
   {
      tloc->loc = tloc->litlocator;
   }
   #endif

   return v;
}

static void output_literals(int tlocator)
{
   txo			*s = ltag[tlocator];
   location_counter	*q = &locator[tlocator];
   int			 v;
   
   if (!s) return;

   if (selector['q'-'a']) printf("$%2.2x:%x\n", tlocator, s->loc);
   outcounter(tlocator, s->loc, "\n$");
   while (s)
   {
      write(ohandle, s->d, s->symbols);
      write(ohandle, "\n", 1);

      if ((selector['l'-'a']) && (list >= depth))
      {
         v = s->loc;
         printf("%2.2x:", tlocator);

         if (q->flags & 1)
         {
            illustrate_xad(q, v);
         }
         else
         {
            if (selector['d'-'a'])
            {
               if (!q->relocatable)
               {
                  if (q->flags & 128) v += q->base;
                  if (q->breakpoint)  v -= q->base;
               }

               if (selector['v'-'a'])
               {
                  printf("%0*lx:", apwx, q->runbank.a);
               }
               else
               {
                  v += q->runbank.a;
               }
            }
            printf("%0*x", apw, v);
         }

         printf("+%s\n", s->d);
      }

      s = s->along;
   }
   ltag[tlocator] = s;

   if (q->litlocator > q->loc)
   {
      q->loc = q->litlocator;
   }
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


