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

static void load_trailer(char *s, char *limit)
{
   int			 i = label_highest_byte;
   int			 symbol;

   if (*s == qchar)
   {
      s++;
      while (*s != qchar)
      {
	 if (s == limit) break;
	 symbol = *s++;
	 if ((!selector['k'-'a']) && (symbol > 0x60) && (symbol < 0x7B))
	    symbol &= 0x5F;
	 name[i++] = symbol;
	 if (i > 254) break;
      }
      s++;
   }
   else
   {
      while (((*s > 0x2F) && (*s < 0x3A))
      ||     ((*s > 0x40) && (*s < 0x5B))
      ||     ((*s > 0x60) && (*s < 0x7B))
      ||     (*s == '_')
      ||     (*s == '?')
      ||     (*s == '!')
      ||     (*s == '@')
      ||     (*s == sterm)
      ||     (*s == '$'))
      {
	 if (s == limit) break;
	 symbol = *s++;
	 if ((!selector['k'-'a']) && (symbol > 0x60) && (symbol < 0x7B))
	    symbol &= 0x5F;
	 name[i++] = symbol;
	 if (i > 254) break;
      }
   }

   label_margin = s;
   label_highest_byte = i;
  
   name[i++] = 0;
   while (i & (PARAGRAPH-1)) name[i++] = 0;
   label_length = i;
}

#endif	/*	STRUCTURE_DEPTH	*/
