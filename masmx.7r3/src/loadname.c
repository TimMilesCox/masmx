
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
      if ((symbol < '0') || (symbol > '9'))
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
   }

   label_margin = s;
   label_highest_byte = i;

   name[i++] = 0;
   while (i & (PARAGRAPH-1)) name[i++] = 0;
   label_length = i;
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


