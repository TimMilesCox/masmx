
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




static int load_qualifier()
{
   long			 x, v  = 0;

   char			 name_aside[256];
   int			 i = 0, j;

   char			 vname[12];
   int			 symbol;

   char			*s = label_margin;
   char			*limit;


   while ((name_aside[i] = name[i])) i++;

   while ((symbol = *s++))
   {
      name_aside[i++] = symbol;
      if (symbol == ')') break;

      limit = first_at(s, ",)");
      
      while (*s == ' ') s++;
      x = expression(s, limit, NULL);
      v = x;

      j = 12;

      while (v)
      {
	 vname[--j] = (v % 10) | '0';
	 v /= 10;
      }
      while (j < 12) name_aside[i++] = vname[j++];
      
      s = limit;
   }

   memcpy(name, name_aside, i);
   label_highest_byte = i;
   label_margin = s;
   name[i++] = 0;
   while (i & (PARAGRAPH-1)) name[i++] = 0;
   label_length = i;

   return x;
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


