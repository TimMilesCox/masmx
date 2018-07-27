#ifdef	FP_XPRESS

/****************************************************************
		find the next operator
		which is not a unary on a constant
		or a positive unary requiring no action
		it's either the 1st or the 2nd operator encountered
****************************************************************/

static char *next_binary_operator(char *s, char *e, char *list, int exclude)
{
  char			*p;

//   s += ofield;
   p = next_operator(s, e, list, exclude);
   if (p == NULL) return NULL;

   while (s < p)
   {
      if (*s++ ^ ' ') return p;
   }

   /*************************************************************
		this looks unary
		but if it's -variable it must be actioned
   *************************************************************/

   if ((*p == '-') && (number(p + 1, e) == 0)) return p; 

   p += ofield;
   return next_operator(p, e, list, exclude);

   /*************************************************************
		this is not cyclic
		if the first operator is not an action
		the next after is
   *************************************************************/
}

#endif

