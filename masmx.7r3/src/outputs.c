
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





static void pushh2(char i)
{
   char b[2];
   
   if (!pass) return;
   
   b[0] = ((i >> 4) & 15) | 48;
   b[1] = (i & 15) | 48;
   if (b[0] > '9') b[0] += 7;
   if (b[1] > '9') b[1] += 7;
   write(ohandle, b, 2);
}

static void xpushaddress(line_item *i, int id)
{
   location_counter	*q = &locator[id];
   char			 table[64];
   int			 bits = (q->flags & 1) ? xadw : address_size;
   int			 k = RADIX/8-((bits+7)>>3);
   int			 symbol;
   int			 x = 0;
   

   while (k < RADIX/8)
   {
      symbol = i->b[k++];
      table[x++] = left(symbol);
      table[x++] = right(symbol);
   }
   write(ohandle, table, x);
}

static void pushaddress(int i)
{
   int			 j = AQUARTETS;
   int			 k = AQUARTETS - (address_size + 3) / 4;
   char			 b[AQUARTETS];

   if (!pass) return;
   
   while (j > k)
   {
      j--;
      b[j] = (i & 15) | 48 ;
      if (b[j] > '9') b[j] += 7;
      i >>= 4;
   }
   write(ohandle, &b[j], AQUARTETS - j);
}

static void pushsegx(int i)
{
   int			 j = RADIX/4;
   int			 k = RADIX/4 - ((xadw-address_size)+3) / 4;
   char			 b[RADIX/4];

   if (!pass) return;
   
   while (j > k)
   {
      j--;
      b[j] = (i & 15) | 48 ;
      if (b[j] > '9') b[j] += 7;
      i >>= 4;
   }
   write(ohandle, &b[j], RADIX/4-j);
}

static int pushs(char  *b)
{
   int			 x = strlen(b);

   if (!pass) return x;
   write(ohandle, b, x);
   return x;
}

static void outfactor(int counter_id)
{
   int v = locator[counter_id].relocatable;
   
   if (!(v < 0)) return; 
   v = -v;
   locator[counter_id].relocatable = v;
   if (!pass) return;
   write(ohandle, "\n$", 2);
   pushh2(counter_id);
   write(ohandle, ":", 1);
   write(ohandle, "*", 1);
   pushaddress(v);
}

static void outcounter(int counter_id, int location, char *type)
{
   int		     id = counter_id & 127;
   location_counter *q = &locator[id];
   int		     running_bank = q->runbank.a;
   
   if (!pass) return;
   
   if (q->flags & 1)
   {
      #ifdef LONG_TRAILER

      if (q->flags & 2)
      {
         write(ohandle, "\n@:", 3);
         pushh2(id);
         write(ohandle, ":", 1);
         xpushaddress(&q->runbank.p->value, id);
         q->flags &= 0xFD;
      }

      running_bank = 0;

      #else

      pushxad(id, location, type);
      return;

      #endif
   }

   if (q->relocatable) outfactor(id);

   write(ohandle, type, 2);
   pushh2(id);
   write(ohandle, ":", 1);

   if (q->flags & 1)
   {
      #ifdef ZB_G
      if (q->flags & 128) location += q->base;
      #endif
   }
   else
   {
      if (!q->relocatable)
      {
         if (q->flags & 128) location += q->base;
         if (q->breakpoint)  location -= q->base;
      }

      if (selector['v'-'a'])
      {
         pushsegx(running_bank);
         write(ohandle, ":", 1);
      }
      else
      {
         location += running_bank;
      }
   }

   pushaddress(location);
   write(ohandle, "\n", 1);
   /*
   linex = 0;
   */
}

static void produce(int bits, char dflag, line_item *item, txo *a_image)
{
   int			 datum, i, x, bytes, mask, encode = pass;
   int			 v;
   
   txo 			 d_image = { LITERAL, 0, 0, NULL, 0, 0, 0 };
   txo 			*image  = &d_image;

   #ifdef RELOCATION
   link_profile		*mapx_next = mapx;
   #endif

   int			 granule = word;


   if (a_image) image = a_image; 
   
   if (!bits)
   {
      bits = RADIX;
      i = 0;
      while (i < RADIX/8-1)
      {
	 if (item->b[i+1] & 128)
	 {
	    if (item->b[i] != 0xff) break;
	 }
	 else
	 {
	    if (item->b[i])         break;
	 }
	 i++;
	 bits -= 8;
      }
   }
	 
   bits += granule - 1;
   if (bits > RADIX) bits = RADIX;
   bits /= granule;
   bits *= granule;

   bytes = (bits+EIGHT-1) >> 3;
   
   if ((actual->flags & 128)
   &&  (actual->base == 0)
   &&  (actual->relocatable == 0)
   &&  (actual->runbank.a == 0))
   {
      encode = 0;

      if ((x = mapx - mapinfo))
      {
         while (x--)
         {
            mapx_next--;
            if (mapx_next->scale < 0)
            {
            }
            else
            {
               if (mapx_next->recursion < maprecursion) break;
            }
            mapx = mapx_next;
            note("void section: discarding relocation tuple");
         }
      }
   }

   if (encode)
   {
      if (a_image)
      {
         if (image->symbols) image->d[image->symbols++] = '\n';
      }
      else
      {
         if (outstanding) linex = 0;
         
         if ((linex + bytes*2) > lwidth)
         {
	    linex = 0;
	    image->d[image->symbols++] = '\n';
         }
         else
         {
	    if (linex) 
	    {
	       linex++;
	       image->d[image->symbols++] = ' ';
	    }
         }
      }

      #ifdef RELOCATION

      x = mapx - mapinfo;

      #ifndef DOS
      if ((selector['n'-'a'])
      &&  (selector['l'-'a'])
      &&  (list > depth)
      &&  (pass)
      &&  (!a_image))
      {
         i = x;
         while(i--) illustrate_linkage(i);
      }
      #endif

      i = x;
      while (i--) output_linkage(i, image, a_image);

      while (x--)
      {
         mapx_next--;

         if (mapx_next->scale < 0)
         {
         }
         else
         {
	    if (mapx_next->recursion < maprecursion) break;
         }

         mapx = mapx_next;
      }
      #endif
      
      x = image->symbols;
      i = RADIX/8 - bytes;
      
      /*
      if (outstanding) linex = 0;
      */

      if ((mask = bits & 7))
      {
         datum = item->b[i++] & ((1 << mask) - 1);
	 if (mask > 4) image->d[x++] = left(datum);
	 image->d[x++] = right(datum);         
      }

      while (i < RADIX/8)
      {
	 if (x > IMAGE_SIZE-3) stop();
	 datum = item->b[i++];
	 image->d[x++] = left(datum);
	 image->d[x++] = right(datum);
      }
      
      if (!a_image) linex += bytes*2;
      
      /*
      linex += bytes*2+1;
      if (linex > lwidth)
      {
	 linex = 0;
	 image->d[x++] = '\n';
      }
      else
      {
	 image->d[x++] = ' ';
      }
      */

      image->symbols = x;
   }

   image->bits += bits;

   #ifdef TRACE_BITS
   printf("[bitsarstil %d]", bits);
   #endif

   if (a_image) return;
      
   if ((encode) && (outstanding))
   {
      outcounter(counter_of_reference, loc, "\n$");
      outstanding = 0;
   }
   
   if (encode | selector['d'-'a'] | selector['e'-'a'])
   illustrate(loc, bits, counter_of_reference, dflag, encode, item);

   write(ohandle, d_image.d, d_image.symbols);
   v = bits/address_quantum;
   loc += v;
}

static void pushh4(unsigned short h)
{
   char b[4];
   
   if (!pass) return;
   
   b[0] = ((h >> 12) & 15) | 48;
   b[1] = ((h >> 8) & 15) | 48;
   b[2] = ((h >> 4) & 15) | 48;
   b[3] = (h & 15) | 48;
   if (b[0] > '9') b[0] += 7;
   if (b[1] > '9') b[1] += 7;
   if (b[2] > '9') b[2] += 7;
   if (b[3] > '9') b[3] += 7;
   write(ohandle, b, 4);
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


