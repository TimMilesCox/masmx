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
