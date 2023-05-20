
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



/*************************************************************
		assemble a character string
		into the output binary

		the string occupies the
		containing number of words
*************************************************************/

static void stringline(char *qstring, char *param, txo *image)
{
   line_item		 item = zero_o;
   int			 cache_line = RADIX / word * word;
   int			 positions = cache_line;
   int			 bits = 0;
   int			 symbol;
   int			 mask = (byte == 32) ? 0xFFFFFFFF : (1 << byte) - 1;
   int			 buffer;
   char			*q = substitute(qstring, param);

   int			 x,
                         y;

   for (;;)
   {
      symbol = string_read(q);
      q = NULL;

      if (symbol)
      {
         if (symbol == zero_code_point) symbol = 0;
      }
      else break;

      symbol &= mask;

      positions -= byte;
      bits += byte;

      if (positions < 0)
      {
         y = byte + positions;
         positions = cache_line;
         x = byte - y;

         if (y)
         {
            lshift(&item, y);
            buffer = quadextract(&item);
            buffer |= symbol >> x;
            quadinsert(buffer, &item);
         }

         /**********************************************
		write the full cache line
         ***********************************************/

         produce(cache_line, '+', &item, image);
         item = zero_o;
         quadinsert(symbol, &item);
         positions += y - byte;
      }
      else
      {
         lshift(&item, byte);
         buffer = quadextract(&item);
         buffer |= symbol;
         quadinsert(buffer, &item);
      }
   }


   if ((x = positions % word))
   {
      /**************************************************
		this step cannot overflow the cache line
		because it only fills an incomplete word
      **************************************************/

      symbol = string_space() & mask;

      for (;;)
      {
         x -= byte;
         if (x < 0) break;
         lshift(&item, byte);
         buffer = quadextract(&item);
         buffer |= symbol;
         quadinsert(buffer, &item);
         positions -= byte;
      }

      if (x += byte)
      {
         lshift(&item, x);
         positions -= x;
      }
   }

   /****************************************************
		the cache line may contain
		some unwritten words
   ****************************************************/

   if ((x = cache_line - positions)) produce(x, '+', &item, image);

   record_bits(bits);
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


