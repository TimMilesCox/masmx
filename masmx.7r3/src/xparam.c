
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




static line_item *extract_xparam(char *s, char *gparam)
{
   line_item		*v = xpression(s, s, gparam);
   paraform_code	 sample = encode_paraform(s, NULL);
   int			 i, j, x, y;
   array		*a;
   char			*p, *pq, *limit;

   int			 stem = sample.level & 63;
   int                   mask = sample.level & 192;

   #ifdef EQUF
   object		*l = NULL;
   #endif

   int			 z;

   #ifdef AUTOMATIC_LITERALS
   location_counter	*q;
   value		*u;
   #endif

   #ifdef SLIPSHO
   printf("[FO %s]\n", s);
   #endif

   if (gparam)
   {
      j = fields(gparam);
      i = sample.field;

      if (i < 0) return v;
      if (i > j) return v;
      a = field(i);
      y = a->count;

      #ifdef SLIPSHO
      printf("[request %d field %d subfields %d %s]\n", stem,i, y, a->image[0]);
      #endif

      switch (stem)
      {

         case SUBFIELD:
            x = sample.subfield;
            if (x < 0) break;
            if (!x) x = 1;            

            if ((i == 0) && (x == 1))
            {
               if (entry[masm_level]->l.valued != NAME)
               {
                  if (pass | selector['f'-'a'])
                     printf("[%d:%s:%s]:",
                     masm_level,  entry[masm_level]->l.name, gparam);
                  flagf("not a $name: $n may not be retrieved");
                  break;
               }
            }

            #ifdef EQUF
   
            p = a->image[x - 1];

            if ((x > y) || (*p == ','))
            {
               while (y--)
               {
                  pq = a->image[y];
                  if ((*pq == '*') || (*pq == '#')) pq++;
	          if ((l = isanequf(pq)))
                  {
	             x -= y;
	             y = RADIX/32 - x;
	             if (y < 0) return 0;

	             if (mask == 128)
	             {
	                v->b[RADIX/8-1] = l->l.value.b[y<<2] >> 7;
	                return v;
	             }

                     z = l->l.value.i[y];

                     if (address_size < 32)
                     {
                        #ifdef INTEL
                        z &= 0xFFFFFF7F;
                        #else
                        z &= 0x7FFFFFFF;
                        #endif
                     }

                     v->i[RADIX/32-1] = z;
	             return v;
        	  }
               }
 
               return v;

            }

            #else

            if (x > y) return v;
            p = a->image[x - 1];
   
            #endif

            switch (mask)
            {
               case STAR__:

                  #ifdef EQUF
                  if ((l = isanequf(p)))
                  {
	             v->b[RADIX/8-1] = l->l.value.b[RADIX/8-4] >> 7;
                  }
                  #endif
      
                  if (*p == '*') v->b[RADIX/8-1] = 1;
                  break;

               case HASH__:

                  if (*p == '#') v->b[RADIX/8-1] = 1;
                  break;

               default:

                  if ((*p == '*') || (*p == '#')) p++;
                  limit = first_at(p, " ,");

                  #ifdef AUTOMATIC_LITERALS
                  if ((*p == '(') && (selector['a'-'a']))
                  {
   	             z = literal(p, gparam, litloc);
                     quadinsert(z, v);

                     #ifdef LTAG

                     q = &locator[litloc];

                     if ((q->flags & 129) == 1)
                     {
                        if ((u = q->runbank.p))
                        {
                           *v = u->value;
                           quadd_u(z, v);
                        }
                     }

                     #endif

	             break;
                  }
                  #endif
      
                  v = xpression(p, limit, NULL);   
            }

            break;


         case SUBSTRING:
            x = sample.subfield;
            if (x < 0) break;
            if (x > y) break;
            if (!x) x = 1;
            
            p = a->image[x - 1];

            j = substrings(p);
            i = sample.sustring;

            if (!i)
            {
               v->b[RADIX/8-1] = j;
               break;
            }

            if (i < 0) break;
            if (i > j) break;            

            p = substring(p, i);

            if (!p) break;

            if ((*p == '*') || (*p == '#')) p++;
            limit = edge(p, tstring);
            v = xpression(p, limit, NULL);

            break;

         case FIELD:
            v->b[RADIX/8-1] = y;
            break;

         case ALL_FIELDS:
            v->b[RADIX/8-1] = j;
            break;

         case COMPLETE_LINE:
            v->b[RADIX/8-1] = j + 1;
            break;

         case BAD_PARAFORM:
            flag("paraform not decoded");
      }
   }

   return v;
}

#ifdef RANGE_WARNING

static void range_warning(line_item *v)
{
   #if RADIX==192
   int			 u = v->i[0]
                           | v->i[1]
                           | v->i[2]
                           | v->i[3]
                           | v->i[4];
   if (u)
   {
      /************************************************************
      note that any result filling only 32 bits is accepted without
      comment.
      it's not possible to know if the programmer intends unsigned
      ************************************************************/
      
      if (v->b[0] & 128)
      {
         u = v->i[0] & v->i[1] & v->i[2] & v->i[3] & v->i[4];
         
         if (u == 0xFFFFFFFF)
         {
         }
         else
         {
            note("value underflows 32-bit function");

            #ifndef DOS
            if (pass)
            {
               if (selector['p'-'a'] | selector['q'-'a']) display_ra(0, v);
            }
            #endif
         }
      }
      else
      {
         note("value overflows 32-bit function");

         #ifndef DOS
         if (pass)
         {
	    if (selector['p'-'a'] | selector['q'-'a']) display_ra(0, v);
         }
         #endif
      }
   }
   #endif

   #if RADIX==96
   int			 u = v->i[0] | v->i[1];

   if (u)
   {
      /************************************************************
      note that any result filling only 32 bits is accepted without
      comment.
      it's not possible to know if the programmer intends unsigned
      ************************************************************/
      
      if (v->b[0] & 128)
      {
         u = v->i[0] & v->i[1];
         
         if (u == 0xFFFFFFFF)
         {
         }
         else
         {
            note("parameter value underflows 32-bit function");
         }
      }
      else
      {
         note("parameter value overflows 32-bit function");
      }
   }
   #endif 
}

#endif

static int extract_gparam(char *s, char *gparam)
{
   line_item		*v = extract_xparam(s, gparam);

   #ifdef RANGE_WARNING

   range_warning(v);

   #endif
   
   return quadextract(v);
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


