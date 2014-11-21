#define	HT	9
#define	LF	10
#define	CR	13

#define	VT	11
#define	FF	12
#define	BS	8
#define	BEL	7

static long string_read(char *q)
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
   
   if (out_of_band)
   {
      if (*p == qchar)
      {
         p++;
         out_of_band = 0;
      }
      else
      {
         q = first_at(p, tstring);

         symbol =  zxpression(p, q, NULL);

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
         q = first_at(p, tstring);

         symbol =  zxpression(p, q, NULL);

         if (*q == sterm) q++;
         else q = NULL;
         p = q;
         return symbol;
      }
      p = NULL;
      return 0;
   }
 
   if (symbol == '\\')
   {
      if (selector['c'-'a'] == 0) return coded_character('\\');
      symbol = *p++;

      if (symbol == qchar) return qchar;

      if ((symbol >='0') && (symbol <= '7'))
      {
         symbol &= 7;
         y = 2;

         while (y--)
         {
            x = *p;
            if (x < '0') break;
            if (x > '7') break;
            symbol <<= 3;
            symbol |= x & 7;
            p++;
         }

         if (symbol == 0) symbol == zero_code_point;
         return symbol;
      }
      

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

         case 'f':
            symbol = FF;
            break;

         case 'v':
            symbol = VT;
            break;

         case 'b':
            symbol = BS;
            break;

         case 'a':
            symbol = BEL;
            break;

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

            if (symbol == 0) symbol = zero_code_point;

            return symbol;

         case '\"':
         case '\'':
         case '\\':
            break;

         default:
            note("extra \\escape value in line");
      }
   }

   if (code == ASCII)
   {
      if (byte > 6) return symbol;
      return  (symbol & 31) | ((symbol & 64) >> 1) | zero_code_point;
   }

   symbol = code_set[symbol];

   if (symbol == zero_code_point) flag("reassign $zero_code_point to an unsused code point");

   if (symbol == 0) symbol |= zero_code_point;
   return symbol;
}

static int string_space()
{
   if (selector['c'-'a'] ^ selector['z'-'a']) return 0;

   if (code == ASCII)
   {
      if (byte > 6) return 32;
      return 0;
   }

   return code_set[32];
}

