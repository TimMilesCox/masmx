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


#ifdef STRUCTURE_DEPTH

static object *findlabel_in_node()
{
   object *sr = (object *) active_instance[active_x - 1]->l.down;
   char *candidate, *tabled;
   register int symbol;
   
   while (sr)
   {
      candidate = name;
      tabled = sr->l.name;
      for (;;)
      {
	 symbol = *candidate++;
	 if (!symbol)
	 {
	     if (!(symbol ^= *tabled)) return sr;
	     break;
	 }
	 if (symbol ^= *tabled++) break;
      }
      sr = (object *) sr->l.along;
   }
   return NULL;
}

/*********************************************************
	Note *name2 is at an offset in static name[] 
**********************************************************/

static object *findchain_in_node(object *sr, char *name2, char *margin)
{
   #ifdef SYNONYMS
   static label child_synonyms = { LABEL, sizeof(label), 0, INTERNAL_FUNCTION,
				   { 0 },

                                     #ifdef HASH
                                     NULL,
                                     #endif

                                     #ifdef BINARY
                                     NULL,
                                     #endif

                                     NULL, NULL, 
				   { 0, 0, 0, 0, 0, 0,

                                     #if RADIX==192 
				     0, 0, 0, 0, 0, 0,
				     0, 0, 0, 0, 0, 0,
                                     #endif

				     0, 0, 0, 0, 0, CHILD_SYNONYMS }, "$$z" } ;
   #endif

   char			*candidate, *tabled, *forward = name2;

   register int		 symbol;
   int			 b4 = name2 - name;


   stem_pointer = NULL;

   while (sr)
   {
      candidate = name2;
      tabled = sr->l.name;

      for (;;)
      {
	 symbol = *candidate++;
	 if (!symbol)
	 {
	    if (!(symbol -= *tabled)) return sr;
	    break;
	 }
	 if (symbol -= *tabled++) break;
      }
      
      #ifdef SYNONYMS

      if ((symbol == 0-'(') && (*(candidate-1) == 0))
      {
	 if (*label_margin == '(')
	 {

            stem_pointer = sr;
	    load_qualifier(label_margin, margin);

	    if ((*label_margin == sterm) && (label_margin != margin))
            {
               load_trailer(label_margin, margin);
            }

	    continue;
	 }
      }

      #endif
	 
      while ((symbol       == sterm) 
      &&   (*(candidate-1) == sterm)
      &&     (sr = (object *) sr->l.down)) 
      {
         b4 = candidate - name;

	 for (;;)
	 {         
	    forward = candidate;
	    tabled = sr->l.name;
	    for (;;)
	    {
	       symbol = *forward++;
	       if (!symbol)
	       {
		  if (!(symbol ^= *tabled)) return sr;
		  break;
	       }
	       if (symbol ^= *tabled++) break;
	    }

	    #ifdef SYNONYMS
	       
	    if ((symbol == 0^'(') && (*(forward-1) == 0))
	    {
	       if (*label_margin == '(')
	       {
                  stem_pointer = sr;
		  load_qualifier(label_margin, margin);
		     
		  if ((*label_margin == sterm) && (label_margin != margin))
		  {
     	             load_trailer(label_margin, margin);
		  }

		  tabled++;

		  for (;;)
		  {
	             if (symbol = *forward++ - *tabled++) break; 
	             if ((!*forward) && (!*tabled)) return sr;
		  }

		  continue; /* repeat comparison with subscript */	     
	       }
	    }
	    #endif

	    if ((symbol == sterm) && (*(forward-1) == sterm))
	    {
	       candidate = forward;
	       break; 
	    }
	    if (!sr->l.along) break;
	    sr = (object *) sr->l.along;
	 }
      }

      if (!sr) break;

      sr = (object *) sr->l.along;
   }

   if (stem_pointer)
   {
      stem_length = label_highest_byte - b4;
      return (object *) &child_synonyms;
   }

   return NULL;
}

void inslabel(object *o)
{
   object		*next = active_instance[active_x - 1];

   if (next->l.down)
   {
      next = next->l.down;
      while (next->l.along) next = next->l.along;
      next->l.along = o;
   }
   else
   {
      next->l.down = o;
   }
}

#endif	/*	STRUCTURE_DEPTH	*/

