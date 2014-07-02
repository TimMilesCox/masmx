static unsigned long checkwaver(line_item *v, object *o)
{
   unsigned long		check = (v->i[0] ^ o->l.value.i[0])
				      | (v->i[1] ^ o->l.value.i[1])
				      | (v->i[2] ^ o->l.value.i[2])
				      | (v->i[3] ^ o->l.value.i[3])
				      | (v->i[4] ^ o->l.value.i[4])
				      | (v->i[5] ^ o->l.value.i[5]);

   return check;
}

static void checkwave(line_item *v, object *o)
{
   unsigned long		 check = checkwaver(v, o);

   if (check)
   {
      printf("\n");
      print_item(&o->l.value);
      print_item(v);

      flagp(o->l.name, "displacement altered");
   }
}

static void insert_label(object *o)
{
   static object	*trail;

   object		*b4 = NULL, *next = origin;

   if (selector['y'-'a'] == 0)
   {
      if (origin) trail->l.along = o;
      else                origin = o;
      trail = o;
      return;
   }

   while (next)
   {
      if (strcmp(o->l.name, next->l.name) < 0) break;
      b4 = next;
      next = next->l.along;
   }

   if (b4) b4->l.along = o;
   else         origin = o;

   o->l.along = next;
}

#ifndef	HASH

static object *retrieve_label(char *margin)
{
   object		*next = origin;
   object		*udef_encountered = NULL;

   int			 x;

   #ifdef SYNONYMS
   int			 subscript = 0;
   #endif

   #ifdef STRUCTURE_DEPTH
   object		*result;
   #endif

   #if	defined(STRUCTURE_DEPTH)|defined(SYNONYMS)
   char			*p, *q;
   int			 y;
   #endif


   while (next)
   {
      #if defined(STRUCTURE_DEPTH)|defined(SYNONYMS)

      p = name;
      q = next->l.name;

      while (x = *p)
      {
         y = *q;
         x -= y;
         if (x) break;
         p++;
         q++;
      }

      y = *q;

      if (x)
      {
      }
      else x -= y;

      #else

      x = strcmp(name, next->l.name);

      #endif

      #ifdef SYNONYMS
      if (x)
      {
         if ((x == -'(') && (y == '(') &&  (*label_margin == '('))
         {
            subscript = 1;
            x = load_qualifier();

            if (x == 0) return (object *) &count_synonyms;

            continue;
         }
 
         #if 0
         if (selector['y'-'a'])
         {
            if (x < 0) break;
         }
         #endif
      }
      #endif

      if (x == 0)
      {
         if (next->l.valued == UNDEFINED)
         {
            udef_encountered = next;
            next = next->l.along;
            continue;
         }

         #ifdef STRUCTURE_DEPTH
         if ((result = next->l.down) && (*label_margin == sterm))
         {
            x = next->l.valued;
            if ((x != PROC)
            &&  (x != NAME)
            &&  (x != FUNCTION))
            {
               load_trailer(label_margin, margin);
               return findchain_in_node(result,
                                        p + 1,
                                        name + label_highest_byte);
            }
         }
         #endif		/*	STRUCTURE_DEPTH	*/

         return next;
      }

      #ifdef STRUCTURE_DEPTH
      if ((x == sterm) && (*p == sterm))
      {
         if (result = next->l.down)
         {
            x = next->l.valued;
            if ((x != PROC)
            &&  (x != NAME)
            &&  (x != FUNCTION))
            {
               result = findchain_in_node(result, p + 1,
                                          name + label_highest_byte);
               if (result) return result;
            }
         }
      }
      #endif		/*	STRUCTURE_DEPTH	*/

      next = next->l.along;
   }

   #ifdef SYNONYMS
   if (subscript) return (object *) &count_synonyms;
   #endif

   return udef_encountered;
}

#endif		/*	ifndef HASH	*/

static object *retrieve_dynamic_label()
{
   object		*next = floatable;
   object		*result = NULL;
   short		 i = 0, j;
   int			 x;

   #ifdef SYNONYMS
   int			 subscript = 0;
   int			 y;
   char			*p, *q;
   #endif


   while (next < floatop)
   {
      #ifdef SYNONYMS

      p = name;
      q = next->l.name;

      while (x = *p)
      {
         y = *q;
         x -= y;
         if (x) break;
         p++;
         q++;
      }

      y = *q;

      if (x)
      {
      }
      else x -= y;

      #else

      x = strcmp(name, next->l.name);

      #endif

      if (x == 0) result = next;

      #ifdef SYNONYMS
      else
      {
         if ((x == -'(') && (y == '(') && (*label_margin == '('))
         {
            subscript = 1;
            x = load_qualifier();
            if (x == 0) return (object *) &count_synonyms;
            continue;
         }
      }
      #endif

      i = next->h.length;
      next = (object *) ((char *) next + i);
   }

   if (result) return result;

   #ifdef SYNONYMS
   if (subscript) return (object *) &count_synonyms;
   #endif

   return NULL;
}

static object *insert_ltable(char *column, char *limit, line_item *v, int type)
{
   short		 global = masm_level;
   char			*s;
   object		*o = NULL;
   paragraph		*p, *q;

   line_item		 vnew;
   value		*vlbase;

   int			 x, size;
   int			 base_displacement = 0;


   if (type == UNDEFINED) global = 0;
   else
   {
      load_name(column, limit);
      if (label_highest_byte == 0) return NULL;

      #ifdef SYNONYMS
      if (*label_margin == '(') load_qualifier(label_margin, limit);
      #endif

      s = label_margin;

      while (*s++ == '*') global--;
   }


   #ifdef STRUCTURE_DEPTH

   if ((active_x) && ((type == LOCATION) || (type == EQUF) || (type == BLANK)))
   {
      o = findlabel_in_node();
      #ifdef UNDERWATER_DEBRIS
      global = 0;
      #else
      global = active_instance[active_x - 1]->l.r.l.xref;
      #endif
   }

   else
   {
      if (global > 0)
      {
         o = retrieve_dynamic_label();

         if (o)
         {
            if (o->l.r.l.xref ^ global) o = NULL;
         }
      }
      else
      {
         #ifdef HASH
         o = hash_locate(0);
         #else
         o = retrieve_label();
         #endif
      }
   }

   #else

   if (global > 0)
   {
      o = retrieve_dynamic_label();

      if (o)
      {
         if (o->l.r.l.xref ^ global) o = NULL;
      }
   }
   else
   {
      #ifdef HASH
      o = hash_locate(0);
      #else
      o = retrieve_label();
      #endif
   }

   #endif

   if ((type == LOCATION) || (type == BLANK))
   {
      if (x = actual->flags & 129)
      {
         vnew = *v;
         v = &vnew;

         if (x & 128)
         {
            if (type == LOCATION) type = EQUF;
            v->b[RADIX/8-5] = actual->rbase;
            base_displacement = 1;
         }

         if (x == 1)
         {
            vlbase = (value *) actual->runbank;
            operand_add(v, &vlbase->value);
         }
      }
   }


   if (o)
   {
      if (type == BLANK) return o;

      /*************************************

	$blank does not alter any label
	which already exists

      *************************************/
 
      if (x = o->l.valued)
      {
         if (type ^ x)
         {
            if ((pass) && ((type == LOCATION) || (base_displacement)))
            {
               return o;
            }

            flagp(o->l.name, "may not be retyped");
         }
      }

      if (type == FORM) return o;

      if (type == SET)
      {
      }
      else
      {
         if (background_pass)
         {
            if ((type == LOCATION) || (base_displacement))
            {
               checkwave(v, o);
            }
         }
         else
         {
            if (o->l.valued == BLANK)
            {
               o->l.valued = type;
            }
            else
            {
               if (type == EQU)
               {
                  notep1p(o->l.name, "equate restated");

                  if (uselector['E'-'A'] == 0)
                  {
                     printf("unchanged from");
                     print_item(&o->l.value);
                     return o;
                  }
               }
               else
               {
                  #ifdef BINARY
                  if (o->l.valued == UNDEFINED) o->l.valued = type;
                  else
                  #endif
                  flagp1p(o->l.name, "may not be restated");
               }
            }
         }
      }
   }
   else
   {
      size = sizeof(label) + label_length - PARAGRAPH;

      if (global > 0)
      {
         flotsam -= size;

         if (flotsam < 0)
         {
            flag_either_pass("too many dynamic labels", "abandon");
            exit(0);
         }

         o = floatop;
         floatop = (object *) ((char *) floatop + size);
         o->l.along = NULL;
         floatop->i = 0;
      }
      else
      {
         o = lr;

         if (remainder < size) o = buy_ltable();

         remainder -= size;

         lr = (object *) ((char *) lr + size);
      }

      lr->i = 0;

      p = (paragraph *) o->l.name;
      q = (paragraph *)      name;
      x = label_length >> 2;

      while (x--) *p++ = *q++;

      o->l.r.i = 0;
      o->l.r.l.xref = global;

      #ifdef HASH
      o->l.hashlink = NULL;
      #endif

      #ifdef BINARY
      o->l.link = NULL;
      #endif

      o->l.down = NULL;
      o->l.along = NULL;
      o->h.type = LABEL;
      o->h.length = size;
      o->l.passflag = 0;

      o->l.valued = type;

      if (type == SET) o->l.value = zero_o;

      if (global > 0)
      {
      }
      else
      {
         #ifdef STRUCTURE_DEPTH
         if ((active_x)
         && ((type == LOCATION) || (type == EQUF) || (type == BLANK)))
         {
            inslabel(o);
         }
         else
         #endif

         {
            #ifdef HASH

            hash_in(o);

            #endif
 
            if ((list) || (o->l.valued  == UNDEFINED))
            {
               insert_label(o);
            }
         }
      }
   }

   if (type == SET) 
   {
   }
   else o->l.value = *v;

   o->l.passflag = masm_level;

   if ((type == LOCATION) || (type == BLANK))
   {
      o->l.r.l.rel = counter_of_reference;

      if (actual->relocatable) o->l.r.l.y |= 1;
      else                     o->l.r.l.y &= 254;
   }

   if (base_displacement) o->l.r.l.rel = counter_of_reference;

   return o; 
}

object *findlabel(char *s, char *limit)
{
   object		*result, *presult;
   int			 x;

   #ifdef STRUCTURE_DEPTH
   int			 y;
   #endif

   load_name(s, limit);

   if (label_highest_byte == 0) return NULL;

   #ifdef STRUCTURE_DEPTH
   if (active_x)
   {
      result = findchain_in_node(active_instance[active_x - 1]->l.down,
                                 name, limit);

      if (result) return result;
   }
   #endif

   presult = retrieve_dynamic_label();

   if (presult)
   {
      #ifdef SYNONYMS
      if ((presult->l.valued == INTERNAL_FUNCTION)
      &&  (presult->l.value.b[RADIX/8-1] == SYNONYMS))
      {
      }
      else
      #endif

      return presult;
   }

   #ifdef HASH

   /******************************************************

	argument value 1 allows hash_locate(1) to return
	the functional value count_synonyms if subscripted
	synomyms are encountered

   ******************************************************/

   result = hash_locate(1);

   if (result)
   {
      if (x = result->l.valued)
      {
         #ifdef STRUCTURE_DEPTH
         if ((*label_margin == sterm)
         &&  (x ^ FUNCTION)
         &&  (x ^ INTERNAL_FUNCTION)
         &&  (x ^ PROC)
         &&  (result->l.down))
         {
            x = label_highest_byte;
            load_trailer(label_margin, limit);
            return findchain_in_node(result->l.down,
                                     name + x + 1,
                                     name + label_highest_byte);
         }
         #endif
            

         if ((result->l.valued == INTERNAL_FUNCTION)
         &&  (result->l.value.b[RADIX/8-1] == SYNONYMS))
         {
                                                         presult = result;
                                                            result = NULL;
         }
         else                                               return result;
      }
   }

   /*****************************************************

	presult is the count_synonyms function if the
	dynamic label stack contains some subscripted
	versions of THE(label)

	if this is so, THE(subscript) was already
	attached to the label in dynamic label stack
	search, and is now retained

	if it was not the dynamic label search which
	loaded the subscript, but the hash chain
	search, the subscript part is stripped
	before the search in the static label stack

	repeating load_name() strips the subscript

	the static label stack search attaches the
	subscript again if subscripted versions of
	THE(label) are found

	in practice SYNONYMS are always configured,
	except in the bcc DOS_LINKER version for
	640K.DOS, where all possible features are
	stripped which linking does not use

	These 640K.DOS binaries separate the
	Linker from the Assembler because not all
	the features fit in one binary

   *****************************************************/


   #ifdef STRUCTURE_DEPTH
   if (!result)
   {
      x = label_highest_byte;

      while (x--)
      {
         if (name[x] == sterm)
         {
            name[x] = 0;
            load_name(name, NULL);
            result = hash_locate(1);

            load_name(s, limit);
            
            if (result)
            {
               if ((result->l.down)
               &&  (y = result->l.valued)
               &&  (y ^ PROC)
               &&  (y ^ FUNCTION)
               &&  (y ^ INTERNAL_FUNCTION))
               {
                  return   findchain_in_node(result->l.down,
                                             name + x + 1,
                                             name + label_highest_byte);
                  break;

               }
               else result = NULL;
            }
         }
      }
   }
   #endif

   if (result) return result;
   return presult;

   #else	/*	HASH	*/

   result = retrieve_label(limit);
   if (result) return result;

   return presult;

   #endif	/*	HASH	*/
}

