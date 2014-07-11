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
