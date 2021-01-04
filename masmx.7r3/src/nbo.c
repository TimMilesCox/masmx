#ifdef	ESPRESSO

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

#ifdef	FP_XPRESS

static int digitstring(char *left, char *right)
{
   int           symbol,
                 digits = 0,
                 points = 0,
                 leading_symbol = 0;

   while (right > left)
   {
      right--;
      symbol = *right;
      if (symbol == '.')
      {
         points++;
         continue;
      }

      if (symbol < '0') break;
      if (symbol > '9') break;
      digits++;
      leading_symbol = symbol;
   }

   if (points > 1) flag("decimal points multiple");
   if ((points == 0) && (leading_symbol == '0')) flag("decimal.string required");
   return digits;
}

static char *next_nonexponent_operator(char *s, char *e, char *list, int exclude)
{
   char                 *origin = s,
                        *p,
                        *q;


   int                   symbol;

//   s += ofield;

   while ((p = next_operator(s, e, list, exclude)))
   {
      q = p - 1;
      symbol = *q;

      s = p + ofield;

      if ((symbol ^ 'e') && (symbol ^ 'E')) break;
      symbol = digitstring(origin, q);
      if (symbol == 0) break;
   }

   return p;
}

static char *next_binary_nonexponent_operator(char *s, char *e, char *list, int exclude)
{
  char                  *p;

//   s += ofield;
   p = next_nonexponent_operator(s, e, list, exclude);
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
   return next_nonexponent_operator(p, e, list, exclude);

   /*************************************************************
                this is not cyclic
                if the first operator is not an action
                the next after is
   *************************************************************/
}

static char *floperates(char *s, char *e, char *list)
{
   char         *sense;
   int           symbol;

   while ((e = operates(s, e, list)))
   {
      symbol = *e;
      sense = e - 1;
      if ((symbol ^ '-') && (symbol ^ '+')) break;
      symbol = *sense;
      if ((symbol ^ 'e') && (symbol ^ 'E')) break;
      if (digitstring(s, sense) == 0) break;
   }

   return e;
}


#endif

