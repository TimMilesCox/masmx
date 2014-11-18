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

      case 'o':
      case 'O':
         return word * 8;
   }

   return 0;
}

static long bucket(long granule)
{
   long power = 1;
   while (power < granule) power <<= 1;
   return -power;
}


static value *apply_value(int id)
{
   value		*p = (value *) lr;

   if (remainder < sizeof(value)) p = (value *) buy_ltable();

   lr = (object *) ((long) lr + sizeof(value));
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
   long			 container;
   #endif

   unsigned long	 v = 0, w = 0, x = 0;
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

   #if 0
   out_standing(counter_of_reference);
   #endif

   if (*limit == ':')
   {
      line_label = limit+1;
      
      limit = first_at(line_label, ",:/)");

      #if 0
      putchar('[');
      {
         char *x = line_label;
         while (x < limit) putchar(*x++);
      }
      putchar(']');
      #endif

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

            #if 0
            if (!actual->touch_base) actual->base = v;
            #endif
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
         
            if (actual->touch_base)
            {
               if (actual->breakpoint == 0)
               {
                  flag("earlier part of segment is not breakpointed");
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
                  vpoint = (value *) actual->runbank;

                  if (!vpoint)
                  {                  
                     actual->runbank
                     = (long) apply_value(counter_of_reference);
                  }

                  ((value *) actual->runbank)->value
                  = *xpression(limit2+1, limit, NULL);


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
                  actual->runbank = x = expression(limit2, limit, param);
                  if (v != actual->base)
                  flag("address space region slipped");
               }
            }

            actual->base = v;
            #if 1
            actual->breakpoint++;
            #endif
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
               #ifdef REBASE           
               actual->base += w;
               loc = 0;
               actual->loc = 0;
               #else
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
               #endif
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
   
   actual->touch_base = 1;
   outstanding = 1; /* outcounter(0); */
}


static long rfunction(int v,
		      char *s, char *param, char *mark, 
		      object *tag)
{
   char			*limit, *d;
   long			 i, j;
   int			 h, symbol, x;
   object		*l;
   location_counter	*q;

   line_item		*item;
   line_item		*breakpoint_base;

   #ifdef BASE
   xref_list		*xrefl;
   value		*vbreak;
   #endif

   #ifdef RELOCATION
   link_profile		*mapxb4;
   #endif

   switch(v)
   {
      case LOCTR:
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

            #ifdef RELOCATION

            #if 0
            if (q->relocatable)
            {
               /******************************************
                      if base+displacement the function is
                      not relocatable
               ******************************************/

               if ((q->flags & 128) == 0) mapx->m.l.y |= 1;
            }
            #else
            if (q->relocatable) mapx->m.l.y |= 1;
            #endif

   	    mapx->m.l.rel = j | 128;
            #endif

            if ((q->flags & 1) && (uselector['W'-'A'] == 0))
            {
               note("GIANT SPACE: $(counter) returns "
                    "intrasegment part of counter only");
               if (q->flags & 128)
               note("for absolute address use $A(WITH_A_LABEL_ARGUMENT)");
               else
               note("reference a label directly in the target segment");
            }

            if (j == counter_of_reference) return loc;
            return q->loc;
         }

         #ifdef RELOCATION

         #if 0
         if (actual->relocatable)
         {
            /******************************************
                   if base+displacement the function is
                   not relocatable
            ******************************************/

            if ((actual->flags & 128) == 0) mapx->m.l.y |= 1;
         }
         #else
         if (actual->relocatable) mapx->m.l.y |= 1;
         #endif

         mapx->m.l.rel = counter_of_reference | 128;
         #endif

         if ((actual->flags & 1) && (uselector['W'-'A'] == 0))
         {
            note("GIANT SPACE: $ returns "
                 "intrasegment part of counter only");
            note("for absolute current location use $A");
         }

         return loc;

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

         return actual->base;
         #endif


      case PNAME:
   
	 return extract_gparam("(0,1)", param);


      case REGION:
	 if (*s != '(') return counter_of_reference;
	 d = substitute(s+1, param);
	 l = findlabel(d, NULL);
	 if ((!l)
	 ||  (l->h.type != LABEL)
	 ||  (l->l.valued == UNDEFINED)) return 0;
	 return l->l.r.l.rel & 127;


      case TYPE:

	 d = substitute(s+1, param);
	 
	 if (!d)
	 {
	    flag_either_pass("Internal Error 3", "abandon");
	    exit(0);
	 }

	 #define SOFTLY

	 #ifdef	SOFTLY
	 symbol = *d;
	 if ((symbol == '-') || (symbol == '+')
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
         #ifdef NESTED_ISREL
         s = substitute(s, param);
         #endif

	 if (*s++ == '(')
	 {
            #ifdef NESTED_ISREL
            limit = fendbe(s);
            #else
	    limit = edge(s, ")");
            #endif

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

               #if 0
               if (selector['y'-'a'])
               {
                  if (x < 0) break;
               }
               #endif

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

         #endif
         #endif

         #ifdef MANTISSA

      case MANTISSA:
         s = substitute(s + 1, param);

         i = quartets(s);
         return i;
         #endif

         #ifdef SCALE

      case SCALE:
         i = 0;
         s = substitute(s + 1, param);

         while (symbol = *s++)
         {
             if (((symbol > 0x2F) && (symbol < 0x3A))
             ||  ((symbol > 0x40) && (symbol < 0x5B))
             ||  ((symbol > 0x60) && (symbol < 0x7B)))
             {
             }
             else break;
         }
         if (symbol == '*')
         {
            symbol = *s++;
            {
               if (symbol == '/') i = quartets(s);
            }
         }
         else
         {
            if (symbol == '/')
            {
               symbol = *s++;
               if (symbol == '*')
               {
                  i = quartets(s);
                  i = -i;
               }
            }
         }

         return i;

         #endif

         #ifdef ABSOLUTE
      case ABSOLUTE:

         q = actual;
         j = loc;
         x = counter_of_reference;
         h = 0;
         l = NULL;

         if (*s == '(')
         {
            d = substitute(s+1, param);
            limit = fendbe(d);

            j = zxpression(d, limit, param);

            #ifdef RELOCATION
            if ((mapx->m.l.y & 129) == 128) return j;
            #endif

            l = findlabel(d, limit);

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
               breakpoint_base = &((value *) q->runbank)->value;
               item = xpression(STACK_TOP_VALUE, NULL, NULL);

               if ((q->flags & 128) || (!l))
               {
                  /*********************************************

                  when $A has had no argument, zxpression has
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
	 if ((actual->breakpoint) && ((actual->flags & 1) == 0)) return actual->runbank;
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
   
   if ((*directive == '+')
   ||  (*directive == '-')
   ||  (*directive == '^')
   ||  (*directive == qchar)) return -1;
   
   sr = findlabel(directive, NULL);
   
   if ((sr) && (  (sr->l.valued == DIRECTIVE)
	       || (sr->l.valued == EQU)  
	       || (sr->l.valued == SET))) return sr->l.value.b[RADIX/8-1];

   return -1;
}

static void pack_ltable(object *toplabel)
{
   int				 i, length;  
   paragraph			*p, *q;
   object			*pr = toplabel;
  
   while ((long) pr != (long) floatop)
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
      
      pr = (object *) ((long) pr + length);
   }

   #ifdef TRACE_RECURS
   printf("exit compress\n");
   #endif
   
   floatop = toplabel;
}

static line_item *external_function(char *s, char *param, char *mark,
		  	            object *l)
{
   long			 i = 0, f;
   int			 j = 1, y = 0, prelif, preskip,
                         bdepth = 0, sinquo = 0, square = 0;
   
   char			*dir, *arg, *v_p;
   object		*x;
   long			 start = loc;

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
      while (symbol1 = *v_p++)
      {
         if (symbol1 == '(') break;
         if (symbol1 == '[') break;
      }
   }

   while (symbol2 = l->l.name[y++]) v_param1[j++] = symbol2;

   v_param1[j++] = 32;

   if ((symbol1 == '(') || (symbol1 == '[')) 
   {
      bdepth = 1;
      if (symbol1 == '[') square = 1;

      while (symbol1 = *v_p++)
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
   
   #ifdef ARRAY

   if (!vtree[masm_level])
   {
      #if 1
      for (j = 0; j < masm_level; j++)
      printf("[L %d %s V %p]\n", j, entry[j]->l.name, vtree[j]);
      #endif

      flag_either_pass(l->l.name, "internal error possibly caused by parameter "
                                  "reference on a macro header line\n");

      exit(0);
   }

   vtree[masm_level++]->ready = 0;

   #ifdef WALKP
   printf("FClear::");
   #endif

   #else  
   masm_level++;
   #endif

   if (masm_level == RECURSION) unwind();
   
   #ifdef RELOCATION
   maprecursion++;
   #endif

   toplabel = floatop;
   
   entry[masm_level] = l;

   #if 1
   prelif = ifdepth;
   #endif

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

      x = (object *) ((long) x + y);
      
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
                  #if 1
                  print_macrotext(x->t.length, x->t.text, l->l.name);
                  #else
	          printf("%s", x->t.text);
                  #endif
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
         if (j = x->nextbdi.next) x = bank[j];
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

      #if 0 
      if (j != TEXT_IMAGE)
      {
         if (pass) printf("[%x]\n", j);
         flag("unexpected token in function text");
         break;
      }
      #endif
      
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
               if (loc != start) flag("Function Adding Code Inline");

               #if 0
               i = vvalue;
               vvalue = prevalue;
               #endif

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
   
   #if 1
   if (ifdepth != prelif) note("Automatic Endif");
   ifdepth = prelif;
   #endif

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

   #if 0
   vvalue = prevalue;
   #endif

   #ifdef POPREL
   mapinfo = savel;
   #endif

   if (!skipping) note("Automatic Function Return Value");
   if (loc != start) flag("Function Adding Code Inline");
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
      while (symbol = *d++)
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

   while (symbol = *from++)
   {
      if (length == FILENAME_LIMIT-5) break;
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
      while (symbol = *extension++)
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
   lr = (object *) ((long) lr + length);
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
   #if 1
   if ((lix) && (pass) && (list > depth) && (selector['L'-'A']))
      printf("  :                            %d: %s\n", ll[depth], plix);

   lix = 0;
   plix[0] = 0;
   #endif

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
      flag_either_pass(file_label[depth]->l.name, "file missing");
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

#endif

#ifdef CODED_EXPRESS
static long coded_character(int symbol)
{
   long           x = symbol;

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
      if (i = (left->b[c] - right->b[c])) break;
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

#ifdef	LINEAR

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

#else	/* LINEAR	*/

static void operand_reverse(line_item *o)
{
   int i = RADIX/32;

   while (i--)
   {
      o->i[i] ^= 0xffffFFFF;
   }
}

static void operand_or(line_item *left, line_item *right)
{
   int i = RADIX/32;

   while (i--)
   {
      left->i[i] |= right->i[i];
   }
}

static void operand_and(line_item *left, line_item *right)
{
   int i = RADIX/32;

   while (i--)
   {
      left->i[i] &= right->i[i];
   }
}

static void operand_xor(line_item *left, line_item *right)
{
   int i = RADIX/32;

   while (i--)
   {
      left->i[i] ^= right->i[i];
   }
}

#endif	/* LINEAR	*/

#endif	/* DOS		*/

#ifdef INTEL

static void operand_addcarry(unsigned short carry, line_item *o)
{
   int		 	i = RADIX/8;
   unsigned long	c = carry;

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

#if 0
static void operand_add_upper(line_item *left, line_item *right)
{
   unsigned short c = 0;
   int i = 12;
   while (i--)
   {
      c += left->b[i];
      c += right->b[i];
      left->b[i] = c;
      c >>= 8;
   }
   if (!twoscomp) operand_addcarry(c, left);
}
#endif

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
   unsigned long	 carry = c;

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

   unsigned			 long c;


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

   unsigned			 long c;


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

   unsigned			 long c;


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
   unsigned long	 c = 0;
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

#if 0
static void operand_add_upper(line_item *left, line_item *right)
{
   unsigned short c = 0;
   int i = 12;
   while (i--)
   {
      c += left->b[i];
      c += right->b[i];
      left->b[i] = c;
      c >>= 8;
   }
   if (!twoscomp) operand_addcarry(c, left);
}
#endif

static void operand_add_negative(line_item *left, line_item *right)
{
   unsigned long	 c = twoscomp;
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
   unsigned long	 c = 0;
   
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

   long				 i = 0, ires;

   char				*d,
				*margin;

   unsigned short		 c;
   short			 x;
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

   #if 1
   *sp = zero_o;
   #else
   *sp = o[0];
   #endif
   
   #ifdef RELOCATION
   mapx->m.i = 0;
   mapx->scale = 0;
   #endif

   if (s == e) return sp;
   
   #ifdef VERY_STACKED_XPRESSION
   if ( sp <  &ostac[2])
   {
      flagg("expression too deep\n");
      return sp;
   }
   #else
   if ( sp <  &o[2])
   {
      flagg("expression too deep\n");
      return sp;
   }
   #endif

   if (d = contains(s, e, "=\0"))
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
   
   if (d = contains(s, e, "^=\0"))
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
   
   if (d = contains(s, e, ">\0"))
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
   
   if (d = contains(s, e, "<\0"))
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
   

   if (d = contains(s, e, "--\0")) 
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

   if (d = contains(s, e, "++\0")) 
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

   if (d = contains(s, e, "/*\0")) 
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

   if (d = contains(s, e, "*/\0")) 
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

   if (d = contains(s, e, "**\0"))
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
      return sp;
   }

   if (d = contains(s, e, "*+\0*-\0"))
   {
      #ifdef REVISE_UNARY
      c = *s;
      if ((c == '+') || (c == '-') || (c == '^')) c = *(s + 1);
      #else 
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
      #endif

      transient_floating_bits = fpwidth;

      margin = d;
      override = *(margin - 2);
      symbol   = *(margin - 1);

      if ((override == ')')  || (override == ':')
      ||  (override == '\'') || (override == qchar))
      {
         if (x = length_mark(symbol))
         {
            margin -= 2;
            transient_floating_bits = x;
         }
      }
      else
      {
         #ifndef REVISE_UNARY
         c = *s;
         #endif

         if (((c == '0') && (symbol ^ 'd') && (symbol ^ 'D'))
         ||  ((c == '0') && (octal))
         ||  ((c  > '0') && (c < '9'+1)))
         {
            if (x = length_mark(symbol))
            {
               margin--;
               transient_floating_bits = x;
            }
         }
      }

      if (transient_floating_bits > RADIX) transient_floating_bits = RADIX;
      transient_floating_bits /= word;
      transient_floating_bits *= word;

      if (pass)
      {
         xpression(s, margin, param);
         sp--;
         i -= expression(d+2, e, param);
         if (*(d + 1) == '-') i = 0 - i;
         sp++;

         #ifdef REVISE_UNARY
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
         #else
         characterise(i, sp);
         floating_position(transient_floating_bits, sp);
         #endif
      }

      return sp;
   }
   #endif       /*      FP_EARLIER        */

   if (d = contains(s, e, "-\0+\0"))
   {
      /*******************************************************
         this precaution here allows unary signs to follow
         after multiply/divide/shift operators without
         getting mistaken for add/subtract operators
      *******************************************************/

      #if 1
      symbol = *(d-1);
      if ((symbol != '*')
      &&  (symbol != '/')
      &&  (symbol != '+')
      &&  (symbol != '-'))
      {
      #endif
	    /*
	    if (*d == '+') return expression(s, d, param)
				+ expression(d+1, e, param);
      
	    if (*d == '-') return expression(s, d, param)
				- expression(d+1, e, param);
	    */
      
	 if (*d == '+')
	 {
	    left = xpression(s, d, param);
	    sp--;
	    
	    #ifdef RELOCATION
	    left_side = mapx->m;
            #endif

	    right = xpression(d+1, e, param);
	    operand_add(left, right);
	    sp++;

	    #ifdef RELOCATION
            #ifdef MULTUPLES

	    if (mapx->m.l.y)
            {
               #if 0
               link_profile *zu = mapinfo;
               #endif

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
            #ifdef MULTUPLES
            {
               #if 0
               link_profile *u7 = mapinfo;
               while (u7 <= mapx)
               {
                  printf("[F %2.2x R %2.2x X %4.4x]\n",
                  u7->m.l.y,
                  u7->m.l.rel,
                  u7->m.l.xref);
                  u7++;
               }
               #endif
            }
            #endif

	    left = xpression(s, d, param);
	    sp--;
	    
	    #ifdef RELOCATION
	    left_side = mapx->m;
            #endif
            c = transient_floating_bits;
	    right = xpression(d+1, e, param);

            #ifdef REVISE_UNARY
            if ((c == 0) && (transient_floating_bits))
            {
               /*****************************************

		-unary has become effectively 0 - token

                prevent floating number from accidentally
                getting 2s-complemented. It must be
                1s-complemented

		this only arises where the unary minus
		is outside (parentheses) which contain
		all fields of the floating number
		as -(1.5*+exponent)

		it's never necessary to do that but
		someone might. It's not intuitive in
		that event to realise that you are about
		to 2-s complement the floating number

		and not nice to expect anyone to realise
		so we guard it here

               *****************************************/

               if (twoscomp) flag("floating cast to integer yields a wrong value");
            }
            #endif

	    operand_add_negative(left, right);
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
      #if 1
      }
      #endif
   }
   

   if (d = contains(s, e, "///\0//\0/\0*\0"))
   {
      /*
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
      */
      
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
   if (d = contains(s, e, "*+\0*-\0"))
   {
      if ((*s == '-') || (*s == '^'))
      {
         xpression(s + 1, e, param);
         operand_reverse(sp);
         return sp;
      }

      xpression(s, d, param);
      sp--;
      i -= expression(d+1, e, param);
      sp++;
      characterise(i, sp);

      #if 1
      floating_position(transient_floating_width, sp);
      #else
      if (sp < &o[XPRESSION])
      {
         floating_position(fpwidth, sp);
      }
      #endif

      return sp;
   }
   #endif	/*	FP_LATER	*/

   #ifdef PROMOTE_UNARY
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
      if (contains(s, e, "*+\0*-\0"))
      {
      }
      else operand_addcarry(twoscomp, sp);
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
      while (ires = *s++)
      {
	 if (ires == 0x27)
	 {
	    ires = *s++;
	    if (ires != 0x27) break;
	 }

         #ifdef CODED_EXPRESS
         ires = coded_character(ires);
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

   if (selector['M'-'A'])
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
 
   if (selector['C'-'A'])
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

               #if 0
               else
               {
                  sp->i[RADIX/32-1] = (long) 0;	/* it is already */
               }
               #endif

               return sp;
            }
            #endif
	    
	    #ifdef RELOCATION
	    if (l->l.r.l.y) mapx->m = l->l.r;
            else            mapx->m.l.rel = l->l.r.l.rel;
	    #endif

            #ifdef XTENDA
            if (selector['i'-'a'])
            {
               if (l->l.value.b[RADIX/8-4] & 128) *sp = minus_o;
            }
            #endif

	    sp->i[RADIX/32-1] = l->l.value.i[RADIX/32-1];

            if ((address_size < 32)
            &&  (selector['i'-'a'] == 0)) sp->b[RADIX/8-4] &= 127;

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
               if (v = (value *) q->runbank)
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

            if ((selector['i'-'a'] == 0) && ((i ==    LOCTR)
                                         ||  (i == ABSOLUTE)
                                         ||  (i ==      NET)))
            {
            }
            else
            {
	       if (ires < 0) *sp = minus_o;
            }

            quadinsert(ires, sp);
	    return sp;

	 case NAME:
	    #ifdef ESC

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
            

	    #else

	    l2 = (object *) l->l.down;
	    if ((!l2)
	    ||  (l2->l.type != LABEL)
	    ||  (l2->l.valued != FUNCTION)
	    ||  (l2 == active_procedure[masm_level]))
	    {
	       *sp = l->l.value;
	       return sp;
	    }
	    #endif
	 case FUNCTION:

            #ifndef ESC

	    if (l == active_procedure[masm_level]) 
	    {
	       #if 1
	    
	       return extract_xparam(label_margin, param);

	       #else
	    
               #ifdef PARAM
	       ires = rfunction(PARAM, label_margin, param, e, l);
	       #else
	       ires = extract_gparam(label_margin, param);
	       #endif
	       
	       if (ires < 0) *sp = minus_o;
               quadinsert(ires, sp);	       
	       return sp;
	       #endif
	    }

            #endif

            if ((uselector['Q'-'A'] == 0) &&  (*s == qchar))
            {
                *sp = l->l.value;
                return sp;
            }

            return external_function(label_margin, param, e, l);

	 case PROC:

            #ifdef ESC

            *sp = l->l.value;
            return sp;

            #else

	    if (l != active_procedure[masm_level])
            {
               *sp = l->l.value;
               return sp;
            }
	    
	    #if 1
	    return extract_xparam(label_margin, param);

	    #else
	    
            #ifdef PARAM
	    ires = rfunction(PARAM, label_margin, param, e, l);
	    #else
	    ires = extract_gparam(label_margin, param);
	    #endif
	    if (ires < 0) *sp = minus_o;
	    sp->b[RADIX/8-1] = ires;
	    sp->b[RADIX/8-2] = ires >> 8;
	    
	    sp->b[RADIX/8-3] = ires >> 16;
	    sp->b[RADIX/8-4] = ires >> 24;

	    return sp;

            #endif
	    #endif
	
	 default:
	    if (l->l.valued > 127)
	    {
	       *sp = l->l.value;
	       return sp;
	    }
      }
   }


   if (!pass) return sp;

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

static long ixpression(char *s, char *e, char *param)
{
   line_item		*o = xpression(s, e, param);

   #if RADIX==192
   return o->i[0] | o->i[1] | o->i[2] | o->i[3] | o->i[4] | o->i[5];
   #endif
   
   #if RADIX==96
   return o->i[0] | o->i[1] | o->i[2];
   #endif
}

#if defined(RESOLVE_ULTRA)||defined(ULTRA_RESOLVE)

/*********************************************************

where intermediate results longer than long must not
be lost but the result should fit in long

*********************************************************/

static long zxpression(char *s, char *e, char *param)
{
   line_item		*sp = xpression(s, e, param);

   #ifdef RANGE_WARNING
   range_warning(sp);

   #endif
   
   return quadextract(sp);
}

#endif

#ifdef VERY_STACKED_XPRESSION

static long expression(char *s, char *e, char *param)
{ 
   long			 y;
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

#ifdef EFLAG

static void eflag()
{
   printf("Error: %s Line %d: "
          "external value %s may not be used in this context\n",
           file_label[depth]->l.name,
           ll[depth],
           name);
   ecount++;
}

#endif

#ifdef DOS
#error you need VERY_STACKED_XPRESSION
#endif

static long expression(char *s, char *e, char *param)
{
   
   long				 i = 0, j;
   char				*d;

   char				 override = 0;

   object			*l;

   int				 symbol, v;

   #ifdef LTAG
   location_counter		*q;
   #endif

   if (s == e) return 0;
   
   if (d = contains(s, e, "=\0"))
   {
      if (expression(s, d, param)
      ==  expression(d+1, e, param)) return 1;
      else                           return 0;
   }
   
   if (d = contains(s, e, "^=\0"))
   {
      if (expression(s, d, param)
      !=  expression(d+2, e, param)) return 1;
      else                           return 0;
   }
   
   if (d = contains(s, e, ">\0"))
   {
      if (expression(s, d, param)
      >   expression(d+1, e, param)) return 1;
      else                           return 0;
   }
   
   if (d = contains(s, e, "<\0"))
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
   
   if (d = contains(s, e, "--\0")) return expression(s, d, param)
					^ expression(d+2, e, param);

   if (d = contains(s, e, "++\0")) return expression(s, d, param)
					| expression(d+2, e, param);

   if (d = contains(s, e, "/*\0")) return expression(s, d, param)
				       >> expression(d+2, e, param);
   
   if (d = contains(s, e, "*/\0")) return expression(s, d, param)
				       << expression(d+2, e, param);

   if (d = contains(s, e, "**\0")) return expression(s, d, param)
					& expression(d+2, e, param);

   if (d = contains(s, e, "-\0+\0"))
   {
      /*******************************************************
         this precaution here allows unary signs to follow
         after multiply/divide/shift operators without 
         getting mistaken for add/subtract operators
      *******************************************************/

      symbol = *(d-1);
      if ((symbol != '*')
      &&  (symbol != '/')
      &&  (symbol != '+')
      &&  (symbol != '-'))
      {
	 if (*d == '+') return expression(s, d, param)
			     + expression(d+1, e, param);
      
	 if (*d == '-') return expression(s, d, param)
			     - expression(d+1, e, param);
      }
   }
   
   if (d = contains(s, e, "///\0//\0/\0*\0"))
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
      while (symbol = *s++)
      {
         if (symbol == 0x27)
         {
	    symbol = *s++;
	    if (symbol != 0x27) return i;
         }

         #ifdef CODED_EXPRESS
         symbol = coded_character(symbol);
         #endif


         #ifdef CODED_EXPRESS
         i <<= byte;
         #else
         i <<= 8;
         #endif

         i |= symbol;
      }
      return i;
   }

   if (selector['M'-'A'])
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
    
   if (selector['C'-'A'])
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
               v = expression(label_margin + 1, e, param);

               if (v < 1)        return (long) 0;
               if (v > RADIX/32) return (long) 0;

               return (long) quadextractx(&l->l.value, v);
            }
            #endif

	    i = (long) quadextract(&l->l.value);
            if ((address_size < 32)
            &&  (selector['i'-'a'] == 0)) i &= 0x7FFFFFFF;

            return i;

	 #endif
	 case EQU:
	 case SET:
	 case LOCATION:
	 
	 #if 0
	 case LINELABEL:
	 #endif         

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
	    return (long) i;

            #ifdef LITERALS
            #ifdef LTAG
         case LTAG:
            j = l->l.r.l.rel & 127;
            i = literal(label_margin, param, j);
            q = &locator[j];
            if (q->flags == 1) i += vextractq((object *) q->runbank);
            return i;
            #endif
            #endif

	 case INTERNAL_FUNCTION:
	    i = qextractv(l);

	    if (*s == qchar) return i;
	    return rfunction(i, label_margin, param, e, l);

	 case NAME:
	    #ifdef ESC

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

	    #else
	    l2 = (object *) l->l.down;
	    if ((!l2)
	    ||  (l2->h.type != LABEL)
	    ||  (l2->l.valued != FUNCTION)
	    ||  (l2 == active_procedure[masm_level]))
	    {
	       (long) i = qextractv(l);
	       return (long) i;
	    }
	    #endif
	 case FUNCTION:
            #ifdef ESC

            if ((uselector['Q'-'A'] == 0)
            &&  (*s == qchar)) return qextractv(l);
            i = quadextract(external_function(label_margin, param, e, l));

            return i;

            #else
            #ifdef PARAM
	    if (l == active_procedure[masm_level]) 
	       return rfunction(PARAM, label_margin, param, e, l);
	    #else
	    if (l == active_procedure[masm_level])
	       return extract_gparam(label_margin, param);
	    #endif

            i = quadextract(external_function(label_margin, param, e, l));

	    return i;
            #endif
	 case PROC:
            #ifdef ESC
            return qextractv(l);
            #else
	    if (l != active_procedure[masm_level])
	    {
	       i = qextractv(l);
	       return i;
	    }
	    
	    #ifdef PARAM
	    return rfunction(PARAM, label_margin, param, e, l);
	    #else
	    return extract_gparam(label_margin, param);
	    #endif
            #endif
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

   eflag();

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
   object		*p = insert_qltable("$bits", bits, SET);

   if (p)
   {
      p->l.valued = SET;
      p->l.value.b[RADIX/8-1] = bits;
   }
   else
   {
      flag("$bits not added");
   }
}

#if 1
static void stringline(char *directive, char *param, txo *image)
#else
static void special_byte_output(char *directive, char *param, txo *image)
#endif
{
   line_item		 item = zero_o;
   int			 i = RADIX;
   
   int			 j, target, upward;
   int			 total = 0;

   line_item		 next;

   char			*limit;
   
   long			 datum, mask = ((long) 1 << byte) - (long) 1;

   #ifdef C_U
   int			 symbol, symbols;
   #endif

   directive = substitute(directive, param);

   for (;;)
   {
      if (*directive == qchar)
      {
	 directive++;
	 for (;;)
	 {
	    if (i < byte) 
	    {
	       target = RADIX-i;
	       if (upward=target%word)
	       {
		  next = item;
		  rshift(&item, upward);
		  target = target/word*word;
	       }
	       produce(target, '+', &item, image);
               total += target;
	       if (upward) item = next;
	       i = RADIX-upward;
	    }
	    if (*directive == qchar)
	    {  if (*(directive+1) == qchar) directive++;
	       else                               break;
	    }
	    if (*directive == 0) break;
	    lshift(&item, byte);
	    datum = *directive++;

            #ifdef C_U
            if (datum == '\\')
            {
               if (selector['c'-'a'])
               {
                  if (datum = *directive++)
                  {
                     switch (datum)
                     {
                        case 'n':
                           datum = 10;
                           break;
                        case 'r':
                           datum = 0x0d;
                           break;
                        case 'f':
                           datum = 12;
                           break;
                        case 't':
                           datum = 9;
                           break;
                        case 'v':
                           datum = 11;
                           break;
                        case 'b':
                           datum = 8;
                           break;
                        case 'a':
                           datum = 7;
                           break;

                        case 'x':
                           symbols = (byte+3)/4;
                           j = symbols;

                           datum = 0;

                           while (j--)
                           {
                              symbol = *directive;
                              if ((symbol > 0x60) && (symbol < 0x67))
                              {
                                 symbol &= 0x5F;
                              }

                              if ((symbol > 0x2F) && (symbol < 0x3A))
                              {
                                 symbol &= 15;
                              }
                              else
                              {
                                 if ((symbol  > 0x40) && (symbol < 0x47))
                                 {
                                    symbol -= 55;
                                 }
                                 else
                                 {
                                    if (pass)
                                    printf("byte = %d: %d hex symbols\n",
                                            byte, symbols);

                                    note("exact number of hexadecimal "
                                         "symbols expected here");
                                    break;
                                 }
                              }
                              datum <<= 4;
                              datum |= symbol;
                              directive++;
                           }

                           break;

                        default:
                           if (datum < '0') break;
                           if (datum > '7') break;

                           datum &= 7;

                           symbols = (byte-1)/3;
                           j = symbols;

                           while (j--)
                           {
                              symbol = *directive;

                              if ((symbol < '0') || (symbol > '7'))
                              {
                                    if (pass)
                                    printf("byte = %d: %d octal symbols\n",
                                            byte, symbols + 1);

                                    note("exact number of octal "
                                         "symbols expected here");

                                    break;
                              }

                              datum <<= 3;
                              datum |= symbol & 7;
                              directive++;
                           }

                     }
                  }
               }
            }
            #endif

            #ifdef CODED_EXPRESS
            datum = coded_character(datum);
            #else
	    if (code == DATA_CODE) datum = code_set[datum];
	    if ((byte < 7) && (code == ASCII)) datum =
		      ((datum & 64)>>1) | (datum & 31);
            #endif

	    datum &= mask;
	    
	    #ifdef INTEL
	    item.b[RADIX/8-1] |= datum;
	    item.b[RADIX/8-2] |= datum>>8;
	    item.b[RADIX/8-3] |= datum>>16;
	    item.b[RADIX/8-4] |= datum>>24;
	    #else
	    item.i[RADIX/32-1] |= datum;
	    #endif

	    i -= byte;
	 }
	 directive++;
      }
      if (*directive == sterm)
      {
	 directive++;
	 while (*directive == 32) directive++;
	 if (*directive == 0) return;
	 if (*directive != qchar)
	 {
	    limit = directive;
	    while ((*limit) && (*limit != sterm) && (*limit != 32)) limit++;
	    lshift(&item, byte);
            
            #ifdef RESOLVE_ULTRA
            datum = zxpression(directive, limit, param);
            #else
	    datum = expression(directive, limit, param);
            #endif
            
	    if ((byte < 7) && (code == ASCII)) datum =
		      ((datum & 64)>>1) | (datum & 31);
	    datum &= mask;
	    
	    #ifdef INTEL
	    item.b[RADIX/8-1] |= datum;
	    item.b[RADIX/8-2] |= datum>>8;
	    item.b[RADIX/8-3] |= datum>>16;
	    item.b[RADIX/8-4] |= datum>>24;
	    #else
	    item.i[RADIX/32-1] |= datum;
	    #endif

	    i -= byte;
	    directive = limit;
	    if (i < byte)
	    {
	       target = RADIX-i;
	       if (upward=target%word)
	       {
		  next = item;
		  rshift(&item, upward);
		  target = target/word*word;
	       }
	       produce(target, '+', &item, image);
               total += target;
	       if (upward) item = next;
	       i = RADIX-upward;
	    }
	 }   
      }
      if ((*directive != qchar) && (*directive != sterm)) break;
   }

   total += RADIX - i;
   
   while (j = (RADIX-i) % word)
   {
      if ((word-j) < byte) break;
      i -= byte;
      lshift(&item, byte);

      if (selector['c'-'a'] ^ selector['z'-'a'])
      {
      }
      else
      {
         if (code == ASCII)
         {
	    if (byte > 6) item.b[RADIX/8-1] |= 32;
         }
         else
         {
	    datum = code_set[32] & mask;

	    #ifdef INTEL
	    item.b[RADIX/8-1] |= datum;
	    item.b[RADIX/8-2] |= datum>>8;
	    item.b[RADIX/8-3] |= datum>>16;
	    item.b[RADIX/8-4] |= datum>>24;
	    #else
	    item.i[RADIX/32-1] |= datum;
	    #endif
         }
      }
   }

   target = RADIX - i;

   if (target)
   {
      if (upward = target%word)
      {
	 lshift(&item, word-upward);
	 note("trailing zero bits in last data word of string");
      }
      produce(target, '+', &item, image);
   }

   /*
   i = RADIX;
   */

   record_bits(total);
}

#if 0
static void stringline(char *directive, char *param, txo *image)
{
   line_item			 item = zero_o;
   int				 i = 0;

   int				 bits, j;
   char				*limit;
   register int			 datum;

   #ifdef C_U
   register int			 symbol;
   #endif

   
   directive = substitute(directive, param);
   
   
   if ((byte != EIGHT) || (word % 8))
   {
      special_byte_output(directive, param, image);
      return;
   }

   for (;;)
   {
      if (*directive == qchar)
      {
	 directive++;
	 for (;;)
	 {
	    if (i == RADIX/8) 
	    {
	       produce(RADIX, '+', &item, image);
	       i = 0;
	    }
	    if (*directive == qchar)
	    {  if (*(directive+1) == qchar) directive++;
	       else                               break;
	    }
	    if (*directive == 0) break;
	    datum = *directive++;

            #ifdef C_U
            if (datum == '\\')
            {
               if (selector['c'-'a'])
               {
                  if (datum = *directive++)
                  {
                     switch (datum)
                     {
                        case 'n':
                           datum = 10;
                           break;
                        case 'r':
                           datum = 0x0d;
                           break;
                        case 'f':
                           datum = 12;
                           break;
                        case 't':
                           datum = 9;
                           break;
                        case 'v':
                           datum = 11;
                           break;
                        case 'b':
                           datum = 8;
                           break;
                        case 'a':
                           datum = 7;
                           break;

                        case 'x':
                           j = 2;
                           datum = 0;

                           while (j--)
                           {
                              symbol = *directive;
                              if ((symbol > 0x60) && (symbol < 0x67))
                              {
                                 symbol &= 0x5F;
                              }

                              if ((symbol > 0x2F) && (symbol < 0x3A))
                              {
                                 symbol &= 15;
                              }
                              else
                              {
                                 if ((symbol  > 0x40) && (symbol < 0x47))
                                 {
                                    symbol -= 55;
                                 }
                                 else
                                 {
                                    note("exactly 2 hexadecimal symbols "
                                         "expected here");
                                    break;
                                 }
                              }
                              datum <<= 4;
                              datum |= symbol;
                              directive++;
                           }

                           break;

                        default:
                           if (datum < '0') break;
                           if (datum > '7') break;

                           datum &= 7;

                           j = 2;

                           while (j--)
                           {
                              symbol = *directive;

                              if ((symbol < '0') || (symbol > '7'))
                              {
                                 note("exactly 3 octal symbols expected here");
                                 break;
                              }

                              datum <<= 3;
                              datum |= symbol & 7;
                              directive++;
                           }

                     }
                  }
               }
            }
            #endif

	    if (code == DATA_CODE) datum = code_set[datum];
	    item.b[i++] = datum;
	 }
	 directive++;
      }
      
      if (*directive == sterm)
      {
	 directive++;
	 while (*directive == 32) directive++;

	 if (*directive == 0) break;

	 if (*directive != qchar)
	 {
	    limit = directive;
	    while ((*limit) && (*limit != sterm) && (*limit != 32)) limit++;
            
            #ifdef RESOLVE_ULTRA
            item.b[i++] = zxpression(directive, limit, param);
            #else
	    item.b[i++] = expression(directive, limit, param);
            #endif
            
	    directive = limit;
	    if (i == RADIX/8)
	    {
	       produce(RADIX, '+', &item, image);
	       i = 0;
	    }
	 }   
      }
      if ((*directive != qchar) && (*directive != sterm)) break;
   }


   #ifdef BYTE_BLOCK
   if (byte_block)
   {
   }
   else
   #endif

   while (i%(word/EIGHT))
   {
      if (selector['c'-'a'])
      {
         item.b[i++] = 0;
      }
      else
      {
         if (code == ASCII)
         {
   	    item.b[i++] = 32;
         }
         else
         {
	    item.b[i++] = code_set[32];
         }
      }
   }
   
   bits = i * 8;
   j = RADIX/8;
   while (i) item.b[--j] = item.b[--i];
   if (bits) produce(bits, '+', &item, image);
}
#endif

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

   long			 v = ii->i[0]
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
   
   while (temp = *p++) scale += temp;

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

   while (datum = *k)
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
	    l = (object *) ((long) l + l->h.length);
         }

         if (l->h.type == TEXT_SUBSTITUTE)
         {
	    c++;
	    k = forward;
	    while (aside[j++] = *c++);
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
   if ((lix) && (pass) && (list > depth) && (selector['L'-'A']))
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

      actual_block = block[depth];
      return 0;
   }

   if (tsubs) x = text_substitute(x, k);

   if (selector['S'-'A'])
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

   #if 0
   if (!(x|lix)) lix = 1;
   #else
   if ((!x) && (pass) && (list > depth) && (selector['L'-'A']))
   {
      printf("  :                            %d %s\n", ll[depth], plix);
      lix = 0;
      plix[0] = 0;
   }

   #endif

   return x;
}

static void quadza(long u, line_item *i)
{
   *i = zero_o;

   /*****************************************************
   zero fill is right for everything that calls this,
   and sign extension never is
   *****************************************************/
   #ifdef XTENDA
   if ((selector['i'-'a']) && (u < 0)) *i = minus_o;
   #endif

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

#ifdef ESC

static object *store_proc_index(char *line_label, char *directive, object *pid)
{
   char				*limit = NULL;
   line_item			*i = &zero_o;


   #ifndef ABOUND
   long valued = pid->l.valued;
   #endif

   object *l;

   char *argument = NULL;

   #ifndef DEEP_RECURS
   if (pass) return;
   #endif

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
 
   #ifdef DEEP_RECURS
   l->l.r.l.y = pid->l.r.l.y;
   l->l.r.l.rel = pid->l.r.l.rel;
   #else
   l->l.r.i = pid->l.r.i;
   #endif
   
   l->l.passflag = pid->l.passflag;

   #ifdef WALKP
   printf("$%d/%d\n", l->l.r.l.rel, l->l.r.l.y);
   #endif
         
   #ifdef ABOUND
   if (pid->l.valued ==     PROC) l->l.passflag |= 128;
   if (pid->l.valued == FUNCTION) l->l.passflag |=  64;
   #endif

   /*
   l->l.down = (void *) index - 1;
   */

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

   for (;;)
   {
      prior = symbol;
      symbol = *f++;
      if (!symbol) break;

      w = t;
      *t++ = symbol;

      if (symbol == qchar)
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
                  if (!symbol) break;
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

      if ((selector['k'-'a'] == 0) 
      &&  (symbol > 0x60)
      &&  (symbol < 0x7B)) symbol &= 0x5F;

      if ((symbol == sentinel)
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
            if (!symbol) break;
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
               break;
            }
            if (symbol != *c++) break;
         }
      }
      if (!symbol) break;
   }
   *t = 0;
   
   return t - x;
}

#ifdef DEEP_RECURS

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
   l->l.down = (void *) ((long) o + o->h.length);
   
   for (;;)
   {
      o = (object *) ((long) o + o->h.length);
      k = o->t.text;
      
      #ifdef TRACE_RECURS
      printf("retrieve image %s\n", k);
      #endif

      #ifdef FOLLOW_RECURS
      printf("retrieve image %s\n", k);
      #endif
     
      if (o->h.type == BYPASS_RECORD)
      {
         if (j = o->nextbdi.next) o = bank[j];
         else                     o = NULL;

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
      i = getline(slipline, 250);
      if (!i) continue;
         
      if (i < 0)
      {
         depth = 0;
         flag_either_pass(name[0], "procedure auto end. assembly abandoned");
         exit(-112);
      }
         
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
            #if 0
            else
            {
               j = TEXT_IMAGE;
            }
            #endif
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

               #ifdef LOOKFOR
               if (nest > 2) i = encode(lr->t.text,slipline,name[nest-3]);
               else          i = encode(lr->t.text,slipline, l->l.name);

               #if 1
               printf("encode3 %s for %s\n", slipline,
               (nest > 2) ? name[nest-3] : l->l.name);
               #endif

               #else
               strcpy(lr->t.text, slipline);
               #endif
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

         lr = (object *) ((long) lr + size);
         remainder -= size;
      }
      
      if (!nest) break;
   }
      
   #ifdef TRACE_RECURS
   printf("procedure store complete\n");
   #endif
}
   
#else		/*	DEEP_RECURS	*/

static void store_function(object *thislabel, int passflag)
{
   static int function_id;
   
   char *directive;
   int  size, i, j;

   char slipline[256];

   if (!thislabel)
   {
      flagp1("FUNCtion requires a label.");
      exit(0);
   }
   
   if (!pass)
   {
      i = function_id++;
      quadza(i, &thislabel->l.value);
      thislabel->l.r.i = 0;

      /*
      thislabel->l.r.l.xref = i;
      */

      thislabel->l.passflag = passflag;

      /*
      thislabel->l.down = thislabel;
      */
   }
   
   for (;;)
   {
     /*
      k = slipline;
      if (!pass)
      {
	 if (remainder < 256)
	 {
	    flagp1("Text for Store Too Late in Assembly");
	    break;
	 }
	 k = lr->t.text;
      }
      
      i = getline(k, 250);
      */

      i = getline(slipline, 250);

      if (!i) continue;

      if (i < 0)
      {
         depth = 0;
	 flag_either_pass(name, "Fatal Error: Func Auto End.");
	 exit(-112);
      }
      
      directive = getop(slipline);
      j = TEXT_IMAGE;
      if (directive) j = meaning(directive);

      if (!pass)
      {
         if (j == NAME)
         {
	    store_proc_index(slipline, directive, thislabel);
	    continue;
         }

         if (j != END) j = TEXT_IMAGE;
	 
	 size = sizeof(header_word) + i + (1+PARAGRAPH-1); 
	 size &= -PARAGRAPH;

	 if (remainder < size) buy_ltable();
   
         i = encode(lr->t.text, slipline, thislabel->l.name);

	 lr->h.type = j;
	 lr->h.length = size;

	 (long) lr += size;
	 remainder -= size;
	 
      }
      if (j == END) break;
   }
}

static void store_proc_text(object *thislabel)
{
   static int procname = 0;
   
   int i, j, size;
   
   char *directive, slipline[256];

   
   if (!thislabel)
   {
      flagp1("PROC requires a label.");
      exit(0);
   }
   
   if (!pass)
   {
      thislabel->l.valued = PROC;
      i = procname++;
      quadza(i, &thislabel->l.value);
      
      thislabel->l.r.l.xref = i;

      /*
      thislabel->l.down = thislabel;
      */
   }
   
   for (;;)
   {
      /*
      k = slipline;
      
      if (!pass)
      {
	 if (remainder < 256) 
	 {
	    flagp1("Text for Store Too Late in Assembly");
	    break;
	 }
	 k = lr->t.text;
      }
      
      i = getline(k, 250);
      */

      i = getline(slipline, 250);

      if (!i) continue;
      
      if (i < 0)
      {
         depth = 0;
	 flag_either_pass(name "Fatal Error:Proc Auto End.");
	 exit(-111);
      }
      
      directive = getop(slipline);
      
      j = TEXT_IMAGE;
      if  (directive) j = meaning(directive);
      
      if (!pass)
      {
         if (j == NAME)
         {
	    store_proc_index(slipline, directive, thislabel);
	    continue;
         }

         if (j != END) j = TEXT_IMAGE;

	 size = sizeof(header_word) + i + (1+PARAGRAPH-1);
	 size &= -PARAGRAPH;

	 if (remainder < size) buy_ltable();

         i = encode(lr->t.text, slipline, thislabel->l.name);

         lr->h.type = j;
	 lr->h.length = size;
	 (long) lr += size;
	 remainder -= size;
      }
      if (j == END) break;
   }
}

#endif		/* DEEP_RECURS	*/

#else		/*	ESC	*/

static void store_proc_index(char *line_label, char *directive, int passes,
			     object *pid)
{
   char *limit;
   line_item *i = &zero_o;

   object *l;

   char *argument = NULL;

   if (pass) return;

   argument = getop(directive);
   
   if (argument)
   {
      limit = edge(argument, ", ");
      i = xpression(argument, limit, NULL);
   }
   else note("Value Expected with $NAME");

   l = insert_ltable(line_label, limit, i, NAME);
   
   if (!l)
   {
      flagp1("Failed to Store SubAssembly(P) Entry Point");
      return;
   }
   
   l->l.r.i = 0;
   l->l.passflag = passes;
   
   l->l.down = pid;
   l->l.r = pid->l.r;
}

static void store_function(object *thislabel, int passflag)
{
   static int function_id;
   
   char *directive;
   int  size, i, j;

   char *k, slipline[256];

   if (!thislabel)
   {
      flagp1("FUNCtion requires a label.");
      exit(0);
   }
   
   if (!pass)
   {
      /*
      thislabel->l.valued = EXTERNAL_FUNCTION;
      */
      quadza(function_id++, &thislabel->l.value);
      thislabel->l.r.i = 0;
      thislabel->l.r.l.xref = masm_level;
      thislabel->l.passflag = passflag;
      thislabel->l.down = qextractv(thislabel);
   }
   
   for (;;)
   {
      k = slipline;
      if (!pass)
      {
	 if (remainder < 256)
	 {
	    flagp1("Text for Store Too Late in Assembly");
	    break;
	 }
	 k = lr->t.text;
      }
      
      i = getline(k, 250);
      if (!i) continue;
      
      if (i < 0)
      {
         depth = 0;
	 flag_either_pass(name, "Fatal Error: Func Auto End.");
	 exit(-112);
      }
      
      directive = getop(k);
      j = TEXT_IMAGE;
      if (directive) j = meaning(directive);
      if (j == NAME)
      {
	 store_proc_index(lr->t.text, directive, passflag, thislabel);
	 continue;
      }
      if (j != END) j = TEXT_IMAGE;

      if (!pass)
      {
	 size = sizeof(header_word) + i + (1+PARAGRAPH-1); 
	 size &= -PARAGRAPH;
	 
	 if (remainder < size) buy_ltable();
	 
	 lr->h.type = j;
	 lr->h.length = size;

	 (long) lr += size;
	 remainder -= size;
	 
      }
      if (j == END) break;
   }
}

static void store_proc_text(object *thislabel)
{
   static int procname = 0;
   
   int i, j, passes = 1, size;
   
   char *directive, *k, slipline[256];

   
   if (!thislabel)
   {
      flagp1("PROC requires a label.");
      exit(0);
   }
   
   if (!pass)
   {
      thislabel->l.valued = PROC;
      quadza(procname++, &thislabel->l.value);
      if (*label_margin == '*') passes = 2; 
      
      thislabel->l.r.l.xref = 0;
      /*
      thislabel->l.r.l.xref = masm_level;
      */

      thislabel->l.passflag = passes;
      thislabel->l.down = qextractv(thislabel);
   }
   
   for (;;)
   {
      k = slipline;
      
      if (!pass)
      {
	 if (remainder < 256) 
	 {
	    flagp1("Text for Store Too Late in Assembly");
	    break;
	 }
	 k = lr->t.text;
      }
      
      i = getline(k, 250);
      if (!i) continue;
      
      if (i < 0)
      {
         depth = 0;
	 flag_either_pass(name, "Fatal Error:Proc Auto End.");
	 exit(-111);
      }
      
      directive = getop(k);
      
      j = TEXT_IMAGE;
      if  (directive) j = meaning(directive);
      
      if (!pass)
      {
	 switch (j)
	 {
	    case NAME:
	       store_proc_index(lr->t.text, directive, passes, thislabel);
	       continue;
	    case END:
	       lr->h.type = END;
	       break;
	    default:
	       lr->h.type = TEXT_IMAGE;
	       break;
	 }
	 size = sizeof(header_word) + i + (1+PARAGRAPH-1);
	 size &= -PARAGRAPH;

	 if (remainder < size) buy_ltable();

	 lr->h.length = size;
	 (long) lr += size;
	 remainder -= size;
      }
      if (j == END) break;
   }
}

#endif		/*	ESC	*/


static void decide(char *arg, char *param)
{
   char			*limit;
   long			 i;

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
   

//   skipping = 1;

   limit = first_at(arg, " ");
   
   #if 1
   i = ixpression(arg, limit, param);
   #else
   if (selector['V'-65]) i = ixpression(arg, limit, param);
   else                  i = expression(arg, limit, param);
   #endif

   skipping = 1;
   if (!i) return;

   skipping = 0;

   skipstate  &= unmask;
   satisficed |=   mask;
}

static void newdecide(char *arg, char *param)
{
   char				*limit;
   long				 i;

   int				 mask, unmask;
   
//   skipping = 0;
   
   if (!ifdepth) return;
   
   mask = 1 << ifdepth;

//   skipping = 1;
   skipstate |= mask;

   if (satisficed & mask)
   {
      skipping = 1;
      return;
   }

   if (skipstate & (mask >> 1)) return;

   limit = first_at(arg, " ");

   skipping = 0;
   
   #if 1
   i = ixpression(arg, limit, param);
   #else
   if (selector['V'-65]) i = ixpression(arg, limit, param);
   else                  i = expression(arg, limit, param);
   #endif

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

   if (i) printf("file state %d problem writing output\n", i);
   
   l = compose_filename(arg, ".txo", 0);
   i = qextractv(l);

   if (i < 0)
   {   
      remove(l->l.name);
      i = rename(OBIN, l->l.name);
      if (i) printf("file state %d problem storing %s\n", i, l->l.name);
      return;
   }

   printf("output file %s is also an input file. not written\n"
          "output is in temp.txo\n", l->l.name);
}


static int iterate(char *arg, char *param, object *tag, txo *image)
{
   char			*limit;
   long			 x;
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
      tag->l.r.l.y = 0;
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

      #if 1
      thislabel->l.r.i   = 0;
      #endif

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
   long				 mask = (1<<byte)-1;
   long				 datum;


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
   
   #if 0
   if (zero_fill == 0)
   {
      for (;;)
      {
         if (byte > bits) break;
         bits -= byte;
         lshift(item, byte);
         if (code == ASCII)
         {
	    if (byte > 6) item->b[RADIX/8-1] |= 32;
         }
         else
         {
	    datum = code_set[32] & mask;

            #ifdef INTEL
	    item->b[RADIX/8-1] |= datum;
	    item->b[RADIX/8-2] |= datum >>  8;
            item->b[RADIX/8-3] |= datum >> 16;
            item->b[RADIX/8-4] |= datum >> 24;
            #else
            item->i[RADIX/32-1] |= datum;
            #endif
         }
      }

      if (bits) note("byte string inexact fit");
   }
   #endif

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
				 y = RADIX/8,
				 guard = 0xE0;


   if (uselector['G'-'A']) guard &= 0xC0;
   if (uselector['F'-'A']) guard &= 0xA0;
   
   #ifdef ROUND3

   if (bytes == 3)
   {
      carry = guard + item->b[RADIX/8-3];
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
   unsigned long sum = scale - 1;
   #else
   unsigned long sum = (scale + 1) >> 1;
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
      write16(w, (int) quo, item);
      w++;
   }
}


static void floating_raise(int w, int scale, line_item *item)
{
   int			 i = RADIX/16;
   unsigned short	 digit = 0, hu;
   unsigned long	 ju;
   
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

static void characterise(long places, line_item *item)
{
   unsigned long	 bias;

   #if 0
   int			 sign = item->b[0] & 128;

   if (sign) operand_reverse(item);
   #endif

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
 
   if (bias & 0xFF800000) note(" Floating Exponent Overflow ");

   item->b[0] = bias >> 16;
   item->b[1] = bias >>  8;
   item->b[2] = bias;

   #if 0
   if (sign) operand_reverse(item);
   #endif
}

static void floating_generate(char *a, char *margin, char *param, line_item *item)
{
   char			*limit;
   long			 places = 0; 

   #ifdef INTEL
   unsigned short	 carry;
   #else
   unsigned long	 carry;
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

   transient_floating_bits = fpwidth;

   if (carry == ':')
   {
      carry = *a++;
   }

   if (i = length_mark(carry))
   {
       transient_floating_bits = i;
       carry = *a++;
   }

   if (transient_floating_bits > RADIX) transient_floating_bits = RADIX;
   transient_floating_bits /= word;
   transient_floating_bits *= word;   

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
   int			 carry, xlow_1, xlow_2;	
   #endif

   characteristic = characteristic_width[(bits-1)/word];

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
      carry = single_bit(RADIX - bits - 1, item);

      #ifdef ROUND3
      if (uselector['F'-'A'] == 0) carry |= single_bit(RADIX - bits - 2, item);
      if (uselector['G'-'A'] == 0) carry |= single_bit(RADIX - bits - 3, item);
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

#ifdef FFLOATING_POINT
static void floating_point(int bits, char unary, char *a, char *search, char *param,
                           line_item *item, txo *image)
{
   floating_generate(a, search, param, item);

   if (transient_floating_bits)
   {
      if (bits)
      {
         if (bits ^ transient_floating_bits) note("receiving field resized");
      }

      bits = transient_floating_bits;
      transient_floating_bits = 0;
   }

   if (!bits) bits = fpwidth;
   if (bits > RADIX) bits = RADIX;
   bits = bits / word * word;

   floating_position(bits, item);

   if ((unary == '-')
   ||  (unary == '^')) lproduce(bits, '^', item, image);
   else                lproduce(bits, '+', item, image);
}

#endif	/* FFLOATING_POINT*/
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
   
   int			 i, j, bits = 0, spotted,
                         commas = 0, slice,
                         known = -1, type = -1;
                         
   line_item		*oo;
   char			*limit;
   char			 xmask, ymask;
   char *fpo;
   char			*v_argument = NULL;

   object		*toplabel, *x, *depx;
   line_item		*ii;
   long			 savelocator[LOCATORS];
   long			 savelocatorl[LOCATORS];
   int			 savepass, subfunction;
   char			*nlabel, *ndirect;
   unsigned char	*subtext;
   char			*directive /* = getop(line_label) */; 
   long			 v;
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
         subfunction = expression(limit, search, param);
         argument = getop(search);
      }
   }


   if ((*line_label) && (*line_label != 32))
   {
      i = LOCATION;

      if (type == DIRECTIVE)
      {
         i = known;

         if (i == EQU)
         {
            if (subfunction < 0)
            {
            }
            else i = subfunction;
         }

         #ifdef RECORD
         if (known == RECORD) i = EQUF;
         #endif
      }

      if (i == RES) i = LOCATION;

      #ifdef STRUCTURE_DEPTH
      if (i == BRANCH) i = LOCATION;
      if (i == TREE)   i = LOCATION;

      if ((type  == DIRECTIVE)
      &&  (known ==    BRANCH)
      &&  (branch_present & (1 << active_x))
      &&  (loc == branch_high[active_x])
      &&  (depx = active_instance[active_x])) loc = qextractv(depx);

      #endif
	    
      #ifdef FPEQU
      if (i == FPEQU) i = SET;
      #endif

      if (i == DO) i = SET;

      #ifdef BINARY
      if (i == PUSHREL) i = EQUF;
      #endif

      #if 0
      if ((type == PROC)
      || ((type == NAME) && (sr->l.passflag & 128)))
      {
         if (sr->l.r.l.rel != counter_of_reference) i = BLANK;
      }
      #endif

      if (*line_label == '*') 
      {
	 if (above)
	 {
	    thislabel = above;


            j = thislabel->l.valued;
            thislabel->l.valued = i;


	    if (i == LOCATION)
	    {
               thislabel->l.r.l.y = 0;
               quadza(loc, &item);

               if (i = actual->flags & 129)
               {
                  if (i & 128)
                  {
                     item.b[RADIX/8-5] = actual->rbase;
                     thislabel->l.valued = EQUF;
                  }

                  if (i  == 1)
                  {
                     operand_add(&item, &((value *) actual->runbank)->value);
                  }
               }
               else
               {
   	          if (actual->relocatable)
	          {
	   	     thislabel->l.r.l.y |= 1;
	          }
               }


	       thislabel->l.r.l.rel = counter_of_reference;
               
               if (pass)
               {
                  if (j != BLANK) checkwave(&item, thislabel);
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
            while (symbol = *ndirect++)
            {
               *limit++ = symbol;
               if (symbol == qchar) break;
            }

            while (symbol = *ndirect++)
            {
               if (symbol != '*') break;
               *limit++ = symbol;
            }

            *limit = 0;

	    ndirect = substitute(name, param);
         }

         #ifdef DEEP_RECURS
         if ((i == PROC) || (i == FUNCTION))
         {
            #ifdef LOOKFOR
            ndirect = substitute(ndirect, param);
            directive = getop(ndirect);
            #endif

            x = floatop;
            masm_level++;

            #ifdef TRACE_RECURS
            printf("[++%s:%d:%s]\n", ndirect, masm_level, param);
            #endif
            
            #ifdef FOLLOW_RECURS
            printf("++%s:%d\n", ndirect, masm_level);
            #endif

            embed_procedure(i, ndirect, getop(directive));

            pack_ltable(x);

            masm_level--;
            
            return 0;
         }
         #endif

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

            if (sr->l.r.l.y   &  1) i = BLANK;
         }

         #if 0
         if ((type  == DIRECTIVE)
         &&  (known ==    BRANCH)
         &&  (branch_present & (1 << active_x))
         &&  (sr = active_instance[active_x])) loc = qextractv(sr);
         #endif

	 thislabel = insert_qltable(ndirect, loc, i);
      }
   }

   if (!directive) return 0;

   if (type < 0)
   {  
      if (*directive == qchar)
      {
         stringline(directive, param, image);
         return 0;
      }
   
      unary = *directive;

      #ifdef REVISE_UNARY
      if ((unary > '0'-1) && (unary < '9'+1)) unary = 0;
      if (unary == '\'') unary = 0;
      #endif

      if ((unary == '+') || (unary == '-') || (unary == '^') || (unary == 0))
      {
         argument = directive;

         #ifdef REVISE_UNARY
         if (unary)
         {
            if (*(argument + 1) == ' ') argument++;
            else unary = '+';
         }
         else unary = '+';
         #else
         argument++;
         #endif

         #if 0
         if (*argument == '(')
         {
  	    unary = '+';
	    argument--;
         }

         while (*argument == 32) argument++;

         #else

         symbolb4 = unary;

         while ((symbol = *argument) == 32)
         {
            symbolb4 = symbol;
            argument++;
         }

         #endif

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

            #ifdef FFLOATING_POINT
	    if ((*search == '.') && (*argument > 0x2f) && (*argument < 0x3a))
	       spotted = 1;
            #endif

	    if ((*search == ',') && (!parenthesised) && (!squoted)) commas++;
	    search++;
         }

         search--;
         while (*search == 32) search--;

         bits = 0;
         i = frightmost(argument, search);

         #if 1

         spotted = *(search-1);
         symbol = *search;

         if ((spotted == ':')
         ||  (spotted == ')')
         ||  ((i  > '0') && (i < '9'+1))
         ||  ((i == '0') && (symbol ^ 'd') && (symbol ^ 'D'))
         ||  ((i == '0') && (octal))
         ||  (spotted == '\'')
         ||  (spotted == qchar)) bits = length_mark(symbol);

         if (bits)
         {
            if (spotted == ':') search--;
         }
         else search++;

         #else

         if ((*(search - 1) == ':') 
         ||  (*(search - 1) == ')')
         ||  ((i > 0x30) && (i < 0x3a)) 
         ||  ((i == '0') && (*search != 'd') && (*search != 'D'))
         ||  ((i == '0') && (octal))
         ||  (*(search - 1) == 0x27)
         ||  (*(search - 1) == qchar))
         /*
         ||  ((*argument > 0x2f) && (*argument < 0x3a))
         ||  (*argument == 0x27)
         ||  (*argument == qchar))
         */
         {
            bits = length_mark(*search);
         }


         if (!bits) search++;
         if (*(search-1) == ':') search--;

         #endif

         #ifdef FPASS1
         if ((!pass) && (bits)) 
         {
	    produce(bits, '+', &item, image);
	    return 0;
         }
         #endif

         #if 0
         transient_floating_width = fpwidth;
         if (bits) transient_floating_width = bits;
         #endif

         if (commas)
         {
   	    if (!bits) bits = word;
	 
	    if (pass)
	    {
	       commas++;
	       slice = bits/commas;

               #if 0
               transient_floating_width = slice;
               #endif

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
                        if (vv = (value *) qq->runbank)
                        {
                           liti = vv->value;
                           quadd_u(v, oo);
                        }
                     }

                     #endif
	          }
	          else
	          #endif

	          oo = xpression(argument, limit, param);
	          i = slice & 7;
	          j = slice >> 3;
  	          xmask = 255 << i;
	          ymask = xmask ^ 255;
	          i = RADIX/8;
	          while (j--)
	          {
		     i--;
		     item.b[i] = oo->b[i];
	          }
	          if (ymask)
	          {
		     i--;
	 	     item.b[i] &= xmask;
		     item.b[i] |= oo->b[i] & ymask;
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

         #ifdef FLOATING_POINT

	 #ifdef FFLOATING_POINT
         if (spotted)
         {
 	    floating_point(bits, unary, argument, search, param, &item, image);
	    return 0;
         }
         #endif

         #if 0
         fpo = contains(argument, search, "*+\0*-\0");

         if (fpo)
         {
            if (!bits) bits = fpwidth;
            item = *xpression(argument, search, param);

            #if 0
            floating_position(bits, &item);
            #endif

            if (unary == '-') unary = '^';
            lproduce(bits, unary, &item, image);
            return 0;
         }
         #endif
         #endif
   
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
               if (vv = (value *) qq->runbank)
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
               if (bits ^ transient_floating_bits) note("field is size of floating number\n"
	       "\t\twords given tag may follow the fraction +1234.567[[:]{sdtqpho}][*+exponent]");
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
      
         #if 0
	 subfunction = -1;
	 limit = edge(directive, ", ");

	 if (*limit++ == ',')
	 {
	    while (*limit == 32) limit++; 
	    search = edge(limit, " ");
	    subfunction = expression(limit, search, param);
	    argument = getop(search);
	 }
         #endif
         
	 switch (known)
	 {
	    #ifdef LITORG
	    case LITORG:
	       if (!pass) break;
	       if (actual->litlocator > loc)
	       loc = actual->litlocator;
	       if (loc > actual->litlocator)
	       actual->litlocator = loc;
	       actual->locator = loc;
	       printf("[%8.8lx/%8.8lx]", loc, actual->litlocator);
	       outstanding = 1; /* outcounter(1); */
	       linex = 0;
	       break;
	       #endif

	    case END:
	       if ((argument) && (pass))
	       {
                  limit = first_at(argument, " ");
                  oo = xpression(argument, limit, param);

                  #ifdef RELOCATION

                  if (mapx->m.l.y & 128)
                  {
                     flag("transfer target must be code "
                          "loaded in this assembly");

                     return END;
                  }

                  i = mapx->m.l.rel;
                  i &= 127;

                  #if 1
                  if ((!i)
                  &&  (!(mapx->m.l.y & 1))
                  &&  (locator[0].relocatable))
                  {
                     flag("absolute transfer address in relocatable $(0)");
                     return END;
                  }
                  #endif

                  #else

                  i = 0;
                  sr = findlabel(argument, limit);
                  if (sr) i = sr->l.r.l.rel & 127;

                  #endif

                  qq = &locator[i];
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
                        vv = (value *) qq->runbank;
                        operand_add(oo, &vv->value);
                     }

                     write(ohandle, "\n>", 2);
                     pushh2(i);

                     write(ohandle, "::", 2);

                     xpushaddress(oo, i);
                     write(ohandle, "\n", 1);
                     return END;
                  }

                  v = quadextract(oo);
                  outcounter(i, v, "\n>");
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

                     if (selector['s'-'a'])
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

               #ifndef DEEP_RECURS
	    case PROC:
	       #ifdef PROCLOC
	       #if 1
	       if (!pass)
	       {
	 	  thislabel->l.r.i = 0;
                  thislabel->l.passflag = 1;
		  if (argument)
		  {
                     if (*argument == '*')
                     {
                        thislabel->l.passflag = 2;
                        argument++;
                        while (*argument == 32) argument++;
                     }

                     if (*argument)
                     {
 		        limit = edge(argument, "(");
		        i = expression(argument, limit, param);
		        if ((*limit == '(')
		        &&  (sr = findlabel(argument, limit))
		        &&  (sr->l.valued == INTERNAL_FUNCTION)
		        &&  (sr->l.value.b[RADIX/8-1] == LOCTR))
		        {
		           argument = limit+1;
		           limit = edge(argument, ")");
		           i = expression(argument, limit, param);

                           #ifdef WALKP
                           printf("$%d\n", i);
                           #endif

		           if ((i < 0) || (i > 71))
		           {
			      flagp1("Proc Automatic Locator Out of Range");
		           }
		           else
		           {
			      thislabel->l.r.l.y |= 1;
			      thislabel->l.r.l.rel = i;
                           }
		        }
                        else
   		        {
                           if (!pass) printf("[%2.2x]%s::",
                                      *argument, argument);
		           notep1("Non-Location Counter Argument on Proc" 
		           " Declaration");
                           notep1(argument);
		        }
		     }
		  }
	       }
	       #else
	       if ((!pass) && (argument))
	       {
	 	  thislabel->l.r.i = 0;

		  if (selector['n'-'a'])
		  {
		     notep1("Option /N    -Automatic Proc Locator Suppressed");
		  }
		  else
		  {
		     limit = edge(argument, " ");
		     i = expression(argument, limit, param);
		     if ((i < 0) || (i > 71))
		     {
		        flagp1("Proc Automatic Locator Out of Range");
		     }
		     else
		     {
		        thislabel->l.r.l.y |= 1;
		        thislabel->l.r.l.rel = i;
		     }
		  }
	       }
	       #endif
	       #endif

	       store_proc_text(thislabel);  /* memorise the subassembly text */

	       break;

               #endif		/* #ifndef DEEP_RECURS  */

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

               #if 0
	       break;
               #endif


               #ifndef DEEP_RECURS
	    case FUNCTION:
	       j = 0;
	       if (subfunction > -1) j = subfunction;
	       store_function(thislabel, j);
	       break;
               #endif

	       #ifdef EXIT
	    case EXIT:
	       if (argument) argument = substitute(argument, param);
	       else          argument = "end assembly";

               flag_either_pass("exit directive", argument);
	       exit(0);
	       #endif

	    case EQU:
	       i = EQU;
	       if (subfunction > -1) i = subfunction;

	       if (thislabel)
	       {
	 	  /*
		  if (thislabel->l.valued != EQU)
		  {
		     if (!pass) printf(thislabel->l.name);
		     flagp1(" This label cannot be changed to an EQUate\n");
		     break;
		  }
		  if (thislabel->l.valued == EQU)
		  {
		     if (!pass) printf(thislabel->l.name);
		     notep1(" Restated");
		  }
		  */

		  insequate(i, thislabel, argument, param);
	       }

	       break;

	    case SET:
	       i = SET;
	       if (subfunction > -1) i = subfunction;

	       if (thislabel)
	       {
		  /*
		  if (thislabel->l.valued != SET)
		  {
		     if (!pass) printf(thislabel->l.name);
		     flagp1(" This label cannot be changed to a SET\n");
		     break;
		  }
		  */

		  insequate(i, thislabel, argument, param);
	       }

	       break;

               #ifdef BLANK

            case BLANK:

               break;

               #endif

               #ifdef FPEQU
	    case FPEQU:
	       if (argument)
	       {
	 	  v_argument = substitute(argument, param);
		  argument = v_argument;
		 
		  if ((*argument == '-') || (*argument == '+')) 
					  unary = *argument++;
		  floating_generate(argument, search, param, &item);
		  if (unary == '-') operand_reverse(&item);
		  if (thislabel)
		  {
		     /*
		     if (thislabel->l.valued != SET)
		     {
		        if (!pass) printf(thislabel->l.name);
		        flagp1(" This label cannot be changed to an FPEQUate\n");
		        break;
		     }
		     */
		     thislabel->l.valued = SET;
		     thislabel->l.value = item;
		     #if 0
		     thislabel->l.r.i = 0;
		     #endif
		  }
	       }
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

	       if (argument)
	       {
	 	  i = RADIX/8;
		  #if 0
		  v_argument = argument;
		  #else

		  v_argument = substitute(argument, param);
                  if (sr = isanequf(v_argument)) item = sr->l.value;

		  #endif
		  for (;;)
		  {
		     limit = first_at(v_argument, ", ");

		     j = 0;
		     v = 0;
		     if (*v_argument == '*')
		     {
		        v_argument++;
		        v = 0x80000000;

                        if (selector['i'-'a'])
                        {
                           flag("sign extended address may not be *flagged");
                        }
		     }

                     i  -= 4;
                     if (v_argument == limit)
                     {
                     }
                     else
                     {
                        #if 1
                        if (i == RADIX/8-4)
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

                        #else

                        #ifdef AUTOMATIC_LITERALS
                        if ((*v_argument == '(') && (selector['a'-'a']))
                        {
                           v |= literal(v_argument, param, litloc);
                        }
                        else
                        #endif

         	        v |= zxpression(v_argument, limit, param);


     		        #ifdef RELOCATION
                        if (mapx->m.l.y)
                        {
		           if (i == RADIX/8-4)
		           {
		              thislabel->l.r = mapx->m;
		           }

                           #ifndef DOS
                           else
                           {
                              note("relocation attributes not stored "
                                   "for fields 2..6 of $equf");
                           }
                           #endif
                        }

                        #if 1
                        if (mapx - b4)
                        {
                           flag("too many relocatable targets in $equf");
                        }
                        #endif

                        mapx = b4;
                        mapx->m.i = 0;
		        #endif

                        #endif

                        #ifdef INTEL
                        item.b[i]   = v >> 24;
                        item.b[i+1] = v >> 16;
                        item.b[i+2] = v >>  8;
                        item.b[i+3] = v;
                        #else
                        item.i[i>>2] = v;
                        #endif
                     }

		     if (!i) break;
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

               #ifdef CASE
	    case CASE:
	       if (argument)
                    selector['k'-'a'] = expression(argument,NULL,param);
	       else selector['k'-'a'] = 1;

	       break;
	    
               #endif

	       #ifdef NOCASE
	    case NOCASE:
	       selector['k'-'a'] = 0;
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
		     limit = first_at(argument, ": ");
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
		        code_set[v++] = expression(argument, limit, param);
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
		  if (octal) apw = (address_size + 2) / 3;
		  else       apw = (address_size + 3) / 4;
	       }
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
               i = 0;
               
               if (argument) argument = substitute(argument, param);
               else          argument = "";

               while (symbol = *argument++) 
               {
                  if (i > 117) break;
                  path[i++] = symbol;
               }

               if (i) path[i++] = PATH_SEPARATOR;
               path[i] = 0;
               
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
	    
	       #ifdef SAVE_OBJECT
	    case SAVE_OBJECT:
	       save_object(argument);
	       break;
	       #endif

	       #ifdef PAGE
	    case PAGE:
	       break;
	       #endif
	    
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

                  #ifdef LONG_MOVING_COUNTER
                  if (actual->flags & 1)
                  {
                     quadd(v, &((label *) actual->runbank)->value);
                  }
                  #endif
	       }

	       if (!pass) break;

	       outstanding = 1;

               /*
	       linex = 0;
               */

               /*********************************************************
               only output the literals at bank step and at end
               that's a bit more deterministic
               *********************************************************/   
   
               #ifdef OUTPUT_LITERALS_ON_ADDRESS_HIGH
               if (loc == actual_lbase)
               {
                  output_literals(counter_of_reference);
                  loc = actual->litlocator;
               }
               #endif

	       break;

	       #ifdef OBJECT
	    case OBJECT:
	       /*
	       generate = expression(argument, limit, param);
	       */
	       break;
	       #endif

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
	       i = 0;
	       if (argument)
	       {
		  limit = edge(argument, " ");
		  i = expression(argument, limit, param);
	       }
	       walktable(i);
	       break;
	    case QUANTUM:
	       if (argument)
	       {
		  limit = edge(argument, " ");
		  address_quantum = expression(argument, limit, param);
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
		  if (octal) apw = (address_size + 2) / 3;
		  else       apw = (address_size + 3) / 4;
		  if (*limit != ':') break;
		  argument = limit+1;
		  limit = edge(argument, " ");
		  xadw = expression(argument, limit, param);
                  if (xadw > RADIX) xadw = RADIX;
                  if (xadw <   0) xadw = 96;
		  if (octal) apwx = (xadw - address_size + 2) / 3;
		  else       apwx = (xadw - address_size + 3) / 4;
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
	       i = sterm;
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
	       if (pass) break;
	       if (!argument) break;
	       search = argument;
	       limit = search;
	       limit++;
	       i = 0;

	       if (remainder < 256)
	       {
		  flagp1("Text for Store Too Late in Assembly");
		  break;
	       }
	      
	       while ((*limit) && (*limit != *search))
	       {
		  lr->t.text[i] = *limit;
		  if ((!selector['k'-'a'])
		  &&  (*limit > 0x60) 
		  &&  (*limit < 0x7b)) lr->t.text[i] &= 0x5f;
		  i++;
		  limit++;
	       }
	       if (*limit == 0) break;
	       lr->t.text[i++] = 0;
	       limit++;
	       while ((*limit) && (*limit != *search))
	       {
		  lr->t.text[i] = *limit;
		  if ((!selector['k'-'a'])
		  &&  (*limit > 0x60) 
		  &&  (*limit < 0x7b)) lr->t.text[i] &= 0x5f;
		  i++;
		  limit++;
	       }
	       lr->t.text[i++] = 0;
	       if (i > 250) break;
	       lr->h.type = TEXT_SUBSTITUTE;
	       lr->h.length = sizeof(header_word) + i + (PARAGRAPH-1);
	       lr->h.length &= -PARAGRAPH;
	       if (!tsubs) earliest_tsub = lr;
	       tsubs++;
	       remainder -= lr->h.length;
	       lr = (object *) ((long) lr + lr->h.length);
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
                     maintained in the field in code itself.

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

                        i = range_check_position_bit;
                        range_free.b[range_check_position_byte] |= i;
                     }
                     else
                     {
                        /*******************************************
                        retrieve from earlier whether this field may
                        truncate. Cache in scalar i
                        *******************************************/

                        i = range_free.b[range_check_position_byte]
                                        & range_check_position_bit;
                     } 

                     if ((i) || (range_check_descant < 0))
                     {
                        /******************************************
                        cancel any earlier range check fail because

                        (i) means this field should not be checked,
                        therefore also abandon this check.

                        or

                        (descant) means an intermediate accumulated
                        48-bit value "offset" is being maintained.

                        Therefore the range check done most recently
                        at write back takes effect, not any intermediate
                        check

                        ******************************************/
                       
                       
                        range_filter.b[range_check_position_byte]
                        &=            ~range_check_position_bit;

                        if (i) break;
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

                           i = range_check_bits - 1;

                           if (ii->b[0] & 128)
                           {
                              range_limit = minus_o;
                              lshift(&range_limit, i);
                              j = operand_compare(ii, &range_limit);
                           } 
                           else
                           {
                              range_limit = zero_o;
                              range_limit.b[RADIX / 8 - (i >> 3) - 1]
                              =                    1 << (i  & 7);

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
	       if (pass) break;
	       if (!argument) break;
	       if (*argument++ == qchar)
	       {
		  while (i = *argument++)
		  {
		     if (i == qchar) break;

		     if      ((i > 0x40) && (i < 0x5B))
                     {
                        uselector[i-'A'] = 1;
                     }
		     else if ((i > 0x60) && (i < 0x7B))
                     {
                        if ((i == 'k')
                        ||  (i == 's')
                        ||  (i == 'y')) notep1("flags -ksy are actioned "
                                               "at command line only");
                        else selector[i-'a'] = 1;
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
		  for (i = 0; i < active_x; i++)
		    printf("%s:", active_instance[i]->l.name);
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
                  &&  (loc == qextractv(sr))
                  &&  (thislabel))
                  {
                     #if 0
                     thislabel->l.value = sr->l.value;
                     #endif

                     outstanding = 1;
                  }

                  branch_present |= (1 << active_x);
               }

               if (thislabel) active_instance[active_x++] = thislabel;
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
                     #if 0
                     printf("%x ? %x\n", loc, branch_high[active_x]);
                     #endif

                     if (loc > branch_high[active_x])
                     {
                        branch_high[active_x] = loc;
                     }
                     else
                     {
                        loc = branch_high[active_x];

                        #if 0
                        printf("loc = high = %x\n", loc);
                        #endif

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

	       #if 0
	       if (selector['Q'-'A']) putchar('^');
	       #endif

	       break;

	       #endif


               #ifdef FLOATING_POINT
	    case FLOATING_POINT:
	       if (!argument)
               {
                  fpwidth = 96;
                  break;
               }

	       limit = edge(argument, " ");
	       fpwidth = expression(argument, limit, param);
	       if (fpwidth < word) fpwidth = word;
	       break;

	    case CHARACTERISTIC:
	       if (!argument) break;
	       limit = edge(directive, ", ");
	       i = fpwidth;
	       if (subfunction > -1) i = subfunction;
	       i /= word;
	       limit = edge(argument, " ");
	       characteristic_width[i-1] = expression(argument, limit, param);
	       break;
               #endif
              


               #ifdef BYTE_BLOCK
            case BYTE_BLOCK:
               if (!argument) break;
               byte_block = expression(argument, NULL, param);
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

                        i = strict_locator(search, symbol);
                        qq = &locator[i];
                        xrefl = file_label[depth]->l.down;
                        v = qq->runbank;

                        #ifdef LONG_ABSOLUTE
                        if (subfunction == LONG_ABSOLUTE)
                        {
                           thislabel->l.valued = EQU;
                           thislabel->l.r.i = 0;

                           if (qq->flags & 1)
                           {
                              if (v)
                              {
                                 thislabel->l.value = ((value *) v)->value;

                                 if (xrefl) quadd_u(xrefl->segments.base[i],
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

                           if (xrefl) v = xrefl->segments.base[i];
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

                        if (xrefl) v = xrefl->segments.base[i];
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

                        if (locator[i].relocatable)
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
                           mapx->m.l.rel = i;
                           mapx->m.l.xref = 0;
                           map_linkages(bits, rvalue);
                           thislabel->l.valued = EQUF;
                           thislabel->l.r.l.rel = i;
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

                           #if 1
                           propagate_upwards(j, rvalue, bits);

                           offset_frame(&item);
                           thislabel->l.value.i[RADIX/32-4]
                           =             item.i[RADIX/32-1];
                           #endif

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
                        thislabel->l.r.l.rel = i;
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

                        i = strict_quartets(4, search);

                        xrefl = file_label[depth]->l.down;

                        if (!xrefl)
                        {
                           flag("no external names have been referenced");
                           break;
                        }

                        if ((i < 0) || (i > XREFS - 1))
                        {
                           flag("external name index out of range1");
                           break;
                        }

                        sr = xrefl->pointer_array[i];

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
                          
                           #if 1
                           thislabel->l.value.i[RADIX/32-1] = 0;
                           thislabel->l.valued = EQUF;
                           #else
                           thislabel->l.valued = SET;
                           #endif

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

                              #if 1
                              thislabel->l.valued = EQUF;
                              thislabel->l.value.i[RADIX/32-1] = 0;
                              #else
                              thislabel->l.valued = SET;
                              thislabel->l.r.i = 0;
                              #endif

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

                              #if 0
                              operand_add(&item, &sr->l.value);
                              #endif

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
                  if (sr = findlabel(argument, NULL))
                  {
                     #if 0
                     printf("[$%x:%x REWRITE %2.2x%2.2x%2.2x%2.2x]\n",
                          counter_of_reference, loc,
                          sr->l.value.b[20], sr->l.value.b[21],
                          sr->l.value.b[22], sr->l.value.b[23]);
                     #endif

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
                           printf("$%X:%0*lX [", counter_of_reference, apw, loc);

                           i = (RADIX - subfunction) >> 3;
                           while (i < RADIX/8) printf("%2.2x", sr->l.value.b[i++]);
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
               fp_xpress(argument, limit);
               break;
               #endif

               #ifdef ESPRESSO
            case ESPRESSO:
               if (!argument) break;
               argument = substitute(argument, param);

               limit = argument;
               while (*limit++);
               i_xpress(argument, limit);
               break;
               #endif

               #ifdef RECORD
            case RECORD:
               if (argument) argument = substitute(argument, param);
               record(thislabel, argument);
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
         #if 0
         if (plist > masm_level)
         {
            if (((pass) && (selector['p'-'a']))
            || ((!pass) && (selector['r'-'a'])))
            {
               printf("::::name:::: [%s]->\n", sr->l.name);
            }
         }
         #endif

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

         #ifdef ARRAY
         vtree[masm_level++]->ready = 0;

         #ifdef WALKP
         printf("PClear::%s\n", sr->l.name);
         #endif

         #else  
         masm_level++;
         #endif

	 if (masm_level == RECURSION) unwind();

	 entry[masm_level] = sr;
	 x = sr;
         
         #ifdef DEEP_RECURS
         if (sr->l.down) x = sr->l.down;
	 else
         #endif
	 
         {
            i = sr->h.length;

            #ifdef CLEATING
            if (!i) cleat(2, sr);
            #endif

	    x = (object *) ((long) x + i);
         }

	 #if 1
         if (plist > masm_level)
         {
	    if (((pass) && (selector['P'-'A']))
            || ((!pass) && (selector['r'-'a'])))
	    {
	       printf("::::PROC:::: %s [%s]\n", sr->l.name,  v_argument);
            }
	 }
	 #endif
	 
	 toplabel = floatop;

	 if ((tpp & 2) && (pass))
	 {
	    actual->loc = loc;
	    for (i = 0; i < LOCATORS; i++) 
	    {
	       savelocator[i] = locator[i].loc;
	       savelocatorl[i] = locator[i].litlocator;
	    }
	    savepass = pass;
	    pass = 0;
	    depx = x;

	    for (;;)
	    {
               j = x->h.type;


               if (j == BYPASS_RECORD)
               {
                  if (i = x->nextbdi.next) x = bank[i];
                  else                     x = NULL;

                  if (!x)
                  {
                     printf("Error %d Retrieving Procedure Text\n", j);
                     exit(0);
                  }

                  j = x->h.type;
               }

               if (j == END) break;

	       nlabel = x->t.text;

               #ifdef QNAMES
               #ifdef REPORT_QNAMES
	       if (j == NAME) qnames++;
               #endif
               if (j == PROC)     j = TEXT_IMAGE;
               if (j == FUNCTION) j = TEXT_IMAGE;
               #endif

	       if (j == TEXT_IMAGE)
	       {
		  next_image[masm_level] = x;
		  rvalue = assemble(nlabel, v_argument, thislabel, image);
		  x = next_image[masm_level];
	       }

               i = x->h.length;

               #ifdef CLEATING
               if (!i) cleat(3, x);
               #endif
            
	       x = (object *) ((long) x + i);
	    }

	    x = depx;
	    pass = savepass;
	    for (i = 0; i < LOCATORS; i++)
	    {
	       locator[i].loc = savelocator[i];
	       locator[i].litlocator = savelocatorl[i];
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
	    j = x->h.type;

            if (j == BYPASS_RECORD)
            {
               if (i = x->nextbdi.next) x = bank[i];
               else                     x = NULL;

               if (!x) 
               {
                  printf("Error %d Retrieving Procedure Text\n", j);
                  exit(0);
               }

               j = x->h.type;
            }


            if (j == END) break;

	    nlabel = x->t.text;
	    
            #ifdef QNAMES
            #ifdef REPORT_QNAMES
            if (j == NAME) qnames++;
            #endif
            if (j == PROC)     j = TEXT_IMAGE;
            if (j == FUNCTION) j = TEXT_IMAGE;
            #endif

	    if (j == TEXT_IMAGE)
	    {
	       next_image[masm_level] = x;
               
	       if (plist > masm_level)
               {
	          if (((pass) && (selector['P'-'A']))
                  || ((!pass) && (selector['r'-'a'])))
	          {
                     print_macrotext(x->t.length, x->t.text, sr->l.name);
                     putchar(10);
	          }
	       }

	       rvalue = assemble(nlabel, v_argument, thislabel, image);
               
               if (rvalue == RETURN) break;
	       x = next_image[masm_level];
	    }
            
            i = x->h.length;

            #ifdef CLEATING
            if (!i) cleat(4, x);
            #endif

	    x = (object *) ((long) x + i);
	 }
	 
         if (plist > masm_level)
         {
            if (((pass) && (selector['P'-'A']))
            || ((!pass) && (selector['r'-'a'])))
            {
                printf(":::end proc:%s\n", x->t.text);
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
	       #ifdef LEADING_EDGE
	       v_argument = leading_edge(argument, param);
	       if (*v_argument == qchar)
	       #else
	       if (*argument == qchar)
	       #endif
	       {
		  v_argument = substitute(argument, param);
		  lhbx(v_argument, slice, &item);
	       }
	       else
	       {
		  if (bits) lshift(&item, slice);
		  limit = first_at(argument, ":, ");
		  i = slice & 7;
		  j = slice >> 3;
		  xmask = 255 << i;
		  ymask = xmask ^ 255;
		  i = RADIX/8;
		  
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
                           if (vv = (value *) qq->runbank)
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
			i--;
			item.b[i] = oo->b[i];
		     }
		     if (ymask)
		     {
			i--;
			item.b[i] &= xmask;
			item.b[i] |= oo->b[i] & ymask;
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
         #if 1
         if (selector['f'-'a'] | pass)
         {
            load_name(directive, NULL);
            if (name[0]) printf("[%s]", name);
            else         printf("[%s]", directive);
         }
         #else
	 if (selector['f'-'a'] | pass) printf(":%s:", sr->l.name);
         #endif

	 flagf("not a command");
	 return 0;
   }
   return 0;
}

main(int argc, char *_argv[])
{
   int			 i = 1, j, bits, bytes;
   
   char 		*b = NULL;

   char 		 line[READSIZE];

   object 		*sr;
   long			 fsize;
   
   location_counter	*q;
   long			 low, high, v;

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

         while (j = *b++)
         {
	    if ((j > 0x60) && (j < 0x7b))  selector[j-'a'] = 1;
	    if ((j > 0x40) && (j < 0x5b)) uselector[j-'A'] = 1;
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

   if (selector['S'-'A'])
   {
      #ifdef MS
      nhandle = open(OSYM, O_CREAT|O_TRUNC|O_RDWR, S_IREAD|S_IWRITE);
      #else
      nhandle = open(OSYM, O_CREAT|O_TRUNC|O_RDWR, S_IREAD|S_IWRITE|S_IRGRP|S_IWGRP|S_IROTH|S_IWOTH);
      #endif
   }
   
   for (;;)
   {
      i = getline(line, READSIZE-1);
      if (!i) continue;

      if (i < 0)
      {
      }
      else
      i = assemble(line, NULL, NULL, NULL);

      #ifndef PRINTBYREAD

      if ((lix) && (pass) && (list > depth) && (selector['L'-'A']))
      {
         printf("  :                            %d %s\n", ll[depth], plix);
      }

      #endif       

      #if 1

      if ((i < 0) || ((!depth) && ((i == END) || (i == RETURN))))
      #else
      b = getop(&line[0]);
      if ((i < 0) 
      ||  ((!depth) && (b) && (!skipping) && (meaning(b) == END)))
      #endif
      {
         #ifdef PRINTBYREAD

         if ((lix) && (pass) && (list > depth) && (selector['L'-'A']))
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

	 if (pass) break;

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
               if (q->bias == 0) v += q->runbank;
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

            if (q->flags & 1) ((value *) q->runbank)->offset = q->loc;
            else                                       q->runbank = 0;

	    q->loc = 0;

            #if 0
            q->flags = 0;
            #endif

            q->touch_base = 0;
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
	 
	 if (selector['S'-'A'])
	 {
            #ifdef BLOCK_WRITE
            block_write(nhandle, NULL, 0);
            #endif

	    close(nhandle);
	    
	    #if 0
	    close(handle[0]);
	    
	    if (selector['X'-65]) walktable(0);
	    if (selector['Y'-65]) walktable(1);
	    return 0;
	    #endif
	 }
	
         #if 1
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
	 #endif
	 
	 if (ecount | selector['h'-'a']) return 0; 
	 pass = 2;
         background_pass = 2;
	 
         if (selector['s'-'a'])
         handle[0] = open(OSYM,                  O_RDONLY);
         else
	 handle[0] = open(file_label[0]->l.name, O_RDONLY);
	 quadza(handle[0], &file_label[0]->l.value);
	 
	 selector['s'-'a'] = 0;

         #ifdef MS
         ohandle = open(OBIN, O_CREAT|O_TRUNC|O_RDWR, S_IREAD|S_IWRITE);
         #else
	 ohandle = open(OBIN, O_CREAT|O_TRUNC|O_RDWR, S_IREAD|S_IWRITE|S_IRGRP|S_IWGRP|S_IROTH|S_IWOTH);   
         #endif

	 if (ohandle < 1)
	 {
	    printf("No Otable\n");
	    return -96;
	 }

	 counter_of_reference = 0;
         actual = locator;
	 loc = 0;
	 depth = 0;
	 masm_level = 0;
	 byte = 8;
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
                  ecount++;
                  printf("error exporting %s "
                         "in multi-breakpoint giant segment\n"
                         "base+displacement tuple cannot be "
                         "safely linked\n", sr->l.name);
               }

               vpoint = (value *) q->runbank;
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

            if ((sr->l.r.l.rel)
            ||  (sr->l.r.l.y)
            ||  (!locator[0].relocatable))
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
   
   #if 0
   close(handle[0]);
   #endif
   
   if (selector['X'-'A']) walktable(0);
   
   for(i = 0; i <  LOCATORS; i++)
   {
      q = &locator[i];

      if (q->litlocator > q->loc) q->loc = q->litlocator;
      
      low = q->base;
      high = q->loc;

      #ifdef GBASIS
      if (((q->flags & 129) == 128)
      &&  ( q->relocatable  ==   0))
      {
         high += q->base;
      }
      #endif

      #if 0
      if (q->runbank)
      {
         if ((q->flags & 1) | selector['v'-'a'])
         {
         }
         else
         {
            low = q->runbank;
            high = q->loc + q->runbank/* - q->base*/;
         }
      }
      #endif
      
      #if 0
      if ((q->touch_base) || (q->loc))
      #else
      if ((q->loc) || (q->flags & 1))
      #endif
      {
         #ifdef LONG_TRAILER
         if (q->flags & 1)
         {
            if (q->flags & 2)
            {
               write(ohandle, "\n@:", 3);
               pushh2(i);
               write(ohandle, ":", 1);
               xpushaddress(&((value *) q->runbank)->value, i);
               q->flags &= 0xFD;
            }
    
            v = ((value *) q->runbank)->offset;
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

         #ifdef TWITCH_ALOT
         else
         {
            if (((q->flags & 1) == 0) && (q->breakpoint))
            {
               low  -= q->base;
               high -= q->base;
               low  += q->runbank;
               high += q->runbank;         
            }
         }
         #endif
         #endif

         #if 0
         if (q->bias)
         {
            low  += q->runbank;
            high += q->runbank;
         }
         #endif

	 write(ohandle, "\n:$", 3);
	 pushh2(i);
	 write(ohandle, "*", 1);
	 pushaddress(q->relocatable);
	 write(ohandle, ":", 1);
	 pushaddress(low);
	 write(ohandle, ":", 1);
	 pushaddress(high);

	 if (!selector['w'-'a'])
         {
            #ifdef OCTALPRINT
	    if (octal)
	    printf(":$(%o):%0*lo:%0*lo ", i, apw, low, apw, high);
	    else
	    printf(":$(%2.2X):%0*lX:%0*lX ", i, apw, low, apw, high);
	    #else
	    printf(":$(%2.2x):%0*lX:%0*lX ", i, apw, low, apw, high);
	    #endif
         }
      }
   }


   #ifdef TEST_B4

   #ifdef BLOCK_WRITE
   write(ohandle, NULL, 0);
   #endif

   fsize = lseek(ohandle, (long) 0, SEEK_CUR);

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

   fsize = lseek(ohandle, (long) 0, SEEK_CUR);

   #endif

   if ((!selector['w'-'a'])
   ||  (ecount)
   || ((ucount) && (selector['u'-'a'])))
   {
      printf("\n%s: object code %ld bytes: "
             "%ld errors: %ld undefined labels\n",
	      file_label[0]->l.name, fsize, ecount, ucount);
   }

   if (ecount) return -1;
   if ((ucount) && (selector['U'-'A'])) return -1;

   if (filename[1]) save_object(filename[1]);

   #ifdef REPORT_QNAMES
   printf("%d names not re-scanned\n", qnames);
   #endif

   return 0;
}


