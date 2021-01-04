
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


static void checkwaveb(line_item *v, object *o)
{
   unsigned int		 check = (v->i[4] ^ o->l.value.i[4])
				       | (v->i[5] ^ o->l.value.i[5]);

   if (check)
   {
      printf("\n");

      if (octal)
      {
         printf("%0*o, %o\n", apw, qextractv(o), quadextractx(&o->l.value, 2));
         printf("%0*o, %o\n", apw, quadextract(v), quadextractx(v, 2));
      }
      else
      {
         printf("%0*X, %X\n", apw, qextractv(o), quadextractx(&o->l.value, 2));
         printf("%0*X, %X\n", apw, quadextract(v), quadextractx(v, 2));
      }
  
      flagp(o->l.name, "base + displacement altered");
   }
}

static unsigned int checkwaver(line_item *v, object *o)
{
   unsigned int		 check = (v->i[0] ^ o->l.value.i[0])
				       | (v->i[1] ^ o->l.value.i[1])
				       | (v->i[2] ^ o->l.value.i[2])
				       | (v->i[3] ^ o->l.value.i[3])
				       | (v->i[4] ^ o->l.value.i[4])
				       | (v->i[5] ^ o->l.value.i[5]);

   return check;
}

static void checkwave(line_item *v, object *o, int section_flags)
{
   unsigned int		 check = (section_flags & 1) ?
				 checkwaver(v, o) : (v->i[5] ^ o->l.value.i[5]);

   if (check)
   {
      if (section_flags & 1)
      { 
         printf("\n");
         print_item(&o->l.value);
         print_item(v);
      }
      else
      {
         if (octal)
         {
            printf("%0*o\n", apw, qextractv(o));
            printf("%0*o\n", apw, quadextract(v));
         }
         else
         {
            printf("%0*X\n", apw, qextractv(o));
            printf("%0*X\n", apw, quadextract(v));
         }
      }

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

         #ifdef EQUAZE
         if (next->l.valued ^ BLANK) return next;
         #else
         return next;
         #endif
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

      while ((x = *p))
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

      #ifdef EQUAZE
      if ((x == 0) && (next->l.valued ^ BLANK)) result = next;
      #else
      if (x == 0) result = next;
      #endif

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

   #ifdef STRUCTURE_DEPTH
   object		*adhesionp
			= (active_x) ? active_instance[active_x - 1]
                                     : NULL;

   int			 adhesion_level = -1;
   int			 b4 = type;
   #endif

   if (type == UNDEFINED) global = 0;
   else
   {
      load_name(column, limit);
      if (label_highest_byte == 0) return NULL;

      #ifdef SYNONYMS
      if (*label_margin == '(') load_qualifier(/*label_margin, limit*/);
      #endif

      s = label_margin;

      while (*s++ == '*') global--;
   }


   #ifdef STRUCTURE_DEPTH

   if ((adhesionp) && (global == adhesionp->l.passflag)
   &&  (type) && (type ^ SET) && (type ^ BLANK))
   {
      o = findlabel_in_node();
      adhesion_level = adhesionp->l.r.l.xref;
      if (adhesion_level < 0) adhesion_level = 0;
      global = adhesion_level;
      if (uselector['B'-'A'])
      printf("[L%x:A%x:G%x:V%x:P%X]%s:%s\n",
              masm_level, adhesion_level, global, type,
              adhesionp->l.passflag,
              adhesionp->l.name, name);
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
      if ((x = actual->flags & 129))
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
            vlbase = actual->runbank.p;
            operand_add(v, &vlbase->value);
         }
      }
   }

   if (o)
   {
      if (type == BLANK) return o;

      x = o->l.valued;

      if (x == BLANK)
      {
         o->l.valued = type;
         o->l.value = *v;
         return o;
      }

      /*************************************

	$blank does not alter any label
	which already exists

      *************************************/
 
      #ifdef RECORD
      if (type == RECORD)
      {
         if ((branch_record == 0) && (record_nest == 0)) base_displacement = 1;
         type = EQUF;

         if (actual->flags & 128)
         {
            vnew = *v;
            v = &vnew;
            v->b[RADIX/8-5] = actual->rbase;
         }
      }
      #endif

      if (x)
      {
         if (type ^ x)
         {
            if ((pass) && ((type == LOCATION) || (base_displacement)))
            {
               if ((x == EQU) || (x == SET) || (x == EQUF))
               return o;
            }

            if (pass) printf("[%x:%x]", x, type);
            flagp(o->l.name, "may not be retyped");
            return o;
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
            if       (type == LOCATION) checkwave(v, o, actual->flags);
            else if (base_displacement) checkwaveb(v, o); 
         }
         else
         {
            #ifdef BINARY
            if (o->l.valued == UNDEFINED) o->l.valued = type;
            else
            #endif
            {
               flagp1p(o->l.name, "may not be restated");
               return o;
            }
         }
      }
   }
   else
   {
      #ifdef EQUAZE
      if ((type == EQU) || (type == SET)) type = BLANK;
      #endif

      size = sizeof(label) + label_length - PARAGRAPH;

      if (global > 0)
      {
         flotsam -= size;

         if ((int) flotsam < 0)
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
         if ((active_x) && (global == adhesion_level)
         &&  (b4) && (b4 ^ SET) && (b4 ^ BLANK)) inslabel(o);
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

   if ((uselector['L'-'A']) && (masm_level))
   {
      printf("[%x<-%x:%x:%s:%d:%s]\n", masm_level, global, type,
              file_label[depth]->l.name, ll[depth], o->l.name);
   }

   if ((type == LOCATION) || (type == BLANK))
   {
      o->l.r.l.rel = counter_of_reference | 128;

      if (actual->relocatable) o->l.r.l.y |= 1;
      else                     o->l.r.l.y &= 254;
   }

   if (base_displacement) o->l.r.l.rel = counter_of_reference | 128;

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
      if ((x = result->l.valued))
      {
         #ifdef STRUCTURE_DEPTH
         if ((*label_margin == sterm)
         &&  (x ^ FUNCTION)
         &&  (x ^ INTERNAL_FUNCTION)
         &&  (x ^ PROC)
         &&  (result->l.down))
         {
            if (context_string)
            {
               if (pass) printf("\n[%c%s%c] ", sterm, name, sterm);
               note("binds string members not structure members");
               if (pass) printf("to traverse structure %c+(%s%cmember)%c\n\n", sterm, name, sterm, sterm);
               return result;
            }

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


