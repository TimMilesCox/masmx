
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




static object *isanequf(char *field)
{
   static label		 x;
   
   object		*l;
   
   int			 v;
   
   location_counter	*c;

   if (!field) return NULL;

   #ifdef AUTOMATIC_LITERALS
   if ((*field == '(') && (selector['a'-'a']))
   {
      c = &locator[litloc];
      
      if (c->flags & 128)
      {
         if ((v = c->rbase))
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

   #ifdef LITERALS
   if (l->l.valued == LTAG)
   {
      c = &locator[l->l.r.l.rel & 127];
      
      if (c->flags & 128)
      {
         v = quadextract1(&l->l.value);
         if (v != c->rbase) flag("not in scope of this literal tag");

         #ifdef RELOCATION
         mapx->m.i = 0; /* global change 3ix2008 */
         #endif

         return l;
      }
   }
   #endif

   if (l->l.valued ==  EQUF) return l;

   if (l->l.valued == BLANK)
   {
      c = &locator[l->l.r.l.rel & 127];
      if (c->flags & 128) return l;
   }

   return NULL;
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


