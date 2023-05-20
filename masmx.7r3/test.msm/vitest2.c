static int	 one = 1;
int		 two_more = 2;

int add_more(int input)
{
   static int	 one = 1;

   int		 two = 2;

   two += input;
   two += one;
   return two;
}

int adagain_more(int input)
{
   static int    one = 1;

   int           two = 2;

   two += input;
   two += one;
   return two;
}
