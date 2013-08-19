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


static void load_name(char *s, char *limit)
{
   int i = 0;
   register int symbol;
   
   if (!s)
   {
      flag_either_pass("Internal Error 0", "abandon");
      exit(0);
   }

   if (s == limit)
   {
      printf(s, "internal error 00 zero columns expression or label");
      exit(0);
   }

   symbol = *s;

   if (symbol == qchar)
   {
      s++;
      while ((s != limit) && (symbol = *s++))
      {
	 if (symbol == qchar) 
	 {
	    symbol = *s;
	    if (symbol != qchar) break;
	    s++;
	 }

	 if ((!selector['k'-'a']) && (symbol > 0x60) && (symbol < 0x7B))
         {
	    symbol &= 0x5F;
         }

	 name[i++] = symbol;
	 if (i > 254)
	 {
	    if (limit) s = limit;
	    break;
	 }
      }
   }
   else
   {
      while (((symbol > 0x2F) && (symbol < 0x3A))
      ||     ((symbol > 0x40) && (symbol < 0x5B))
      ||     ((symbol > 0x60) && (symbol < 0x7B))
      ||     (symbol == '_')
      ||     (symbol == '?')
      ||     (symbol == '!')
      ||     (symbol == '@')
      ||     (symbol == sterm)
      ||     (symbol == '$'))
      {
	 if (s == limit) break;

	 if ((!selector['k'-'a']) && (symbol > 0x60) && (symbol < 0x7B))
         {
	    symbol &= 0x5F;
         }

	 name[i++] = symbol;

	 if (i > 254)
	 {
	    if (limit) s = limit;
	    break;
	 }

         s++;
	 symbol = *s;
      }
   }

   label_margin = s;
   label_highest_byte = i;

   name[i++] = 0;
   while (i & (PARAGRAPH-1)) name[i++] = 0;
   label_length = i;
}
