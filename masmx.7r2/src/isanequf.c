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


static object *isanequf(char *field)
{
   static label		 x;
   
   object		*l;
   
   long			 v;
   
   location_counter	*c;

   if (!field) return NULL;

   #ifdef AUTOMATIC_LITERALS
   if ((*field == '(') && (selector['a'-'a']))
   {
      c = &locator[litloc];
      
      if (c->flags & 128)
      {
         if (v = c->rbase)
         {
            quadinsert1(v, &x.value);
            #ifdef RELOCATION
            mapx->m.i = 0; /* global change 3ix2008 */
            #endif

            return (object *) &x;
         }
      }

      return NULL;
   }
   #endif
   
   l  = findlabel(field, NULL);
   if (!l) return NULL;

   #if 0
   printf("[is %x::%s a $equf?]", l->l.valued, name);
   #endif

   #ifdef LITERALS
   if (l->l.valued == LTAG)
   {
      c = &locator[l->l.r.l.rel];
      
      if (c->flags & 128)
      {
         #if 1
         v = quadextract1(&l->l.value);
         if (v != c->rbase) flag("not in scope of this literal tag");

         #ifdef RELOCATION
         mapx->m.i = 0; /* global change 3ix2008 */
         #endif

         return l;

         #else

         if (v = c->rbase)
         {
            #ifdef LITWISE
            printf("[in isanequf idxv %d]\n", v);
            #endif
            
            #if 0
            l->l.value.b[19] = v;
            l->l.value.b[18] = v >>  8;
            l->l.value.b[17] = v >> 16;
            l->l.value.b[16] = v >> 24;
            #endif
            
            #ifdef RELOCATION
            mapx->m.i = 0; /* global change 3ix2008 */
            #endif

            return l;
         }

         #endif

      }
   }
   #endif

   if (l->l.valued ==  EQUF) return l;

   if (l->l.valued == BLANK)
   {
      c = &locator[l->l.r.l.rel];
      if (c->flags & 128) return l;
   }

   return NULL;
}
