
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
   long			 symbol;
   long			 mask = (1 << byte) - 1;
   long			 buffer;
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


   if (x = positions % word)
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

   if (x = cache_line - positions) produce(x, '+', &item, image);

   record_bits(bits);
}
