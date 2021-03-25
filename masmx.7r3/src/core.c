
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




static int length_mark(int symbol)
{
   switch(symbol)
   {
      case 's':
      case 'S':
         return word;

      case 'd':
      case 'D':
      case 'l':
      case 'L':
         return word * 2;

      case 't':
      case 'T':
         return word * 3;

      case 'q':
      case 'Q':
         return word * 4;

      case 'p':
      case 'P':
         return word * 5;

      case 'h':
      case 'H':
         return word * 6;

      case 'z':
      case 'Z':
         return word * 7;

      case 'o':
      case 'O':
         return word * 8;
   }

   return 0;
}

static int suffix_noclash(int symbol)
{
   if ((symbol == 'h') || (symbol == 'H')
   ||  (symbol == 'o') || (symbol == 'O')
   ||  (symbol == 'q') || (symbol == 'Q')
   ||  (symbol == 'd') || (symbol == 'D')) return 0;

   return 1;
}

static int bucket(int granule)
{
   int power = 1;
   while (power < granule) power <<= 1;
   return -power;
}


static value *apply_value(int id)
{
   value		*p = (value *) lr;

   if (remainder < sizeof(value)) p = (value *) buy_ltable();

   lr = (object *) ((char *) lr + sizeof(value));
   remainder -= sizeof(value);

   p->type = VALUE;
   p->length = sizeof(value);
   p->oblong = id;
   p->offset = 0;

   return p;
}

static void switch_locator(char *p, char *param)
{
   object		*l;
   char			*limit, *limit2, *line_label = p;

   #ifdef RELOCATION
   int			 container;
   #endif

   unsigned int	 v = 0, w = 0, x = 0;
   value		*vpoint;

   line_label++;

   if (*line_label++ != '(')
   {
      flag_either_pass(p, "locator format error, abandon"); 

      exit(0);
   }
   
   actual->loc = loc;
   
   limit = edge(line_label, ",:/)");

   counter_of_reference = expression(line_label, limit, NULL);

   if (counter_of_reference > (LOCATORS-1))
   {
      flag_either_pass(p, "location counter out of range, abandon");
      exit(0);
   }

   actual = &locator[counter_of_reference];
   w = actual->loc;
   loc = w;

   if (*limit == ':')
   {
      line_label = limit + 1;
      
      limit = first_at(line_label, ",:/)");

      if (*line_label == '*')
      {

         #ifdef RELOCATION
	 line_label++;
	 container = expression(line_label, limit, NULL);

         if (actual->touch_base)
         {
            if (actual->relocatable)
            {
               if ((container == actual->relocatable)
               || (-container == actual->relocatable))
               {
               }
               else
               {
                  flagf("locator has different relocation attribute");
               }
            }
            else
            {
               flagf("locator has absolute attribute already");
            }
         }
         else
         {
	    actual->relocatable = bucket(container);

            #ifdef BINARY
            one_touch.base[counter_of_reference] = 1;
            #endif
         }

         #else

         if (*line_label == '*')
         {
            flag("MASM7 "VERSION "r" REVISION
                 ": no relocation support: alignment word skipped");
         }

         #endif

         if (*limit == ':')
         {
	    line_label = limit+1;
            limit = first_at(line_label, ",/)");

            v = expression(line_label, limit, NULL);
            w = actual->loc;
            if (v < w) flag("location_overlay");
            actual->loc = v;
         }
      }     
      else
      {   
         v = expression(line_label, limit, NULL);

         if (!actual->touch_base) actual->base = v;

         if (*limit == ':')
         {
            limit2 = substitute(limit+1, param);
            limit = first_at(limit2, ",/)");
         
            if (!pass)
            {
            if (actual->touch_base)
            {
               if (actual->breakpoint == 0)
               {
                  flag("earlier part of segment is not breakpointed");
               }
            }
            }

            #ifdef LITERALS
            if ((actual->touch_base)

            #ifndef LTAG
            &&  ((actual->flags & 129) != 1)
            #endif

            &&  (actual->breakpoint < 63))
            {
               if (pass)
               {
                  #ifdef LITERALS
                  output_literals(counter_of_reference);
                  #endif

                  actual->litlocator = actual->lroot
                  = read_breakpoint(counter_of_reference);
               }
               else
               {
                  write_breakpoint(counter_of_reference, w);
               }
            }
            #endif
         
            if (*limit2 == '*')
            {
               if ((actual->touch_base) && ((actual->flags & 1) == 0))
               {
                  flagp1("locator may not be changed to giant address space");
               }
               else
               {
                  vpoint =actual->runbank.p;

                  if (!vpoint)
                  {                  
                     actual->runbank.p = apply_value(counter_of_reference);
                  }

                  forward_reference = 0;

                  actual->runbank.p->value = *xpression(limit2+1, limit, NULL);

                  if (forward_reference)
                  {
                      flagp1("forward reference may not be used as giant section origin");
                  }

                  if (mapx->m.l.y)
                  {
                      flag("relocatable value may not be used as giant section origin");
                  }
 
                  actual->flags |= 3;
               }
            }
            else
            {
               if ((actual->touch_base) && (actual->flags & 1))
               {
                  flagf("locator may not be changed back from giant address space");
               }
               else
               {
                  actual->bias = 1;
                  actual->runbank.a = x = expression(limit2, limit, param);
                  if (v != actual->base)
                  flag("address space region slipped");
               }
            }

            actual->base = v;
            actual->breakpoint++;
         }
         else
         {
            if (v < w) flagf("Location Overlay");
         }
         actual->loc = v;
      }
   }
   
   loc = actual->loc;
   actual_lbase = actual->lroot;
   
   if (*limit == ',')
   {
      if (actual->relocatable == 0)
      {
         if (actual->touch_base)
         {
            if (actual->flags & 128)
            {
               if ((v) && (v != actual->base))
               flag("base+displacement segment may not be reconstructed");
               if (actual->breakpoint)
               {
                   if (actual->flags & 1)
                   {
                   }
                   else
                   {
                      loc = 0;
                      actual->loc = 0;
                   }
               }
            }
            else
            {
               flag("earlier segment of section is not base+displacement");
            }
         }
         else
         {
            actual->base = v;

            if (actual->flags & 1)
            {
            }
            else
            {
               loc = 0;
               actual->loc = 0;
            }
         }
      }

      limit2 = limit + 1;
      while (*limit2 == 32) limit2++;
      limit = first_at(limit2, "/)");
      actual->rbase = expression(limit2, limit, param);
      actual->flags |= 128;

   }

   else
   {
      if ((v | x) && (actual->flags & 128))
      {
         #ifdef DRIFT_GUARD

         if (actual->flags & 1)
         {
            if (v)
            {
               flag("base+displacement section in giant space\n"
                    "may not set OFFSET, as: $(xx:OFFSET:...");
            }

            actual->loc  = w;
            actual->base = w;
            loc          = w;
         }
         else

         #endif

         if (!actual->relocatable)
         {
            if (actual->breakpoint)
            {
               if (actual->flags & 1)
               {
               }
               else
               {
                  if (!x) flag("absolute breakpoint expected");
                  loc = 0;
                  actual->loc = 0;
               }
            }
            else
            {
               if ((v) && (v != actual->base))
               flag("root of absolute base+displacement section is fixed");
               loc = w;
               actual->loc = w;
            }
         }
      }
   }

   #ifdef LITERALS
   if (*limit == '/')
   {
      limit2 = edge(limit, ")");
      if (!pass) 
      {
         l = insert_qltable(limit+1, LITERAL, LTAG);
        
         if (l)
         {
            l->l.r.l.rel = counter_of_reference | 128;
            if (actual->flags & 128)
            {
               quadinsert1(actual->rbase, &l->l.value);
            }
         }
         else
         {
            flag("literal pool tag not added");
         }
      }
   }
   #endif
   
   actual->touch_base |= 1;
   outstanding = 1; /* outcounter(0); */
}


static int rfunction(int v,
		      char *s, char *param, char *mark, 
		      object *tag)
{
   char			*limit, *d = NULL;
   int			 i, j;
   int			 h, symbol, x;
   object		*l;
   location_counter	*q;

   line_item		*item;
   line_item		*breakpoint_base;

   #ifdef RELOCATION
   link_profile		*mapxb4;
   #endif

   switch(v)
   {
      case LOCTR:

         q = actual;
         i = loc;
         x = counter_of_reference;

         if (*s++ == '(')
         {
            limit = edge(s, ")");
            x = expression(s, limit, NULL);

            if ((x < 0) || (x > 71))
            {
               flag("locator not in 0..71");
               return 0;
            }

            q = &locator[x];

            if (x ^ counter_of_reference) i = q->loc;
         }

         #ifdef RELOCATION
         if (q->relocatable) mapx->m.l.y |= 1;
         mapx->m.l.rel = x | 128;
         #endif

         if ((q->flags & 129) == 1)
         {
            breakpoint_base = &q->runbank.p->value;
            item = xpression(STACK_TOP_CLEAR, STACK_TOP_CLEAR, NULL);
            mapx->m.l.rel = x | 128;
            quadinsert(i, item);
            operand_add(item, breakpoint_base);
            return quadextract(item);
         }

         return i;


         #ifdef ZENITH

      case ZENITH:

         q = actual;
         i = loc;

         if (*s++ == '(')
         {
            limit = edge(s, ")");
            j = expression(s, limit, NULL);

            if ((j < 0) || (j > 71))
            {
               flag("locator not in 0..71");
               return 0;
            }

            q = &locator[j];
            i = q->loc;
         }

         j = q->litlocator;

         if (i > j) j = i;
         return j;

         #endif

         #ifdef SIMPLE_BASE
      case SIMPLE_BASE:

	 #ifdef RELOCATION
         mapx->m.l.rel = counter_of_reference | 128;
         if (actual->relocatable) mapx->m.l.y = 1;
         #endif

         if (actual->flags & 1)
         {
            breakpoint_base = &actual->runbank.p->value;
            item = xpression(STACK_TOP_CLEAR, STACK_TOP_CLEAR, NULL);
            quadinsert(actual->base, item);
            operand_add(item, breakpoint_base);
            return quadextract(item);
         }

         return actual->base;
         #endif


      case PNAME:
   
	 return extract_gparam("(0,1)", param);


      case REGION:
	 if (*s != '(') return counter_of_reference;

         #if 0

         d = s + 1;
         limit = fendbe(d);
         j = zxpression(d, limit, param);
         if (x = mapx->m.l.y) return x & 127;
         return 0;

         #else
	 d = substitute(s+1, param);

	 l = findlabel(d, NULL);
	 if ((!l)
	 ||  (l->h.type != LABEL)
	 ||  (l->l.valued == UNDEFINED)) return 0;
	 return l->l.r.l.rel & 127;
         #endif

      case TYPE:

         #if 0
         d = s + 1;
         #else
	 d = substitute(s+1, param);
         #endif
	 
	 if (!d)
	 {
	    flag_either_pass("Internal Error 3", "abandon");
	    exit(0);
	 }

	 #define SOFTLY

	 #ifdef	SOFTLY
	 symbol = *d;
	 if ((symbol == '-') || (symbol == '+')
          || (symbol == '^')
          || (symbol == '*') || (symbol == '#')) d++;
	 #endif

	 l = findlabel(d, NULL);


	 if (!l) return 0;

         /**********************************************
         it's only completely correct to use this if the
         text @ *d is certainly meant to be a label.
         A self-explanatory reference like a number
         will give the same result as an unknown label.
         *********************************************/


	 return l->l.valued;

      case OPTION:
	 if (*s++ == '(')
         {
            limit = fendbe(s);
            h = expression(s, limit, param);
            if ((h > 0x60) && (h < 0x7b)) return  selector[h-97];
	    if ((h > 0x40) && (h < 0x5b)) return uselector[h-65];
         }

	 return 0;

      case REL:

	 if (*s++ == '(')
	 {
	    limit = edge(s, ")");

	    j = expression(s, limit, NULL);

            if ((j < 0) || (j > 71))
            {
               flag("locator not in 0..71");
               return 0;
            }

	    return locator[j].relocatable;
	 }
	 return actual->relocatable;

      case NET:

	 if (*s++ == '(')
	 {
	    limit = fendbe(s);

            #ifdef RELOCATION
            mapxb4 = mapx;
            #endif
	    i = zxpression(s, limit, param);

	    #ifdef RELOCATION
            mapx = mapxb4;
	    mapx->m.i = 0;
	    #endif

	    return i;

	 }
	 flagf("$net() directive badly typed");

	 #ifdef RELOCATION
	 mapx->m.i = 0;
	 #endif

	 return 0;

	 #ifdef SYNONYMS
      case SYNONYMS:

         i = 0;
         l = floatable;

         h = label_highest_byte;
         h -= 2;
         symbol = name[h++];

         while (l < floatop)
         {
            if ((l->h.type == LABEL)
            && ((l->h.length - sizeof(label) + PARAGRAPH) > h))
            {
               if (memcmp(name, l->l.name, h))
               {
               }
               else
               {
                  limit = "";

                  if (symbol == '(')
                  {
                     limit = edge(&l->l.name[h], ",)");
                  }
                  else
                  {
                     if (l->l.name[h] == ',')
                     {
   	                limit = edge(&l->l.name[h+1], ",)");
                     }
                  }

                  if (*limit == ')') i++;
               }
            }

            l = (object *) ((char *) l + l->l.length);
         }

         l = origin;

         while (l)
         {
            if ((l->h.type == LABEL)
            && ((l->h.length - sizeof(label) + PARAGRAPH) > h))
            {
               x = memcmp(name, l->l.name, h);

               if (x)
               {
               }
               else
               {
                  limit = "";

                  if (symbol == '(')
                  {
                     limit = edge(&l->l.name[h], ",)");
                  }
                  else
                  {
                     if (l->l.name[h] == ',')
                     {
                        limit = edge(&l->l.name[h+1], ",)");
                     }
                  }

                  if (*limit == ')') i++;
               }
            }

            l = l->l.along;
         }

         return i;

         #ifdef STRUCTURE_DEPTH

      case CHILD_SYNONYMS:

         i = 0;
         l = stem_pointer;
         d = l->l.name;

         h = stem_length;
         h--;
         symbol = d[h-1];

         while (l)
         {
            if ((l->h.length - sizeof(label) + PARAGRAPH) > h)
            {
               if (memcmp(d, l->l.name, h))
               {
               }
               else
               {
                  limit = "";

                  if (symbol == '(')
                  {
                     limit = edge(&l->l.name[h], ",)");
                  }
                  else if (l->l.name[h] == ',')
                  {
   	             limit = edge(&l->l.name[h+1], ",)");
                  }

                  if (*limit == ')') i++;
               }
            }
            l = l->l.along;
         }

         return i;

         #endif
         #endif


         #ifdef ABSOLUTE
      case ABSOLUTE:

         q = actual;
         j = loc;
         x = counter_of_reference | 128;
         h = 0;
         l = NULL;

         if (*s == '(')
         {
            #if 1
            d = s + 1;
            #else
            d = substitute(s+1, param);
            #endif

            limit = fendbe(d);

            j = zxpression(d, limit, param);

            #ifdef RELOCATION
            if ((mapx->m.l.y & 129) == 128) return j;
            #endif

            #if 1
            l = findlabel(d, limit);
            if ((x = mapx->m.l.rel)) q = &locator[x & 127];
            else return j;
            #elif 0
            printf("[%x]", mapx->m.l.rel);
            printf("[%p]", l);
            if (l) printf("[%x]", l->l.r.l.rel);
            if ((l) && (x = l->l.r.l.rel)) q = &locator[x & 127];
            else return j;
            #else
            if ((l) && ((l->l.valued == LOCATION)
                    ||  (l->l.valued ==      EQU)
                    ||  (l->l.valued ==      SET)
                    ||  (l->l.valued ==     EQUF)))
            {
                  x = l->l.r.l.rel & 127;
                  q = &locator[x];
            }
            else
            {
               return j;
            }
            #endif
         }

         #ifdef RELOCATION

         mapx->m.l.rel = x | 128;
         if (q->relocatable)
         {
            mapx->m.l.y = 1;
         }
         else

         #endif

         {
            if (q->flags & 1)
            {
               breakpoint_base = &q->runbank.p->value;
               item = xpression(STACK_TOP_VALUE, NULL, NULL);

               if ((q->flags & 128) || (d == NULL) || ((x) && (l) && (l->l.valued == EQUF)))
               {
                  /*********************************************

                  when $a has had no argument, zxpression has
                  also not been called. Somehow the stack top
                  returned here manages to be zero and not any
                  residual value.

                  Were that not so, in the case (!l) (no $a argument),
                  *breakpoint_base should be copied not added

                  *********************************************/

                  operand_add(item, breakpoint_base);
                  if (l) j =  quadextract(item);
                  else   j+=  quadextract(item);
               }
            }
            else
            {
               if (q->flags & 128) j += q->base;
            }
         }

         return j;

         #endif		/* ifdef ABSOLUTE */

         #ifdef	BANK_INDEX

      case BANK_INDEX:
	 if ((actual->breakpoint) && ((actual->flags & 1) == 0)) return actual->runbank.a;
         return 0;

         #endif		/* ifdef BANK_INDEX */	

      default:
	 flag("Internal Function Paradox");
	 return  0;
   }
}

static int meaning(char *directive)
{
   object		*sr;
   int			 symbol = *directive;
   
   if ((symbol == '+')
   ||  (symbol == '-')
   ||  (symbol == '^')
   ||  (symbol == qchar)) return -1;

   sr = findlabel(directive, NULL);
   
   if (sr)
   {
      if (sr->l.valued == DIRECTIVE) return sr->l.value.b[RADIX/8-1];
   }

   return -1;
}

static void pack_ltable(object *toplabel)
{
   int				 i, length;  
   paragraph			*p, *q;
   object			*pr = toplabel;
  
   while (pr != floatop)
   {
      length = pr->h.length;
      
      #ifdef TRACE_RECURS
      printf("consider %s in compress[%d/%d:%x:%d]\n",
	     pr->l.name, pr->l.r.l.xref, masm_level, pr->l.r.l.y, pr->h.length);
      #endif
      
      if ((pr->h.type ^ LABEL) || (pr->l.r.l.xref < masm_level))
      {
         #ifdef TRACE_RECURS
	 printf("save %s in compress[%d]\n", pr->l.name, pr->h.length);
	 #endif
         
         i = length >> PARAGRAPH_LOG;
	 p = (paragraph *) toplabel;
	 q = (paragraph *) pr;
	 while (i--) *p++ = *q++;
	
	 toplabel = (object *) p; 
      }
      else
      {
	 flotsam += length;
      }
      
      #ifdef TRACE_RECURS
      printf("advance cursor %d\n", length);
      #endif
      
      pr = (object *) ((char *) pr + length);
   }

   #ifdef TRACE_RECURS
   printf("exit compress\n");
   #endif
   
   floatop = toplabel;
}

static line_item *external_function(char *s, char *param, char *mark,
		  	            object *l)
{
   int			 i = 0, f;
   int			 j = 1, y = 0, prelif, preskip,
                         bdepth = 0, sinquo = 0, square = 0;
   
   char			*dir, *arg, *v_p;
   object		*x;
   int			 start = loc;

   char			 symbol1, symbol2;
   
   char			 v_param1[FUNCTION_SYMBOLS + 8] = " Param ";

   object		*toplabel;
   int			 rvalue, yewerat;
   char			*starboard = NULL;

   int			 scope = function_scope;


   
   if ((l->h.type == LABEL) && (l->l.passflag & 2) && (!pass))
   {
      return &zero_o;
   }

   function_scope = l->l.passflag;
   
   v_p = substitute(s, param);

   if (plist > masm_level)
   {
      if ((( pass) && (selector['q'-'a']))
      ||  ((!pass) && (selector['r'-'a'])))
      {
         printf("::function::  %s %s\n", l->l.name, v_p);
      }
   }

   symbol1 = *v_p++;

   if (symbol1 == '\\')
   {
      while ((symbol1 = *v_p++))
      {
         if (symbol1 == '(') break;
         if (symbol1 == '[') break;
      }
   }

   while ((symbol2 = l->l.name[y++])) v_param1[j++] = symbol2;

   v_param1[j++] = 32;

   if ((symbol1 == '(') || (symbol1 == '[')) 
   {
      bdepth = 1;
      if (symbol1 == '[') square = 1;

      while ((symbol1 = *v_p++))
      {
         if ((symbol1 == '\'')  && ((sinquo & 2) == 0)) sinquo ^= 1;
         if ((symbol1 == qchar) && ((sinquo & 1) == 0)) sinquo ^= 2;

         if (!sinquo)
         {
	    if (((symbol1 == '(') && (!square))
            ||  ((symbol1 == '[') &&  (square))) bdepth++;

	    if (((symbol1 == ')') && (!square))
            ||  ((symbol1 == ']') &&  (square)))
	    {
	       bdepth--;
	       if (!bdepth) break;
	    }
         }

	 v_param1[j++] = symbol1;
      }

      if (symbol1)
      {
         if ((symbol1 = *v_p++)
         &&  (symbol1 != ' ')
         &&  (symbol1 != ',')
         &&  (symbol1 != sterm))
         {
            v_param1[j++] = 32;

            while (symbol1)
            {
               v_param1[j++] = symbol1;
               symbol1 = *v_p++;
            }
         }
      }
   }

   
   v_param1[j] = 0;
   v_p = v_param1;

   if (j > FUNCTION_SYMBOLS) stop();

   if (plist > masm_level)
   {
      if ((( pass) && (selector['q'-'a']))
      ||  ((!pass) && (selector['r'-'a'])))
      {
         printf("[%d]\n", masm_level);
         printf("::::scan::::%s\n", v_p);
      }
   }
   
   if (!vtree[masm_level])
   {
      for (j = 0; j < masm_level; j++)
      printf("[L %d %s V %p]\n", j, entry[j]->l.name, vtree[j]);

      flag_either_pass(l->l.name, "internal error possibly caused by parameter "
                                  "reference on a macro header line\n");

      exit(0);
   }

   vtree[masm_level++]->ready = 0;

   #ifdef WALKP
   printf("FClear::");
   #endif

   if (masm_level == RECURSION) unwind();
   
   #ifdef RELOCATION
   maprecursion++;
   #endif

   toplabel = floatop;
   
   entry[masm_level] = l;

   prelif = ifdepth;

   preskip = skipping;
   skipping = 0;
      
   x = l;
   if (l->l.down) x = x->l.down;
   
   for (;;)
   {
      y = x->h.length;

      #ifdef CLEATING
      if (!y) cleat(1, x);
      #endif

      x = (object *) ((char *) x + y);
      
      #ifdef DISPLAY_Q
      if (plist > masm_level)
      {
         if (((pass) && (selector['q'-'a']))
         || ((!pass) && (selector['r'-'a'])))

         {
  	    switch (x->h.type)
	    {
	       case LABEL:        
	          printf("%d:%s", x->l.valued, x->l.name);
	          break;
	       case END: 
	          printf(":::end func:%s\n", x->t.text);
	          break;
               case PROC:
               case FUNCTION:
               case NAME:
	       case TEXT_IMAGE:
                  print_macrotext(x->t.length, x->t.text, l->l.name);
	          break;
	       default:
	          printf("[%d*]", x->h.type);
	          break;
            }

            putchar(10);
	 }
      }
      #endif

      j = x->h.type;

      if (j == BYPASS_RECORD)
      {
         if ((j = x->nextbdi.next)) x = bank[j];
         else                     x = NULL;

         if (!x)
         {
            printf("Error %d Retrieving Function Text\n", j);
            exit(0);
         }

         j = x->h.type;
      }

      if (j == END) break;
      if (j == LABEL) continue;

      j = 0;
      
      dir = getop(x->t.text);
      arg = NULL;
      f = 0;
      if (dir)
      {
	 arg = getop(dir);
	 f = meaning(dir);
      }
      
      switch(f)
      {
	 case END:
	    break;

	 default:
	    next_image[masm_level] = x;

	    rvalue = assemble(x->t.text, v_p, NULL, NULL);

            if ((rvalue == RETURN) && (!skipping))
            {
               ifdepth = prelif;
               skipping = preskip;


               #ifdef  SQUEEZE_LTABLE
               if (!l->l.passflag) floatop = toplabel;
               else
               #endif

               pack_ltable(toplabel);
               masm_level--;

               #ifdef RELOCATION
               maprecursion--;
               #endif

               function_scope = scope;

               if (uselector['I'-'A'] == 0)
               {
                  if (loc != start) flag("Function Adding Code Inline");
               }

               if (plist > (masm_level + 1))
               {
                  if (((pass) && (selector['q'-'a']))
                  || ((!pass) && (selector['r'-'a'])))
                  {
                     printf(":::result::: ");
                     print_item(xpression(STACK_TOP_VALUE, NULL, NULL));
                  }
               }

               return xpression(STACK_TOP_VALUE, NULL, NULL);
            }

            x = next_image[masm_level];

	    break;
      }
   }
   
   if (ifdepth != prelif) note("Automatic Endif");
   ifdepth = prelif;

   skipping = preskip;
   
               #ifdef  SQUEEZE_LTABLE
               if (!l->l.passflag) floatop = toplabel;
               else
               #endif

   pack_ltable(toplabel);
   masm_level--;
   
   #ifdef RELOCATION
   maprecursion--;
   #endif
   

   function_scope = scope;

   if (!skipping) note("Automatic Function Return Value");

   if (uselector['I'-'A'] == 0)
   {
      if (loc != start) flag("Function Adding Code Inline");
   }

   return &zero_o;
}

static object *compose_filename(char *from, char *extension, int prefix)
{
   char			 bounded = 0;
   char			 extended = 0;
   int			 length = 0, paragraphs, symbol;
   char			*k = name;
   object		*l = files;
   paragraph		*p, *q;

   #ifdef PATH
   char			*d = path;
   #endif

   if (!from)
   {
      flag_either_pass("filename", "expected");
      exit(0);
   }

   #ifdef PATH
   if (prefix)
   {
      while ((symbol = *d++))
      {
         if ((selector['o'-'a'])
         &&  (symbol > 0x40)
         &&  (symbol < 0x5B)) symbol |= 32;

         *k++ = symbol;
         length++;
      }
   }
   #endif

   if (*from == qchar) bounded = *from++;

   while ((symbol = *from++))
   {
      if (length == FILENAME_LIMIT) break;
      if (symbol == '.') extended = '.';
      
      if (!bounded)
      {
         if (symbol == 32) break;

         #if defined(MS) || defined(DJGPP)
         if ((symbol ==            '/')
         ||  (symbol == PATH_SEPARATOR)) extended = 0;
         #else
         if (symbol == PATH_SEPARATOR) extended = 0;
         #endif
         
         if ((selector['o'-'a'])
         &&  (symbol > 0x40)
         &&  (symbol < 0x5B)) symbol |= 32;
      }
      
      if (symbol == qchar) break;
      *k++ = symbol;
      length++;
   }
   
   if ((extension) && (!extended))
   {
      while ((symbol = *extension++))
      {
         if ((selector['o'-'a'])
         &&  (symbol > 0x40)
         &&  (symbol < 0x5B)) symbol |= 32;
         
         *k++ = symbol;
         length++;
      }
   }
   
   *k++ = 0;
   length++;
   
   while (l)
   {
      if (strcmp(l->l.name, name) == 0) return l;
      l = l->l.along;
   }
   
   while(length & PARAGRAPH-1) name[length++] = 0;
   paragraphs = length>>2;
   length += sizeof(label)-PARAGRAPH;
   if (length > remainder) lr = buy_ltable();
   remainder -= length;
   l = lr;
   lr = (object *) ((char *) lr + length);
   l->l.r.l.xref = 0;
   l->l.r.l.rel = depth;
   l->l.r.l.y = 0;
   l->l.type = LABEL;
   l->l.length = length;
   l->l.valued = FILE_LABEL;
   l->l.value = minus_o;
   p = (paragraph *) l->l.name;
   q = (paragraph *) name;
   while (paragraphs--) *p++ = *q++;
   l->l.along = files;
   l->l.down  =  NULL;
   files = l;
   return l;
}

static void loadfile(char *arg, char *qual)
{
   if ((lix) && (pass) && (list > depth) && (selector['l'-'a']))
      printf("  :                            %d: %s\n", ll[depth], plix);

   lix = 0;
   plix[0] = 0;

   depth++;

   if (depth > INCLUDE_MAXDEPTH-1)
   {
      depth = INCLUDE_MAXDEPTH - 1;
      flag_either_pass("Include Nesting Too Deep", "abandon");
      exit(0);
   }

   file_label[depth] = compose_filename(arg, qual, 1);

   if (*arg == OFLAG) handle[depth] = 0;
   else  handle[depth] = open(file_label[depth]->l.name, O_RDONLY);

   quadza(handle[depth], &file_label[depth]->l.value);

   if (handle[depth] < 0)
   {
      flag_file_access();
      exit(0);
   }

   #ifdef BLOCK

   actual_block = block[depth];
   if (!actual_block)
   {
      actual_block = (rcb *) malloc(sizeof(rcb));

      if (!actual_block)
      {
         depth--;
         flagp1(arg);
         flagp1("No Read Resource");
         return;
      }

      block[depth] = actual_block;
   }

   actual_block->r = 0;
   actual_block->w = 0;

   #endif

   ll[depth] = 0;
}

#ifdef BLOCK

static int physin()
{
   rcb *b = actual_block;
   int x = b->r;

   if (x < b->w)
   {
      b->r++;
      return b->d[x];
   }

   x = read(handle[depth], b->d, BLOCK);

   if (x < 0)
   {
      printf("error reading file %s\n", file_label[depth]->l.name);
      exit(0);
   }

   b->w = x;

   if (!x) return -1;

   b->r = 1;
   return b->d[0];
}

static int next_byte()
{
   rcb			*b = actual_block;
   int			 x = b->r;

   if (x < b->w) return b->d[x];
   x = read(handle[depth], b->d, BLOCK);

   if (x < 0)
   {
      printf("error pre-reading file %s\n", file_label[depth]->l.name);
      exit(0);
   }

   b->w = x;
   b->r = 0;

   if (!x) return -1;
   return b->d[0];
}


#else

static int physin()
{
   int i;
   char c;
   for(;;)
   {
      i = read(handle[depth], &c, 1);
      if (i == 1) return c;
      close(handle[depth]);
      depth--;
      if (depth < 0) return -1;
   }
}

static int next_byte()
{
   int		 f = handle[depth];
   char		 c = 0;
   off_t	 here;

   if (pass == 0) return 0;
   here = lseek(f, 0, SEEK_CUR);
   read(f, &c, 1);
   lseek(f, here, SEEK_SET);
   return c;
}

#endif

#ifdef CODED_EXPRESS
static int coded_character(int symbol)
{
   int           x = symbol;

   if (code == ASCII)
   {
      if (byte < 7) x = (symbol & 0x1F) | ((symbol & 0x40) >> 1);
   }
   else
   {
      x = code_set[symbol];
   }

   return x;
}
#endif


static int operand_compare(line_item *left, line_item *right)
{
   int i, c = 0;
   
   if ((left->b[0] ^ right->b[0]) & 128)
   {
      if (left->b[0] & 128) return -1;
      return 1;
   }
   
   #ifdef INTEL
   while (c < RADIX/8)
   {
      if ((i = (left->b[c] - right->b[c]))) break;
      c++;
   }
   #else
   while (c < RADIX/16)
   {
      i = left->h[c] - right->h[c];

      if (i) break;

      /*********************************************
      int is 32 bits on all platforms except DOS BCC
      but .i[] is signed and must be cast to unsigned
      **********************************************/

      c++;
   }

   #endif


   return i;
}

#ifdef	DOS

static void operand_reverse(line_item *o)
{
   int i = RADIX/16;

   while (i--)
   {
      o->h[i] ^= 0xFFFF;
   }
}

static void operand_or(line_item *left, line_item *right)
{
   int i = RADIX/16;

   while (i--)
   {
      left->h[i] |= right->h[i];
   }
}

static void operand_and(line_item *left, line_item *right)
{
   int i = RADIX/16;

   while (i--)
   {
      left->h[i] &= right->h[i];
   }
}

static void operand_xor(line_item *left, line_item *right)
{
   int i = RADIX/16;

   while (i--)
   {
      left->h[i] ^= right->h[i];
   }
}

#else

static void operand_reverse(line_item *o)
{
   o->i[0] ^= 0xffffFFFF;
   o->i[1] ^= 0xffffFFFF;
   o->i[2] ^= 0xffffFFFF;

   #if RADIX==192
   o->i[3] ^= 0xffffFFFF;
   o->i[4] ^= 0xffffFFFF;
   o->i[5] ^= 0xffffFFFF;
   #endif
}

static void operand_or(line_item *left, line_item *right)
{
   left->i[0] |= right->i[0];
   left->i[1] |= right->i[1];
   left->i[2] |= right->i[2];

   #if RADIX==192
   left->i[3] |= right->i[3];
   left->i[4] |= right->i[4];
   left->i[5] |= right->i[5];
   #endif
}

static void operand_and(line_item *left, line_item *right)
{
   left->i[0] &= right->i[0];
   left->i[1] &= right->i[1];
   left->i[2] &= right->i[2];

   #if RADIX==192
   left->i[3] &= right->i[3];
   left->i[4] &= right->i[4];
   left->i[5] &= right->i[5];
   #endif
}

static void operand_xor(line_item *left, line_item *right)
{
   left->i[0] ^= right->i[0];
   left->i[1] ^= right->i[1];
   left->i[2] ^= right->i[2];

   #if RADIX==192
   left->i[3] ^= right->i[3];
   left->i[4] ^= right->i[4];
   left->i[5] ^= right->i[5];
   #endif
}

#endif	/* DOS		*/

#ifdef INTEL

static void operand_addcarry(unsigned short carry, line_item *o)
{
   int		 	i = RADIX/8;
   unsigned int	c = carry;

   while ((c) && (i))
   {
      i--;
      c += o->b[i];
      o->b[i] = c;
      c >>= 8;
   }
}

static void ashift(line_item *o, int scale)
{
   shift_matrix			 m;

   int				 i = scale >> 3,
				 j = scale & 7,
				 k = 0;

   unsigned			 short c;


   m.upper = zero_o;
   m.lower = *o;

   if (o->b[0] & 128) m.upper = minus_o;

   if (scale > 0)
   {
      while (k < (RADIX/8))
      {
         c = m.upper.b[i++] << 8;
         if (i < (RADIX/4)) c |= m.upper.b[i];
         c <<= j;
         m.upper.b[k++] = c >> 8;
      }
   }

   *o = m.upper;
}

static void lshift(line_item *o, short distance)
{
   int				 i = distance >> 3,
				 j = distance & 7,
				 k = 0;

   unsigned short		 c;


   if (distance < 0)
   {
      ashift(o, RADIX + distance);
      return;
   }

   while (i < RADIX/8)
   {
      c = o->b[i++] << 8;
      if (i < RADIX/8) c |= o->b[i];
      c <<= j;
      o->b[k++] = c >> 8;
   }
   while (k < RADIX/8) o->b[k++] = 0;
}

static void rshift(line_item *o, int distance)
{
   int				 i = RADIX/8 - (distance >> 3),
				 j = distance & 7,
				 k = RADIX/8;

   unsigned short		 c;

   if (i < 0) return;

   while (i--)
   {
      k--;
      c = o->b[i];
      if (i) c |= o->b[i-1] << 8;
      c >>= j;
      o->b[k] = c;
   }
   while (k--) o->b[k] = 0;
}

static int operand_shift_count(line_item *o)
{
   int		 i = 0, j = 0, c;

   while (i < RADIX/8)
   {
      if (o->b[i]) break;
      i++;
   }

   if (i == RADIX/8) return RADIX;

   c = i << 3;
   j = o->b[i];

   while (!(j & 128))
   {
      j <<= 1;
      c++;
   }

   lshift(o, c);
   return c;
}

static void operand_add(line_item *left, line_item *right)
{
   unsigned short c = 0;
   int i = RADIX/8;
   while (i--)
   {
      c += left->b[i];
      c += right->b[i];
      left->b[i] = c;
      c >>= 8;
   }
   if (!twoscomp) operand_addcarry(c, left);
}

static void operand_add_negative(line_item *left, line_item *right)
{
   unsigned short c = twoscomp;
   int i = RADIX/8;
   while (i--)
   {
      c += left->b[i];
      c += right->b[i] ^ 255;
      left->b[i] = c;
      c >>= 8;
   }
   if (!twoscomp) operand_addcarry(c, left);
}


static void operand_multiply(line_item *product, line_item *left, line_item *right)
{
   unsigned char sign1 = left->b[0] & 128;
   unsigned char sign2 = right->b[0] & 128;
   unsigned char sign = sign1 ^ sign2;
   unsigned char b;
   
   int i = 0, j, u;
   unsigned short c = 0;
   
   line_item transient;
   
   if (sign1)
   {
      operand_reverse(left);
      operand_addcarry(twoscomp, left);
   }
   if (sign2)
   {
      operand_reverse(right);
      operand_addcarry(twoscomp, right);
   }
   while (i < RADIX/8)
   {
      if (right->b[i]) break; 
      i++;
   }
   while (i < RADIX/8)
   {
      j = i + 1;
      c = 0;
      b = right->b[i];
      u = RADIX/8;
      while (j)
      {
	 j--;
	 u--;
	 c += left->b[u] * b;
	 transient.b[j] = c;
	 c >>= 8;
      }
      j = i + 1;
      c = 0;
      while (j)
      {
	 j--;
	 c += transient.b[j] + product->b[j];
	 product->b[j] = c;
	 c >>= 8;
      }
      i++;
   }
   if (sign)
   {
      operand_reverse(product);
      operand_addcarry(twoscomp, product);
   }
}
#else

static void operand_addcarry(unsigned short c, line_item *o)
{
   int			 i = RADIX/16;
   unsigned int	 carry = c;

   while ((carry) && (i))
   {
      i--;
      carry += o->h[i];
      o->h[i] = carry;
      carry >>= 16;
   }
}

static void ashift(line_item *o, int scale)
{
   shift_matrix			 m = { zero_o, *o } ;

   int				 i = scale >> 4,
				 j = scale & 15,
				 k = 0;

   unsigned			 int c;


   if (o->b[0] & 128) m.upper = minus_o;

   while (i < 2*RADIX/16)
   {
      c = m.upper.h[i++] << 16;
      if (i < 2*RADIX/16) c |= m.upper.h[i];
      c <<= j;
      m.upper.h[k++] = c >> 16;
   }

   *o = m.upper;
}

static void lshift(line_item *o, short distance)
{
   int				 i = distance >> 4,
				 j = distance & 15,
				 k = 0;

   unsigned			 int c;


   if (distance < 0)
   {
      ashift(o, RADIX + distance);
      return;
   }

   while (i < RADIX/16)
   {
      c = o->h[i++] << 16;
      if (i < RADIX/16) c |= o->h[i];
      c <<= j;
      o->h[k++] = c >> 16;
   }
   while (k < RADIX/16) o->h[k++] = 0;
}

static void rshift(line_item *o, int distance)
{
   int				 i = RADIX/16 - (distance >> 4),
				 j = distance & 15,
				 k = RADIX/16;

   unsigned			 int c;


   if (i < 0) return;
   while (i--)
   {
      k--;
      c = o->h[i];
      if (i) c |= o->h[i-1] << 16;
      c >>= j;
      o->h[k] = c;
   }

   while (k--) o->h[k] = 0;
}

static int operand_shift_count(line_item *o)
{
   int		 i = 0, j = 0, c;

   while (i < RADIX/16)
   {
      if (o->h[i]) break;
      i++;
   }

   if (i == RADIX/16) return RADIX;
   c = i << 4;

   j = o->h[i];

   while (!(j & 32768))
   {
      j <<= 1;
      c++;
   }

   lshift(o, c);

   return c;
}

static void operand_add(line_item *left, line_item *right)
{
   unsigned int	 c = 0;
   int			 i = RADIX/16;

   while (i--)
   {
      c += left->h[i];
      c += right->h[i];
      left->h[i] = c;
      c >>= 16;
   }
   if (!twoscomp) operand_addcarry(c, left);
}

static void operand_add_negative(line_item *left, line_item *right)
{
   unsigned int	 c = twoscomp;
   int			 i = RADIX/16;
   while (i--)
   {
      c += left->h[i];
      c += right->h[i] ^ 65535;
      left->h[i] = c;
      c >>= 16;
   }
   if (!twoscomp) operand_addcarry(c, left);
}

static void operand_multiply(line_item *product, line_item *left, line_item *right)
{
   unsigned char	 sign1 = left->b[0]  & 128;
   unsigned char	 sign2 = right->b[0] & 128;
   unsigned char	 sign = sign1 ^ sign2;
   unsigned short	 b;
   
   int			 i = 0, j, u;
   unsigned int	 c = 0;
   
   line_item transient;
   
   if (sign1)
   {
      operand_reverse(left);
      operand_addcarry(twoscomp, left);
   }

   if (sign2)
   {
      operand_reverse(right);
      operand_addcarry(twoscomp, right);
   }

   while (i < RADIX/16)
   {
      if (right->h[i]) break; 
      i++;
   }

   while (i < RADIX/16)
   {
      j = i + 1;
      c = 0;
      b = right->h[i];
      u = RADIX/16;

      while (j)
      {
	 j--;
	 u--;
	 c += left->h[u] * b;
	 transient.h[j] = c;
	 c >>= 16;
      }

      j = i + 1;
      c = 0;

      while (j)
      {
	 j--;
	 c += transient.h[j] + product->h[j];
	 product->h[j] = c;
	 c >>= 16;
      }
      i++;
   }

   if (sign)
   {
      operand_reverse(product);
      operand_addcarry(twoscomp, product);
   }
}


#endif

static void operand_divide(line_item *quotient, line_item *left, line_item *right)
{
   char			 sign1 = left->b[0] & 128;
   char			 sign2 = right->b[0] & 128;
   char			 sign = sign1 ^ sign2;
   int			 i, range;
   
   if (sign1)
   {
      operand_reverse(left);
      operand_addcarry(twoscomp, left);
   }

   if (sign2)
   {
      operand_reverse(right);
      operand_addcarry(twoscomp, right);
   }

   range = operand_shift_count(right);

   if (range < RADIX)
   {
      while (range--)
      {
	 rshift(right, 1);
	 lshift(quotient, 1);

	 i = operand_compare(left, right);

	 if (i > (-1))
	 {
	    quotient->b[RADIX/8-1] |= 1;
	    operand_add_negative(left, right);
	 }
      }
   }

   if (sign)
   {
      operand_reverse(quotient);
      operand_addcarry(twoscomp, quotient);
   }

   if (sign1)
   {
      operand_reverse(left);
      operand_addcarry(twoscomp, left);
   }
}

static line_item *xpression(char *s, char *e, char *param)
{
   #ifndef VERY_STACKED_XPRESSION
   static line_item		 o[XPRESSION+1];
   static line_item		*sp = &o[XPRESSION];
   #endif

   int				 i = 0, ires;

   char				*d,
				*p,
				*margin;

   unsigned short		 c;
   short			 x;
   short			 y;

   char				 override = 0, symbol;

   line_item			*left, *right, *final = sp;
   object			*l;
   
   #ifdef RELOCATION
   linkage			 left_side;
   #endif

   #ifdef LTAG
   location_counter		*q;
   value			*v;
   #endif

   if (s == STACK_TOP_VALUE) return sp;

   *sp = zero_o;
   floating_field = 0;
   
   #ifdef RELOCATION
   mapx->m.i = 0;
   mapx->scale = 0;
   #endif

   while ((s < e) && (*s == ' ')) s++;

   if (s == e) return sp;
   
   #ifdef VERY_STACKED_XPRESSION
   if ( sp <  &ostac[2])
   {
      flagg("expression too deep\n");
      return sp;
   }

   if (sp == &ostac[XPRESSION]) floating_conversion = 0;
   #else
   if ( sp <  &o[2])
   {
      flagg("expression too deep\n");
      return sp;
   }

   if (sp == &o[XPRESSION]) floating_conversion = 0;
   #endif

#if 0
   if ((d = contains(s, e, "=\0")))
   {
      /*
      if (expression(s, d, param)
      ==  expression(d+1, e, param)) return 1;
      else                                  return 0;
      */
      sp--;
      left = xpression(s, d, param);
      
      #ifdef RELOCATION
      left_side = mapx->m;
      #endif

      sp--;
      right = xpression(d+1, e, param);
      i = operand_compare(left, right);
      sp += 2;
      if (!i) sp->b[RADIX/8-1] = 1;

      #ifdef RELOCATION
      if ((left_side.l.y | mapx->m.l.y)
      &&  (left_side.i   ^ mapx->m.i))
      flag("comparison between differently relocated values");
      #endif
      
      return sp;
   }
#endif   

   if ((d = contains(s, e, "^=\0")))
   {
      /*
      if (expression(s, d, param)
      !=  expression(d+1, e, param)) return 1;
      else                                  return 0;
      */
      sp--;
      left = xpression(s, d, param);
      
      #ifdef RELOCATION
      left_side = mapx->m;
      #endif

      sp--;
      right = xpression(d+2, e, param);
      i = operand_compare(left, right);
      sp += 2;
      if (i) sp->b[RADIX/8-1] = 1;

      #ifdef RELOCATION
      if ((left_side.l.y | mapx->m.l.y)
      &&  (left_side.i   ^ mapx->m.i))
      flag("Comparison between differently relocated values");
      #endif
      
      return sp;
   }
   
   if ((d = contains(s, e, "=\0")))
   {  
      /* 
      if (expression(s, d, param)
      ==  expression(d+1, e, param)) return 1;
      else                                  return 0;
      */
      sp--;
      left = xpression(s, d, param);
      
      #ifdef RELOCATION
      left_side = mapx->m;
      #endif
      
      sp--; 
      right = xpression(d+1, e, param);
      i = operand_compare(left, right);
      sp += 2;
      if (!i) sp->b[RADIX/8-1] = 1;
      
      #ifdef RELOCATION
      if ((left_side.l.y | mapx->m.l.y)
      &&  (left_side.i   ^ mapx->m.i))
      flag("comparison between differently relocated values");
      #endif
      
      return sp;
   }
  
   #if OPERATORS == 19

   if ((d = contains(s, e, "^>\0")))
   {
      sp--;
      left = xpression(s, d, param);

      #ifdef RELOCATION
      left_side = mapx->m;
      mapx->m.i = 0;
      #endif

      sp--;
      right = xpression(d+2, e, param);
      i = operand_compare(left, right);
      sp += 2;

      if ((i < 0) || (i == 0)) sp->b[RADIX/8-1] = 1;

      #ifdef RELOCATION
      if ((left_side.l.y | mapx->m.l.y)
      &&  (left_side.i   ^ mapx->m.i))
      flag("Comparison between differently relocated values");
      #endif

      return sp;
   }

   #endif

   if ((d = contains(s, e, ">\0")))
   {
      /*
      if (expression(s, d, param)
      >   expression(d+1, e, param)) return 1;
      else                                  return 0;
      */
      sp--;
      left = xpression(s, d, param);
      
      #ifdef RELOCATION
      left_side = mapx->m;
      mapx->m.i = 0;
      #endif

      sp--;
      right = xpression(d+1, e, param);
      i = operand_compare(left, right);
      sp += 2;
      if (i > 0) sp->b[RADIX/8-1] = 1;

      #ifdef RELOCATION
      if ((left_side.l.y | mapx->m.l.y)
      &&  (left_side.i   ^ mapx->m.i))
      flag("Comparison between differently relocated values");
      #endif
      
      return sp;
   }

   #if OPERATORS == 19

   if ((d = contains(s, e, "^<\0")))
   {
      sp--;
      left = xpression(s, d, param);

      #ifdef RELOCATION
      left_side = mapx->m;
      mapx->m.i = 0;
      #endif

      sp--;
      right = xpression(d+2, e, param);
      i = operand_compare(left, right);
      sp += 2;

      if (i < 0)
      {
      }
      else  sp->b[RADIX/8-1] = 1;

      #ifdef RELOCATION
      if ((left_side.l.y | mapx->m.l.y)
      &&  (left_side.i   ^ mapx->m.i))
      flag("Comparison between differently relocated values");
      #endif

      return sp;
   }

   #endif

   if ((d = contains(s, e, "<\0")))
   {
      /*
      if (expression(s, d, param)
      <   expression(d+1, e, param)) return 1;
      else                                  return 0;
      */
      sp--;
      left = xpression(s, d, param);
      
      #ifdef RELOCATION
      left_side = mapx->m;
      mapx->m.i = 0;
      #endif

      sp--;
      right = xpression(d+1, e, param);
      i = operand_compare(left, right);
      sp += 2;
      if (i < 0) sp->b[RADIX/8-1] = 1;

      #ifdef RELOCATION
      if ((left_side.l.y | mapx->m.l.y)
      &&  (left_side.i   ^ mapx->m.i))
      flag("Comparison between differently relocated values");
      #endif
      
      return sp;
   }

   #ifndef PROMOTE_UNARY
   /*
   if (*s == '!') return expression(++s, e, param) ^ -1;
   if (*s == '-') return 0 - expression(++s, e, param);
   */
   if (*s == '^')
   {
      xpression(++s, e, param);
      operand_reverse(sp);
      return sp;
   }

   if (*s == '-')
   {
      xpression(++s, e, param);
      operand_reverse(sp);
      operand_addcarry(twoscomp, sp);
      return sp;
   }

   if (*s == '+') s++;
   #endif
   

   if ((d = contains(s, e, "--\0")))
   {
      left = xpression(s, d, param);
      
      #ifdef RELOCATION
      RCHECK(s)
      #endif
      
      sp--;
      right = xpression(d+2, e, param);
      operand_xor(left, right);

      #ifdef RELOCATION
      RCHECK(d)
      #endif
      
      sp++;
      return sp;
   }

   if ((d = contains(s, e, "++\0")))
   {
      left = xpression(s, d, param);
      
      #ifdef RELOCATION
      RCHECK(s)
      #endif
      
      sp--;
      right = xpression(d+2, e, param);
      operand_or(left, right);

      #ifdef RELOCATION
      RCHECK(d)
      #endif
      
      sp++;
      return sp;
   }

   if ((d = contains(s, e, "/*\0")))
   {
      left = xpression(s, d, param);
      
      #ifdef RELOCATION
      left_side = mapx->m;
      #endif
      
      sp--;
      right = xpression(d+2, e, param);

      #ifdef RELOCATION
      RCHECK(d)

      if (left_side.l.y)
      {
         x = read16(RADIX/16-1, right);
         map_offset(-x, left);
         o_range(0, left);
      }

      mapx->m  = left_side;
      #endif

      rshift(left, right->b[RADIX/8-1]);
      sp++;
      return sp;
   }

   if ((d = contains(s, e, "*/\0")))
   {
      left = xpression(s, d, param);
      
      #ifdef RELOCATION
      left_side = mapx->m;
      #endif
      
      sp--;
      right = xpression(d+2, e, param);

      x = read16(RADIX/16-1, right);

      #ifdef RELOCATION
      RCHECK(d)

      if (left_side.l.y)
      {
         /****************************************
         if the shift expression begins with unary
         minus, this signals link steps to treat
         the field as signed

         therefore left shift argument -0 switches
	 on the signed flag without shifting
         ****************************************/


         if (*(d + 2) == '-') left_side.l.y |= 4;

         if (x < 0)
         {
            /****************************************
            if the left shift is really a right shift
            then the separately encoded unrelocated
            part + the shift indication are output
            ****************************************/

            left_side.l.y |= 4;
            map_offset(x, left);
            o_range(left_side.l.y, left);
         }

         else
         {
            /****************************************
            the else lets this test get skipped:
            an advantage rather than a necessity

            if the left shift is positive, the
            shifted thing may not be relocatable
            ****************************************/

            if (x) flag("left shift relocatable target");
         }
      }

      mapx->m = left_side;
      #endif
      
      lshift(left, x);
      sp++;
      return sp;
   }

   if ((d = contains(s, e, "**\0")))
   {
      left = xpression(s, d, param);
      
      #ifdef RELOCATION
      left_side = mapx->m;
      if (mapx->m.l.y) left_side.l.y |= 2;
      #endif
      
      sp--;
      right = xpression(d+2, e, param);
      operand_and(left, right);

      #ifdef RELOCATION
      RCHECK(d)
      mapx->m = left_side;
      #endif
      
      sp++;
      return sp;
   }

   #define FP_EARLIER
   #ifdef  FP_EARLIER


   if  (digitstring_fraction(s, e))
   {
      if ((*s == '-') || (*s == '^'))
      {
         xpression(s + 1, e, param);
         operand_reverse(sp);
         return sp;
      }
      else if (*s == '+')
      {
         xpression(s + 1, e, param);
         return sp;
      }


      floating_generate(s, e, param, sp);
      floating_position(transient_floating_bits, sp);
      floating_field = transient_floating_bits;
      return sp;
   }

   if ((d = contains(s, e, "*+\0*-\0")))
   {
      if (!transient_floating_bits) transient_floating_bits = fpwidth;

      margin = d;

      override = 0;
      symbol = 0;

      if (margin > s)
      {
         symbol = *(margin - 1);
         if (margin > (s + 1)) override = *(margin - 2);
      }

      if ((x = length_mark(symbol)))
      {
         if (override == ':')
         {
            margin -= 2;
            transient_floating_bits = x;
         }
         else if ((override == ')') || (override == '\'') || (override == qchar))
         {
            margin--;
            transient_floating_bits = x;
         }
         else
         {
            p = frightmost(s, d);
            c = *p;

            if ((c > '0' - 1) && (c < '9' + 1))
            {
               if (suffix)
               {
                  if (suffix_noclash(symbol))
                  {
                     margin--;
                     transient_floating_bits = x;
                  }
               }
               else if (selector['c'-'a'])
               {
                  y = *(p + 1);
                  if ((c > '0')
                  ||  ((c == '0') && (y ^ 'x') && (y ^ 'X'))
                  ||  ((c == '0') && (symbol ^ 'd') && (symbol ^ 'D')))
                  {
                     margin--;
                     transient_floating_bits = x;
                  }
               }
               else
               {
                  if ((c > '0')
                  ||  ((c == '0') && (octal))
                  ||  ((c == '0') && (symbol ^ 'd') && (symbol ^ 'D')))
                  {
                     margin--;
                     transient_floating_bits = x;
                  }
               }
            }
         }
      }

      if (transient_floating_bits > RADIX) transient_floating_bits = RADIX / word * word;

      #if 0
      transient_floating_bits /= word;
      transient_floating_bits *= word;
      #endif

      if (pass)
      {
//         floating_conversion = 0;
         xpression(s, margin, param);
         sp--;
         i -= expression(d+2, e, param);
         if (*(d + 1) == '-') i = 0 - i;
         sp++;

         if (floating_conversion) flag("overloaded floating conversion");
         floating_conversion++;

         if (sp->b[0] & 128)
         {
            operand_reverse(sp);
            operand_addcarry(1, sp);
            characterise(i, sp);
            floating_position(transient_floating_bits, sp);
            operand_reverse(sp);
         }
         else
         {
            characterise(i, sp);
            floating_position(transient_floating_bits, sp);
         }
      }

      floating_field = transient_floating_bits;
      return sp;
   }
   #endif       /*      FP_EARLIER        */

   if ((d = operates(s, e, "-\0+\0")))
   {
      /*******************************************************
         this precaution here allows unary signs to follow
         after multiply/divide/shift operators without
         getting mistaken for add/subtract operators
      *******************************************************/

      #if 0	/* operates function does this */
      symbol = *(d-1);
      if ((symbol != '*')
      &&  (symbol != '/')
      &&  (symbol != '+')
      &&  (symbol != '-'))
      {
      #endif

	 if (*d == '+')
	 {
	    left = xpression(s, d, param);
	    sp--;
	    
	    #ifdef RELOCATION
	    left_side = mapx->m;
            #endif

	    right = xpression(d + 1, e, param);
	    operand_add(left, right);
	    sp++;

	    #ifdef RELOCATION
            #ifdef MULTUPLES

	    if (mapx->m.l.y)
            {
               mapx->scale = 0;

               if (left_side.l.y)
               {
                  mapx->m.l.y |= 16;
                  mapx->recursion = maprecursion;
                  mapx++;
                  mapx->m.i = left_side.i;
               }
            }

            else mapx->m.i = left_side.i;

            #else

	    if (left_side.l.y & mapx->m.l.y)
	    flag("Adding two relocated values not accepted1");

            #endif
	    
            #ifndef MULTUPLES
	    if (left_side.l.y & 1)
	    {
	       mapx->m.l.y |= 1;
	       mapx->m.l.rel = left_side.l.rel;
	    }

	    if (left_side.l.y & 128)
	    {
	       mapx->m.l.y |= 128;
	       mapx->m.l.xref = left_side.l.xref;
	    }
            #endif
            #endif
      
	    return sp;
	 }
	 
	 if (*d == '-')
	 {
	    left = xpression(s, d, param);
	    sp--;
	    
	    #ifdef RELOCATION
	    left_side = mapx->m;
            #endif
            c = transient_floating_bits;
	    right = xpression(d + 1, e, param);

            if (floating_field)
            {
               operand_reverse(right);
               operand_add(left, right);

               /*****************************************

		-unary has become effectively 0 - token

                prevent floating number from accidentally
                getting 2s-complemented. It must be
                1s-complemented

               *****************************************/
            }
	    else operand_add_negative(left, right);

	    sp++;

	    #ifdef RELOCATION

	    if (mapx->m.l.y)
	    {
	       if ((left_side.i == mapx->m.i)
               ||  (((left_side.l.y & 129) == 1)
                 && ((left_side.l.y &   8) == 0)
                 && ((mapx->m.l.y   & 129) == 1)
                 && (left_side.l.rel == mapx->m.l.rel)))
	       {
		  mapx->m.i = 0;

                  /******************************************
                  both relocated with the same segment or
                  external = difference is not relocatable
                  ******************************************/


                  if (mapx > mapinfo)
                  {
                     if ((mapx-1)->scale < 0) mapx--;
                     if (mapx > mapinfo)
                     {
                        mapx->m.i = 0;
                        mapx--;
                        mapx->m.l.y &= 0xEF;
                     }
                  }

                  /******************************************
                  the tuple newly at the stack top is now
                  the main initial tuple and not a chain
                  successor
                  ******************************************/
	       }
	       else
	       {
                  #ifdef MULTUPLES

                  mapx->scale = 0;
                  mapx->m.l.y |= 8;

                  if (left_side.l.y)
                  {
                     mapx->m.l.y |= 16;
                     mapx->recursion = maprecursion;
                     mapx++;
                     mapx->m.i = left_side.i;
                  }

                  #else

		  flag("subtracting unrelated relocatables");

                  #endif
	       }
	    }

            else
            {
               mapx->m.i = left_side.i;
            }
       
            #endif

	    return sp; 
	 }
      #if 0	/*	operates() function did that	*/
      }
      #endif
   }
   

   if ((d = operates(s, e, "///\0//\0/\0*\0")))
   {
      sp--;
      left = xpression(s, d, param);
      sp--;
      
      #ifdef RELOCATION
      RCHECK(s)
      #endif
      
      if (*d == '*')
      {
	 right = xpression(d+1, e, param);
	 operand_multiply(final, left, right);

	 #ifdef RELOCATION
	 RCHECK(s)
	 #endif
      
	 sp += 2;
	 return sp;
      }
      if ((*d == '/') && (*(d+1) == '/') && (*(d+2) == '/'))
      {
	 right = xpression(d+3, e, param);
	 operand_divide(final, left, right);
	 *final = *left;

	 #ifdef RELOCATION
	 RCHECK(d)
	 #endif
      
	 sp += 2;
	 return sp;
      }
      if ((*d == '/') && (*(d+1) == '/'))
      {
	 right = xpression(d+2, e, param);
	 operand_add(left, right);
	 operand_add(left, &minus_o);
	 operand_divide(final, left, right);

	 #ifdef RELOCATION
	 RCHECK(d)
	 #endif
      
	 sp += 2;
	 return sp;
      }
      if (*d == '/')
      {
	 right = xpression(d+1, e, param);
	 operand_divide(final, left, right);

	 #ifdef RELOCATION
	 RCHECK(d)
	 #endif
      
	 sp += 2;
	 return sp;
      }
   }

   #undef FP_LATER
   #ifdef FP_LATER
   #endif	/*	FP_LATER	*/

   #ifdef PROMOTE_UNARY
   
   if (*s == '^')
   {
      xpression(++s, e, param);
      operand_reverse(sp);
      return sp;
   }

   if (*s == '-')
   {
      xpression(++s, e, param);
      operand_reverse(sp);
      if (contains(s, e, "*+\0*-\0"))
      {
      }
      else operand_addcarry(twoscomp, sp);

      #ifdef RELOCATION
      #ifdef MULTUPLES
      if (mapx->m.l.y)
      {
         /*****************************************
		if a relocation tuple applies
		it only needs -polarity 
         *****************************************/

         mapx->m.l.y |= 8;
         mapx->recursion = maprecursion;
      }
      #endif
      #endif

      return sp;
   }

   if (*s == '+')
   {
      xpression(++s, e, param);
      return sp;
   }
   
   #endif


   if (*s == '(')
   {
      d = fendb(s, e);
      xpression(s+1, d, param);
      return sp;
   }
      
   if (*s == 0x27)
   {
      if (qchar == 0x27) s = substitute(s, param);
      s++;

      while ((ires = *s++))
      {
	 if (ires == 0x27)
	 {
	    ires = *s++;
	    if (ires != 0x27) break;
	 }

         if ((selector['c'-'a']) && (ires == '\\'))
         {
            ires = *s++;


            if ((ires >='0') && (ires <= '7'))
            {
               ires &= 7;

               /*******************************************************************
                one octal symbol has been consumed

                there may be 2 more for bytes 7..9 bits in size = 3 maximum
                             3 more for bytes 10..12 bits in size = 4 maximum
                             nane more for bytes 1..3 bits in size = 1 maximum
                             1 more for bytes 4..6 bits in size = 2 maximum
                             4 more for bytes 11..15 bits in size = 5 maximum
                             5 more for bytes 16..18 bits in size = 6 maximum
                             6 more for bytes 19..21 bits in size = 7 maximum
                             7 more for bytes 22..24 bits in size = 8 maximum
                and so on up to 11 octal symbols maximum for 32-bit bytes

                bytes may be any size 1..32 bits without regard to word
                or address quantum
               *******************************************************************/

               y = (byte - 1)/3;

               while (y--)
               {
                  x = *s;
                  if (x < '0') break;
                  if (x > '7') break;
                  ires <<= 3;
                  ires |= x & 7;
                  s++;
               }

               if ((code == DATA_CODE) && (uselector['D'-'A']))
               {
                  if (ires & -256)
                  {
                     flag("-D flag \\translate input outside Latin-1 range");
                  }
                  else ires = code_set[ires];
               }
            }

            else switch (ires)
            {
               case 'x':

                  ires = 0;

                  for (;;)
                  {
                     x = *s;

                     if      ((x >= '0') && (x <= '9')) x &= 15;
                     else if ((x >= 'a') && (x <= 'f')) x += 10 - 'a';
                     else if ((x >= 'A') && (x <= 'F')) x += 10 - 'A';
                     else break;

                     ires <<= 4;
                     ires |= x;
                     s++;
                  }

                  if ((code == DATA_CODE) && (uselector['D'-'A']))
                  {
                     if (ires & -256)
                     {
                        flag("-D flag \\translate input outside Latin-1 range");
                     }
                     else ires = code_set[ires];
                  }

                  break;

               default:
                 ires = simple_c_escape(ires);
                 ires = coded_character(ires);
            }
         } 
         else
         {
            #ifdef CODED_EXPRESS
            ires = coded_character(ires);
            #endif
         }

         #ifdef CODED_EXPRESS
         lshift(sp, byte);

         #ifdef INTEL
         sp->b[RADIX/8-1] |= ires; 
         sp->b[RADIX/8-2] |= ires >>  8;
         sp->b[RADIX/8-3] |= ires >> 16;
         sp->b[RADIX/8-4] |= ires >> 24;
         #else
         sp->i[RADIX/32-1] |= ires;
         #endif
         
         #else
	 for (i = 0; i < RADIX/8-1; i++) sp->b[i] = sp->b[i+1];
	 sp->b[RADIX/8-1] = ires;
         #endif
      }
      return sp;
   }

   if (selector['m'-'a'])
   {
      if (*s == '$')
      {
	 s++;
	 override = 'H';
      }

      if (*s == '@')
      {
         s++;
         override = 'O';
      }

      if (*s == '%')
      {
	 s++;
	 override = 'B';
      }
   }
 
   if (selector['c'-'a'])
   {
      if (*s == '0')
      {
	 s++;
	 if ((*s == 'x') || (*s == 'X'))
	 {
	    s++;
	    override = 'H';
	 }
	 else
	 {
	    override = 'O';
	 }
      }  
   }
 
   i = 0;
   if ((suffix) && (*s > 0x2f) && (*s < 0x3a))
   {
      override = *(e - 1);
      if ((override > 0x60) && (override < 0x7b)) override &= 0x5f;
      if (override == 'Q') override = 'O'; 
      if ((override != 'D')
      &&  (override != 'O')
      &&  (override != 'B')
      &&  (override != 'H')) override = 0;
      if ((!override) && (suffix & 2)) override = 'D';
   }
   
   if (((*s == '0') && (!override) && (!octal)) 
   ||  (override == 'H'))
   {
      while (((*s > 0x2F) && (*s < 0x3A))
      ||     ((*s > 0x40) && (*s < 0x47))
      ||     ((*s > 0x60) && (*s < 0x67)))
      {
	 lshift(sp, 4);
	 if (*s < 0x40) sp->b[RADIX/8-1] |=  (*s & 15);
	 else           sp->b[RADIX/8-1] |= ((*s & 15) + 9);
	 s++;
	 if (s == e) break;
      }
      return sp; 
   }

   if (((*s == '0') && (!override) && (octal))
   ||  (override == 'O'))
   {
      while ((*s > 0x2F) && (*s < 0x38))
      {
	 lshift(sp, 3);
	 sp->b[RADIX/8-1] |= *s++ & 7;
	 if (s == e) break;
      }
      return sp;
   }

   if ((*s == '\\') || (override == 'B'))
   {
      if (*s == '\\') s++;
      while ((*s == 48) || (*s == 49))
      {
	 lshift(sp, 1);
	 sp->b[RADIX/8-1] |= *s++ & 1;
	 if (s == e) break;
      }
      return sp;
   }
   
   if ((*s > 0x2F) && (*s < 0x3A))
   {
      while ((*s > 0x2F) && (*s < 0x3A))
      {
	 i = RADIX/8;
	 c = *s++ & 15;
	 while (i--)
	 {
	    c += sp->b[i] * 10;
	    sp->b[i] = c;
	    c >>= 8;
	 }
	 if (s == e) break;
      }
      return sp;
   }  

   if (*s == qchar) s = substitute(s, param);

   #ifdef ESC

   if (*s == ESC) return extract_xparam(s+1, param);

   #else
   #error set ESC
   #endif

   l = findlabel(s, e);

   if (l)
   {
      switch (l->l.valued)
      {
	 #ifdef EQUF
	 case EQUF:

            #ifdef PART_EQUF
	    if (*label_margin == '\\')
            {
               i = expression(label_margin+1, e, param);

               if ((i > 0) && (i < (RADIX/32+1)))
               {
                  if (l->l.value.b[RADIX/8 - i*4] & 128) *sp = minus_o;
                  sp->i[RADIX/32-1] = l->l.value.i[RADIX/32-i];
               }

               return sp;
            }
            #endif
	    
	    #ifdef RELOCATION
	    if (l->l.r.l.y) mapx->m = l->l.r;
            else            mapx->m.l.rel = l->l.r.l.rel;
	    #endif

	    sp->i[RADIX/32-1] = l->l.value.i[RADIX/32-1];

            if (address_size < 32) sp->b[RADIX/8-4] &= 127;

	    return sp;
	 #endif

         case LOCATION:
	 case EQU:
	 case SET:
	
	 case DIRECTIVE:
            if (l->l.valued == DIRECTIVE)
            {
               #ifdef GEOMETRIC_FUNCTIONS
               switch (l->l.value.b[RADIX/8-1])
               {
                  case WORD:
                    sp->b[RADIX/8-1] = word;
                    return sp;
                  case BYTE:
                    sp->b[RADIX/8-1] = byte;
                    return sp;
                  case AWIDTH:
                    sp->b[RADIX/8-1] = address_size;
                    return sp;
                  case QUANTUM:
                    sp->b[RADIX/8-1] = address_quantum;
                    return sp;
                  case LITS:
                    sp->b[RADIX/8-1] = litloc;
                    return sp;
               }
               #else
               switch (l->l.value.b[RADIX/8-1])
               {
                  case WORD:
                     note("function use of $word does not yield word size");
                     break;
                  case BYTE:
                     note("function use of $byte does not yield byte size");
                     break;                 
                  case AWIDTH:
                     note("function use of $awidth does not yield address width");
                     break;                 
                  case QUANTUM:
                     note("function use of $quantum does not yield address quantum");                
                     break;
               }
               #endif
            }

	 case FORM:
	    
	    #ifdef RELOCATION
            mapx->m.l.rel = l->l.r.l.rel;
	    if (l->l.r.l.y) mapx->m = l->l.r;
	    #endif

	    *sp = l->l.value;
	    return sp;

            #ifdef LITERALS
         case LTAG:
            i = l->l.r.l.rel & 127;
            ires = literal(label_margin, param, i);
            quadza(ires, sp);

            q = &locator[i];

            if ((q->flags & 129) == 1)
            {
               if ((v = (value *) q->runbank.a))
               {
                  *sp = v->value;
                  quadd_u(ires, sp);
               }
            }

            return sp;
            #endif

	 case INTERNAL_FUNCTION:

            if (plist > masm_level)
            {
               if (((pass) && (selector['q'-'a']))
               || ((!pass) && (selector['r'-'a'])))
               {
                  printf(":::: IF :::: %s %s %s\n", l->l.name,
                                         label_margin, param);
               }
            }

	    i = qextractv(l);
	    if (*s == qchar) 
		 ires = i;
	    else ires = rfunction(i, label_margin, param, e, l);
            
            /**************************************************
            location counter is conceptually unsigned. Zero fill
            is applied to location counter,  and sign extension
            to the other internal functions
            **************************************************/

            #ifdef ABSOLUTE
            if ((ires < 0)
            &&  (i ^ LOCTR) && (i ^ ABSOLUTE) && (i ^ NET) && (i ^ SIMPLE_BASE)) *sp = minus_o;
            #else
            if ((ires < 0)
            &&  (i ^ LOCTR) && (i ^ NET) && (i ^ SIMPLE_BASE)) *sp = minus_o;
            #endif

            quadinsert(ires, sp);
	    return sp;

	 case NAME:

	    if (l == entry[masm_level])
            {
               *sp = l->l.value;
               return sp;
            }

            #ifdef ABOUND
            if (l->l.passflag & 64)
            {
            }
            else
            {
               *sp = l->l.value;
               return sp;
            }
            #endif
            

	 case FUNCTION:

            if ((uselector['Q'-'A'] == 0) &&  (*s == qchar))
            {
                *sp = l->l.value;
                return sp;
            }

            return external_function(label_margin, param, e, l);

	 case PROC:

            *sp = l->l.value;
            return sp;

	 default:
	    if (l->l.valued > 127)
	    {
	       *sp = l->l.value;
	       return sp;
	    }
      }
   }


   if (!pass)
   {
      if (l)
      {
         if (l->l.valued == UNDEFINED) forward_reference = 1;
      }
      else forward_reference = 1;

      return sp;
   }

   if (l)
   {
      if (l->l.valued)
      {
         *sp = l->l.value;
	 return sp;
      }
      else
      {
         /***********************************************
            we only arrive here on the second pass
         ***********************************************/

         #ifdef BINARY
         if (l->l.r.l.xref < 0)
         {
            l->l.r.l.xref = ucount++;
         }
         #endif

         uflag(name);
      }
   }
   else
   {
      if (label_highest_byte == 0)
      {
         flag("expression particle not understood");
         return sp;
      }
      
      uflag(name);

      l = insert_ltable(name, NULL, &zero_o, UNDEFINED);

      if (!l)
      {
         flag("internal error");
         return sp;
      }

      l->l.r.l.xref = ucount++;

   }
   
   #ifdef RELOCATION
   mapx->m.l.y |= 128;
   mapx->m.l.xref = l->l.r.l.xref;
   #endif

   return /* &o[0] */ sp;
}

static int ixpression(char *s, char *e, char *param)
{
   line_item		*o = xpression(s, e, param);

   #if RADIX==192
   return o->i[0] | o->i[1] | o->i[2] | o->i[3] | o->i[4] | o->i[5];
   #endif
   
   #if RADIX==96
   return o->i[0] | o->i[1] | o->i[2];
   #endif
}

#ifdef ULTRA_RESOLVE

/*********************************************************

where intermediate results inter than int must not
be lost but the result should fit in int

*********************************************************/

static /* int */ int zxpression(char *s, char *e, char *param)
{
   line_item		*sp = xpression(s, e, param);

   #ifdef RANGE_WARNING
   range_warning(sp);

   #endif
   
   return quadextract(sp);
}

#endif

#ifdef VERY_STACKED_XPRESSION

static int expression(char *s, char *e, char *param)
{ 
   int			 y;
   link_profile		*b4 = mapx;

   sp--;
   y = zxpression(s, e, param);
   sp++;

   #ifdef EFLAG
   if (mapx->m.l.y & 128)
   {
      flag_either_pass(name,
                      "external value may not be used in this context");
   }
   #endif

   mapx = b4;
   mapx->m.i = 0;

   return y;
}

#else

#ifdef DOS
#error you need VERY_STACKED_XPRESSION
#endif

static int expression(char *s, char *e, char *param)
{
   
   int				 i = 0, j;
   char				*d;

   char				 override = 0;

   object			*l;

   int				 symbol,
				 x,
				 y;

   #ifdef LTAG
   location_counter		*q;
   #endif

   while ((s < e) && (*s == ' ')) s++;

   if (s == e) return 0;
#if 0   
   if ((d = contains(s, e, "=\0")))
   {
      if (expression(s, d, param)
      ==  expression(d+1, e, param)) return 1;
      else                           return 0;
   }
#endif
   if ((d = contains(s, e, "^=\0")))
   {
      if (expression(s, d, param)
      !=  expression(d+2, e, param)) return 1;
      else                           return 0;
   }
   
   if ((d = contains(s, e, "=\0")))
   {
      if (expression(s, d, param)
      ==  expression(d+1, e, param)) return 1;
      else                           return 0;
   }
  
   #if OPERATORS == 19

   if ((d = contains(s, e, "^>\0")))
   {
      if (expression(s, d, param)
      >   expression(d+2, e, param)) return 0;
      else                           return 1;
   }

   #endif

   if ((d = contains(s, e, ">\0")))
   {
      if (expression(s, d, param)
      >   expression(d+1, e, param)) return 1;
      else                           return 0;
   }

   #if OPERATORS == 19

   if ((d = contains(s, e, "^<\0")))
   {
      if (expression(s, d, param)
      <   expression(d+2, e, param)) return 0;
      else                           return 1;
   }

   #endif
 
   if ((d = contains(s, e, "<\0")))
   {
      if (expression(s, d, param)
      <   expression(d+1, e, param)) return 1;
      else                           return 0;
   }
   
   #ifndef PROMOTE_UNARY
   if (*s == '^') return expression(++s, e, param) ^ -1;
   if (*s == '-') return 0 - expression(++s, e, param);
   if (*s == '+') return expression(++s, e, param);
   #endif
   
   if ((d = contains(s, e, "--\0"))) return expression(s, d, param)
					^ expression(d+2, e, param);

   if ((d = contains(s, e, "++\0"))) return expression(s, d, param)
					| expression(d+2, e, param);

   if ((d = contains(s, e, "/*\0"))) return expression(s, d, param)
				       >> expression(d+2, e, param);
   
   if ((d = contains(s, e, "*/\0"))) return expression(s, d, param)
				       << expression(d+2, e, param);

   if ((d = contains(s, e, "**\0"))) return expression(s, d, param)
					& expression(d+2, e, param);

   if ((d = operates(s, e, "-\0+\0")))
   {
      /*******************************************************
         this precaution here allows unary signs to follow
         after multiply/divide/shift operators without 
         getting mistaken for add/subtract operators
      *******************************************************/

      #if 0
      symbol = *(d-1);
      if ((symbol != '*')
      &&  (symbol != '/')
      &&  (symbol != '+')
      &&  (symbol != '-'))
      {
      #endif
	 if (*d == '+') return expression(s, d, param)
			     + expression(d + 1, e, param);
      
	 if (*d == '-') return expression(s, d, param)
			     - expression(d + 1, e, param);
      #if 0
      }
      #endif
   }
   
   if ((d = operates(s, e, "///\0//\0/\0*\0")))
   {
      if (*d == '*') return expression(s, d, param)
			  * expression(d+1, e, param);

      if ((*d == '/') && (*(d+1) == '/') && (*(d+2) == '/'))
		     return expression(s, d, param)
			  % expression(d+3, e, param);
      
      if ((*d == '/') && (*(d+1) == '/'))
      {                  
			i = expression(s, d, param);
			j = expression(d+2, e, param);
			i += j-1;
			return i/j;
      }

      if (*d == '/') return expression(s, d, param)
			  / expression(d+1, e, param);
   }   
         
   #ifdef PROMOTE_UNARY
   if (*s == '^') return expression(++s, e, param) ^ -1;
   if (*s == '-') return 0 - expression(++s, e, param);
   if (*s == '+') return expression(++s, e, param);
   #endif
   
   if (*s == '(')
   {
      d = fendb(s, e);
      return expression(s+1, d, param);
   }

   i = 0;
    
   if (*s == 0x27)
   {
      if (qchar == 0x27) s = substitute(s, param);
      s++;
      while ((symbol = *s++))
      {
         if (symbol == 0x27)
         {
	    symbol = *s++;
	    if (symbol != 0x27) return i;
         }

         if ((selector['c'-'a']) && (symbol == '\\'))
         {
            symbol = *s++;

            if ((symbol >='0') && (symbol <= '7'))
            {
               symbol &= 7;

               /*******************************************************************
                one octal symbol has been consumed

                there may be 2 more for bytes 7..9 bits in size = 3 maximum
                             3 more for bytes 10..12 bits in size = 4 maximum
                             nane more for bytes 1..3 bits in size = 1 maximum
                             1 more for bytes 4..6 bits in size = 2 maximum
                             4 more for bytes 11..15 bits in size = 5 maximum
                             5 more for bytes 16..18 bits in size = 6 maximum
                             6 more for bytes 19..21 bits in size = 7 maximum
                             7 more for bytes 22..24 bits in size = 8 maximum
                and so on up to 11 octal symbols maximum for 32-bit bytes

                bytes may be any size 1..32 bits without regard to word
                or address quantum
               *******************************************************************/

               y = (byte - 1)/3;

               while (y--)
               {
                  x = *s;
                  if (x < '0') break;
                  if (x > '7') break;
                  symbol <<= 3;
                  symbol |= x & 7;
                  s++;
               }

               if ((code == DATA_CODE) && (uselector['D'-'A']))
               {
                  if (symbol & -256)
                  {
                     flag("-D flag \\translate input outside Latin-1 range");
                  }
                  else symbol = code_set[symbol];
               }
            }
            else switch (symbol)
            {
               case 'x':

                  symbol = 0;

                  for (;;)
                  {
                     x = *s;

                     if      ((x >= '0') && (x <= '9')) x &= 15;
                     else if ((x >= 'a') && (x <= 'f')) x += 10 - 'a';
                     else if ((x >= 'A') && (x <= 'F')) x += 10 - 'A';
                     else break;

                     symbol <<= 4;
                     symbol |= x;
                     s++;
                  }

                  if ((code == DATA_CODE) && (uselector['D'-'A']))
                  {
                     if (symbol & -256)
                     {
                        flag("-D flag \\translate input outside Latin-1 range");
                     }
                     else symbol = code_set[symbol];
                  }

                  break;

               default:
                 symbol = simple_c_escape(symbol);
                 symbol = coded_character(symbol);
            }
         }
         else
         {
            #ifdef CODED_EXPRESS
            symbol = coded_character(symbol);
            #endif
         }


         #ifdef CODED_EXPRESS
         i <<= byte;
         #else
         i <<= 8;
         #endif

         i |= symbol;
      }
      return i;
   }

   if (selector['m'-'a'])
   {
      if (*s == '$')
      {
	 s++;
	 override = 'H';
      }

      if (*s == '@')
      {
         s++;
         override = 'O';
      }

      if (*s == '%')
      {
	 s++;
	 override = 'B';
      }
   }
    
   if (selector['c'-'a'])
   {
      if (*s == '0')
      {
	 s++;
	 if ((*s == 'x') || (*s == 'X'))
	 {
	    s++;
	    override = 'H';
	 }
	 else
	 {
	    override = 'O';
	 }
      }
   }
    
   if ((suffix) && (*s > 0x2f) && (*s < 0x3a))
   {
      override = *(e - 1);
      if ((override > 0x60) && (override < 0x7b)) override &= 0x5f;
      if (override == 'Q') override = 'O'; 
      if ((override != 'D')
      &&  (override != 'B')
      &&  (override != 'O')
      &&  (override != 'H')) override = 0;
      if ((!override) && (suffix & 2)) override = 'D';
   }
   
   if (((*s == '0') && (!override) && (!octal)) 
   ||  (override == 'H'))
   {
      while (((*s > 0x2F) && (*s < 0x3A))
      ||     ((*s > 0x40) && (*s < 0x47))
      ||     ((*s > 0x60) && (*s < 0x67)))
      {
	 i <<= 4;
	 if (*s < 0x40) i |= (*s & 15);
	 else           i |= ((*s & 15) + 9);
	 s++;
	 if (s == e) break;
      }
      return i; 
   }
    
   if (((*s == '0') && (!override) && (octal))
   ||  (override == 'O'))
   {
      while ((*s > 0x2F) && (*s < 0x38))
      {
	 i <<= 3;
	 i |= *s++ & 7;
	 if (s == e) break;
      }
      return i;
   }
    
   if ((*s == '\\') || (override == 'B'))
   {
      if (*s == '\\') s++;
      while ((*s == 48) || (*s == 49))
      {
	 i <<= 1;
	 i |= *s++ & 1;
	 if (s == e) break;
      }
      return i;
   }
    
   if ((*s > 0x2F) && (*s < 0x3A))
   {
      i = *s++ & 15;
      while ((*s > 0x2F) && (*s < 0x3A))
      {
	 i *= 10;
	 i += *s++ & 15;
	 if (s == e) break;
      }
      return i;
   }  


   if (*s == qchar) s = substitute(s, param);


   #ifdef ESC
   if (*s == ESC) return extract_gparam(s+1, param);
   #else
   #error set ESC
   #endif

   l = findlabel(s, e);

   if (l)
   {
      switch (l->l.valued)
      {
	 #ifdef EQUF
	 case EQUF:

            #ifdef PART_EQUF
            if (*label_margin == '\\')
            {
               x = expression(label_margin + 1, e, param);

               if (x < 1)        return 0;
               if (x > RADIX/32) return 0;

               return quadextractx(&l->l.value, x);
            }
            #endif

	    i = quadextract(&l->l.value);

            if (address_size < 32) i &= 0x7FFFFFFF;

            return i;

	 #endif

	 case EQU:
	 case SET:
	 case LOCATION:
	 case DIRECTIVE:
            if (l->l.valued == DIRECTIVE)
            {
               #ifdef GEOMETRIC_FUNCTIONS
               switch (l->l.value.b[RADIX/8-1])
               {
                  case WORD:
                    return word;
                  case BYTE:
                    return byte;
                  case AWIDTH:
                    return address_size;
                  case QUANTUM:
                    return address_quantum;
                  case LITS:
                    return litloc;
               }
               #else
               switch (l->l.value.b[RADIX-1])
               {
                  case WORD:
                     note("function use of $word does not yield word size");
                     break;
                  case BYTE:
                     note("function use of $byte does not yield byte size");
                     break;
                  case AWIDTH:
                     note("function use of $awidth does not yield address width");
                     break;
                  case QUANTUM:
                     note("function use of $quantum does not yield address quantum");
                     break;
               }

               #endif
            }

	 case FORM:
	    
	    #ifdef RELOCATION_IN_MINIATURE
	    if (l->l.r.l.y) mapx->m = l->l.r;
	    #endif

	    i = qextractv(l);
	    return i;

            #ifdef LITERALS
            #ifdef LTAG
         case LTAG:
            j = l->l.r.l.rel & 127;
            i = literal(label_margin, param, j);
            q = &locator[j];
            if (q->flags == 1) i += vextractq((object *) q->runbank.p);
            return i;
            #endif
            #endif

	 case INTERNAL_FUNCTION:
	    i = qextractv(l);

	    if (*s == qchar) return i;
	    return rfunction(i, label_margin, param, e, l);

	 case NAME:

	    if (l == entry[masm_level]) return qextractv(l);            

            #ifdef ABOUND
            if (l->l.passflag & 64)
            {
            }
            else
            {
               return qextractv(l);
            }
            #endif

	 case FUNCTION:

            if ((uselector['Q'-'A'] == 0)
            &&  (*s == qchar)) return qextractv(l);
            i = quadextract(external_function(label_margin, param, e, l));

            return i;

	 case PROC:
            return qextractv(l);

	 default:
	    if (l->l.valued > 127)
	    {
	       i = qextractv(l);
	       return i;
	    }
	    break;
      }
   }

   if (!pass) return 0;

   #ifdef EFLAG

   flag_either_pass(name,
                   "external value may not be used in this context");

   #else

   if (l)
   {
      if (l->l.valued)
      {
         flagp(l->l.name, " use not understood");
      }
      else
      {
         /***********************************************
            we only arrive here on the second pass
         ***********************************************/

         #ifdef BINARY
         if (l->l.r.l.xref < 0) l->l.r.l.xref = ucount++;
         #endif

         uflag(name);
      }
   }
   else   
   {
      if (label_highest_byte == 0)
      {
         flag("expression particle not understood");
         return 0;
      }
      
      uflag(name);

      l = insert_ltable(name, NULL, &zero_o, UNDEFINED);

      if (!l)
      {
         flag("internal error");
         return 0;
      }

      l->l.r.l.xref = ucount++;
   }
   

   #ifdef RELOCATION_IN_MINIATURE
   mapx->m.l.y |= 128;
   mapx->m.l.xref = l->l.r.l.xref;
   #endif

   #endif	/* EFLAG */

   return 0;
}

#endif

static void lproduce(int bits, char unary, line_item *item, txo *image)
{
   if ((unary == '^') || (unary == '-')) operand_reverse(item);
   if ((unary == '-') && (twoscomp == 1)) operand_addcarry(1, item);
   produce(bits, '+', item, image);
}

static void record_bits(int bits)
{
   int			 aside = masm_level;
   object		*p;

   masm_level = 0;
   p = insert_qltable("$bits", bits, SET);

   if (p)
   {
      p->l.valued = SET;
      p->l.r.i = 0;
      p->l.value = zero_o;
      quadinsert(bits, &p->l.value);
   }
   else flag("$bits not added");

   masm_level = aside;
}


#ifdef RELOCATION
static void map_linkages(int bits, int scale)
{
   if (!pass) return;

   if (mapx->m.l.y == 0) return;

   mapx->recursion = maprecursion;
   mapx->slice = bits;
   mapx->scale = scale;
   mapx++;

   if (mapx > &mapinfo[MAPSTACK-1])
   {
      flag_either_pass("Internal Error M", "abandon");
      exit(0);
   }

   mapx->m.i = 0;
}

static void map_offset(int scale, line_item *item)
{
   link_profile		*p = mapx;
   short		*q = (short *) p;

   if (!pass) return;

   *q = scale;

   q[1] = item->h[RADIX/16-3];
   q[2] = item->h[RADIX/16-2];
   q[3] = item->h[RADIX/16-1];

   mapx++;
   if (mapx > &mapinfo[MAPSTACK-1])
   {
      flag_either_pass("Internal Error mM", "");
      exit(0);
   }

   mapx->m.i = 0;
}

#ifndef DOS
static void display_ra(int flags, line_item *ii)
{
   printf("[%x]", flags);
   print_item(ii);
}
#endif

static void o_range(int flags, line_item *ii)
{
   int			 z = 0;

   /* int */ int	 v = ii->i[0]
                           | ii->i[1]
                           | ii->i[2]
                           | ii->i[3]
                           | ii->h[8];

   if (flags & 4)
   {
      if (ii->b[18] & 128)
      {
         v = ii->i[0] & ii->i[1] & ii->i[2] & ii->i[3];

         if ((v == 0xFFFFFFFF) && (ii->h[8] == 0xFFFF))
         {
         }
         else z = -1;
      }
      else
      {
         if (v) z = -1;
      }
   }
   else
   {
      if (v) z = -1;
   }

   if (z < 0)
   {
      flag("intermediate address larger than 48 bits");

      #ifndef DOS
      display_ra(flags, ii);
      #endif
   }
}

static void output_linkage(int x, txo *image, txo *a_image)
{
   static int		 bits,
			 scale,
			 descant,
                         flags;

   static link_offset	*q;


   link_profile		*p = &mapinfo[x];

   int			 y = image->symbols;
   int			 code = p->m.l.y;   
   int			 xref, rel;

   int			 symbol_pair,
                         mask, z;

   if (!pass) return;


   if (p->scale < 0) return;

   if (code & 16)
   {
   }
   else
   {
      if (p->recursion != maprecursion) return;

      bits  = p->slice;
      scale = p->scale;

      descant = 0;
      flags   = code;

      if (x)
      {
         q = (link_offset *) p;
         q--;
         descant = q->scale;
      }
   }

   if (!code) return;
   if (!bits) bits = address_size;

   if (code & 1)
   {
      if (y > IMAGE_SIZE-10) stop();
      image->d[y++] = '(';
      rel = p->m.l.rel & 127;
      if (code & 8) image->d[y++] = '-';
      image->d[y++] = left(rel);
      image->d[y++] = right(rel);

      if (descant < 0)
      {
         mask = (1 << (address_size & 7)) - 1;
         z = 6 - (address_size >> 3);

         image->d[y++] = ':';

         if (mask)
         {
            symbol_pair = q->offset[z-1];
            symbol_pair &= mask;
            image->d[y++] = left(symbol_pair);
            image->d[y++] = right(symbol_pair);
         }

         while (z < 6)
         {
            symbol_pair = q->offset[z++];
            image->d[y++] = left(symbol_pair);
            image->d[y++] = right(symbol_pair);
         }

         image->d[y++] = '/';
         image->d[y++] = '*';
         symbol_pair = -descant;
         image->d[y++] = left(symbol_pair);
         image->d[y++] = right(symbol_pair);
      }

      image->d[y++] = ')';
      image->d[y++] = left(bits);
      image->d[y++] = right(bits);
      
      if (scale)
      {
         image->d[y++] = '*';
	 image->d[y++] = '/';
         image->d[y++] = left(scale);
	 image->d[y++] = right(scale);
      }

      if (flags & 4) image->d[y++] = '+';
      if (flags & 2) image->d[y++] = '-';
      image->d[y++] = ':';
   }

   if (code & 128)
   {
      if (y > IMAGE_SIZE-12) stop();
      image->d[y++] = '[';
      xref = p->m.l.xref;

      if (code & 8) image->d[y++] = '-';

      image->d[y++] = right(xref >> 12);
      image->d[y++] = right(xref >>  8);
      image->d[y++] = right(xref >>  4);
      image->d[y++] = right(xref);

      if (descant < 0)
      {
         mask = (1 << (address_size & 7)) - 1;
         z = 6 - (address_size >> 3);

         image->d[y++] = ':';

         if (mask)
         {
            symbol_pair = q->offset[z-1];
            symbol_pair &= mask;
            image->d[y++] = left(symbol_pair);
            image->d[y++] = right(symbol_pair);
         }

         while (z < 6)
         {
            symbol_pair = q->offset[z++];
            image->d[y++] = left(symbol_pair);
            image->d[y++] = right(symbol_pair);
         }

         image->d[y++] = '/';
         image->d[y++] = '*';
         symbol_pair = -descant;
         image->d[y++] = left(symbol_pair);
         image->d[y++] = right(symbol_pair);
      }

      image->d[y++] = ']';
      image->d[y++] = left(bits);
      image->d[y++] = right(bits);
      
      if (scale)
      {
	 image->d[y++] = '*';
	 image->d[y++] = '/';
  	 image->d[y++] = left(scale);
         image->d[y++] = right(scale);
      }

      if (flags & 4) image->d[y++] = '+';
      if (flags & 2) image->d[y++] = '-';
      image->d[y++] = ':';
   }

   p->m.i = 0; /* global change 3ix2008 */


   if (!a_image) linex += y - image->symbols;
   image->symbols = y;
}

static void map_field(unsigned char *p)
{
   int temp, scale = 0, bits = *p++;

   if (!pass) return;
   
   while ((temp = *p++)) scale += temp;

   map_linkages(bits, scale);
}
#endif		/* RELOCATION */

static int text_substitute(int i, char *buffer)
{
   char			 aside[1024];
   int			 j = 0, changed = 0;
   object		*l;
   char			*forward, *k = buffer, *c;
   char			 *opcode = getop(buffer);
   int			 inquotes = 0, inquotes_b4;

   register char	 datum;

   if (opcode)
   {
      if (meaning(opcode) == TEXT_SUBSTITUTE) return i;
   }

   while ((datum = *k))
   {
      inquotes_b4 = inquotes;

      if (datum == qchar)
      {
         if (!(inquotes & 2)) inquotes ^= 1;
      }
      else
      {
         if (datum == 0x27)
         {
            if (!(inquotes & 1)) inquotes ^= 2;
         }
      }

      if ((inquotes)
      ||  ((inquotes_b4) && (!inquotes)))
      {
         aside[j++] = datum;
         k++;
      }
      else
      {
         l = earliest_tsub;

         while (l->h.type == TEXT_SUBSTITUTE)
         {
   	    forward = k;
	    c = l->t.text;
	    while (*c)
	    {
	       datum = *forward++;
	       if ((!selector['k'-'a'])
	       &&  (datum > 0x60)
	       &&  (datum < 0x7b)) datum &= 0x5f;

	       if (datum != *c) break;
	       c++;
	    }

  	    if (*c == 0) break;
	    l = (object *) ((char *) l + l->h.length);
         }

         if (l->h.type == TEXT_SUBSTITUTE)
         {
	    c++;
	    k = forward;
	    while ((aside[j++] = *c++));
	    j--;
	    changed = 1;
	    l = earliest_tsub;
         }
         else
         {
	    aside[j++] = *k++;
         }
      }
   }

   if (!changed) return i;
   aside[j] = 0;
   strcpy(buffer, aside);
   return j;
}

static int nline(char data[], int z)
{
   int y = 0, inquotes = 0, symbol;

   z--;

   lix = 0;
   plix[0] = 0;
   column_r = NULL;

   while (y < z)
   {
      symbol = physin();

      if (symbol < 0)      
      {
         data[y] = 0;
         if (y) return y;
	 return -1;
      }
      
      if (symbol == 13) continue;
      if (symbol == 10) break;

      if (lix < DISPLAY_WIDTH) plix[lix++] = symbol;

      if (symbol ==    qchar)
      {
         if (!(inquotes & 2))    inquotes ^= 1;
      }
      else
      {
         if (symbol ==  0x27)
         {
            if (!(inquotes & 1)) inquotes ^= 2;
         }
      }

      if (symbol ==        9) symbol   = 32;
      
      if (!inquotes)
      {
         if (symbol == lterm)
         {
            if ((symbol ^ '.') || (next_byte() < 0x21))
            {
               /*************************************************

		when period . is comment character, it terminates
		the line only when followed by whitespace. Not
		even a second . will terminate the line otherwise

		any other comment character terminates the line
		regardless of what the next character is

               *************************************************/

               column_r = &plix[lix - 1];

               for (;;)
               {
                  symbol = physin();

                  if (symbol < 0)      
                  {
                     data[y] = 0;
                     if (y) return y;
      	             return -1;
                  }

                  if (symbol == 10) break;

                  if (lix < DISPLAY_WIDTH) plix[lix++] = symbol;
               }

               break;
            }
         }

         while ((symbol == cont_char) && (next_byte() < 0x21))
         {
            for (;;)
            {
               symbol = physin();

               if (symbol < 0)      
               {
                  data[y] = 0;
                  if (y) return y;
        	  return -1;
               }
 
               if (lix < DISPLAY_WIDTH) plix[lix++] = symbol;

               if (symbol == 10) break;
            }

            #ifdef DISPLAY_V
            plix[lix] = 0;

            if ((list > depth) && (pass) && (selector['l'-'a']))
            {
               printf("                                %s", plix);
            }

            lix = 0;
            plix[0] = 0;
            #endif

            ll[depth]++;

            for (;;)
            {
               symbol = physin();

               if (symbol < 0)      
               {
                  data[y] = 0;
                  if (y) return y;
        	  return -1;
               }
      
               if (lix < DISPLAY_WIDTH) plix[lix++] = symbol;

               if ((symbol != 32) && (symbol != 9)) break;
            }

            if (symbol == qchar)
            {
               if (!(inquotes & 2))    inquotes ^= 1;
            }
            else
            {
               if (symbol ==  0x27)
               {
                  if (!(inquotes & 1)) inquotes ^= 2;
               }
            }
         }
      }

      data[y++] = symbol;
   }
   
   data[y] = 0;
   return y;
}

static int getline(char *k, int max)
{
   int x, known;
   char *p;

   #ifdef PRINTBYREAD
   if ((lix) && (pass) && (list > depth) && (selector['l'-'a']))
      printf("  :                            %d %s\n", ll[depth], plix);

   #endif

   x = nline(k, max);
   
   if (x < 0)
   {
      close(handle[depth]);
      depth--;

      if (depth < 0)
      {
         if (!selector['w'-'a']) printf("*EOF*\n");
         return -1;
      }

      #ifdef BLOCK
      actual_block = block[depth];
      #endif
      return 0;
   }

   if (tsubs) x = text_substitute(x, k);

   if ((selector['s'-'a']) && (pass == 0))
   {
      known = -1;
      p = getop(k);
      if (p) known = meaning(p);
	     
      if ((known != TEXT_SUBSTITUTE) && (known != INCLUDE))
      {
	 write(nhandle, k, x);
         if (column_r) write(nhandle, column_r, plix + lix - column_r);
	 write(nhandle, "\n", 1);
      }
   }
	 
   ll[depth]++;
   plix[lix] = 0;

   if ((!x) && (pass) && (list > depth) && (selector['l'-'a']))
   {
      printf("  :                            %d %s\n", ll[depth], plix);
      lix = 0;
      plix[0] = 0;
   }

   return x;
}

static void quadza(int u, line_item *i)
{
   *i = zero_o;

   /*****************************************************
   zero fill is right for everything that calls this,
   and sign extension never is
   *****************************************************/

   #ifdef INTEL
   i->b[RADIX/8-1] = u;
   i->b[RADIX/8-2] = u >>  8;
   i->b[RADIX/8-3] = u >> 16;
   i->b[RADIX/8-4] = u >> 24;
   #else
   i->i[RADIX/32-1] = u;
   #endif
}

static void store_form(object *thislabel, 
		       char   *directive, 
		       char    *argument)
{
   char *limit;
   int i = 0;

   if (pass) return;

   if (!thislabel)
   {
      flagp1("FORM requires a label.");
      return;
   }
   
   if (thislabel->l.valued != FORM)
   {
      if (!pass) fputs(thislabel->l.name, stdout);
      flagp1(" May not be restated as a FORM.");
      return;
   }
   
   thislabel->l.valued = FORM;
   thislabel->l.r.i = 0;
   
   while (argument)
   {
      while (*argument == 32) argument++;
      if (*argument == 0) break;
      limit = edge(argument, ", ");
      thislabel->l.value.b[i++] = expression(argument, limit, NULL);
      if (*limit != ',') break;
      if (i > 22)
      {
	 flagg("Too Many Fields in Form");
	 return;
      }
      argument = limit + 1;
   }
   thislabel->l.value.b[i] = 0;
}

static object *store_proc_index(char *line_label, char *directive, object *pid)
{
   char				*limit = NULL;
   line_item			*i = &zero_o;


   #ifndef ABOUND
   int valued = pid->l.valued;
   #endif

   object *l;

   char *argument = NULL;

   argument = getop(directive);
   
   if (argument)
   {
      limit = edge(argument, ", ");
      i = xpression(argument, limit, NULL);
   }
   
   l = insert_ltable(line_label, limit, i, NAME);
   
   if (!l)
   {
      flagp1("Failed to Store SubAssembly(P) Entry Point");
      return l;
   }
 
   l->l.r.l.y = pid->l.r.l.y;
   l->l.r.l.rel = pid->l.r.l.rel;
   
   l->l.passflag = pid->l.passflag;

   #ifdef WALKP
   printf("$%d/%d\n", l->l.r.l.rel, l->l.r.l.y);
   #endif
         
   #ifdef ABOUND
   if (pid->l.valued ==     PROC) l->l.passflag |= 128;
   if (pid->l.valued == FUNCTION) l->l.passflag |=  64;
   #endif


   #ifdef FOLLOW_RECURS
   printf("%s @ %d/%d t %d\n",
           l->l.name,
           masm_level,
           l->l.r.l.xref,
         ((label *) l->l.along)->valued);
   #endif

   return l;
}

static int encode(char *x, char *f, char *n)
{

   char symbol = 0, sentinel = *n, prior;
   char *c, *w, *t = x;

   char		 insiquo = 0;


   for (;;)
   {
      prior = symbol;
      symbol = *f++;
      if (!symbol) break;

      w = t;
      *t++ = symbol;

      if ((symbol == qchar) && (insiquo == 0))
      {
         for (;;)
         {
            symbol = *f++;
            w = t;
            *t++ = symbol;

            if ((selector['k'-'a'] == 0) 
            &&  (symbol > 0x60)
            &&  (symbol < 0x7B)) symbol &= 0x5F;

            if (symbol == sentinel)
            {
               c = n + 1;
               for (;;)
               {
                  symbol = *f++;

                  #if 0
                  if (!symbol) break;
                  #endif

                  if ((symbol == '(') && (*c == 0))
                  {
                     t = w;
                     *t++ = ESC;
                     *t++ = symbol;
                     break;
                  }
                  *t++ = symbol;

                  if ((selector['k'-'a'] == 0) 
                  &&  (symbol > 0x60)
                  &&  (symbol < 0x7B)) symbol &= 0x5F;

                  if (symbol != *c++) break;
               }
            }
            if (symbol == qchar) break;
            if (!symbol) break;
         }
         continue;
      }

      if (symbol == '\'') insiquo ^= 1;

      if ((selector['k'-'a'] == 0) 
      &&  (symbol > 0x60)
      &&  (symbol < 0x7B)) symbol &= 0x5F;

      if ((symbol == sentinel)
      &&  (insiquo == 0)
      &&  (!(((prior > 0x40) && (prior < 0x5B))
           ||((prior > 0x60) && (prior < 0x7B))  
           ||((prior > 0x2F) && (prior < 0x3A))  
           ||(prior == '_')
           ||(prior == '?')
           ||(prior == '$')
           ||(prior == '!')
           ||(prior == '@'))))
      {
         c = n+1;

         for (;;)
         {
            prior = symbol;
            symbol = *f++;

            #if 0
            if (!symbol) break;
            #endif

            *t++ = symbol;

            if ((selector['k'-'a'] == 0)
            &&  (symbol > 0x60)
            &&  (symbol < 0x7B)) symbol &= 0x5F;

            if (!(((symbol > 0x40) && (symbol < 0x5B))
                ||((symbol > 0x60) && (symbol < 0x7B)) 
                ||((symbol > 0x2F) && (symbol < 0x3A))  
                ||(symbol == '_')
                ||(symbol == '?')
                ||(symbol == '$')
                ||(symbol == '!')
                ||(symbol == sterm)
                ||(symbol == '@')))
            {
               if (*c == 0)
               {
                  t = w;
                  *t++ = ESC;
                  *t++ = symbol;
               }
               #if 0
               putchar('.');
               #endif

               break;
            }
            if (symbol != *c++) break;
         }
         #if 0
         printf("[%c%c %2.2x]\n", sentinel, symbol, *(t-2));
         #endif
      }
      if (!symbol) break;
   }
   *t = 0;
   
   return t - x;
}

static object *procedure_head(char *line, int id, int type, char *argument)
{
   char			*limit;
   int			 i;
   object		*sr,
                        *l = insert_qltable(line, id++, type);
      
   #ifdef TRACE_RECURS
   printf("store [%s] head\n", l->l.name);
   #endif

   if (!l)
   {
      flag_either_pass("not tabled", line);
      exit(0);
   }
      
   l->l.passflag = 1;

   if (argument)
   {
      if (*argument == '*') l->l.passflag |= 2;
          
      if (type == PROC)
      {
         if (*argument == '*')
         {
            argument++;
            while (*argument == 32) argument++;
         }

         if (*argument)
         {
            limit = edge(argument, "(");

            if ((*limit == '(')
            &&  (sr = findlabel(argument, limit))
            &&  (sr->l.valued == INTERNAL_FUNCTION)
            &&  (sr->l.value.b[RADIX/8-1] == LOCTR))
            {
                argument = limit+1;
                limit = edge(argument, ")");
                i = expression(argument, limit, NULL);

                if ((i < 0) || (i > 71))
                {
                   flagp1("Proc Automatic Locator Out of Range");
                }
                else
                {
                   l->l.r.l.y |= 1;
                   l->l.r.l.rel = i;
                }
            }
            else
            {
               notep1p("non-location counter argument on proc" 
                      " declaration: ", argument);
            }
         }
      }
   }
   return l;
}

static void awake_procedure(int type, char *line, char *argument)
{
   object		*l,
                        *sr,
                        *o;
                        
   char                 *k,
                        *directive;

   int			 j, nest = 1;

   l = procedure_head(line, traverse_id++, type, argument);

   o = next_image[masm_level - 1];
   l->l.down = (void *) o;
   if (type != FUNCTION)
   l->l.down = (void *) ((char *) o + o->h.length);
   
   for (;;)
   {
      o = (object *) ((char *) o + o->h.length);
      k = o->t.text;
      
      #ifdef TRACE_RECURS
      printf("retrieve image %s\n", k);
      #endif

      #ifdef FOLLOW_RECURS
      printf("retrieve image %s\n", k);
      #endif
     
      if (o->h.type == BYPASS_RECORD)
      {
         if ((j = o->nextbdi.next)) o = bank[j];
         else                       o = NULL;

         if (o == NULL)
         {
            printf("embedded macro underflow. abandon\n");
            exit(0);
         }
      }
 
      #ifdef QNAMES
      j = o->h.type;
      #else
      j = TEXT_IMAGE;
      directive = getop(k);
      if (directive) j = meaning(directive);
      #endif
      
      if (j ==     PROC) nest++;
      if (j == FUNCTION) nest++;
      if (j ==      END) nest--;

      if (j == NAME)
      {
         if (masm_level > nest)
         {
            #ifdef TRACE_RECURS
            printf("L%d N%d store %s index\n", masm_level, nest, k);
            #endif

            #ifdef FOLLOW_RECURS
            printf("L%d N%d store %s index type %d\n", masm_level, nest, k,
                    l->l.valued);
            #endif

            #ifdef QNAMES           
            directive = getop(k);
            #endif

            sr = store_proc_index(k, directive, l);
            sr->l.down = (void *) o;
            
            #ifdef TRACE_RECURS
            printf("[%d:%d/%d]\n", sr->h.length, sr->l.r.l.xref, l->l.r.l.xref);
            #endif
            
            continue;
         }
      }
      if (!nest) break;
   }
   
   next_image[masm_level - 1] = o;   
}

static void embed_procedure(int type, char *line, char *argument)
{
   static int		 id;
   
   object		*l,
                        *sr;
                        
   char                 *k,
                        *directive;
                        
   int			 i, j, size, nest = 1, symbol;
   
   char			 slipline[256];
   char			 name[DEEP_RECURS][32] = { "macro" };
   
   #ifdef TRACE_RECURS
   printf("store procedure %s:%d\n", line, masm_level);
   #endif

   #ifdef FOLLOW_RECURS
   printf("store procedure %s:%d\n", line, masm_level);
   #endif

   if (masm_level > 1)
   {
      if (masm_level < 3) traverse_id = id;
      awake_procedure(type, line, argument);
      return;
   }
   
   if (!pass) l = procedure_head(line, id++, type, argument);

   for (;;)
   {
      i = getline(slipline, 252);
      if (!i) continue;
         
      if (i < 0)
      {
         depth = 0;
         flag_either_pass(name[0], "procedure auto end. assembly abandoned");
         exit(-112);
      }

      if (i > 250) brake(slipline, "macro text line > 250 characters, assembly abandoned");
         
      directive = getop(slipline);
      j = TEXT_IMAGE;
      if (directive) j = meaning(directive);
      if (j ==     PROC) nest++;
      if (j == FUNCTION) nest++;
      if (j ==      END) nest--;
         
      if (!pass)
      {
         if (j == NAME)
         {
            if (nest < 2)
            {
               sr = store_proc_index(slipline, directive, l);
                  
               #ifdef TRACE_RECURS
               printf("L%d N%d store %s index\n", masm_level, nest, slipline);
               printf("[%d/%d]\n", sr->l.r.l.xref, l->l.r.l.xref);
               #endif
                  
               continue;
            }
         }
            
         #ifdef TRACE_RECURS
         printf("n%d store image %s\n", nest, slipline);
         #endif
   
         size = sizeof(header_word) + i + (1+PARAGRAPH-1); 
         size &= -PARAGRAPH;

         if (remainder < size) buy_ltable();
            
         if (nest > 1)
         {
            if (nest > (DEEP_RECURS + 1))
            {
               flagp1("declarations nested too deep");
               exit(0);
            }
               
            if ((j == PROC) || (j == FUNCTION))
            {
               k = slipline;
               symbol = *k++;
               i = 0;
            
               if (symbol == qchar)
               {
                  while (i < 31)
                  {
                     symbol = *k++;
                     if (symbol == 0) break;
                     if (symbol == qchar) break;

                     if (!selector['k'-'a'])
                     {
                        if ((symbol > 0x60) && (symbol < 0x7B)) symbol &= 0x5F;
                     }
                     
                     name[nest-2][i++] = symbol;
                  }
               }
               else
               {
                  while (i < 31)
                  {
                     if (symbol == 0) break;
                     if (symbol == 32) break;
                     if (symbol == '*') break;

                     if (!selector['k'-'a'])
                     {
                        if ((symbol > 0x60) && (symbol < 0x7B)) symbol &= 0x5F;
                     }
                     
                     name[nest-2][i++] = symbol;
                     symbol = *k++;
                  }
               }
               
               name[nest-2][i] = 0;

               if (!i)
               {
                  notep1("zero length macro label");
               }

               strcpy(lr->t.text, slipline);
            }
            else
            {
               #ifdef TRACE_RECURS
               printf("encode1 for %s\n", name[nest-2]);
               #endif
                  
               i = encode(lr->t.text, slipline, name[nest-2]);
            }
         }
         else
         {
            #ifdef TRACE_RECURS
            printf("encode2 for %s\n", l->l.name);
            #endif
               
            i = encode(lr->t.text, slipline, l->l.name);
         }
            
         #ifdef QNAMES
         if ((j != END)  && (j != FUNCTION)
         &&  (j != NAME) && (j != PROC)) j = TEXT_IMAGE;
         #else
         if (j != END) j = TEXT_IMAGE;
         #endif
            
         lr->h.type = j;
         lr->h.length = size;

         lr = (object *) ((char *) lr + size);
         remainder -= size;
      }
      
      if (!nest) break;
   }
      
   #ifdef TRACE_RECURS
   printf("procedure store complete\n");
   #endif
}
   



static void decide(char *arg, char *param)
{
   char			*limit;
   int			 i;

   int			 mask, unmask;
   

   ifdepth++;

   mask   = 1 << ifdepth;
   unmask =        ~mask;

   satisficed &= unmask;
   skipstate  |=   mask;

   if (skipping)
   {
      return;
   }
   

   limit = first_at(arg, " ");
   
   i = ixpression(arg, limit, param);

   skipping = 1;
   if (!i) return;

   skipping = 0;

   skipstate  &= unmask;
   satisficed |=   mask;
}

static void newdecide(char *arg, char *param)
{
   char				*limit;
   int				 i;

   int				 mask, unmask;
   
   
   if (!ifdepth)
   {
      flag("$elseif not in scope of $if");
      return;
   }
   
   mask = 1 << ifdepth;

   skipstate |= mask;

   if (satisficed & mask)
   {
      skipping = 1;
      return;
   }

   if (skipstate & (mask >> 1)) return;

   limit = first_at(arg, " ");

   skipping = 0;
   
   i = ixpression(arg, limit, param);

   skipping = 1;
   if (!i) return;
   
   skipping = 0;

   unmask = ~mask;

   skipstate  &= unmask;
   satisficed |=   mask;
}

static void swap()
{
   int			 mask = 1 << ifdepth;

   if (!ifdepth)
   {
     flag("$else not in scope of $if");
     skipping = 0;
     return;
   }
   
   if (satisficed & mask) skipping = 1;
   else
   {
      if ((skipstate & (mask >> 1)) == 0)
      {
	 satisficed |= mask; 
	 skipping = 0;
      }
   }
   
   if (skipping) skipstate |=  mask;
   else          skipstate &= ~mask;
}

static void resume()
{
   if (ifdepth < 0) ifdepth = 0;
   if (ifdepth)     ifdepth--;
   else note("$endif not in scope of $if");

   if (ifdepth) skipping = (skipstate >> ifdepth) & 1;
   else         
   {
      skipstate    = 0;
      satisficed  |= 1;
      skipping     = 0;
   }
}


static void save_object(char *arg)
{
   int		 i = close(ohandle);
   object	*l;

   if (i < 0) printf("file state %d %d problem writing output\n", i, errno);
   
   l = compose_filename(arg, ".txo", 0);
   i = qextractv(l);

   if (i < 0)
   {   
      remove(l->l.name);
      i = rename(OBIN, l->l.name);
      if (i < 0)  printf("file state %d %d problem storing %s\n", i, errno, l->l.name);
      return;
   }

   printf("output file %s is also an input file. not written\n"
          "output is in temp.txo\n", l->l.name);
}


static int iterate(char *arg, char *param, object *tag, txo *image)
{
   char			*limit;
   int			 x;
   int			 rvalue;


   if (!arg) arg = "1";

   limit = first_at(arg, ", ");

   #ifdef ULTRA_RESOLVE
   x = zxpression(arg, limit, param);
   #else
   x = expression(arg, limit, param);
   #endif

   if (tag) 
   {
      tag->l.valued = SET;
      tag->l.value = zero_o;
      tag->l.r.i = 0;
      tag->l.r.l.xref = masm_level;
   }
   
   if (*limit == ',')
   {
      while (x > 0)
      {
	 if (tag) operand_addcarry(1, &tag->l.value);
	 rvalue = assemble(limit+1, param, NULL, image);
         if (rvalue == RETURN) return rvalue;
         if (rvalue ==    END) return rvalue;
         x--;
      }
   }
   else flagg("$do count,image");
   return 0;
}


static void insequate(int how,
		      object *thislabel,
		      char *argument,
		      char *param)
{
   char			*limit;
   
   line_item		*i = &zero_o;

   #ifdef BINARY
   line_item		 v;
   int			 bits = 0;
   int			 x;
   #endif

   #ifdef RELOCATION
   #ifdef IN_EQUATE
   link_profile		*b4 = mapx;
   #endif
   #endif

   #ifdef BINARY
   if (how == BINARY)
   {
      v = zero_o;
      argument = substitute(argument, param);

      bits = load_quartets(argument, &v);

      thislabel->l.valued = SET;
      thislabel->l.value  = v;
      thislabel->l.r.l.y = 0;
      thislabel->l.r.l.rel = 0;

      bits /= word;
      bits *= word;

      record_bits(bits);

      return;
   }
   #endif

   if ((how > 255) || ((how <  128)
                   &&  (how != SET)
                   &&  (how != EQU)
                   &&  (how != NAME)
                   &&  (how != DIRECTIVE)
                   &&  (how != INTERNAL_FUNCTION)))
   {
      if (pass) printf("[%d]%s\n",
          thislabel->l.valued, thislabel->l.name);
      flag("protected label class");
      return;
   }

   if (argument)
   {
      limit = first_at(argument, " ");
      i = xpression(argument, limit, param);
   }

   x = thislabel->l.valued;
   if (x == BLANK) thislabel->l.valued = how;
   else if (x ^ how) return;

   thislabel->l.value = *i;
   
   thislabel->l.r.l.y = 0;
   thislabel->l.r.l.rel = 0;

   #ifdef RELOCATION
   if ((how == EQU) || (how == SET))
   {
      #ifndef INTENSE_EQUATE

      thislabel->l.r.l.y = mapx->m.l.y;
      thislabel->l.r.l.rel = mapx->m.l.rel;
      if (thislabel->l.r.l.y & 128) thislabel->l.r = mapx->m;

      #ifdef IN_EQUATE
      if (mapx - b4) flag("too many relocatable targets in equate");
      mapx = b4;
      mapx->m.i = 0;
      #endif

      #else

      thislabel->l.r.i   = 0;

      for (;;)
      {
         if (mapx->scale < 0)
         {
            flag("relocatable right shift cannot be equated or set");
         }
         else
         {
            if (mapx->m.l.y)
            {
               if (thislabel->l.r.l.y)
               {
                  flag("too many relocatable targets in equate");
               }

               thislabel->l.r.i = mapx->m.i;
            }
            else
            {
               if (!thislabel->l.r.l.y) thislabel->l.r.l.rel = mapx->m.l.rel;
            }
         }

         if (mapx == b4) break;
         mapx--;
      }


      mapx->m.i = 0;
      #endif
   }

   #endif

   /*
   thislabel->l.r.l.xref = masm_level;
   */
}


static void lhbx(char *from, int bits, line_item *item)
{
   int				 mask = (1<<byte)-1;
   int				 datum;


   from++;
   
   for(;;)
   {
      if (byte > bits) break;
      datum = *from++;
      if (datum == 0) break;
      if ((datum == qchar) && (*from++ != qchar)) break;
      lshift(item, byte);

      #ifdef CODED_EXPRESS
      datum = coded_character(datum);
      #else
      if ((byte < 7) && (code == ASCII)) datum =
		((datum & 64)>>1) | (datum & 31);
      if (code == DATA_CODE) datum = code_set[datum];
      #endif

      datum &= mask;

      #ifdef INTEL
      item->b[RADIX/8-1] |= datum;
      item->b[RADIX/8-2] |= datum>>8;
      item->b[RADIX/8-3] |= datum >> 16;
      item->b[RADIX/8-4] |= datum >> 24;
      #else
      item->i[RADIX/32-1] |= datum;
      #endif

      bits -= byte;
   }
   
   lshift(item, bits);
}

#ifdef INTEL
static unsigned short read16(int w, line_item *item)
{
  int		 b = w << 1;

  return (item->b[b] << 8)
  |       item->b[b+1];
}

static void write16(int w, int v, line_item *item)
{
  int		b = w << 1;

  if (b > 22) return;
  item->b[b]   = v >> 8;
  item->b[b+1] = v;
}
#endif

#ifdef FLOATING_POINT

static void operand_round_down(int bytes, line_item *item)
{
   unsigned short		 carry = 0,
				 x = RADIX/8,
				 y = RADIX/8;
   
   #ifdef ROUND3

   if (bytes == 3)
   {
      carry = guard_pattern + item->b[RADIX/8-3];
      carry >>= 8;
      x = RADIX/8-3;
   }
   else

   #endif

   while (bytes--)
   {
      x--;
      carry += item->b[x];
      
      carry += 128;
      
      carry >>= 8;
   }
   
   while (x--)
   {
      y--;
      carry += item->b[x];
      item->b[y] = carry;
      carry >>= 8;
   }
   
   while (y--)
   {
      item->b[y] = carry;
      carry >>= 8;
   }
}


static void reduce(int w, int scale, line_item *item)
{
   #ifdef ROUND1
   unsigned int sum = scale - 1;
   #else
   unsigned int sum = (scale + 1) >> 1;
   #endif

   unsigned short digit = 0, quo;
   int i = RADIX/16;

   while (i > w)
   {
      i--;
      sum += (unsigned short) read16(i, item);
      quo = sum;
      write16(i, quo, item);
      sum >>= 16;
   }
   
   while (w < RADIX/16)
   {
      sum = digit; 
      sum <<= 16; 
      sum |= (unsigned short) read16(w, item);
      digit = sum % scale;
      quo   = sum / scale;
      write16(w, quo, item);
      w++;
   }
}


static void floating_raise(int w, int scale, line_item *item)
{
   int			 i = RADIX/16;
   unsigned short	 digit = 0, hu;
   unsigned int	 ju;
   
   while (i--)
   {
      hu = read16(i, item);
      ju = hu; 
      ju *= scale;
      ju += digit;
      hu = ju;
      write16(i, hu, item);
      ju >>= 16;
      digit = ju;
   }
}

static void characterise(int places, line_item *item)
{
   unsigned int	 bias;

   bias = 0x00400000 + RADIX - operand_shift_count(item);
   if (bias == 0x00400000) return;

   /**************************************************
   operand_shift_count == RADIX means mantissa == zero
   return at this point and line item = all zero
   **************************************************/

   while (places < -5)
   {
      if (item->h[0])
      {
         operand_round_down(2, item);
         bias += 16;
      }
      places += 6;
      bias += 6;
      floating_raise(0, 15625, item);
   }

   while (places < 0)
   {
      if (item->b[0])
      {
         operand_round_down(1, item);
         bias += 8;
      }
      places++;
      bias++;
      floating_raise(0, 5, item);
   }

   while (places > 5)
   {
      reduce(0, 15625, item);
      places -= 6;
      bias -= 6;
      bias -= operand_shift_count(item);
   }

   #ifdef ROUND2
   while (places > 0)
   {
      reduce(0, 10, item);
      places--;
      bias -= operand_shift_count(item);
   }
   #else
   while (places > 0)
   {
      reduce(0, 5, item);
      places--;
      bias--;
      bias -= operand_shift_count(item);
   }
   #endif

   bias -= operand_shift_count(item);

   operand_round_down(3, item);

   if (item->b[2])
   {
      bias++;
      rshift(item, 1);
   }
 
   if (bias & 0xFF800000) flag(" Floating Exponent Overflow ");

   item->b[0] = bias >> 16;
   item->b[1] = bias >>  8;
   item->b[2] = bias;
}

static void floating_generate(char *a, char *margin, char *param, line_item *item)
{
   char			*limit;
   int			 places = 0; 

   #ifdef INTEL
   unsigned short	 carry;
   #else
   unsigned int	 carry;
   #endif

   unsigned short	 fraction_triggered = 0, i;

   for (;;)
   {
      carry = *a++;
      if (carry == '.')
      {
	 fraction_triggered = 1;
	 continue;
      }

      if ((carry < '0') || (carry > '9')) break;
      
      if (item->b[0] > 24)
      {
	 if (!fraction_triggered) places--;
	 continue;
      }
      
      if (fraction_triggered) places++;

      carry &= 15;

      #ifdef INTEL

      i = RADIX/8;

      while (i--)
      {
	 carry += item->b[i] * 10;
	 item->b[i] = carry;
	 carry >>= 8;
      }

      #else

      i = RADIX/16;

      while (i--)
      {
	 carry += item->h[i] * 10;
	 item->h[i] = carry;
	 carry >>= 16;
      }

      #endif
   }

   if (!transient_floating_bits) transient_floating_bits = fpwidth;

   if (carry == ':')
   {
      carry = *a++;
   }

   if ((i = length_mark(carry)))
   {
       transient_floating_bits = i;
       carry = *a++;
   }

   if (transient_floating_bits > RADIX)
   {
      transient_floating_bits = RADIX / word * word;
   }

   #if 0
   transient_floating_bits /= word;
   transient_floating_bits *= word;
   #endif

   if (carry == '*')
   {
      carry = *a++;
      if      (carry == '+') places -= expression(a, margin, param);
      else if (carry == '-') places += expression(a, margin, param);
   }
   else if ((carry == 'e') || (carry == 'E'))
   {
      places -= expression(a, margin, param);
   }

   floating_conversion++;
   
   if (pass) characterise(places, item);
}


#ifdef ROUNDING
int single_bit(int x, line_item *item)
{
   if (x < 0) return 0;

   /***************************************************

	that was for the unlikely event that
	the number-size is 190 or 191 bits

	then at least 1 guard bit is available
	but less than 3 guard bits are available 

   ***************************************************/

   return (item->b[(RADIX - x - 1) >> 3] >> (x & 7)) & 1;
}

void single_bit_on(int x, line_item *item)
{
   item->b[(RADIX - x - 1) >> 3] |= 1 << (x & 7);
}
#endif

static void floating_position(int bits, line_item *item)
{
   char			 top2bits;
   int			 characteristic;

   #ifdef ROUNDING
   int			 carry = 0, xlow_1, xlow_2;	
   #endif

   int			 x = bits / word;


   if (x > 17) x = 17;

   characteristic = characteristic_width[x];

   if (characteristic < 24)
   {
      top2bits = item->b[0] & 0xc0;
      lshift(item, 24-characteristic);
      item->b[0] &= 0x3f;
      item->b[0] |= top2bits;
   }

   #ifdef ROUNDING

   if (bits < RADIX)
   {
      if (guard_pattern & 0x80) carry = single_bit(RADIX - bits - 1, item);

      #ifdef ROUND3 
      if (guard_pattern & 0x40) carry |= single_bit(RADIX - bits - 2, item);
      if (guard_pattern & 0x20) carry |= single_bit(RADIX - bits - 3, item);
      #endif

      rshift(item, RADIX - bits);

      if (carry)
      {
         xlow_1 = single_bit(bits - characteristic, item);
         operand_addcarry(carry, item);
         xlow_2 = single_bit(bits - characteristic, item);

         if (xlow_1 ^ xlow_2)
         {
            /***************************************************
            rounding has carried into the characteristic.

            The normalising bit must be forced back on for the
            best approximate result, because the true value is
            about 1 scale something, but the mantissa is now zero.

            The increment to the the characteristic is correct
            unless it has overflowed into the sign
            ***************************************************/


            single_bit_on(bits - characteristic - 1, item);
            if (single_bit(bits - 1, item)) note("characteristic outflow");
         }
      }
   }

   #else

   if (bits < RADIX) rshift(item, RADIX-bits);

   #endif
}

#endif	/* FLOATING_POINT */


static int assemble(char *line_label,char *param,object *above,txo *image)
{
   static header_word    zero_header_word;

   #ifdef BINARY
   static short          range_check_descant;

   static unsigned short range_check_position_bit,
                         range_check_position_byte,
                         range_check_flags,
                         range_check_bits;

   static line_item	 range_filter,
                         range_free,
                         range_sign;

   line_item		 range_limit;
   link_profile		*m;
   #endif

   object		*sr, *thislabel = NULL;
   char			*argument, *search = line_label,
                         unary = 0, tpp;
   
   int			 x, y,
			 j, bits = 0, spotted,
                         commas = 0, slice,
                         known = -1, type = -1;
                         
   line_item		*oo;
   char			*limit;
   char			 xmask, ymask;
   char *fpo;
   char			*v_argument = NULL;

   object		*toplabel, *txp, *depx;
   line_item		*ii;
   int			 savelocator[LOCATORS];
   int			 savelocatorl[LOCATORS];
   int			 savepass, subfunction;
   char			*nlabel, *ndirect;
   unsigned char	*subtext;
   char			*directive /* = getop(line_label) */; 
   int			 v;
   int			 parenthesised, squoted;

   line_item		 item = zero_o;

   #ifdef AUTOMATIC_LITERALS
   line_item		 liti;
   #endif

   #ifdef PROCLOC
   int			 uploc = counter_of_reference;
   int			 downloc = uploc;
   #endif

   int			 symbol, rvalue, symbolb4;
   
   #ifdef LTAG
   location_counter	*qq;
   value                *vv;
   #endif

   #ifdef RELOCATION

   #ifdef BINARY
   xref_list		*xrefl;
   #endif

   link_offset		*o;
   unsigned short	*h;

   #endif

   #ifdef SUPERSET
   char			*xmodifier = "";
   #endif

   int			 prelif  =  ifdepth,
			 preskip = skipping;

   link_profile		*b4 = mapx;

   if (*search == '$') search = past_parentheses(search);   

   directive = getop(search);
   
   if (directive)
   {
      argument = getop(directive); 
      if ((*directive != '+')
      &&  (*directive != '-')
      &&  (*directive != '^')
      &&  (*directive != qchar))
      {
         if (*directive==ESC)
         {
            directive = substitute(directive, param);
            symbol = *directive;
            if ((symbol == '*') || (symbol == '#')) directive++;
         }

         sr = findlabel(directive, NULL);
 
         if (sr)
         {
	    type = sr->l.valued;
            known = qextractv(sr);
            tpp = sr->l.passflag;
         }
      }
   }
   
   if (skipping) 
   {
      if (type != DIRECTIVE) return 0;
      if ((known != IF) 
      &&  (known != ELSEIF)
      &&  (known != ELSE)
      &&  (known != ENDIF)) return 0;
   }
   
   if (*line_label == '$')
   {
      switch_locator(line_label, param);
      line_label = past_parentheses(line_label);
   }

   if (type == DIRECTIVE)
   {
      subfunction = -1;
      limit = edge(directive, ", ");

      if (*limit++ == ',')
      {
         while (*limit == 32) limit++;
         search = edge(limit, " ");

         #ifdef SUPERSET
         if ((known == FP_XPRESS) || (known == ESPRESSO)) xmodifier = limit;
         else
         #endif

         subfunction = expression(limit, search, param);

         argument = getop(search);
      }
   }


   if ((*line_label) && (*line_label != 32))
   {
      x = LOCATION;

      if (type == DIRECTIVE)
      {
         x = known;

         if (x == EQU)
         {
            if (subfunction < 0)
            {
            }
            else x = subfunction;
         }

         #ifdef RECORD
         if (known == RECORD)
         {
            if ((subfunction ^ BRANCH)
            ||  (loc ^ branch_restart)) branch_record &= (1 << active_x)-1;
         }
         #endif
      }

      if (x == RES) x = LOCATION;

      #ifdef STRUCTURE_DEPTH
      if (x == BRANCH) x = LOCATION;
      if (x == TREE)   x = LOCATION;

      if ((type  == DIRECTIVE)
      &&  (known ==    BRANCH)
      &&  (branch_present & (1 << active_x))
      &&  (loc == branch_high[active_x])
      &&  (depx = active_instance[active_x])) loc = active_origin[active_x];

      #endif
	    
      if (x == DO) x = SET;

      #ifdef BINARY
      if (x == PUSHREL) x = EQUF;
      #endif

      if (*line_label == '*') 
      {
	 if (above)
	 {
	    thislabel = above;


            j = thislabel->l.valued;
            thislabel->l.valued = x;


	    if (x == LOCATION)
	    {
               thislabel->l.r.l.y = 0;
               quadza(loc, &item);

               if ((x = actual->flags & 129))
               {
                  if (x & 128)
                  {
                     item.b[RADIX/8-5] = actual->rbase;
                     thislabel->l.valued = EQUF;
                  }

                  if (x  == 1)
                  {
                     operand_add(&item, &actual->runbank.p->value);
                  }
               }
               else
               {
   	          if (actual->relocatable)
	          {
	   	     thislabel->l.r.l.y |= 1;
	          }
               }


	       thislabel->l.r.l.rel = counter_of_reference | 128;
               
               if (pass)
               {
                  if (j != BLANK) checkwave(&item, thislabel, x);
               }

               thislabel->l.value = item;
               item = zero_o;
	    }

            thislabel->l.passflag = masm_level;
	 }
      }
      else
      {
	 ndirect = line_label;

	 if ((*line_label == qchar) && (masm_level))
         {
            limit = name;
            ndirect++;
            *limit++ = qchar;
            while ((symbol = *ndirect++))
            {
               *limit++ = symbol;
               if (symbol == qchar) break;
            }

            while ((symbol = *ndirect++))
            {
               if (symbol != '*') break;
               *limit++ = symbol;
            }

            *limit = 0;

	    ndirect = substitute(name, param);
         }

         if ((x == PROC) || (x == FUNCTION))
         {
            txp = floatop;
            masm_level++;

            #ifdef TRACE_RECURS
            printf("[++%s:%d:%s]\n", ndirect, masm_level, param);
            #endif
            
            #ifdef FOLLOW_RECURS
            printf("++%s:%d\n", ndirect, masm_level);
            #endif

            embed_procedure(x, ndirect, getop(directive));

            pack_ltable(txp);

            masm_level--;
            
            return 0;
         }

         if ((type == PROC)
         || ((type == NAME) && (sr->l.passflag & 128)))
         {
            /*****************************************************

		$BLANK is used to allow $PROC macros to change
		a location label on the $PROC call line to
		some new meaning

		this is kept restricted so that waiting labels:

			zac*	$proc
			*	.
				$end

			a_zac	zac

		are not accidentally linked outside of a
		current structured name space, before the
		$PROC macro starts to be expanded

		if the macro is to attach the waiting label
		other than at the displacement where the $PROC
		expansion starts, there must be an out-of-line
		argument $(locator) on the $PROC line

			yazac*	$proc	$(70)
				$res	+($+ALIGMENT-1**-ALIGMENT)-$
			*	.
				$end

		this can be the name locator where the $PROC
		was called from or a different one. Either
		way macro yazac generates code if any in $(70)

			$(70)
			zac(1)  yazac

			$(_TEXT)
			zac(2)	yazac

            
            ******************************************************/

            if (sr->l.r.l.y   &  1) x = BLANK;
         }

	 thislabel = insert_qltable(ndirect, loc, x);
      }
   }

   if (!directive) return 0;

   if (type < 0)
   {  
      if (*directive == qchar)
      {
         context_string = 1;
         stringline(directive, param, image);
         context_string = 0;
         return 0;
      }
   
      unary = *directive;

      if ((unary > '0'-1) && (unary < '9'+1)) unary = 0;
      if (unary == '\'') unary = 0;

      if ((unary == '+') || (unary == '-') || (unary == '^') || (unary == 0))
      {
         argument = directive;

         if (unary)
         {
            if (*(argument + 1) == ' ') argument++;
            else unary = '+';
         }
         else unary = '+';

         symbolb4 = unary;

         while ((symbol = *argument) == 32)
         {
            symbolb4 = symbol;
            argument++;
         }

         search = argument;
         parenthesised = 0;
         squoted = 0;

         spotted = 0;
         while (*search)
         {
   	    if (*search ==  0x27)
	    { 
	       squoted ^= 1;
 	       search++;
	       continue;
	    }
	    if (*search == '(') parenthesised++;
 	    if ((*search == ')') && (parenthesised)) parenthesised--;

	    if ((*search == ',') && (!parenthesised) && (!squoted)) commas++;
	    search++;
         }

         search--;
         while (*search == 32) search--;

         bits = 0;


         /*************************************************
		the default case, *search must be the last
		column of expression + 1 and it wasn't
         *************************************************/

         limit = search++;
         symbol = *limit;

         if ((j = length_mark(symbol)))
         {
            x = 0;
            if (limit > argument) x = *(limit - 1);
            
            if (x == ':')
            {
               /********************************************
		: is not part of the expression. *search must
		point to the column after the expression = :
               ********************************************/

               search = limit - 1;
               bits = j;
            }
            else if ((x == ')') || (x == '\'') || (x == qchar))
            {
               /*******************************************
		'") is part of the expression
		*search goes where it was
               *******************************************/

               search = limit;
               bits = j;
            }
            else
            {
               /*******************************************
		is the last token in the expression
		a label or a number string? Motorola $hex
		looks like a label, so it  needs : or )'"
		if you want to add a length flag

		native syntax and -c syntax hex can use
		'l' 'L' instead of 'd' 'D' for two words
		or separate the length flag +(0number)d
		or 0number:d

		Intel-style notation suffix OQDHoqhd masks
		a length flags octaword quadword hexaword
		doubleword unless you separate the length
		length flag (numberD)o numberQ:q

		Intel suffix is always in a macro with a
		name like DW or DD or DB or .byte or .word
		or .int, so macro code can ensure syntax
		clarity and application code needs no
		alteration
               *******************************************/

               subtext = (unsigned char *) frightmost(argument, search);

               x = *subtext;

               if ((x  > '0' - 1) && (x < '9' + 1))
               {
                  if (suffix)
                  {
                     if (suffix_noclash(symbol))
                     {
                        /****************************************
				digit string
				suffix is not [OQDHoqhd]
                                *search goes where it was
                        ****************************************/

                        bits = j;
                        search = limit;
                     }
                  }
                  else if (selector['c'-'a'])
                  {
                     y = *(subtext + 1);
                     if ((x > '0')
                     ||  ((x == '0') && (y  ^ 'x') && (y ^ 'X'))
                     ||  ((x == '0') && (symbol ^ 'd') && (symbol ^ 'D')))
                     {
                        bits = j;
                        search = limit;
                     }
                  }
                  else
                  {
                     if ((x > '0')
                     ||  ((x == '0') && (octal))
                     ||  ((x == '0') && (symbol ^ 'd') && (symbol ^ 'D')))
                     {
                        /****************************************
				digit string other than
				hex ending in 'd' or 'D'
				*search goes where it was
                        ****************************************/

                        bits = j;
                        search = limit;
                     }
                  }
               }
            }
         }

         #ifdef FPASS1
         if ((!pass) && (bits)) 
         {
	    produce(bits, '+', &item, image);
	    return 0;
         }
         #endif

         if (commas)
         {
   	    if (!bits) bits = word;
	 
	    if (pass)
	    {
	       commas++;
	       slice = bits/commas;

	       while (commas--)
	       {
	          lshift(&item, slice);
	          limit = search;
	          if (commas) limit = first_at(argument, ",");
	       
	          #ifdef RELOCATION
	          mapx->m.i = 0; /* global change 3ix2008 */
	          #endif
	       
	          #ifdef AUTOMATIC_LITERALS
	          if ((*argument == '(') && (selector['a'-'a']) && (symbolb4 == ' '))
	          {
		     v = literal(argument, param, litloc);
		     oo = &liti;
		     quadza(v, oo);

                     #ifdef LTAG

                     qq = &locator[litloc];

                     #ifdef LPOOL_CCHECK
                     if (qq->flags & 128)
                     flag("base+displacement literal "
                          "cannot be addressed in this context");
                     #endif

                     if ((qq->flags & 129) == 1)
                     {
                        if ((vv = (value *) qq->runbank.a))
                        {
                           liti = vv->value;
                           quadd_u(v, oo);
                        }
                     }

                     #endif
	          }
	          else
	          #endif
                  {
                     transient_floating_bits = slice;
	             oo = xpression(argument, limit, param);
                  }

	          x = slice & 7;
	          j = slice >> 3;
  	          xmask = 255 << x;
	          ymask = xmask ^ 255;
	          x = RADIX/8;
	          while (j--)
	          {
		     x--;
		     item.b[x] = oo->b[x];
	          }
	          if (ymask)
	          {
		     x--;
	 	     item.b[x] &= xmask;
		     item.b[x] |= oo->b[x] & ymask;
	          }
	       
	          #ifdef RELOCATION
	          map_linkages(slice, commas*slice);
	          #endif

	          if (commas)
	          {
	   	     argument = limit;
	  	     argument++;
	          }

	          while (*argument == 32) argument++;
                  symbolb4 = ' ';
	       }
	    }

            transient_floating_bits = 0;
	    lproduce(bits, unary, &item, image);
	    return 0;
         }

         #ifdef AUTOMATIC_LITERALS

         if ((*argument   == '(')
         &&  (selector['a'-'a'])
         &&  (symbolb4    == ' ')
         &&  (*(search-1) == ')'))
         {
	    v = literal(argument, param, litloc);
            quadinsert(v, &item);
            bits = address_size;
			
            #ifdef LTAG

            qq = &locator[litloc];

            #ifdef LPOOL_CHECK
            if (qq->flags & 128)
            flag("base+displacement literal "
                 "cannot be addressed in this context");
            #endif

            if ((qq->flags & 129) == 1)
            {
               if ((vv = (value *) qq->runbank.a))
               {
                  item = vv->value;
                  quadd_u(v, &item);
                  bits = xadw;
               }
            }

            #endif		/* LTAG */

   	    #ifdef RELOCATION
	    map_linkages(0, 0);
	    #endif

	    produce(bits, unary, &item, image);
	    return 0;
         }
         #endif

         oo = xpression(argument, search, param);
         item = *oo;
      
         #ifdef RELOCATION
         map_linkages(bits, 0);
         #endif

         if (transient_floating_bits)
         {
            if (unary == '-') unary = '^';
            if (bits)
            {
               if (bits ^ transient_floating_bits)
               {
                  if (bits > RADIX)
                  {
                     note("floating number is maximum words");
                     #if 0
                     transient_floating_bits = RADIX / word * word;
                     #endif
                  }
                  else
                  {
                     note("floating number words given tag may follow the fraction");
	             note("+1234.567[[:]{sdltqpho}][*+exponent]");
                  }
               }
            }

            bits = transient_floating_bits;
            transient_floating_bits = 0;
         }

         lproduce(bits, unary, &item, image);
         return 0;
      }
   }
   
   
   switch (type)
   {
      case DIRECTIVE:
      
	 switch (known)
	 {

	    case END:
	       if ((argument) && (pass))
	       {
                  limit = first_at(argument, " ");
                  oo = xpression(argument, limit, param);

                  #ifdef RELOCATION

                  if (mapx->m.l.y & 128)
                  {
                     flag("transfer target must be a code "
                          "location in this assembly");

                     return END;
                  }

                  x = mapx->m.l.rel;

                  if ((!x)
                  /*
                  &&  (!(mapx->m.l.y & 1))
                  */
                  &&  (locator[0].relocatable))
                  {
                     flag("absolute transfer address assigned to relocatable $(0)");
                     return END;
                  }

                  x &= 127;

                  #else

                  x = 0;
                  sr = findlabel(argument, limit);
                  if (sr) x = sr->l.r.l.rel & 127;

                  #endif

                  qq = &locator[x];
                  j = qq->flags;

                  if (qq->breakpoint > 1)
                  {
                     flag("transfer target in "
                          "multiple breakpoint segment\n"
                          "use a separate location counter "
                          "with one breakpoint or none");
                  }

                  if (j & 1)
                  {
                     if ((sr = isanequf(argument))
                     &&  ((j & 129) == 129))
                     {
                        vv = (value *) qq->runbank.p;
                        operand_add(oo, &vv->value);
                     }

                     write(ohandle, "\n>", 2);
                     pushh2(x);

                     write(ohandle, "::", 2);

                     xpushaddress(oo, x);
                     write(ohandle, "\n", 1);
                     return END;
                  }

                  v = quadextract(oo);
                  outcounter(x, v, "\n>");
	       }

	       return END;

	    case INCLUDE:

               #ifdef BINARY

               switch (subfunction)
               {
                  case VOID:
                     if (pass) break;

                  case BINARY:
                     loadfile(argument, ".txo");

                     if ((selector['s'-'a']) && (pass == 0))
                     {
                        write(nhandle, line_label, strlen(line_label));
                        write(nhandle, "\n", 1);
                     }

                     actual->loc = loc;

                     load_binary(argument);
                     break;

                  default:
                     loadfile(argument, ".msm");

               }

               #else

               switch (subfunction)
               {
                  case -1:
                     loadfile(argument, ".msm");
                     break;

                  default:
                     flag("unsupported load file type in $include,SUBCOMMAND");
               }

               #endif

	       break;

	    case FORM:
	       store_form(thislabel, directive, argument);
	       break;


	    case NAME:

               if (thislabel)
               {
                  if (argument) 
                  {
                     insequate(NAME, thislabel, argument, param);
                  }
               }
	       /*
	       store_proc_index(line_label, thislabel, directive, 1, NULL);
	       */
	       break;
	    
	    #ifdef PUSHLOCATOR
	    case PUSHLOCATOR:
	       pushlocator();
	       break;
	    case POPLOCATOR:
	       poplocator();
	       break;
	    #endif

	    case IF:
	       if (argument) decide(argument, param);
	       else                 flag("$if what?");
	       break;
	    case ELSE:
	       swap();
	       break;
	    case ELSEIF:
	       if (argument) newdecide(argument, param);
               else               flag("$elseif what?");
	       break;
	    case ENDIF:
	       resume();
	       break;
	    case DO:
	       return iterate(argument, param, thislabel, image);

	       #ifdef EXIT
	    case EXIT:
	       if (argument) argument = substitute(argument, param);
	       else          argument = "end assembly";

               flag_either_pass("exit directive", argument);
	       exit(0);
	       #endif

	    case EQU:
	       x = EQU;
	       if (subfunction > -1) x = subfunction;

	       if (thislabel)
	       {
		  insequate(x, thislabel, argument, param);
	       }

               transient_floating_bits = 0;
	       break;

	    case SET:
	       x = SET;
               /*	j = transient_floating_bits;	*/
	       if      (subfunction > RADIX) x = subfunction;
               else if (subfunction < 0)
               {
               }
               else    transient_floating_bits = subfunction;

	       if (thislabel)
	       {
		  insequate(x, thislabel, argument, param);
	       }

               transient_floating_bits = 0;	/*	j;	*/
	       break;

               #ifdef BLANK

            case BLANK:

               break;

               #endif


	       #ifdef EQUF
	    case EQUF:

               if (!thislabel)
               {
                  flag("$equf stores a label");
                  return 0;
               }

	       thislabel->l.r.l.y = 0;
	       thislabel->l.r.l.rel = 0;

               if (thislabel->l.valued == EQUF) item = thislabel->l.value;

	       if (argument)
	       {
	 	  x = RADIX/8;

		  v_argument = substitute(argument, param);
                  if ((sr = isanequf(v_argument))) item = sr->l.value;

		  for (;;)
		  {
		     limit = first_at(v_argument, ", ");

		     j = 0;
		     v = 0;
		     if (*v_argument == '*')
		     {
		        v_argument++;
		        v = 0x80000000;
		     }

                     x  -= 4;
                     if (v_argument == limit)
                     {
                     }
                     else
                     {
                        if (x == RADIX/8-4)
                        {
                           #ifdef AUTOMATIC_LITERALS
                           if ((*v_argument == '(') && (selector['a'-'a']))
                           {
                              v |= literal(v_argument, param, litloc);
                           }
                           else
                           #endif
                           {
                              v |= zxpression(v_argument, limit, param);
                           }

                           if (mapx->m.l.y) thislabel->l.r = mapx->m;
                           thislabel->l.r.l.rel = mapx->m.l.rel;

                           if (mapx - b4)
                           {
                              flag("too many relocatable targets in $equf");
                           }
                        }
                        else
                        {
                           v |= expression(v_argument, limit, param);
                        }

                        mapx = b4;
                        mapx->m.i = 0;


                        #ifdef INTEL
                        item.b[x]   = v >> 24;
                        item.b[x+1] = v >> 16;
                        item.b[x+2] = v >>  8;
                        item.b[x+3] = v;
                        #else
                        item.i[x>>2] = v;
                        #endif
                     }

		     if (!x) break;
		     if (*limit != ',') break;
		     v_argument = limit;
		     v_argument++;
		     while (*v_argument == 32) v_argument++;
		  }
	       }

	       thislabel->l.valued = EQUF;
               thislabel->l.value = item;

	       break;
	       #endif

	    case DATA_CODE:
               code = DATA_CODE;

	       if (argument)
	       {
		  argument = substitute(argument, param);
		  while (*argument)
		  {
		     while (*argument == 32) argument++;
		     if (*argument == 0) break;
		     limit = first_at(argument, ", ");
		     v = expression(argument, limit, param);

		     for (;;)
		     {
                        argument = limit;

                        if (*limit ==  0) break;
                        if (*limit == 32) break;

		        if ((v < 0) || (v > 255))
		        {
		 	   flag("left side of translate must be in "
                                "8-bit range");

			   return 0; /* break;*/
		        }

		        for (;;)
		        {
			   argument++;
			   if (*argument != 32) break;
		        }

		        if (*argument == 0) break;
		        limit = first_at(argument, ", ");
		        code_set[v++] = zxpression(argument, limit, param);
		     }
		  }
	       }

	       break;

	    case ASCII:
	       code = ASCII;
	       break;
	    case WORD:
	       if (argument)
	       {
		  limit = edge(argument, " ");
		  word = expression(argument, limit, param);
		  address_quantum = word;
		  address_size = word;
                  if (address_size > (AQUARTETS*4)) address_size = AQUARTETS*4;
                  if (xadw < address_size) xadw = address_size;

		  if (octal)
                  {
                     apw = (address_size + 2) / 3;
                     apwx = (xadw + 2) / 3;
                  }
		  else
                  {
                     apw = (address_size + 3) / 4;
                     apwx = (xadw + 3) / 4;
                  }
	       }

               fpwidth /= word;
               fpwidth *= word;
               if (fpwidth == 0) fpwidth = word;
               
	       break;
	    case BYTE:
	       if (argument)
	       {
		  limit = edge(argument, " ");
		  byte = expression(argument, limit, param);
	       }
	       break;
	    case LIST:
	       if (argument)
	       {
		  limit = edge(argument, " ");
		  list = expression(argument, limit, param);
	       }
	       else list = 1;
	       break;
	    
               #ifdef PATH
            case PATH:
               x = 0;
               
               if (argument) argument = substitute(argument, param);
               else          argument = "";

               rvalue = *argument;
               if (rvalue == qchar) argument++;
               
               while ((symbol = *argument++)) 
               {
                  if (symbol == qchar) break;
                  if (symbol == ' ')
                  {
                     if (rvalue ^ qchar) break;
                  }

                  if (x > 200) break;
                  path[x++] = symbol;
               }

               if (x) path[x++] = PATH_SEPARATOR;
               path[x] = 0;
               
               break;
               #endif

	    case PLIST:
	       if (argument)
	       {
		  limit = edge(argument, " ");
		  plist = expression(argument, limit, param);
	       }
	       else plist = 0;
	       break;
	    
	    case RES:
	       if (argument)
	       {
		  limit = first_at(argument, " ");
		  v = expression(argument, limit, param);

                  if (uselector['Z'-'A'])
                  {
                     while (v--) produce(address_quantum, '+', &zero_o, image);
                  }
                  else loc += v;
	       }

	       if (!pass) break;

	       outstanding = 1;

	       break;

               #ifdef LITERALS
	       #ifdef LITS
	    case LITS:
	       litloc = counter_of_reference;
	       if (argument)
	       {
	 	  limit = edge(argument, " ");
		  litloc = expression(argument, limit, param);
	       }
	       if ((!pass) && (thislabel))
	       {
                  #ifdef LTAG
                  thislabel->l.valued = LTAG;
                  #else
		  thislabel->l.valued = INTERNAL_FUNCTION;
                  #endif

		  quadza(LITERAL, &thislabel->l.value);
		  thislabel->l.r.l.rel = litloc; 
	       }
	       break;
	       #endif
               #endif

	    case SNAP:
	       if ((!pass) && (subfunction != 1)) break;
               if (( pass) && (subfunction == 1)) break;
	       x = 0;
	       if (argument)
	       {
		  limit = edge(argument, " ");
		  x = expression(argument, limit, param);
	       }
	       walktable(x);
	       break;
	    case QUANTUM:
	       if (argument)
	       {
		  limit = edge(argument, " ");
		  address_quantum = expression(argument, limit, param);
                  quanta = word / address_quantum;

                  if ((quanta == 0) || (word % address_quantum))
                  {
                     brake("", "$word and $quantum are not in a possible relation");
                  }

                  for (x = 0; x < 10; x++)
                  {
                     if ((address_quantum << x) == word) break;
                  }

                  if ((address_quantum << x) == word)
                  {
                  }
                  else notep1("$word is not a log2 of $quantum");
	       }
	       break;
	    case LWIDTH:
	       if (argument)
	       {
		  limit = edge(argument, " ");
		  lwidth = expression(argument, limit, param);
	       }
	       break;
	    case AWIDTH:
	       if (argument)
	       {
		  limit = edge(argument, " :");
		  address_size = expression(argument, limit, param);
                  if (address_size > (AQUARTETS*4)) address_size = AQUARTETS*4;

		  if (*limit == ':')
                  {
		     argument = limit+1;
		     limit = edge(argument, " ");
		     xadw = expression(argument, limit, param);
                  }

                  if (xadw < address_size) xadw = address_size;
                  if (xadw > RADIX) xadw = RADIX;

                  if (octal)
                  {
                     apw  = (address_size + 2) / 3;
                     apwx = (xadw - address_size + 2) / 3;
                  }
                  else
                  {
                     apw  = (address_size + 3) / 4;
                     apwx = (xadw - address_size + 3) / 4;
                  }
	       }
	       break;

	    case LTERM:

	       if (argument)
	       {
		  limit = edge(argument, " ");
		  lterm = expression(argument, limit, param);
	       }

               if (pass) break;
               if (!selector['w'-'a']) printf("LTERM=%c\n", lterm);
	       break;

	    case STERM:
	       x = sterm;
	       if (argument)
	       {
		  limit = edge(argument, " ");
		  sterm = expression(argument, limit, param);
	       }
	       tstring[0] = sterm;

               if (masm_level) break;
               if (pass) break;
               if (!selector['w'-'a'])  printf("STERM=%c\n", sterm);

	       break;
 
	       #ifdef TWOSCOMP
	    case TWOSCOMP:
	       if (argument)
	       {
		  limit = edge(argument, " ");
		  twoscomp = expression(argument, limit, param);
		  twoscomp &= 1;
	       }
	       break;
	       #endif
	    
	    
	    case CONT_CHAR:

	       if (argument)
	       {
		  limit = edge(argument, " ");
		  cont_char = expression(argument, limit, param);
	       }
              
               if (pass) break;
	       if (!selector['w'-'a']) printf("CONT_CHAR=%c\n", cont_char);
	       break;

	    case FLAG:
	       /*
	       if (!argument) argument = "?";
	       */
	       flag(argument);
	       break;
	    case NOTE:
	       /*
	       if (!argument) argument = "?";
	       */
	       note(argument);
	       break;
	    case FLAGF:
	       /*
	       if (!argument) argument = "?";
	       */
	       flagp1(argument);
	       break;
	    case NOTEF:
	       /*
	       if (!argument) argument = "?";
	       */
	       notep1(argument);
	       break;

	    case QUOTEC:
	       if (argument)
	       {
		  limit = edge(argument, " ");
		  qchar = expression(argument, limit, param);
	       }

               if (pass) break;
	       if (!selector['w'-'a']) printf("QDELIM=%c\n", qchar);
	       break;
              
	    case RETURN:

               if (argument)
               {
                  limit = first_at(argument, " ");

                  xpression(argument, limit, param);
               }

               return RETURN;

	    case TRACE:
	       if ((!pass) && (subfunction != 1)) break;
	       v_argument = substitute(argument, param);
	       printf("[%s]", v_argument);
	       limit = edge(v_argument, " ,");
	       ii = xpression(v_argument, limit, param);
               print_item(ii);
	       break;
	    case TEXT_SUBSTITUTE:
 
 	       if (pass)
               {
                  /***************************************************
			switch on previously stored translate patterns
                   	at the point they are encountered
 			they do not affect source code until that
                  ***************************************************/
 
                  tsubs = pass1_tsubs;
                  break;
               }

	       if (!argument) break;
	       search = argument;
	       limit = search;
	       limit++;
	       x = 0;

	       if (remainder < 256)
	       {
		  flagp1("Text for Store Too Late in Assembly");
		  break;
	       }
	      
	       while ((*limit) && (*limit != *search))
	       {
		  lr->t.text[x] = *limit;
		  if ((!selector['k'-'a'])
		  &&  (*limit > 0x60) 
		  &&  (*limit < 0x7b)) lr->t.text[x] &= 0x5f;
		  x++;
		  limit++;
	       }
	       if (*limit == 0) break;
	       lr->t.text[x++] = 0;
	       limit++;

               if (subfunction > 0)
               {
                  if (file_arguments < subfunction) limit = "";
                  else limit = filename[subfunction - 1];
               }

	       while ((*limit) && (*limit != *search))
	       {
		  lr->t.text[x] = *limit;
		  if ((!selector['k'-'a'])
		  &&  (*limit > 0x60) 
		  &&  (*limit < 0x7b)) lr->t.text[x] &= 0x5f;
		  x++;
		  limit++;
	       }
	       lr->t.text[x++] = 0;
	       if (x > 250) break;
	       lr->h.type = TEXT_SUBSTITUTE;
	       lr->h.length = sizeof(header_word) + x + (PARAGRAPH-1);
	       lr->h.length &= -PARAGRAPH;
	       if (!tsubs) earliest_tsub = lr;
	       tsubs++;
	       remainder -= lr->h.length;
	       lr = (object *) ((char *) lr + lr->h.length);
               lr->h = zero_header_word;

	       break;

	       #ifdef NOP
	    case NOP:
	       break;
	       #endif

	    case SUFFIX:
	       if (argument) 
	       {
		  limit = edge(argument, " ");
		  suffix = expression(argument, limit, param);
	       }
	       else          suffix = 1;
	       break;
	    case OCTAL:
	       octal = 1;
	       apw = (address_size + 2) / 3;
               apwx = (xadw - address_size + 2) / 3;
	       break;
	    case HEX:
	       octal = 0;
	       apw = (address_size + 3) / 4;
	       apwx = (xadw - address_size + 3) / 4;
	       break;

               #ifdef BINARY

	    case INFO:
	       if (!pass) break;

               switch(subfunction)
               {
                  case OFFSET:

                     m = mapx - 1;

                     if (m > mapinfo)
                     {
                        o = (link_offset *) m - 1;

                        if (o->scale < 0)
                        {
                           if (argument)
                           {
                              v_argument = substitute(argument, param);
                              limit = first_at(v_argument, " ");
                              ii = xpression(v_argument, limit, param);

                              h = (unsigned short *) o;

                              h[1] = ii->h[RADIX/16-3];
                              h[2] = ii->h[RADIX/16-2];
                              h[3] = ii->h[RADIX/16-1];

                              #ifdef MULTUPLES
                              propagate_downwards(o);

                              o_range(m->m.l.y, ii);

                              #endif
                           }

                        } 
                        else
                        {
                           flag("relocation stack top item has no offset");
                        }
                     }


                     break;

                     #ifdef RANGE_FLAGS

                  case RANGE_FLAGS:

                     /*********************************************

                     This is the less stringent range check, and it
                     is expected that intermediate overflows are not
                     being lost because macro language is buffering
                     the intermediate values at the masm7 default
                     precision of 192 bits. 

                     The range check done most recently at write back
                     takes effect, not any intermediate check

                     Any earlier check fail for this field is zeroed

                     *********************************************/

                     range_filter.b[range_check_position_byte]
                     &=            ~range_check_position_bit;

                  case RANGE_FLAGS1:

                     /*********************************************

                     This is the more stringent range check. It
                     provides that earlier check fails for this
                     field are retained, if the updated value is
                     malongained in the field in code itself.

                     Intermediate overflows are flagged.

                     This stringency is not necessary if:

                     assembly has marked the field not to be
                     checked on relocation because truncation
                     on store is expected

                     or

                     The field has a final right-shift. In this 
		     case the intermediate values are buffered
                     internally at 48-bit precision, which is also
                     tested for overflow.

                     **********************************************/
                    
                     if (range_check_flags & 2)
                     {
                        /*******************************************
                        learn at this point truncation is expected.
                        cache in scalar i and table for later
                        *******************************************/

                        x = range_check_position_bit;
                        range_free.b[range_check_position_byte] |= x;
                     }
                     else
                     {
                        /*******************************************
                        retrieve from earlier whether this field may
                        truncate. Cache in scalar i
                        *******************************************/

                        x = range_free.b[range_check_position_byte]
                                        & range_check_position_bit;
                     } 

                     if ((x) || (range_check_descant < 0))
                     {
                        /******************************************
                        cancel any earlier range check fail because

                        (x) means this field should not be checked,
                        therefore also abandon this check.

                        or

                        (descant) means an intermediate accumulated
                        48-bit value "offset" is being malongained.

                        Therefore the range check done most recently
                        at write back takes effect, not any intermediate
                        check

                        ******************************************/
                       
                       
                        range_filter.b[range_check_position_byte]
                        &=            ~range_check_position_bit;

                        if (x) break;
                     }


                     if (argument)
                     {
                        v_argument = substitute(argument, param);
                        limit = first_at(v_argument, " ");

                        ii = xpression(v_argument, limit, param);

                        slice = RADIX / 8 - (range_check_bits >> 3);
                       
                        if ((range_check_flags & 4)
                        ||  (range_sign.b[range_check_position_byte]
                           & range_check_position_bit))

                        {
                           range_sign.b[range_check_position_byte]
                           |=           range_check_position_bit;

                           x = range_check_bits - 1;

                           if (ii->b[0] & 128)
                           {
                              range_limit = minus_o;
                              lshift(&range_limit, x);
                              j = operand_compare(ii, &range_limit);
                           } 
                           else
                           {
                              range_limit = zero_o;
                              range_limit.b[RADIX / 8 - (x >> 3) - 1]
                              =                    1 << (x  & 7);

                              j = operand_compare(ii, &range_limit);
                              j ^= -1;                         
                           }
                        }

                        else
                        {
                           if (ii->b[0] & 128) j = -1;
                           else
                           {
                              range_limit = zero_o;
                              range_limit.b[RADIX/8-(range_check_bits>>3)-1]
                              =                1 << (range_check_bits  & 7);

                              j = operand_compare(ii, &range_limit);
                              j ^= -1;
                           }                 
                        }

                        if (j < 0) range_filter.b[range_check_position_byte]
                                   |=             range_check_position_bit;
                     }
                     else flag("$range_check requires a value");

                     break;

                     #endif

                  default:

                     flag("$info type not known");
               }

	       break;

               #endif

	    case SET_OPTION:

	       if (!argument) break;
	       if (*argument++ == qchar)
	       {
		  while ((x = *argument++))
		  {
		     if (x == qchar) break;

		     if      ((x > 0x40) && (x < 0x5B))
                     {
                        uselector[x-'A'] = 1;
                        if (x == 'E') guard_pattern = 0xE0;
                        if (x == 'F') guard_pattern = 0xC0;
                        if (x == 'G') guard_pattern = 0x80;
                        if (x == 'H') guard_pattern = 0;
                     }
		     else if ((x > 0x60) && (x < 0x7B))
                     {
                        if ((x == 'k')
                        ||  (x == 's')
                        ||  (x == 'y')) notep1("flags -ksy are actioned "
                                               "at command line only");
                        else selector[x-'a'] = 1;
                     }
		  }
	       }
	       break;
	    
	       #ifdef STRUCTURE_DEPTH
	    
	    case TREE:
            case BRANCH:

               if (treeflag)
               {
                  flag("$tree and $branch are not permitted in literals");
                  break;
               }

	       if (active_x == STRUCTURE_DEPTH)
	       {
		  for (x = 0; x < active_x; x++)
		    printf("%s:", active_instance[x]->l.name);
		  flag_either_pass("structure too deep", "abandon");
		  exit(0);
	       }
    
               sr = active_instance[active_x];
               if (known == TREE) 
               {
                  branch_present &= (-1 ^ (1 << active_x));
               }
               #ifdef TRACE_STORAGE_BRANCH
               printf("from %x\n", branch_present);
               #endif

               if (!(branch_present & (1 << active_x)))
                  branch_high[active_x] = 0;

               if (known == BRANCH)
               {
                  #ifdef TRACE_STORAGE_BRANCH
                  printf("detect %x\n", branch_present & (1 << active_x));
                  #endif

                  if ((branch_present & (1 << active_x))
                  &&  (sr = active_instance[active_x])
                  &&  (loc == active_origin[active_x]) 
                  &&  (thislabel))
                  {
                     outstanding = 1;
                     if ((pass) && (selector['p'-'a']))
                     {
                        printf("[%x %s %x %x]\n", loc, sr->l.name, sr->l.valued, active_x);
                     }
                  }

                  branch_present |= (1 << active_x);
               }

               if (thislabel)
               {
                  thislabel->l.passflag = masm_level;
                  active_origin[active_x] = loc;
                  active_instance[active_x++] = thislabel;
               }
               else flagp1("trees and branches must have names");

	       break;
              
	    case ROOT:

               if (treeflag)
               {
                  flag("$root is not permitted in literals");
                  break;
               }

	       if (active_x)
               {
                  branch_present &= (1 << active_x) - 1;
                  active_x--;

                  if (branch_present & (1 << active_x))
                  {
                     if ((pass) && (selector['p'-'a']))
                     {
                        printf("[%x ? %x:%x]\n", loc, branch_high[active_x], active_x);
                     }
                     if (loc > branch_high[active_x])
                     {
                        branch_high[active_x] = loc;
                     }
                     else
                     {
                        loc = branch_high[active_x];
                        outstanding = 1;
                     }

                     #ifdef TRACE_STORAGE_BRANCH
                     printf("loc = high = %x\n", loc);
                     #endif
                  }
                  /*
                  branch_present &= (1 << active_x) - 1;
                  */
               }
	       else flagp1("You are already at the root of roots");

	       break;

	       #endif


               #ifdef FLOATING_POINT
	    case FLOATING_POINT:
	       if (argument)
               {
	          limit = edge(argument, " ");
	          fpwidth = expression(argument, limit, param);
               }
               else fpwidth = 96;

               if (fpwidth > RADIX) fpwidth = RADIX;
               fpwidth /= word;
               fpwidth *= word;
	       if (fpwidth == 0) fpwidth = word;
	       break;

	    case CHARACTERISTIC:
	       if (!argument) break;
	       limit = edge(directive, ", ");
	       x = fpwidth;
	       if (subfunction > -1) x = subfunction;
	       x /= word;
               if (x > 17) x = 17;
	       limit = edge(argument, " ");
	       characteristic_width[x] = expression(argument, limit, param);
	       break;
               #endif
              
            case STORE:
               #ifdef NO_STORE_OVERRIDE
               filename[1] = NULL;
               #else
               if (filename[1]) break;
               #endif

               if (argument)
               {
                  v_argument = substitute(argument, param);

                  if (v_argument)
                  {
                     sr = compose_filename(v_argument, ".txo", 0);
                     if (sr) filename[1] = sr->l.name;
                  }
               }

               break;


               #ifdef BINARY

            case PUSHREL:

               unary = 0;

               if (!thislabel)
               {
                  flag("$pushrel: label in column 1 needed");
                  break;
               }

               if (argument)
               {
                  argument = substitute(argument, param);

                  switch(*argument)
                  {
                     case '(':
                        search = argument + 1;
                        limit = edge(search, ":)");

                        symbol = *limit++;

                        if (*search == '-')
                        {
                           unary = 8;
                           search++;
                        }

                        x = strict_locator(search, symbol);
                        qq = &locator[x];
                        xrefl = file_label[depth]->l.down;
                        vv = qq->runbank.p;
			v = qq->base;

                        #ifdef LONG_ABSOLUTE
                        if (subfunction == LONG_ABSOLUTE)
                        {
                           thislabel->l.valued = EQU;
                           thislabel->l.r.i = 0;

                           if (qq->flags & 1)
                           {
                              if (vv)
                              {
                                 thislabel->l.value = vv->value;

                                 if (xrefl) quadd_u(xrefl->segments.base[x],
                                                   &thislabel->l.value);

                                 if (unary == 8)
                                 {
                                    operand_reverse(&thislabel->l.value);
                                    operand_addcarry(1,
                                                    &thislabel->l.value); 
                                   
                                 }

                                 break;
                              }
                              else
                              {
                                 flag_either_pass("internal error 90",
                                                  "abandon");
                                 exit(0);
                              }
                           }

                           if (xrefl) v = xrefl->segments.base[x];
                           quadza(v, &thislabel->l.value);

                           if (unary == 8)
                           {
                              operand_reverse(&thislabel->l.value);
                              operand_addcarry(1,
                                             &thislabel->l.value); 
                           }

                           break;
                        }
                        #endif

                        if (xrefl) v = xrefl->segments.base[x];
                        quadinsert(v, &thislabel->l.value);

                        if (unary == 8)
                        {
                           quadinsert(-v, &thislabel->l.value);
                        }
                      
                        search = limit;

                        j = 0;

                        if (symbol == ':')
                        {
                           limit = edge(search, ")");

                           load_offset(search, &item);

                           j = scale(search);

                           quadinsert4(j, &thislabel->l.value);

                           symbol = *limit++;
                           search = limit;
                        }


                        if (symbol == ')')
                        {
                           bits = mantissa(search);
                           rvalue = scale(search);

                           quadinsert1(bits, &thislabel->l.value);
                           quadinsert2(rvalue, &thislabel->l.value);                          
                        }
                        else
                        {
                           flag("relocation information wrong");
                        }

                        #ifdef RANGE_FLAGS

                        limit = edge(search, "+-:");
                        symbol = *limit;

                        if (symbol == '+') unary |= 4;
                        if (symbol == '-') unary |= 2;

                        /**************************************************
                        trailing + on the tuple = sign extended range check
                        trailing - on the tuple = may truncate, don't check
                        **************************************************/

                        range_check_flags = unary;
                        range_check_bits  = bits - j;

                        range_check_position_byte = RADIX/8
                                                  - (rvalue >> 3)
                                                  - 1;

                        range_check_position_bit  =      1 << (rvalue  & 7);

                        range_check_descant       = j;

                        /**************************************************
                        j is either nothing or negative indicating right
                        shift on store, allowing larger value than [bits]
                        **************************************************/

                        #endif

                        if (locator[x].relocatable)
                        {
                           if (j < 0)
                           {
                              map_offset(j, &item);

                              #ifdef MULTUPLES

                              propagate_upwards(j, rvalue, bits);

                              offset_frame(&item);

                              thislabel->l.value.i[RADIX/32-4]
                              =             item.i[RADIX/32-1];

                              #endif
                           }

                           mapx->m.l.y = unary | 1;
                           mapx->m.l.rel = x;
                           mapx->m.l.xref = 0;
                           map_linkages(bits, rvalue);
                           thislabel->l.valued = EQUF;
                           thislabel->l.r.l.rel = x;
                           break;
                        }

                        #ifdef MULTUPLES
                        if (j < 0)
                        {
                           /***********************************
                           place in the stack a relocation tuple
                           which will not be output.

                           This will cause the offset part to
                           be accumulated as macro language writes
                           back via $info,$offset
                           ************************************/

                           map_offset(j, &item);

                           propagate_upwards(j, rvalue, bits);

                           offset_frame(&item);
                           thislabel->l.value.i[RADIX/32-4]
                           =             item.i[RADIX/32-1];

                           mapx->m.i = 0;
                           mapx->m.l.y = unary & 4;

                           /*******************************
                           sign extension flag 4 of relocation
                           tuple is used for range checking
                           *******************************/

                           mapx->scale = rvalue;
                           mapx->slice = bits;
                           mapx->recursion = maprecursion;
                           mapx++;
                           mapx->m.i = 0; 
                        }
                        #endif

                        thislabel->l.valued = EQUF;
                        thislabel->l.r.l.rel = x;
                        break;

                     case '[':
                        search = argument + 1;
                        limit = edge(search, ":]");

                        symbol = *limit++;

                        if (*search == '-')
                        {
                           unary = 8;
                           search++;
                        }

                        x = strict_quartets(4, search);

                        xrefl = file_label[depth]->l.down;

                        if (!xrefl)
                        {
                           flag("no external names have been referenced");
                           break;
                        }

                        if ((x < 0) || (x > XREFS - 1))
                        {
                           flag("external name index out of range1");
                           break;
                        }

                        sr = xrefl->pointer_array[x];

                        if (!sr)
                        {
                           flag("external name index out of range2");
                           break;
                        }

                        thislabel->l.r.l.y = sr->l.r.l.y;
                        thislabel->l.r.l.rel = sr->l.r.l.rel;
                        thislabel->l.value = sr->l.value;

                        if (unary == 8)
                        {
                           operand_reverse(&thislabel->l.value);
                           operand_addcarry(1, &thislabel->l.value); 
                        }

                        #ifdef LONG_ABSOLUTE
                        if (subfunction == LONG_ABSOLUTE)
                        {
                           if (sr->l.r.l.y)
                           {
                              printf("%s\n", sr->l.name);
                              flag("label is not absolute");
                           }
                           thislabel->l.valued = EQU;
                           break;
                        }
                        #endif
                      
                        search = limit;

                        j = 0;

                        if (symbol == ':')
                        {
                           limit = edge(search, "]");

                           load_offset(search, &item);

                           j = scale(search);

                           quadinsert4(j, &thislabel->l.value);

                           symbol = *limit++;
                           search = limit;
                        }


                        if (symbol == ']')
                        {
                           bits = mantissa(search);
                           rvalue = scale(search);

                           quadinsert1(bits, &thislabel->l.value);
                           quadinsert2(rvalue, &thislabel->l.value);                          
                        }
                        else
                        {
                           flag("relocation information wrong");
                        }

                        #ifdef RANGE_FLAGS

                        limit = edge(search, "+-:");
                        symbol = *limit;

                        if (symbol == '+') unary |= 4;
                        if (symbol == '-') unary |= 2;

                        /**************************************************
                        trailing + on the tuple = sign extended range check
                        trailing - on the tuple = may truncate, don't check
                        **************************************************/

                        range_check_flags = unary;
                        range_check_bits  = bits - j;

                        range_check_position_byte = RADIX/8
                                                  - (rvalue >> 3)
                                                  - 1;

                        range_check_position_bit  =      1 << (rvalue  & 7);

                        range_check_descant       = j;

                        /**************************************************
                        j is either nothing or negative indicating right
                        shift on store, allowing larger value than [bits]
                        **************************************************/

                        #endif

                        if (sr->l.valued == UNDEFINED)
                        {
                          
                           thislabel->l.value.i[RADIX/32-1] = 0;
                           thislabel->l.valued = EQUF;

                           if (sr->l.r.l.xref < 0)
                           {
                              sr->l.r.l.xref = ucount++;
                           }

                           if (j < 0)
                           {
                              map_offset(j, &item);

                              #ifdef MULTUPLES
                              propagate_upwards(j, rvalue, bits);

                              offset_frame(&item);
                              thislabel->l.value.i[RADIX/32-4]
                              =             item.i[RADIX/32-1];
                              #endif
                           }

                           mapx->m.l.y = 128 | unary;
                           mapx->m.l.rel = 0;
                           mapx->m.l.xref = sr->l.r.l.xref;

                           map_linkages(bits, rvalue);

                           break;
                        }


                        if (sr->l.r.l.y)
                        {
                           #ifdef XREF

                           if (selector['j'-'a'])
                           {
                              /***********************************
                              SET instead of EQUF informs the @map
                              macro that the values in thislabel->
                              need not be applied
                              ***********************************/

                              thislabel->l.valued = EQUF;
                              thislabel->l.value.i[RADIX/32-1] = 0;

                              /********************************
                              optionally advertise the relocatable
                              label reference  again for later
                              absolute resolution. The alternative
                              (not -J flag) is to convert it to
                              a location-counter relocation
                              request, see below. The effects
                              may be different in intermediate
                              links but should be the same in
                              final absolute links.
                              *********************************/


                              /*********************************
                              here the offset is the "something"
                              in "label+something", and the label
                              will be presented again in a later
                              link.
                              Offset is only there if there is a
                              right shift to be operated on the
                              finally relocated address.
                              *********************************/

                              if (j < 0)
                              {
                                 map_offset(j, &item);

                                 #ifdef MULTUPLES
                                 propagate_upwards(j, rvalue, bits);

                                 offset_frame(&item);
                                 thislabel->l.value.i[RADIX/32-4]
                                 =             item.i[RADIX/32-1];
                                 #endif
                              }

                              mapx->m.l.y = 128 | unary;
                              mapx->m.l.rel = 0;
                              mapx->m.l.xref = xref_index(sr);

                              map_linkages(bits, rvalue);
                              break;
                           }

                           #endif

                           thislabel->l.r.l.y = 0;

                           if (j < 0)
                           {
                              /********************************
                              add the newly known offset part
                              to the originally known offset.
                              This satisfies "label+something"
                              *********************************/

                              map_offset(j, &item);

                              #ifdef MULTUPLES
                              propagate_upwards(j, rvalue, bits);

                              offset_frame(&item);
                              thislabel->l.value.i[RADIX/32-4]
                              =             item.i[RADIX/32-1];
                              #endif
                           }

                           mapx->m.l.y = 1 | unary;
                           mapx->m.l.rel = sr->l.r.l.rel;
                           mapx->m.l.xref = 0;

                           map_linkages(bits, rvalue);

                           thislabel->l.valued = EQUF;
                           break;
                        }

                        #ifdef MULTUPLES
                        if (j < 0)
                        {
                           /***********************************
                           place in the stack a relocation tuple
                           which will not be output.

                           This will cause the offset part to
                           be accumulated as macro language writes
                           back via $info,$offset
                           ************************************/

                           map_offset(j, &item);

                           propagate_upwards(j, rvalue, bits);

                           offset_frame(&item);
                           thislabel->l.value.i[RADIX/32-4]
                           =             item.i[RADIX/32-1];

                           mapx->m.i = 0;
                           mapx->m.l.y = unary & 4;

                           /*******************************
                           sign extension flag 4 of relocation
                           tuple is used for range checking
                           *******************************/

                           mapx->scale = rvalue;
                           mapx->slice = bits;
                           mapx->recursion = maprecursion;
                           mapx++;
                           mapx->m.i = 0; 
                        }
                        #endif

                        thislabel->l.valued = EQUF;
                        break;

                     default:
                        printf("%s\n", argument);
                        flag("wrong argument type in $pushrel");
                        break;
                  }
               }
               else
               {
                  flag("$pushrel takes an argument");
               }

               break;



            case LOAD:

               if (!pass) break;
              
               if (argument)
               {
                  if ((sr = findlabel(argument, NULL)))
                  {
                     #ifdef RANGE_FLAGS
                     v = range_filter.i[0]
                       | range_filter.i[1]
                       | range_filter.i[2]
                       | range_filter.i[3]
                       | range_filter.i[4]
                       | range_filter.i[5];

                     if (v)
                     {
                        flag("field out of range on relocation, -n flag for details");

                        if (selector['n'-'a'])
                        {
                           printf("$%X:%0*X [", counter_of_reference, apw, loc);

                           x = (RADIX - subfunction) >> 3;
                           while (x < RADIX/8) printf("%2.2x", sr->l.value.b[x++]);
                           printf("]\n");

                           display_ra(0, &range_filter);
                           display_ra(0, &range_free);
                           display_ra(0, &range_sign);
                        }
                     }

                     range_filter = zero_o;
                     range_free   = zero_o;
                     range_sign   = zero_o;

                     #endif

                     produce(subfunction, '+', &sr->l.value, NULL);
                     break;
                  }
               }
               flag_either_pass("binary output error", "abandon");
               exit(0);

               #endif		/*	BINARY	*/

               #ifdef SYM
            case SYM:

               if (!pass) break;
            
               if (argument)
               {
                  limit = first_at(argument, " ");
                  symbol = expression(argument, limit, param);
                  putchar(symbol);
               }
               break;
               #endif

               #ifdef FP_XPRESS
            case FP_XPRESS:
               if (!argument) break;
               argument = substitute(argument, param);

               limit = argument;
               while (*limit++);
               fp_xpress(argument, limit, xmodifier);
               break;
               #endif

               #ifdef ESPRESSO
            case ESPRESSO:
               if (!argument) break;
               argument = substitute(argument, param);

               limit = argument;
               while (*limit++);
               i_xpress(argument, limit, xmodifier);
               break;
               #endif

               #ifdef RECORD
            case RECORD:

               if (masm_level) fields(param);

               #if 1
               if (argument) argument = substitute_alternative(argument, param);
               #endif

               record(thislabel, argument, subfunction);
               break;
               #endif

               #ifdef ZERO_CODE_POINT
            case ZERO_CODE_POINT:
               if (argument)
               {
                  limit = first_at(argument, " ");
                  zero_code_point = zxpression(argument, limit, param);
               }
               else zero_code_point = DEFAULT_ZERO_CODE_POINT;
               break;
               #endif

            default:
	       flagf("unknown directive ");

               #ifndef DOS
	       if (selector['f'-'a'] | pass)
               {
                  printf("%d/%x/%s\n", type, known, directive);
               }
               #endif
	 }

	 return 0;
      
      case NAME:

         #ifdef ABOUND
         if (tpp & 128)
         {
         }
         else
         {
            flagg(sr->l.name);

            #ifdef FOLLOW_RECURS
            printf("[%s:%d]",
                   ((label *) sr->l.along)->name,
                   ((label *) sr->l.along)->valued);
            #endif

            flagg(" not a procedure entry point");
            break;
         }
         #endif

      case PROC:


	 #ifdef PROCLOC
	 if ((sr->l.r.l.y) && (counter_of_reference != sr->l.r.l.rel))
	 {
	    actual->loc = loc;
            
            downloc = sr->l.r.l.rel;
	    counter_of_reference = downloc;
            
            actual = &locator[counter_of_reference];
            
	    loc = actual->loc;
            
            if (!actual->touch_base)
            {
               note("code generated in unbased counter");
            }

            outstanding = 1;
	 }
	 #endif

         #ifdef WALKP
         printf("VClear::%s\n", sr->l.name);
         #endif
	 
	 v_argument = substitute(line_label, param);

         vtree[masm_level++]->ready = 0;

         #ifdef WALKP
         printf("PClear::%s\n", sr->l.name);
         #endif

	 if (masm_level == RECURSION) unwind();

	 entry[masm_level] = sr;
	 txp = sr;
         
         if (sr->l.down) txp = sr->l.down;
	 else
         {
            x = sr->h.length;

            #ifdef CLEATING
            if (!x) cleat(2, sr);
            #endif

	    txp = (object *) ((char *) txp + x);
         }

         if (plist > masm_level)
         {
	    if (((pass) && (selector['p'-'a']))
            || ((!pass) && (selector['r'-'a'])))
	    {
	       printf("::::PROC:::: %s [%s]\n", sr->l.name,  v_argument);
            }
	 }
	 
	 toplabel = floatop;

	 if ((tpp & 2) && (pass))
	 {
	    actual->loc = loc;
	    for (x = 0; x < LOCATORS; x++) 
	    {
	       savelocator[x] = locator[x].loc;
	       savelocatorl[x] = locator[x].litlocator;
	    }
	    savepass = pass;
	    pass = 0;
	    depx = txp;

	    for (;;)
	    {
               j = txp->h.type;


               if (j == BYPASS_RECORD)
               {
                  if ((x = txp->nextbdi.next)) txp = bank[x];
                  else                         txp = NULL;

                  if (!txp)
                  {
                     printf("Error %d Retrieving Procedure Text\n", j);
                     exit(0);
                  }

                  j = txp->h.type;
               }

               if (j == END) break;

	       nlabel = txp->t.text;

               #ifdef QNAMES
               #ifdef REPORT_QNAMES
	       if (j == NAME) qnames++;
               #endif
               if (j == PROC)     j = TEXT_IMAGE;
               if (j == FUNCTION) j = TEXT_IMAGE;
               #endif

	       if (j == TEXT_IMAGE)
	       {
		  next_image[masm_level] = txp;
		  rvalue = assemble(nlabel, v_argument, thislabel, image);
		  txp = next_image[masm_level];
	       }

               x = txp->h.length;

               #ifdef CLEATING
               if (!x) cleat(3, txp);
               #endif
            
	       txp = (object *) ((char *) txp + x);
	    }

	    txp = depx;
	    pass = savepass;
	    for (x = 0; x < LOCATORS; x++)
	    {
	       locator[x].loc = savelocator[x];
	       locator[x].litlocator = savelocatorl[x];
	    }
	    loc = actual->loc;

            if (prelif != ifdepth)
            {
               note("$proc prepass has left $if nesting deeper");
            }
            if (skipping)
            {
               note("$proc prepass has turned assembly off");
            }
	 }
	 
	 savepass = pass;
	 if (pass) pass = tpp;

	 for (;;)
	 {
	    j = txp->h.type;

            if (j == BYPASS_RECORD)
            {
               if ((x = txp->nextbdi.next)) txp = bank[x];
               else                         txp = NULL;

               if (!txp) 
               {
                  printf("Error %d Retrieving Procedure Text\n", j);
                  exit(0);
               }

               j = txp->h.type;
            }


            if (j == END) break;

	    nlabel = txp->t.text;
	    
            #ifdef QNAMES
            #ifdef REPORT_QNAMES
            if (j == NAME) qnames++;
            #endif
            if (j == PROC)     j = TEXT_IMAGE;
            if (j == FUNCTION) j = TEXT_IMAGE;
            #endif

	    if (j == TEXT_IMAGE)
	    {
	       next_image[masm_level] = txp;
               
	       if (plist > masm_level)
               {
	          if (((pass) && (selector['p'-'a']))
                  || ((!pass) && (selector['r'-'a'])))
	          {
                     print_macrotext(txp->t.length, txp->t.text, sr->l.name);
                     putchar(10);
	          }
	       }

	       rvalue = assemble(nlabel, v_argument, thislabel, image);
               
               if (rvalue == RETURN) break;
	       txp = next_image[masm_level];
	    }
            
            x = txp->h.length;

            #ifdef CLEATING
            if (!x) cleat(4, txp);
            #endif

	    txp = (object *) ((char *) txp + x);
	 }

         if (plist > masm_level)
         {
            if (((pass) && (selector['p'-'a']))
            || ((!pass) && (selector['r'-'a'])))
            {
                printf(":::end proc:%s\n", txp->t.text);
            }
         }

         if (prelif != ifdepth)
         {
            note("$proc has left $if nesting deeper");
         }

         if (skipping)
         {
            note("$proc has turned assembly off");
         }

	 pass = savepass;
	    
	 if (tpp) pack_ltable(toplabel);
	 
	 masm_level--;
 
	 #ifdef PROCLOC
	 if ((sr->l.r.l.y) && (uploc != downloc))
	 {
            #if 0	/* this is now checked at the end */

            if (actual->litlocator ^ actual->lroot)
            {
               if (loc < actual->litlocator)
               {
               }
               else
               {
                  flag("2nd pass code overlaps literal table");
               }
            }

            #endif

            actual->loc = loc;

	    counter_of_reference = uploc;
            downloc = uploc;

            actual = &locator[counter_of_reference];
	    loc = actual->loc;
            
            outstanding = 1;
         }
	 #endif

	 return 0;
      
      case FORM:
	 subtext = sr->l.value.b;
	 
	 #ifdef FPASS1
	 if (!pass)
	 {
	    while (*subtext) bits += *subtext++;
	    produce(bits, '+', &item, image);
	 }
	 #endif

	 slice = *subtext;
	 
	 while (slice)
	 {
	    if ((argument) && (pass))
	    {
	       if (*argument == qchar)
	       {
		  v_argument = substitute(argument, param);
		  lhbx(v_argument, slice, &item);
	       }
	       else
	       {
		  if (bits) lshift(&item, slice);
		  limit = first_at(argument, ":, ");
		  x = slice & 7;
		  j = slice >> 3;
		  xmask = 255 << x;
		  ymask = xmask ^ 255;
		  x = RADIX/8;
		  
		  #ifdef RELOCATION
		  mapx->m.i = 0; /* global change 3ix2008 */
		  #endif
		  
		  {
		     #ifdef AUTOMATIC_LITERALS
		     if ((*argument == '(') && (selector['a'-'a']))
		     {
			v = literal(argument, param, litloc);
			oo = &liti;
                        quadza(v, oo);
			
                        #ifdef LTAG

                        qq = &locator[litloc];

                        if ((qq->flags & 129) == 1)
                        {
                           if ((vv = (value *) qq->runbank.p))
                           {
                              liti = vv->value;
                              quadd_u(v, oo);
                           }
                        }

                        #endif		/* LTAG */
		     }
		     else
		     #endif

		     oo = xpression(argument, limit, param);
		     
		     while (j--)
		     {
			x--;
			item.b[x] = oo->b[x];
		     }
		     if (ymask)
		     {
			x--;
			item.b[x] &= xmask;
			item.b[x] |= oo->b[x] & ymask;
		     }
		  }
		  
		  #ifdef RELOCATION
		  map_field(subtext);
 		  mapx->m.i = 0; /* global change 3ix2008 */
		  #endif
	       }
	       

	       argument = first_at(argument, ", ");
	       
	       if (*argument == ',')
	       {
		  argument++;
		  while (*argument == 32) argument++;
	       }
	    }
	    bits += slice;
	    subtext++;
	    slice = *subtext;
	 }

         transient_floating_bits = 0;
	 produce(bits, '+', &item, image);
	 return 0;

      default:
         if (selector['f'-'a'] | pass)
         {
            load_name(directive, NULL);
            if (name[0]) printf("[%2.2x %s]", type, name);
            else         printf("[%2.2x %s]", type, directive);
         }

	 flagf("not a command");
	 return 0;
   }
   return 0;
}

int main(int argc, char *_argv[])
{
   int			 i = 1, j, bits, bytes;
   
   char 		*b = NULL;

   char 		 line[READSIZE];

   object 		*sr;
   int			 fsize;
   
   location_counter	*q;
   int			 low, high, v;

   value		*vpoint;

   #ifdef INBANK
   lr = (object *) inbank;
   floatable = (object *) overbank;
   #else

   bank[0]   = (object *) malloc(BANK);
   floatable = (object *) malloc(BANK);

   if (!bank[0]) return -3;
   if (!floatable) return -33;

   lr = bank[0];
   #endif

   floatop = floatable;

   remainder = BANK-MARGIN;

   while (i < argc)
   { 
      b = _argv[i];

      if (*b == OFLAG)
      {
         b++;

         while ((j = *b++))
         {
	    if ((j > 0x60) && (j < 0x7b))  selector[j-'a'] = 1;
	    if ((j > 0x40) && (j < 0x5b))
            {
                uselector[j-'A'] = 1;
                if (j == 'E') guard_pattern = 0xE0;
                if (j == 'F') guard_pattern = 0xC0;
                if (j == 'G') guard_pattern = 0x80;
                if (j == 'H') guard_pattern = 0;
            }
            if (j == '+') list = 1;
         }
      }
      else
      {
         if (file_arguments < FILE_ARGUMENTS)
         {
            filename[file_arguments++] = b;
         }
      }

      i++;
   }


   #if defined(DOS) && defined(MS)

   if (!selector['w'-'a']) printf("MASMX/%d " VERSION "r" REVISION "\n",
                                  _stklen);
   
   #else

   if (!selector['w'-'a']) printf("MASMX " VERSION "r" REVISION "\n");
   
   #endif


   internal_labels();

   initial_flags = *(flag_box *) selector;
   initial_uflags = *(flag_box *) uselector;

   list = 1;

   depth = -1;
   
   if (!file_arguments) filename[0] = "-";
   
   if (*filename[0] == OFLAG)
   {
      selector['s'-'a'] = 1;

      loadfile("-INPUT", ">>");
   }

   else loadfile(filename[0], ".msm");

   entry[0] = file_label[0];

   if (!selector['w'-'a']) printf("%d/%s\n", handle[0], file_label[0]->l.name);

   if (handle[0] < 0) return 0;   

   if (selector['s'-'a'])
   {
      #ifdef MS
      nhandle = open(OSYM, O_CREAT|O_TRUNC|O_RDWR, S_IREAD|S_IWRITE);
      #else
      nhandle = open(OSYM, O_CREAT|O_TRUNC|O_RDWR, S_IREAD|S_IWRITE|S_IRGRP|S_IWGRP|S_IROTH|S_IWOTH);
      #endif

      if (nhandle < 0)
      {
	 printf("temp symbolic cannot be written %d\n", errno);
	 return 0;
      }
   }
   
   for (;;)
   {
      i = getline(line, READSIZE-1);
      if (!i) continue;

      if (i < 0)
      {
      }
      else i = assemble(line, NULL, NULL, NULL);

      #ifndef PRINTBYREAD

      if ((lix) && (pass) && (list > depth) && (selector['l'-'a']))
      {
         printf("  :                            %d %s\n", ll[depth], plix);
      }

      #endif       

      if ((i < 0) || ((!depth) && ((i == END) || (i == RETURN))))
      {
         #ifdef PRINTBYREAD

         if ((lix) && (pass) && (list > depth) && (selector['l'-'a']))
         {
            printf("  :                            %d %s\n",
                                           ll[depth], plix);
         }

         #endif       

	 actual->loc = loc;

         #ifdef STRUCTURE_DEPTH
         if (active_x)
         {
            depth = 0;
            flagg("end of assembly reached within $tree or $branch");
         }
         #endif


	 if (pass)
         {
            q = locator;

            for (i = 0; i < LOCATORS; i++)
            {
               v = q->lroot;
               high = q->loc;

               #if 0
               if (high == 0) high = v;
               #endif

               if (high > v)				/*	code has changed size	*/
               {
                  if (q->litlocator > v)
                  {
                     flagz();				/*	there are literals	*/
                     printf("2nd assembly pass code overload\n");	/*	resized code clashes	*/
                     summarise_revision(q, v, high);
                  }
               }
               else if ((q->touch_base) && (high < v))
               {
                  if ((q->flags & 1) == 0)
                  {
                     if (q->touch_base & 2)		/*	binary linker touch	*/
                     {
                        #if 1
                        flagz();
                        printf("segment missing on 2nd assembly pass\n");
                        summarise_revision(q, v, high);
                        #endif
                     }
                     else if (q->litlocator == v)	/*	there are no literals	*/
                     {
                        notez();
                        printf("adjusting storage map\n");
                        q->litlocator = high;
                        summarise_revision(q, v, high);
                     }
                  }
               }

               q++;
            }

            break;
         }

         #ifdef RELOCATION
         mapx = mapinfo;
         mapx->m.i = 0;
         #endif

         q = locator;

	 for (i = 0; i < LOCATORS; i++)
	 {
            v = q->loc;

            #ifdef GBASIS_ALOT
            if (((q->flags & 129) == 128)
            &&  ( q->relocatable  ==   0))
            {
               if (q->bias == 0) v += q->runbank.a;
            }
            #endif

	    q->litlocator = v;
            q->lroot      = v;

            #ifdef LITERALS
            if (lpart[i])
            {
               write_breakpoint(i, v);
	       q->litlocator = q->lroot = read_breakpoint(i);
            }
            #endif

            if (q->flags & 1) q->runbank.p->offset = q->loc;
            else              q->runbank.a = 0;

	    q->loc = 0;

            #if 1
            q->touch_base = 0;
            #endif

            q->breakpoint = 0;
            q->bias       = 0;
            q++;
	 }

         cont_char = ';';
	 qchar     = '"';
         lterm     = '.';
         sterm     = ':';

	 lix = 0;
	 plix[0] = 0;
	 ll[0] = 0;
	 
	 if (selector['s'-'a'])
	 {
            #ifdef BLOCK_WRITE
            block_write(nhandle, NULL, 0);
            #endif

	    close(nhandle);
	 }
	
         if (depth < 0)
         {
         }
	 else
         {
            close(handle[0]);

            #ifdef BLOCK
            block[0]->r = 0;
            block[0]->w = 0;
            #endif
	 }
	 
	 if (ecount | selector['h'-'a']) return 0; 
	 pass = 2;
         background_pass = 2;
	 
         if (selector['s'-'a']) handle[0] = open(OSYM, O_RDONLY);
         else
         {
            handle[0] = open(file_label[0]->l.name, O_RDONLY);
            pass1_tsubs = tsubs;
  
            /******************************************************
 		save the count of text translate patterns
 		recorded on the 1st pass
 		to switch on when the block of patterns if any
 		is encountered again on the 2nd pass
 		but not if the 2nd pass input file is temp.msm OSYM
 		because translates are applied to OSYM on pass 1
 		repeating the translates can be wrong
 		and makes more work forcing the intended behaviour
             ******************************************************/
         }

         if (handle[0] < 0) printf("temp symbolic cannot be read %d\n", errno);

	 quadza(handle[0], &file_label[0]->l.value);
	 
	 selector['s'-'a'] = 0;
         tsubs = 0;

         #ifdef MS
         ohandle = open(OBIN, O_CREAT|O_TRUNC|O_RDWR, S_IREAD|S_IWRITE);
         #else
	 ohandle = open(OBIN, O_CREAT|O_TRUNC|O_RDWR, S_IREAD|S_IWRITE|S_IRGRP|S_IWGRP|S_IROTH|S_IWOTH);   
         #endif

	 if (ohandle < 1)
	 {
	    printf("temp binary cannot be written %d\n", errno);
	    return -96;
	 }

	 counter_of_reference = 0;
         actual = locator;
	 loc = 0;
	 depth = 0;
	 masm_level = 0;

         word = 24;
         address_quantum = 24;
         address_size = 24;
         xadw = 48;

	 byte = 8;
         apw = 6;
         apwx = 6;
         
	 code = ASCII;         
         for (i = 0; i < 256; i++) code_set[i] = i;

	 ifdepth = 0;
	 skipstate = 0;
	 satisficed |= 1;
	 skipping = 0;
	 litloc = 0;         

	 outstanding = 1;
	 list = 1;
	 plist = 0;
	 octal = 0;

         #ifdef STRUCTURE_DEPTH
         branch_present = 0;
         #endif

         #ifdef PATH
         path[0] = 0;
         #endif

         fpwidth = 96;

         characteristic_width[0] = characteristic_width[1] = 8;
         characteristic_width[2] = 12;
         characteristic_width[3] = characteristic_width[4] = characteristic_width[5] = 24;
         characteristic_width[6] = characteristic_width[7] = characteristic_width[8] = 24;
         characteristic_width[9] = characteristic_width[10] = characteristic_width[11] = 24;
         characteristic_width[12] = characteristic_width[13] = characteristic_width[14] = 24;
         characteristic_width[15] = characteristic_width[16] = characteristic_width[17] = 24;

         guard_pattern = 0xE0;

         *(flag_box *) selector = initial_flags;
         *(flag_box *) uselector = initial_uflags;

         if (uselector['E'-'A']) guard_pattern = 0xE0;
         if (uselector['F'-'A']) guard_pattern = 0xC0;
         if (uselector['G'-'A']) guard_pattern = 0x80;
         if (uselector['H'-'A']) guard_pattern = 0;

         #ifdef ZERO_CODE_POINT
         zero_code_point = DEFAULT_ZERO_CODE_POINT;
         #endif
         
	 continue;
      }
   }
   
   #ifdef LITERALS
   for (i = 0; i < LOCATORS; i++)
   {
      output_literals(i);
   }
   #endif

   
   lr->i = 0;;

   sr = origin;
   
   while (sr)
   {
      if ((sr->h.type == LABEL)
      &&  (sr->l.valued)
      &&  (sr->l.r.l.xref < 0))
      {
	 write(ohandle, "\n+", 2);
	 pushs(sr->l.name);
	 write(ohandle, ":", 1);

         i = sr->l.r.l.rel & 127;
         q = &locator[i];

         j = sr->l.valued;
         if (j == BLANK)
         {
            j = LOCATION;
            if (q->flags & 128) j = EQUF;
         }

         if (j == EQUF)
         {
            if (((q->flags & 129) == 128)
            &&  ( q->relocatable  ==   0))
            {
               quadd_u(q->base, &sr->l.value);
               j = LOCATION;
            }

            #ifdef DRIFT_GUARD_1
            if ((q->flags & 129) == 129)
            {
               if (q->breakpoint > 1)
               {
                  flagz();
                  printf("error exporting %s "
                         "in multi-breakpoint giant segment\n"
                         "base+displacement tuple cannot be "
                         "safely linked\n", sr->l.name);
               }

               vpoint = (value *) q->runbank.p;
               v = qextractv(sr);
               quadza(v, &sr->l.value);

               operand_add(&sr->l.value, &vpoint->value);
               j = LOCATION;
            }
            #endif
         }

	 if (j == LOCATION)
	 {
	    write(ohandle, "$", 1);
	    pushh2(i);
	    write(ohandle, ":", 1);

	    xpushaddress(&sr->l.value, i);
	 }
	 else
	 {
	    bits = RADIX;
	    i = 0;
	    while (i < RADIX/8-1)
	    {
	       if (sr->l.value.b[i+1] & 128)
	       {
		  if (sr->l.value.b[i] != 0xff) break;
	       }
	       else
	       {
		  if (sr->l.value.b[i])         break;
	       }
	       i++;
	       bits -= 8;
	    }
	    bits += word-1;
	    bits /= word;
	    bits *= word;
	    bytes = (bits+EIGHT-1) >> 3;

            if (sr->l.valued == EQUF) bytes = (address_size+EIGHT-1) >> 3;
   
	    i = RADIX/8 - bytes;

            if ((sr->l.r.l.rel) ||  (sr->l.r.l.y))
            {
               write(ohandle, "$", 1);
	       pushh2(sr->l.r.l.rel & 127);
	       write(ohandle, ":", 1);
            }

	    while (i < RADIX/8) pushh2(sr->l.value.b[i++]);
	 }
      }
      
      sr = sr->l.along;
   }

   sr = origin;

   while (sr)
   {
      if ((sr->h.type == LABEL)
      &&  (sr->l.valued == UNDEFINED)
      &&  (!(sr->l.r.l.xref < 0)))
      {
	 write(ohandle, "\n-", 2);
	 pushs(sr->l.name);
	 write(ohandle, ":[", 2);
	 pushh4(sr->l.r.l.xref);
	 write(ohandle, "]", 1);
      }
      
      sr = sr->l.along;
   }

   #ifdef BINARY
   #ifdef XREF
   sr = xref_wait;
   while (sr)
   {
      write(ohandle, "\n-", 2);
      pushs(sr->x.name);
      write(ohandle, ":[", 2);
      pushh4(sr->x.xref);
      write(ohandle, "]", 1);

      if (selector['l'-'a']) printf("%s awaiting absolute part\n",
                                     sr->x.name);

      sr = sr->x.along;
   }

   #endif
   #endif
   
   
   if (selector['x'-'a'])
   {
       if (selector['i'-'a']) walktable(3);
       else                   walktable(0);
   }
   
   for(i = 0; i <  LOCATORS; i++)
   {
      q = &locator[i];

      if (q->litlocator > q->loc) q->loc = q->litlocator;
      
      low = q->base;
      high = q->loc;

      if ((selector['d'-'a']) && ((q->flags | q->relocatable) == 0) && (q->breakpoint))
      {
         low += q->runbank.a - q->base;
         high += q->runbank.a - q->base;
      }

      #ifdef GBASIS
      if (((q->flags & 129) == 128)
      &&  ( q->relocatable  ==   0))
      {
         high += q->base;
      }
      #endif

      if (q->loc | (q->flags & 1))
      {
         #ifdef LONG_TRAILER
         if (q->flags & 1)
         {
            if (q->flags & 2)
            {
               write(ohandle, "\n@:", 3);
               pushh2(i);
               write(ohandle, ":", 1);
               xpushaddress(&q->runbank.p->value, i);
               q->flags &= 0xFD;
            }
    
            v = q->runbank.p->offset;
            if (v > high) high = v;

            if (!selector['w'-'a'])
            {
               if (selector['d'-'a'])
               {
                  printf("\n@:");
                  illustrate_xad(q, 0);
               }
            }
         }

         #endif

         if ((q->flags & 128) && (q->base == 0) && (q->runbank.a == 0)
         &&  (q->relocatable == 0))
         {
         }
         else
         {
	    write(ohandle, "\n:$", 3);
	    pushh2(i);
	    write(ohandle, "*", 1);
	    pushaddress(q->relocatable);
	    write(ohandle, ":", 1);
	    pushaddress(low);
	    write(ohandle, ":", 1);
	    pushaddress(high);
         }

	 if (!selector['w'-'a'])
         {
	    if (octal)
	    printf(":$(%o):%0*o:%0*o ", i, apw, low, apw, high);
	    else
	    printf(":$(%2.2X):%0*X:%0*X ", i, apw, low, apw, high);
         }
      }
   }


   #ifdef TEST_B4

   #ifdef BLOCK_WRITE
   write(ohandle, NULL, 0);
   #endif

   fsize = lseek(ohandle, (off_t) 0, SEEK_CUR);

   if (fsize)
   {
      write(ohandle, "\n", 1);

      #ifdef BLOCK_WRITE
      write(ohandle, NULL, 0);
      #endif
   }

   #else

   write(ohandle, "\n", 1);

   #ifdef BLOCK_WRITE
   write(ohandle, NULL, 0);
   #endif

   fsize = lseek(ohandle, (off_t) 0, SEEK_CUR);

   #endif

   if ((!selector['w'-'a'])
   ||  (ecount)
   || ((ucount) && (selector['u'-'a'])))
   {
      printf("\n%s: object code %d bytes: "
             "%d errors: %d undefined labels\n",
	      file_label[0]->l.name, fsize, ecount, ucount);
   }

   if (ecount) return -1;
   if ((ucount) && (selector['u'-'a'])) return -1;

   if (filename[1]) save_object(filename[1]);

   #ifdef REPORT_QNAMES
   printf("%d names not re-scanned\n", qnames);
   #endif

   return 0;
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


