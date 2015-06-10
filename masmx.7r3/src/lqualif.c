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
      
      while (*s == ' ') s++;
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
