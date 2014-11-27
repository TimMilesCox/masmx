#define	HT	9
#define	LF	10
#define	CR	13

#define	VT	11
#define	FF	12
#define	BS	8
#define	BEL	7

static long simple_c_escape(int symbol)
{
   switch (symbol)
   {
      case 'n':
         symbol = LF;
         break;

      case 'r':
         symbol = CR;
         break;

      case 't':
         symbol = HT;
         break;

      case 'v':
         symbol = VT;
         break;

      case 'f':
         symbol = FF;
         break;

      case 'b':
         symbol = BS;
         break;

      case 'a':
         symbol = BEL;
         break;

      case '\"':
      case '\'':
      case '\\':
         break;

      default:
         note("extra \\escape value in line");

   }

   return symbol;
}

static inline long string_read(char *q)
{
   static char		*p;
   static int		 out_of_band;

   long			 symbol;
   int			 x,
			 y;


   if (q)
   {
      symbol = *q;
      if (symbol == 0) return 0;
      out_of_band = 0;

      if (symbol == qchar) q++;
      else out_of_band = 1;

      p = q;
   }

   if (p == NULL) return 0;
   
   for (;;)
   {
      if (out_of_band)
      {
         while ((symbol = *p) == ' ') p++;

         if (symbol == 0)
         {
            p = NULL;
            return 0;
         }

         if (symbol == qchar)
         {
            p++;
            out_of_band = 0;
         }
         else
         {
            q = first_at(p, tstring);

            symbol =  zxpression(p, q, NULL);

            if (symbol == zero_code_point)
            {
               note("out-of-band expression equals $zero_code_point");
            }

            if (symbol == 0) symbol = zero_code_point;

            if (*q == sterm) q++;
            else q = NULL;
            p = q;
            return symbol;
         }
      }

      if (p == NULL) return 0;
      symbol = *p++;

      if (symbol == 0)
      {
         p = NULL;
         return 0;
      }


      if (symbol == qchar)
      {
         symbol = *p++;

         if (symbol == qchar) return qchar;

         if (symbol == sterm)
         {
            out_of_band = 1;
            continue;
         }
         p = NULL;
         return 0;
      }
 
      if (symbol == '\\')
      {
         if (selector['c'-'a'] == 0) break;
         symbol = *p++;

         if (symbol == qchar) return qchar;

         if ((symbol >='0') && (symbol <= '7'))
         {
            symbol &= 7;

            /*******************************************************************
		one octal symbol is consumed
		there may be 2 more for bytes 7..9 bits in size = 3 maximum
			     3 more for bytes 10..12 bits in size = 4 maximum
                             nane more for bytes 1..3 bits in size = 1 maximum
                             1 more for bytes 4..6 bits in size = 2 maximum
			     4 more for bytes 11..15 bits in size = 5 maximum
			     5 more for bytes 16..18 bits in size = 6 maximum
			     6 more for bytes 19..21 bits in size = 7 maximum
			     8 more for bytes 22..24 bits in size = 8 maximum
		and so on up to 11 octal symbols maximum for 32-bit bytes

		bytes may be any size 1..32 bits without regard to word
		or address quantum
            *******************************************************************/

            y = (byte - 1)/3;

            while (y--)
            {
               x = *p;
               if (x < '0') break;
               if (x > '7') break;
               symbol <<= 3;
               symbol |= x & 7;
               p++;
            }

            if ((code == DATA_CODE) && (uselector['D'-'A']))
            {
               if (symbol & -256)
               {
                  flag("-D flag \\translate input outside Latin-1 range");
               }
               else symbol = code_set[symbol];
            }

            if (symbol == zero_code_point)
            {
               note("\\escaped expression equals $zero_code_point");
            }

            if (symbol == 0) symbol = zero_code_point;
            return symbol;
         }
      

         switch (symbol)
         {
            case 'x':
               symbol = 0;

               for (;;)
               {
                  x = *p;

                  if      ((x >= '0') && (x <= '9')) x &= 15;
                  else if ((x >= 'a') && (x <= 'f')) x += 10 - 'a';
                  else if ((x >= 'A') && (x <= 'F')) x += 10 - 'A';
                  else break;

                  symbol <<= 4;
                  symbol |= x;
                  p++;
               }

               if ((code == DATA_CODE) && (uselector['D'-'A']))
               {
                  if (symbol & -256)
                  {
                     flag("-D flag \\translate input outside Latin-1 range");
                  }
                  else symbol = code_set[symbol];
               }
         
               if (symbol == 0) symbol = zero_code_point;

               if (symbol == zero_code_point)
               {
                  note("\\escaped expression equals $zero_code_point");
               }

               return symbol;

            default:
               symbol = simple_c_escape(symbol);

         }
      }

      break;
   }

   if (code == ASCII)
   {
      if (byte > 6) return symbol;
      return  (symbol & 31) | ((symbol & 64) >> 1) | zero_code_point;
   }

   symbol = code_set[symbol];

   if (symbol == zero_code_point)
   {
      note("reassign $zero_code_point to an unused code point");
   }

   if (symbol == 0) symbol = zero_code_point;
   return symbol;
}

static int string_space()
{
   if (selector['c'-'a'] ^ selector['z'-'a']) return 0;

   if (code == ASCII)
   {
      if (byte > 6) return ' ';
      return 0;
   }

   return code_set[' '];
}

