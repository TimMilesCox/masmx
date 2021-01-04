
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




static object *buy_ltable()
{
   object *sr;
   lr->h.type = BYPASS_RECORD;
   lr->h.length = remainder+MARGIN;
   lr->nextbdi.next = 0;
   banx++;

   if (banx == BANKS)
   {
      printf("[%d] too many long labels\n", banx);
      exit(-1);
   }   
   
   sr = (object *) malloc(BANK);
   
   if (!sr) 
   {
      printf("[%d] Too Many Long Labels\n", banx);
      exit(-1);
   }   
   
   lr->nextbdi.next = banx;
   bank[banx] = sr;
   lr = sr;
   remainder = BANK-MARGIN;
   return sr;
}

object *buy_object(int size)
{
   object	*sr = lr;
   int		 bucket = (size + PARAGRAPH - 1) & -PARAGRAPH;

   if (remainder < size) sr = buy_ltable();
   remainder -= bucket;

   sr->h.length = bucket;
   lr = (object *) (char *) sr + bucket;

   return sr;
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


