#define	ASIDE_BUFFER	4096

static char *stack_string(char *q)
{
   static char		 aside[ASIDE_BUFFER];
   static char		*p = aside;

   char			*from = q;
   char			*to = p;


   if (to > (aside + ASIDE_BUFFER - 120)) p = to = aside;

   while (*to++ = *from++)
   {
      if (to > (aside + ASIDE_BUFFER - 4))
      {
         p = to = aside;
         from = q;
      }
   }

   from = p;
   p = to;
   return from;
}

static char *substitute_alternative(char *s, char *param)
{
   if (selector['q'-'a']) printf("[a::%p \"%s\"]\n", s, s);

   if ((masm_level) && (s))
   {
      s = substitute(s, param);

      if (s) s = stack_string(s);
   }

   if (selector['q'-'a']) printf("[A::%p \"%s\"]\n", s, s);
   return s;
}
