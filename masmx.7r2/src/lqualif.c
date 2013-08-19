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


static int load_qualifier()
{
   long			 x, v  = 0;

   char			 name_aside[256];
   int			 i = 0, j;

   char			 vname[12];
   int			 symbol;

   char			*s = label_margin;
   char			*limit;


   while (name_aside[i] = name[i]) i++;

   while (symbol = *s++)
   {
      name_aside[i++] = symbol;
      if (symbol == ')') break;

      limit = first_at(s, ",)");
      
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
