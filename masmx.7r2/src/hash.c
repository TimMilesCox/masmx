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


#ifdef HASH

static void hash_in(object *sr)
{
   int			 x = label_length >> 1;
   unsigned short	 sum = 0;
   unsigned short	*p2su = (unsigned short *) name;


   while (x--) sum += *p2su++;

   #if HASH==65536
   #else
   sum &= HASH-1;
   #endif

   sr->l.hashlink = pointer_array[sum];
   pointer_array[sum] = sr;
}

static object *hash_locate(int	purpose)
{
   int			 x = label_length >> 1;
   unsigned short	 sum = 0;
   unsigned short	*p2su = (unsigned short *) name;

   unsigned long	*p, *q;
   object		*sr;

   object		*udef_encountered = NULL;

   #ifdef SYNONYMS
   char			*p2c, *q2c;
   int			 subscript = 0;
   #endif

   while (x--) sum += *p2su++;

   #if HASH==65536
   #else
   sum &= HASH-1;
   #endif

   sr = pointer_array[sum];

   for (;;)
   {
      if (!sr)
      {
         #ifdef SYNONYMS

         if (!purpose) break;

         /**************************************************

		the subscript if any is already attached
		to the name on label insert

         ***************************************************/

         if (*label_margin == '(')
         {
             subscript = 1;
             x = load_qualifier();

             if (!x) return (object *) &count_synonyms;

             sum = 0;
             p2su = (unsigned short *) name;
             x = label_length >> 1;
             while (x--) sum += *p2su++;

             #if HASH==65536
             #else
             sum &= HASH-1;
             #endif

             sr = pointer_array[sum];

             if (sr) continue;
         }
         #endif

         break;
      }

      p = (unsigned long *) name;
      q = (unsigned long *) sr->l.name;
      x = label_length >> 2;

      while (x)
      {
         if (*p++ ^ *q++) break;
         x--;
      }

      if (!x)
      {
         if (sr->l.valued == UNDEFINED)
         {
            udef_encountered = sr;
            sr = sr->l.hashlink;
            continue;
         }

         return sr;
      }
         sr = sr->l.hashlink;
   }

   #ifdef SYNONYMS

   /***********************************************

	if the call is from insert_ltable()
	its purpose is not to obtain this
	functional result count_synonyms

	if the call is from findlabel(), the
	purpose may be served with count_synonyms

   ************************************************/


   if (subscript) return (object *) &count_synonyms; 

   #endif

   return udef_encountered;
}

#endif
